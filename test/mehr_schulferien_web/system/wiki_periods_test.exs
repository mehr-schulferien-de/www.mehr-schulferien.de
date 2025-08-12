defmodule MehrSchulferienWeb.WikiPeriodsSystemTest do
  use MehrSchulferienWeb.ConnCase
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  import MehrSchulferien.Factory

  alias MehrSchulferien.{Periods, Repo}

  describe "wiki hub page" do
    test "displays wiki hub with links to all features", %{conn: conn} do
      # Visit the wiki hub page
      conn = get(conn, "/wiki")
      response = html_response(conn, 200)

      # Verify page content
      assert response =~ "Wiki - Gemeinsam mehr Schulferien"
      assert response =~ "Helfen Sie mit, die Daten zu verbessern"

      # Check for school management section
      assert response =~ "Schulen verwalten"
      assert response =~ "Schuladressen hinzufügen, bearbeiten und aktualisieren"
      assert response =~ "Neue Schule hinzufügen"

      # Check for period management section
      assert response =~ "Ferientermine verwalten"
      assert response =~ "Schulferien für Bundesländer bearbeiten"
      assert response =~ "Ferientermine anzeigen"
      assert response =~ "Neue Ferien hinzufügen"

      # Check guidelines
      assert response =~ "Richtlinien für Wiki-Beiträge"
      assert response =~ "Alle Änderungen werden protokolliert"
    end
  end

  describe "period index page" do
    setup do
      # Create test data
      germany = insert(:country, name: "Deutschland")
      bayern = insert(:federal_state, parent_location_id: germany.id, name: "Bayern")
      hessen = insert(:federal_state, parent_location_id: germany.id, name: "Hessen")

      sommerferien =
        insert(:holiday_or_vacation_type,
          name: "Sommerferien",
          slug: "sommerferien",
          default_is_school_vacation: true
        )

      winterferien =
        insert(:holiday_or_vacation_type,
          name: "Winterferien",
          slug: "winterferien",
          default_is_school_vacation: true
        )

      # Create periods - always in the future for testing
      future_date = Date.utc_today() |> Date.add(30)
      _future_year = future_date.year

      period1 =
        insert(:period,
          location_id: bayern.id,
          holiday_or_vacation_type_id: sommerferien.id,
          starts_on: future_date,
          ends_on: future_date |> Date.add(14),
          is_school_vacation: true
        )

      period2 =
        insert(:period,
          location_id: hessen.id,
          holiday_or_vacation_type_id: winterferien.id,
          starts_on: future_date |> Date.add(60),
          ends_on: future_date |> Date.add(75),
          is_school_vacation: true
        )

      %{
        bayern: bayern,
        hessen: hessen,
        sommerferien: sommerferien,
        winterferien: winterferien,
        period1: period1,
        period2: period2
      }
    end

    test "displays list of periods with filtering", %{
      conn: conn,
      bayern: bayern,
      hessen: _hessen,
      sommerferien: sommerferien,
      period1: _period1,
      period2: _period2
    } do
      {:ok, view, _html} = live(conn, "/wiki/periods")

      # Verify page title
      assert has_element?(view, "h1", "Ferientermine verwalten")

      # Verify filter controls - now checkboxes
      assert has_element?(view, "input[type='checkbox'][name='federal_state_#{bayern.id}']")
      assert has_element?(view, "input[type='checkbox'][name='vacation_type_#{sommerferien.id}']")
      assert has_element?(view, "input[type='checkbox'][name='year_#{Date.utc_today().year}']")

      # Verify all periods are shown initially
      assert has_element?(view, "td", "Bayern")
      assert has_element?(view, "td", "Hessen")
      assert has_element?(view, "td", "Sommerferien")
      assert has_element?(view, "td", "Winterferien")

      # Test filtering by federal state - click the nur button for Bayern
      view
      |> render_click("select_only_federal_state", %{"id" => to_string(bayern.id)})

      assert has_element?(view, "td", "Bayern")
      refute has_element?(view, "td", "Hessen")

      # Reset to all federal states
      view
      |> render_click("select_all_federal_states")

      # Test filtering by vacation type - click the nur button for Sommerferien
      view
      |> render_click("select_only_vacation_type", %{"id" => to_string(sommerferien.id)})

      assert has_element?(view, "td", "Sommerferien")
      refute has_element?(view, "td", "Winterferien")
    end

    test "shows edit links for each period", %{conn: conn} do
      # Create a period first
      germany = insert(:country, name: "Deutschland")
      bayern = insert(:federal_state, parent_location_id: germany.id, name: "Bayern")

      sommerferien =
        insert(:holiday_or_vacation_type,
          name: "Sommerferien",
          slug: "sommerferien",
          default_is_school_vacation: true
        )

      current_year = Date.utc_today().year

      period =
        insert(:period,
          location_id: bayern.id,
          holiday_or_vacation_type_id: sommerferien.id,
          starts_on: Date.new!(current_year, 7, 29),
          ends_on: Date.new!(current_year, 9, 9),
          is_school_vacation: true
        )

      {:ok, view, _html} = live(conn, "/wiki/periods")

      # Verify edit link exists (checking for the SVG icon inside the link)
      assert has_element?(view, "a[href=\"/wiki/periods/#{period.id}/edit\"]")
    end

    test "shows add new period button", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/wiki/periods")

      # Verify new period button
      assert has_element?(view, "a[href='/wiki/periods/new']", "Neue Ferien")
    end
  end

  describe "period create functionality" do
    setup do
      germany = insert(:country, name: "Deutschland")
      bayern = insert(:federal_state, parent_location_id: germany.id, name: "Bayern")

      sommerferien =
        insert(:holiday_or_vacation_type,
          name: "Sommerferien",
          slug: "sommerferien",
          default_is_school_vacation: true
        )

      %{bayern: bayern, sommerferien: sommerferien}
    end

    test "user can create a new period", %{conn: conn, bayern: bayern, sommerferien: sommerferien} do
      {:ok, view, _html} = live(conn, "/wiki/periods/new")

      # Verify page title
      assert has_element?(view, "h1", "Neuen Ferientermin hinzufügen")

      # Fill in the form
      view
      |> form("form",
        period: %{
          location_id: bayern.id,
          holiday_or_vacation_type_id: sommerferien.id,
          starts_on: "2024-07-15",
          ends_on: "2024-08-26",
          memo: "Test Sommerferien"
        }
      )
      |> render_submit()

      # Should redirect to periods index
      flash = assert_redirect(view, "/wiki/periods")
      assert flash["info"] == "Ferientermin wurde erfolgreich erstellt."

      # Verify period was created
      period = Periods.list_periods() |> List.last()
      assert period.location_id == bayern.id
      assert period.holiday_or_vacation_type_id == sommerferien.id
      assert period.starts_on == ~D[2024-07-15]
      assert period.ends_on == ~D[2024-08-26]
      assert period.memo == "Test Sommerferien"
    end

    test "shows validation errors for invalid data", %{
      conn: conn,
      bayern: bayern,
      sommerferien: sommerferien
    } do
      {:ok, view, _html} = live(conn, "/wiki/periods/new")

      # Submit with invalid data (end date before start date) but with required fields
      view
      |> form("form",
        period: %{
          location_id: bayern.id,
          holiday_or_vacation_type_id: sommerferien.id,
          starts_on: "2024-08-26",
          ends_on: "2024-07-15"
        }
      )
      |> render_submit()

      # Should show error on the form
      html = render(view)
      assert html =~ "should be less than or equal to"
    end
  end

  describe "period edit functionality" do
    setup do
      germany = insert(:country, name: "Deutschland")
      bayern = insert(:federal_state, parent_location_id: germany.id, name: "Bayern")

      sommerferien =
        insert(:holiday_or_vacation_type,
          name: "Sommerferien",
          slug: "sommerferien",
          default_is_school_vacation: true
        )

      # Create period in the future for testing
      future_date = Date.utc_today() |> Date.add(30)

      period =
        insert(:period,
          location_id: bayern.id,
          holiday_or_vacation_type_id: sommerferien.id,
          starts_on: future_date,
          ends_on: future_date |> Date.add(14),
          is_school_vacation: true,
          memo: "Original memo"
        )

      %{period: period, bayern: bayern, sommerferien: sommerferien}
    end

    test "user can edit an existing period", %{conn: conn, period: period} do
      {:ok, view, _html} = live(conn, "/wiki/periods/#{period.id}/edit")

      # Verify page shows current data
      assert has_element?(view, "h1", "Ferientermin bearbeiten")

      # Check that the form has the date inputs (not checking specific values due to dynamic dates)
      assert has_element?(view, "input[name='period[starts_on]']")
      assert has_element?(view, "input[name='period[ends_on]']")

      # Update the period
      new_start = period.starts_on |> Date.add(5)
      new_end = period.ends_on |> Date.add(5)

      view
      |> form("form",
        period: %{
          starts_on: Date.to_string(new_start),
          ends_on: Date.to_string(new_end),
          memo: "Updated memo"
        }
      )
      |> render_submit()

      # Should show success message (stays on same page)
      html = render(view)
      assert html =~ "Ferientermin wurde erfolgreich aktualisiert."

      # Verify changes were saved
      updated_period = Periods.get_period!(period.id)
      assert updated_period.starts_on == new_start
      assert updated_period.ends_on == new_end
      assert updated_period.memo == "Updated memo"
    end

    test "shows version history", %{conn: conn, period: period} do
      # Create two versions by updating the period
      {:ok, _} =
        PaperTrail.update(
          Periods.Period.changeset(period, %{memo: "Version 1"}),
          meta: %{ip_address: "127.0.0.1"}
        )

      {:ok, _} =
        PaperTrail.update(
          Periods.Period.changeset(Repo.reload!(period), %{memo: "Version 2"}),
          meta: %{ip_address: "127.0.0.1"}
        )

      {:ok, view, html} = live(conn, "/wiki/periods/#{period.id}/edit")

      # Verify version history section
      assert has_element?(view, "h3", "Änderungshistorie")

      # With two versions, the older one should have a rollback link (changed from button to text link)
      assert html =~ "← Zurücksetzen"
    end

    test "user can delete a period", %{conn: conn, period: period} do
      {:ok, view, _html} = live(conn, "/wiki/periods/#{period.id}/edit")

      # Click delete button to show modal
      view
      |> element("button[phx-click='show_delete_modal']", "Löschen")
      |> render_click()

      # Modal should be shown with affected schools count
      html = render(view)
      assert html =~ "Diese Aktion betrifft"
      assert html =~ "Schulen"

      # Confirm deletion in modal
      view
      |> element("button[phx-click='delete']", "Endgültig löschen")
      |> render_click()

      # Should redirect
      flash = assert_redirect(view, "/wiki/periods")
      assert flash["info"] == "Ferientermin wurde erfolgreich gelöscht."

      # Verify period was deleted
      assert_raise Ecto.NoResultsError, fn ->
        Periods.get_period!(period.id)
      end
    end

    test "user can close delete modal without deleting", %{conn: conn, period: period} do
      {:ok, view, _html} = live(conn, "/wiki/periods/#{period.id}/edit")

      # Click delete button to show modal
      view
      |> element("button[phx-click='show_delete_modal']", "Löschen")
      |> render_click()

      # Modal should be shown
      html = render(view)
      assert html =~ "Ferientermin löschen"

      # Cancel deletion in modal
      view
      |> element("button[phx-click='hide_delete_modal']", "Abbrechen")
      |> render_click()

      # Modal should be closed
      html = render(view)
      refute html =~ "Ferientermin löschen"

      # Period should still exist
      assert Periods.get_period!(period.id)
    end

    test "user cannot edit a past period", %{
      conn: conn,
      bayern: bayern,
      sommerferien: sommerferien
    } do
      # Create a period in the past
      past_period =
        insert(:period,
          location_id: bayern.id,
          holiday_or_vacation_type_id: sommerferien.id,
          starts_on: Date.utc_today() |> Date.add(-30),
          ends_on: Date.utc_today() |> Date.add(-15),
          is_school_vacation: true
        )

      {:ok, view, html} = live(conn, "/wiki/periods/#{past_period.id}/edit")

      # Should show warning message
      assert html =~ "Dieser Ferientermin liegt in der Vergangenheit"

      # Form fields should be disabled
      assert has_element?(view, "input[name='period[starts_on]'][disabled]")
      assert has_element?(view, "button[type='submit'][disabled]")

      # Delete button should be disabled
      assert has_element?(view, "button[phx-click='show_delete_modal'][disabled]")
    end
  end

  describe "daily limit enforcement" do
    setup do
      # Set up test data
      germany = insert(:country, name: "Deutschland")
      bayern = insert(:federal_state, parent_location_id: germany.id, name: "Bayern")

      sommerferien =
        insert(:holiday_or_vacation_type,
          name: "Sommerferien",
          slug: "sommerferien",
          default_is_school_vacation: true
        )

      period =
        insert(:period,
          location_id: bayern.id,
          holiday_or_vacation_type_id: sommerferien.id,
          starts_on: ~D[2024-07-29],
          ends_on: ~D[2024-09-09],
          is_school_vacation: true
        )

      # Simulate reaching daily limit
      today = Date.utc_today()
      limit = MehrSchulferien.Config.daily_change_limit()

      # Insert a daily change count at the limit
      %MehrSchulferien.Wiki.DailyChangeCount{
        date: today,
        count: limit
      }
      |> Repo.insert!()

      %{period: period, bayern: bayern, sommerferien: sommerferien}
    end

    test "shows limit reached message on create page", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/wiki/periods/new")

      # Should show limit reached warning
      assert has_element?(view, "div", "Das tägliche Limit")

      # Submit button should be disabled
      assert has_element?(view, "button[disabled]", "Ferientermin erstellen")
    end

    test "prevents editing when limit reached", %{conn: conn, period: period} do
      {:ok, view, _html} = live(conn, "/wiki/periods/#{period.id}/edit")

      # Should show limit reached warning
      assert has_element?(view, "div", "Das tägliche Limit")

      # All form elements should be disabled
      assert has_element?(view, "button[disabled]", "Änderungen speichern")
      assert has_element?(view, "button[disabled]", "Löschen")
    end
  end

  describe "mobile responsiveness" do
    test "period index page works on mobile", %{conn: conn} do
      # Insert test data
      germany = insert(:country, name: "Deutschland")
      bayern = insert(:federal_state, parent_location_id: germany.id, name: "Bayern")

      sommerferien =
        insert(:holiday_or_vacation_type,
          name: "Sommerferien",
          slug: "sommerferien",
          default_is_school_vacation: true
        )

      insert(:period,
        location_id: bayern.id,
        holiday_or_vacation_type_id: sommerferien.id,
        starts_on: ~D[2024-07-29],
        ends_on: ~D[2024-09-09],
        is_school_vacation: true
      )

      {:ok, view, _html} = live(conn, "/wiki/periods")

      # Verify responsive grid classes
      assert view |> element("div.grid.grid-cols-1.md\\:grid-cols-3") |> has_element?()

      # Verify table has overflow handling
      assert view |> element("div.overflow-x-auto") |> has_element?()
    end
  end

  describe "dark mode support" do
    test "all wiki pages have dark mode classes", %{conn: conn} do
      # Test hub page
      conn_hub = get(conn, "/wiki")
      hub_response = html_response(conn_hub, 200)
      assert hub_response =~ "dark:bg-gray-900"
      assert hub_response =~ "dark:text-gray-100"

      # Test period pages
      {:ok, index_view, _} = live(conn, "/wiki/periods")
      assert has_element?(index_view, "div.dark\\:bg-gray-900")

      {:ok, new_view, _} = live(conn, "/wiki/periods/new")
      assert has_element?(new_view, "div.dark\\:bg-gray-900")
    end
  end
end
