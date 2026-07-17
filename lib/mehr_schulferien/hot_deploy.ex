defmodule MehrSchulferien.HotDeploy do
  @moduledoc """
  Hot code upgrade support for MehrSchulferien.

  This module enables filesystem-based hot code upgrades, allowing near-zero
  downtime deployments (typically <1 second) without restarting the application.

  ## How It Works

  1. The deployment script places a `.beam` file tarball in the hot-upgrades directory
  2. This module detects the new file and extracts the beam files
  3. It suspends processes, loads the new code, and resumes processes
  4. The upgrade completes in <1 second while preserving connections

  ## Configuration

      config :mehr_schulferien, MehrSchulferien.HotDeploy,
        enabled: true,
        upgrades_dir: "/home/mehrschul2025/app/hot-upgrades",
        check_interval: 10_000  # Check every 10 seconds

  ## Usage

  Hot upgrades are triggered automatically when:
  1. A file named `hot-upgrade-*.tar.gz` is placed in the upgrades directory
  2. The application is running in production mode
  3. Hot deploy is enabled in configuration

  To force a cold deploy instead, add `[cold-deploy]` or `[restart]` to your
  commit message.
  """

  require Logger

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
            apply_upgrade(upgrades_dir, version)

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

  @doc """
  Manually trigger a hot upgrade from a specific tarball.
  """
  def apply_from_tarball(tarball_path) do
    config = Application.get_env(:mehr_schulferien, __MODULE__, [])
    upgrades_dir = Keyword.get(config, :upgrades_dir, "/tmp/hot-upgrades")

    with {:ok, version} <- extract_version_from_path(tarball_path),
         :ok <- extract_tarball(tarball_path, upgrades_dir, version),
         :ok <- apply_upgrade(upgrades_dir, version) do
      {:ok, :upgraded, version}
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
      load_beam_files(beam_dir)
    else
      {:error, {:beam_dir_not_found, beam_dir}}
    end
  end

  defp load_beam_files(beam_dir) do
    beam_files =
      beam_dir
      |> File.ls!()
      |> Enum.filter(&String.ends_with?(&1, ".beam"))

    if Enum.empty?(beam_files) do
      {:error, :no_beam_files}
    else
      Logger.info("[HotDeploy] Loading #{length(beam_files)} beam files")

      # Suspend processes before loading new code
      :sys.suspend(MehrSchulferienWeb.Endpoint)

      try do
        results =
          Enum.map(beam_files, fn beam_file ->
            module_name =
              beam_file
              |> String.trim_trailing(".beam")
              |> String.to_atom()

            beam_path = Path.join(beam_dir, beam_file)
            beam_binary = File.read!(beam_path)

            case :code.load_binary(module_name, ~c"#{beam_path}", beam_binary) do
              {:module, ^module_name} ->
                Logger.debug("[HotDeploy] Loaded #{module_name}")
                {:ok, module_name}

              {:error, reason} ->
                Logger.warning("[HotDeploy] Failed to load #{module_name}: #{inspect(reason)}")
                {:error, module_name, reason}
            end
          end)

        successful = Enum.count(results, &match?({:ok, _}, &1))
        failed = Enum.count(results, &match?({:error, _, _}, &1))

        Logger.info("[HotDeploy] Loaded #{successful} modules, #{failed} failed")

        if failed == 0 do
          :ok
        else
          {:error, {:partial_load, successful, failed}}
        end
      after
        # Resume processes after loading
        :sys.resume(MehrSchulferienWeb.Endpoint)
      end
    end
  end

  defp extract_tarball(tarball_path, upgrades_dir, version) do
    target_dir = Path.join([upgrades_dir, version, "beams"])
    File.mkdir_p!(target_dir)

    case System.cmd("tar", ["-xzf", tarball_path, "-C", target_dir], stderr_to_stdout: true) do
      {_, 0} -> :ok
      {output, code} -> {:error, {:tar_failed, code, output}}
    end
  end

  defp extract_version_from_path(path) do
    # Expected format: hot-upgrade-VERSION.tar.gz
    basename = Path.basename(path)

    case Regex.run(~r/^hot-upgrade-(.+)\.tar\.gz$/, basename) do
      [_, version] -> {:ok, version}
      nil -> {:error, :invalid_tarball_name}
    end
  end
end
