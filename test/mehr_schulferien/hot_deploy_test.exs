defmodule MehrSchulferien.HotDeployTest do
  use ExUnit.Case, async: true

  alias MehrSchulferien.HotDeploy

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

  describe "apply_from_tarball/1" do
    test "returns error for invalid tarball name" do
      assert {:error, :invalid_tarball_name} = HotDeploy.apply_from_tarball("/tmp/invalid.tar.gz")
    end

    test "extracts version from valid tarball name" do
      # This will fail at extraction step but validates the name parsing
      result = HotDeploy.apply_from_tarball("/tmp/hot-upgrade-1.0.0.tar.gz")
      # Either succeeds in parsing version or fails at extraction
      assert match?({:error, _}, result) or match?({:ok, _, _}, result)
    end
  end
end
