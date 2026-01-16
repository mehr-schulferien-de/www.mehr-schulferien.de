defmodule Mix.Tasks.SchoolQuarantineTest do
  use MehrSchulferien.DataCase
  import ExUnit.CaptureIO
  import MehrSchulferien.Factory

  alias Mix.Tasks.SchoolQuarantine

  describe "school_quarantine task" do
    test "quarantine option quarantines a school" do
      school = insert(:school, is_quarantined: false)

      output =
        capture_io(fn ->
          SchoolQuarantine.run(["--quarantine", school.slug])
        end)

      assert output =~ "School quarantined"

      # Verify in database
      updated = MehrSchulferien.Locations.get_school_by_slug_including_quarantined(school.slug)
      assert updated.is_quarantined == true
    end

    test "unquarantine option removes quarantine" do
      school = insert(:school, is_quarantined: true)

      output =
        capture_io(fn ->
          SchoolQuarantine.run(["--unquarantine", school.slug])
        end)

      assert output =~ "Quarantine removed"

      # Verify in database
      updated = MehrSchulferien.Locations.get_school_by_slug_including_quarantined(school.slug)
      assert updated.is_quarantined == false
    end

    test "quarantine reports already quarantined school" do
      school = insert(:school, is_quarantined: true)

      output =
        capture_io(fn ->
          SchoolQuarantine.run(["--quarantine", school.slug])
        end)

      assert output =~ "already quarantined"
    end

    test "unquarantine reports not quarantined school" do
      school = insert(:school, is_quarantined: false)

      output =
        capture_io(fn ->
          SchoolQuarantine.run(["--unquarantine", school.slug])
        end)

      assert output =~ "not quarantined"
    end

    test "list option shows quarantined schools" do
      _normal = insert(:school, is_quarantined: false)
      quarantined = insert(:school, is_quarantined: true)

      output =
        capture_io(fn ->
          SchoolQuarantine.run(["--list"])
        end)

      assert output =~ quarantined.name
      assert output =~ "Quarantined schools"
    end

    test "list option shows message when no quarantined schools" do
      insert(:school, is_quarantined: false)

      output =
        capture_io(fn ->
          SchoolQuarantine.run(["--list"])
        end)

      assert output =~ "No quarantined schools found"
    end

    test "status option shows school status" do
      school = insert(:school, is_quarantined: true)

      output =
        capture_io(fn ->
          SchoolQuarantine.run(["--status", school.slug])
        end)

      assert output =~ school.name
      assert output =~ "QUARANTINED"
    end

    test "status option shows active for non-quarantined" do
      school = insert(:school, is_quarantined: false)

      output =
        capture_io(fn ->
          SchoolQuarantine.run(["--status", school.slug])
        end)

      assert output =~ school.name
      assert output =~ "ACTIVE"
    end

    test "reports error for non-existent school" do
      output =
        capture_io(:stderr, fn ->
          SchoolQuarantine.run(["--quarantine", "non-existent-school"])
        end)

      assert output =~ "School not found"
    end

    test "shows usage for invalid arguments" do
      # Error message goes to stderr, usage goes to stdout
      {_stderr, stdout} =
        capture_both(:stderr, fn ->
          capture_io(fn ->
            SchoolQuarantine.run(["--invalid"])
          end)
        end)

      assert stdout =~ "Usage:"
    end

    defp capture_both(device, fun) do
      stderr_output =
        capture_io(device, fn ->
          send(self(), {:stdout, fun.()})
        end)

      receive do
        {:stdout, stdout} -> {stderr_output, stdout}
      end
    end
  end
end
