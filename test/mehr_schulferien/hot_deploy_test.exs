defmodule MehrSchulferien.HotDeployTest do
  # Loads code into the running VM and changes the application env
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog

  alias MehrSchulferien.HotDeploy

  @changed MehrSchulferien.HotDeployTest.Changed
  @unchanged MehrSchulferien.HotDeployTest.Unchanged

  describe "startup_reapply_current/0" do
    test "returns :ok when disabled" do
      assert HotDeploy.startup_reapply_current() == :ok
    end
  end

  describe "check_and_apply/0" do
    test "returns disabled when not enabled in config" do
      # Default test config has hot deploy disabled
      assert HotDeploy.check_and_apply() == {:ok, :disabled}
    end
  end

  describe "with hot deploy enabled" do
    setup do
      dir = Path.join(System.tmp_dir!(), "hot-deploy-test-#{System.unique_integer([:positive])}")
      File.mkdir_p!(dir)
      previous = Application.get_env(:mehr_schulferien, HotDeploy)
      Application.put_env(:mehr_schulferien, HotDeploy, enabled: true, upgrades_dir: dir)

      on_exit(fn ->
        if previous,
          do: Application.put_env(:mehr_schulferien, HotDeploy, previous),
          else: Application.delete_env(:mehr_schulferien, HotDeploy)

        :persistent_term.erase({HotDeploy, :version})
        File.rm_rf!(dir)

        for module <- [@changed, @unchanged] do
          :code.purge(module)
          :code.delete(module)
          :code.purge(module)
        end
      end)

      {:ok, dir: dir}
    end

    test "loads a changed module into the running VM", %{dir: dir} do
      load(@changed, 1)
      stage(dir, "9.9.9-abc1234", "pending", [{@changed, beam(@changed, 2)}])

      assert HotDeploy.check_and_apply() == {:ok, :upgraded, "9.9.9-abc1234"}

      assert value(@changed) == 2
      assert File.read!(Path.join(dir, "current")) == "9.9.9-abc1234"
      refute File.exists?(Path.join(dir, "pending"))
    end

    test "reports the hot version as the deployed version", %{dir: dir} do
      assert HotDeploy.deployed_version() ==
               to_string(Application.spec(:mehr_schulferien, :vsn))

      stage(dir, "9.9.9-abc1234", "pending", [{@changed, beam(@changed, 2)}])
      assert {:ok, :upgraded, _} = HotDeploy.check_and_apply()

      assert HotDeploy.deployed_version() == "9.9.9-abc1234"
    end

    test "only touches modules whose code differs", %{dir: dir} do
      load(@changed, 1)
      load(@unchanged, 1)

      stage(dir, "9.9.9-abc1234", "pending", [
        {@changed, beam(@changed, 2)},
        {@unchanged, beam(@unchanged, 1)}
      ])

      beam_dir = Path.join([dir, "9.9.9-abc1234", "beams"])

      assert [@changed] == beam_dir |> HotDeploy.changed_modules() |> Enum.map(&elem(&1, 0))
    end

    test "refuses an upgrade that changes the application module", %{dir: dir} do
      running = MehrSchulferien.Application.module_info(:md5)

      stage(dir, "9.9.9-abc1234", "pending", [
        {MehrSchulferien.Application, beam(MehrSchulferien.Application, 2)}
      ])

      log =
        capture_log(fn ->
          assert HotDeploy.check_and_apply() ==
                   {:error, {:restart_required, [MehrSchulferien.Application]}}
        end)

      assert log =~ "restart_required"
      assert MehrSchulferien.Application.module_info(:md5) == running
      refute File.exists?(Path.join(dir, "current"))
    end

    # Consolidated protocols only know the implementations the release was
    # built with, so a new one dispatches nowhere until the next release.
    test "refuses an upgrade that brings a protocol implementation", %{dir: dir} do
      stage(dir, "9.9.9-abc1234", "pending", [{@changed, beam(@changed, 1, [:__impl__])}])

      log =
        capture_log(fn ->
          assert HotDeploy.check_and_apply() == {:error, {:restart_required, [@changed]}}
        end)

      assert log =~ "restart_required"
      refute Code.ensure_loaded?(@changed)
    end

    # A deleted implementation stays loaded and stays part of the dispatch
    test "sees a protocol implementation the new build no longer has", %{dir: dir} do
      {:module, @unchanged} =
        :code.load_binary(@unchanged, ~c"hot_deploy_test", beam(@unchanged, 1, [:__impl__]))

      load(@changed, 1)
      stage(dir, "9.9.9-abc1234", "pending", [{@changed, beam(@changed, 2)}])
      beam_dir = Path.join([dir, "9.9.9-abc1234", "beams"])

      assert HotDeploy.removed_protocol_modules(beam_dir, [@changed, @unchanged]) == [@unchanged]
    end

    test "refuses an upgrade while a process still runs older code", %{dir: dir} do
      load(@changed, 1)
      pid = spawn(@changed, :loop, [])
      # The process stays in version 1, which is now the old code
      load(@changed, 2)
      stage(dir, "9.9.9-abc1234", "pending", [{@changed, beam(@changed, 3)}])

      log =
        capture_log(fn ->
          assert HotDeploy.check_and_apply() == {:error, {:old_code_in_use, [@changed]}}
        end)

      assert log =~ "old_code_in_use"
      assert value(@changed) == 2
      assert Process.alive?(pid)
      send(pid, :stop)
    end

    test "startup_reapply_current/0 loads the current upgrade again", %{dir: dir} do
      load(@changed, 1)
      stage(dir, "9.9.9-abc1234", "current", [{@changed, beam(@changed, 2)}])

      assert HotDeploy.startup_reapply_current() == :ok

      assert value(@changed) == 2
      assert HotDeploy.deployed_version() == "9.9.9-abc1234"
    end
  end

  # A module with value/0 and a loop/0 that blocks in a receive. Built from
  # Erlang forms, so nothing is loaded or redefined while compiling.
  # `marker_functions` adds exported one-argument functions, the way a
  # protocol implementation carries `__impl__/1`.
  defp beam(module, value, marker_functions \\ []) do
    forms = [
      {:attribute, 1, :module, module},
      {:attribute, 1, :export, [value: 0, loop: 0] ++ Enum.map(marker_functions, &{&1, 1})},
      {:function, 1, :value, 0, [{:clause, 1, [], [], [{:integer, 1, value}]}]},
      {:function, 1, :loop, 0,
       [
         {:clause, 1, [], [],
          [{:receive, 1, [{:clause, 1, [{:atom, 1, :stop}], [], [{:atom, 1, :ok}]}]}]}
       ]}
      | Enum.map(marker_functions, fn name ->
          {:function, 1, name, 1, [{:clause, 1, [{:var, 1, :_}], [], [{:atom, 1, :ok}]}]}
        end)
    ]

    {:ok, ^module, binary} = :compile.forms(forms)
    binary
  end

  # The module only exists at runtime, so the call must not be checked at compile time
  defp value(module), do: module.value()

  defp load(module, value) do
    {:module, ^module} = :code.load_binary(module, ~c"hot_deploy_test", beam(module, value))
  end

  defp stage(dir, version, marker, beams) do
    beam_dir = Path.join([dir, version, "beams"])
    File.mkdir_p!(beam_dir)

    for {module, binary} <- beams do
      File.write!(Path.join(beam_dir, "#{module}.beam"), binary)
    end

    File.write!(Path.join(dir, marker), version)
  end
end
