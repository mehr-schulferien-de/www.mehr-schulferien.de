defmodule MehrSchulferien.HotDeploy do
  @moduledoc """
  Hot code upgrade support for MehrSchulferien.

  This module enables filesystem-based hot code upgrades, allowing near-zero
  downtime deployments (typically <1 second) without restarting the application.

  ## How It Works

  1. The deployment script compiles the new code and copies the application's
     `.beam` files to `<upgrades_dir>/<version>/beams`
  2. It writes the version to `<upgrades_dir>/pending` and calls
     `check_and_apply/0` on the running node (`bin/mehr_schulferien rpc`)
  3. The modules whose code differs from the loaded one are loaded; all others
     are left alone
  4. The version moves to `<upgrades_dir>/current`, which a restart of the
     release loads again on boot, because the release on disk is still the old one

  A hot upgrade only replaces code of this application. Dependencies, config,
  `priv`, static assets and migrations are the deployment script's business:
  it restarts the release (cold deploy) when any of them changed.

  An upgrade is refused, and the script falls back to a cold deploy, when it
  changes a module that only takes effect on a restart or with a new release
  (the application module, protocols and their implementations), or when a
  process still runs code from before the previous upgrade.

  ## Configuration

      config :mehr_schulferien, MehrSchulferien.HotDeploy,
        enabled: true,
        upgrades_dir: "/home/mehrschul2025/app/hot-upgrades"

  To force a cold deploy, add `[cold-deploy]` or `[restart]` to the commit
  message. Do that for changes to supervised processes and their state.
  """

  require Logger

  # Their code runs once, when the application starts
  @restart_modules [MehrSchulferien.Application]

  # Protocols are consolidated when the release is built: a protocol or an
  # implementation that arrives later is not part of the dispatch.
  @protocol_functions [__protocol__: 1, __impl__: 1]

  @doc """
  The version the node is running: the release version, or the version of
  the hot upgrade applied on top of it (`<version>-<commit>`).
  """
  def deployed_version do
    :persistent_term.get(
      {__MODULE__, :version},
      to_string(Application.spec(:mehr_schulferien, :vsn))
    )
  end

  @doc """
  Called at application startup to reapply any pending hot upgrade.

  If the application crashed or was restarted after a hot upgrade was deployed
  but before it was fully applied, this ensures the latest code is loaded.
  """
  def startup_reapply_current do
    config = Application.get_env(:mehr_schulferien, __MODULE__, [])
    enabled = Keyword.get(config, :enabled, false)
    upgrades_dir = Keyword.get(config, :upgrades_dir)

    if enabled and upgrades_dir do
      current_marker = Path.join(upgrades_dir, "current")

      if File.exists?(current_marker) do
        case File.read(current_marker) do
          {:ok, version} ->
            version = String.trim(version)
            Logger.info("[HotDeploy] Reapplying current version #{version} on startup")

            with {:error, reason} <- apply_upgrade(upgrades_dir, version) do
              Logger.error("[HotDeploy] Could not reapply #{version}: #{inspect(reason)}")
            end

          {:error, reason} ->
            Logger.warning("[HotDeploy] Could not read current marker: #{inspect(reason)}")
        end
      end
    end

    :ok
  end

  @doc """
  Checks for and applies any pending hot upgrades.

  Returns:
  - `{:ok, :upgraded, version}` if an upgrade was applied
  - `{:ok, :no_upgrade}` if no upgrade was pending
  - `{:error, reason}` if an error occurred
  """
  def check_and_apply do
    config = Application.get_env(:mehr_schulferien, __MODULE__, [])
    enabled = Keyword.get(config, :enabled, false)
    upgrades_dir = Keyword.get(config, :upgrades_dir)

    cond do
      not enabled ->
        {:ok, :disabled}

      is_nil(upgrades_dir) ->
        {:error, :no_upgrades_dir_configured}

      not File.dir?(upgrades_dir) ->
        {:error, :upgrades_dir_not_found}

      true ->
        check_for_upgrade(upgrades_dir)
    end
  end

  # Private functions

  defp check_for_upgrade(upgrades_dir) do
    pending_marker = Path.join(upgrades_dir, "pending")

    if File.exists?(pending_marker) do
      case File.read(pending_marker) do
        {:ok, version} ->
          version = String.trim(version)
          Logger.info("[HotDeploy] Found pending upgrade: #{version}")

          case apply_upgrade(upgrades_dir, version) do
            :ok ->
              # Move pending to current
              current_marker = Path.join(upgrades_dir, "current")
              File.write!(current_marker, version)
              File.rm(pending_marker)
              {:ok, :upgraded, version}

            {:error, reason} = error ->
              Logger.error("[HotDeploy] Failed to apply upgrade: #{inspect(reason)}")
              error
          end

        {:error, reason} ->
          {:error, {:read_pending_marker, reason}}
      end
    else
      {:ok, :no_upgrade}
    end
  end

  defp apply_upgrade(upgrades_dir, version) do
    beam_dir = Path.join([upgrades_dir, version, "beams"])

    if File.dir?(beam_dir) do
      Logger.info("[HotDeploy] Applying upgrade from #{beam_dir}")

      with :ok <- load_changed_modules(beam_dir) do
        :persistent_term.put({__MODULE__, :version}, version)
        :ok
      end
    else
      {:error, {:beam_dir_not_found, beam_dir}}
    end
  end

  @doc false
  # The modules in `beam_dir` whose code differs from the loaded one, as
  # `{module, md5, path, binary}`.
  def changed_modules(beam_dir) do
    beam_dir
    |> File.ls!()
    |> Enum.filter(&String.ends_with?(&1, ".beam"))
    |> Enum.sort()
    |> Enum.flat_map(fn beam_file ->
      path = Path.join(beam_dir, beam_file)
      binary = File.read!(path)
      {:ok, {module, md5}} = :beam_lib.md5(binary)

      if loaded_md5(module) == md5, do: [], else: [{module, md5, path, binary}]
    end)
  end

  defp needs_restart?({module, _md5, _path, binary}) do
    {:ok, {^module, [exports: exports]}} = :beam_lib.chunks(binary, [:exports])

    module in @restart_modules or Enum.any?(@protocol_functions, &(&1 in exports))
  end

  @doc false
  # The protocols and implementations among `app_modules` that `beam_dir` no
  # longer ships. They stay loaded, and a consolidated protocol keeps
  # dispatching to them.
  def removed_protocol_modules(beam_dir, app_modules) do
    shipped = beam_dir |> File.ls!() |> MapSet.new(&Path.rootname(&1, ".beam"))

    Enum.filter(app_modules, fn module ->
      Atom.to_string(module) not in shipped and Code.ensure_loaded?(module) and
        Enum.any?(@protocol_functions, fn {name, arity} ->
          function_exported?(module, name, arity)
        end)
    end)
  end

  defp loaded_md5(module) do
    if Code.ensure_loaded?(module), do: module.module_info(:md5)
  end

  defp load_changed_modules(beam_dir) do
    changed = changed_modules(beam_dir)
    modules = Enum.map(changed, &elem(&1, 0))
    app_modules = Application.spec(:mehr_schulferien, :modules) || []

    restart =
      for(entry <- changed, needs_restart?(entry), do: elem(entry, 0)) ++
        removed_protocol_modules(beam_dir, app_modules)

    cond do
      File.ls!(beam_dir) == [] ->
        {:error, :no_beam_files}

      restart != [] ->
        {:error, {:restart_required, restart}}

      # Loading a module a second time needs its old code gone. A soft purge
      # refuses while a process still runs it, instead of killing the process.
      (in_use = Enum.reject(modules, &:code.soft_purge/1)) != [] ->
        {:error, {:old_code_in_use, in_use}}

      true ->
        load_modules(changed)
    end
  end

  defp load_modules(changed) do
    Logger.info("[HotDeploy] Loading #{length(changed)} changed modules")

    # Not running yet when the upgrade is reapplied during application start
    endpoint = Process.whereis(MehrSchulferienWeb.Endpoint)
    if endpoint, do: :sys.suspend(endpoint)

    try do
      failed =
        Enum.reject(changed, fn {module, md5, path, binary} ->
          match?({:module, ^module}, :code.load_binary(module, to_charlist(path), binary)) and
            loaded_md5(module) == md5
        end)

      if failed == [] do
        :ok
      else
        {:error, {:partial_load, length(changed) - length(failed), length(failed)}}
      end
    after
      if endpoint, do: :sys.resume(endpoint)
    end
  end
end
