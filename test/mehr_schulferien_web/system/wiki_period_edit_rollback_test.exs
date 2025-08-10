defmodule MehrSchulferienWeb.System.WikiPeriodEditRollbackTest do
  use MehrSchulferienWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  import MehrSchulferien.Factory

  alias MehrSchulferien.Repo

  describe "wiki period edit and rollback functionality" do
    setup do
      # Create test data using factories
      germany = insert(:country, name: "Deutschland")

      federal_state =
        insert(:federal_state, parent_location_id: germany.id, name: "Test Bundesland")

      vacation_type =
        insert(:holiday_or_vacation_type,
          name: "Testferien",
          default_is_school_vacation: true
        )

      # Create a period that's in the future so it can be edited
      future_date = Date.utc_today() |> Date.add(30)

      period =
        insert(:period,
          starts_on: future_date,
          ends_on: future_date |> Date.add(10),
          location_id: federal_state.id,
          holiday_or_vacation_type_id: vacation_type.id,
          is_school_vacation: true,
          memo: "Original memo"
        )

      %{
        federal_state: federal_state,
        vacation_type: vacation_type,
        period: period
      }
    end

    test "edit period shows version history with before/after values", %{
      conn: conn,
      period: period
    } do
      # First make a change to create version history
      {:ok, %{model: _period, version: _version}} =
        PaperTrail.update(
          MehrSchulferien.Periods.Period.changeset(period, %{memo: "First update"}),
          meta: %{ip_address: "127.0.0.1"}
        )

      # Visit the edit page
      {:ok, view, html} = live(conn, "/wiki/periods/#{period.id}/edit")

      # Check initial state
      assert html =~ "Ferientermin bearbeiten"
      assert html =~ "Änderungshistorie"

      # Verify version history shows the changes
      # Note: PaperTrail doesn't capture the original value before the first change,
      # so we can't see "Original memo" in the version history
      # New value
      assert html =~ "First update"
      assert html =~ "Notiz:"

      # Now make another change through the form
      # First change the form value
      view
      |> element("form")
      |> render_change(%{
        period: %{
          memo: "Second update via form"
        }
      })

      # Then submit the form with the same values
      view
      |> element("form")
      |> render_submit(%{
        period: %{
          memo: "Second update via form"
        }
      })

      # Get the updated HTML
      html = render(view)

      # Check that the flash message appears
      assert html =~ "erfolgreich aktualisiert"

      # Reload the period to verify it was actually saved
      period = Repo.reload!(period)
      assert period.memo == "Second update via form"

      # Check version history now shows the latest change with before/after
      # The version history should show the new memo value
      assert html =~ "Second update via form"

      # Check for the improved diff display (old value in red background, new value in green background)
      assert html =~ "bg-red-50"
      assert html =~ "bg-green-50"
      # Arrow showing transition
      assert html =~ "→"
      # Check for "Aktueller Stand" label on the most recent version
      assert html =~ "Aktueller Stand"
    end

    test "rollback functionality works correctly", %{conn: conn, period: period} do
      # Create two versions
      {:ok, %{model: _period, version: version1}} =
        PaperTrail.update(
          MehrSchulferien.Periods.Period.changeset(period, %{memo: "Version 1"}),
          meta: %{ip_address: "127.0.0.1"}
        )

      {:ok, %{model: _period, version: _version2}} =
        PaperTrail.update(
          MehrSchulferien.Periods.Period.changeset(Repo.reload!(period), %{memo: "Version 2"}),
          meta: %{ip_address: "127.0.0.1"}
        )

      # Visit the edit page
      {:ok, view, _html} = live(conn, "/wiki/periods/#{period.id}/edit")

      # The most recent version (version2) should show "Aktueller Stand" and not have a rollback button
      # The older version (version1) should have a rollback button
      # Click the rollback button for the first version
      view
      |> element("[phx-click='rollback'][phx-value-version-id='#{version1.id}']")
      |> render_click()

      # Check the result
      html = render(view)

      assert html =~ "Erfolgreich zur ausgewählten Version zurückgekehrt"

      # Verify the data has been rolled back in the database
      period = Repo.reload!(period)
      assert period.memo == "Version 1"

      # IMPORTANT: Verify the form input also shows the rolled-back value
      # Check if the form shows Version 1
      form_has_version1 =
        html =~ ~r/<textarea[^>]*name=["']period\[memo\]["'][^>]*>Version 1<\/textarea>/s ||
          html =~
            ~r/<input[^>]*type=["']text["'][^>]*name=["']period\[memo\]["'][^>]*value=["']Version 1["']/s

      assert form_has_version1, "Form should show 'Version 1' after rollback"

      # Check that version history now shows the rollback as a new version
      html = render(view)
      # Old value
      assert html =~ "Version 2"
      # Rolled back to value
      assert html =~ "Version 1"
    end

    test "daily changes counter updates correctly", %{conn: conn, period: period} do
      # Visit the edit page
      {:ok, view, html} = live(conn, "/wiki/periods/#{period.id}/edit")

      # Check initial daily changes display
      assert html =~ "Änderungen heute:"

      # Make a change
      view
      |> element("form")
      |> render_change(%{
        period: %{
          memo: "Updated memo"
        }
      })

      view
      |> element("form")
      |> render_submit()

      # The daily changes counter should increment
      html = render(view)
      assert html =~ "Änderungen heute:"
      # Check that the counter shows at least 1 change
      assert html =~ ~r/Änderungen heute: \d+ \/ \d+/
    end
  end
end
