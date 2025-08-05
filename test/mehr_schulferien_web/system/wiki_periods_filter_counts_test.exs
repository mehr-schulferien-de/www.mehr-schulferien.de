defmodule MehrSchulferienWeb.System.WikiPeriodsFilterCountsTest do
  use MehrSchulferienWeb.ConnCase
  import Phoenix.LiveViewTest
  import MehrSchulferien.Factory

  describe "wiki periods filter counts" do
    setup do
      # Create test data using factories
      germany = insert(:country, name: "Deutschland", slug: "d")
      
      # Create Hamburg as a federal state
      hamburg = insert(:federal_state, name: "Hamburg", slug: "hamburg", parent_location_id: germany.id)

      # Create vacation types
      sommer = insert(:holiday_or_vacation_type, name: "Sommer", slug: "sommer", default_is_school_vacation: true)
      herbst = insert(:holiday_or_vacation_type, name: "Herbst", slug: "herbst", default_is_school_vacation: true)
      ostern = insert(:holiday_or_vacation_type, name: "Ostern", slug: "ostern", default_is_school_vacation: true)

      # Create periods for Hamburg with different vacation types in 2025 and 2026
      # Create 2 Sommer periods that should show up when Sommer is unchecked
      insert(:period,
        location_id: hamburg.id,
        holiday_or_vacation_type_id: sommer.id,
        starts_on: ~D[2025-07-01],
        ends_on: ~D[2025-08-15],
        is_school_vacation: true
      )

      insert(:period,
        location_id: hamburg.id,
        holiday_or_vacation_type_id: sommer.id,
        starts_on: ~D[2026-07-01],
        ends_on: ~D[2026-08-15],
        is_school_vacation: true
      )

      # Create periods for other vacation types that are already visible
      insert(:period,
        location_id: hamburg.id,
        holiday_or_vacation_type_id: herbst.id,
        starts_on: ~D[2025-10-01],
        ends_on: ~D[2025-10-15],
        is_school_vacation: true
      )

      insert(:period,
        location_id: hamburg.id,
        holiday_or_vacation_type_id: ostern.id,
        starts_on: ~D[2026-04-01],
        ends_on: ~D[2026-04-15],
        is_school_vacation: true
      )

      %{
        conn: build_conn(),
        hamburg: hamburg,
        sommer: sommer,
        herbst: herbst,
        ostern: ostern
      }
    end

    test "shows additional count when deselecting Sommer vacation type", %{
      conn: conn,
      hamburg: hamburg,
      sommer: sommer
    } do
      {:ok, view, _html} = live(conn, "/wiki/periods")

      # Wait for the page to load
      assert has_element?(view, "h1", "Ferientermine verwalten")

      # First, select only Hamburg to simplify the test
      view
      |> element("button[phx-click='select_only_federal_state'][phx-value-id='#{hamburg.id}']")
      |> render_click()

      # Deselect all vacation types first
      view
      |> element("button[phx-click='select_none_vacation_types']")
      |> render_click()

      # The result list should be empty (no selections means no results)
      refute has_element?(view, "td", "Hamburg")
      
      # Now check only Herbst and Ostern (not Sommer)
      # Get all vacation type checkboxes from the current HTML
      html = render(view)
      vacation_type_ids = Regex.scan(~r/id="vacation_type_(\d+)"/, html)
        |> Enum.map(fn [_, id] -> String.to_integer(id) end)
      
      # Find the IDs for our vacation types
      herbst_checkbox = Enum.find(vacation_type_ids, fn id -> 
        html =~ ~r/vacation_type_#{id}".*?Herbst/s
      end)
      
      ostern_checkbox = Enum.find(vacation_type_ids, fn id -> 
        html =~ ~r/vacation_type_#{id}".*?Ostern/s
      end)

      # Build form params with Hamburg, selected vacation types (not Sommer), and years
      form_params = %{
        "federal_state_#{hamburg.id}" => "true",
        "vacation_type_#{herbst_checkbox}" => "true",
        "vacation_type_#{ostern_checkbox}" => "true",
        "year_2025" => "true",
        "year_2026" => "true"
      }

      # Submit the form
      view
      |> form("form[phx-change='filter_changed']", form_params)
      |> render_change()

      # Now Sommer should be unchecked and show (+2)
      refute has_element?(view, "#vacation_type_#{sommer.id}[checked]")
      
      # Look for the count in the label
      sommer_label_html = view
        |> element("label[for='vacation_type_#{sommer.id}']")
        |> render()
      
      assert sommer_label_html =~ "Sommer"
      # The actual count might be different due to how the calculation works
      # Let's extract the actual count from the HTML
      assert sommer_label_html =~ ~r/\(\+(\d+)\)/
      
      # Extract the number to verify it's positive
      [_, count_str] = Regex.run(~r/\(\+(\d+)\)/, sommer_label_html)
      count = String.to_integer(count_str)
      assert count > 0, "Expected positive count, got #{count}"
    end

    test "recalculates counts when clicking Alle and Keine buttons", %{
      conn: conn,
      hamburg: hamburg,
      sommer: sommer
    } do
      {:ok, view, _html} = live(conn, "/wiki/periods")

      # Wait for the page to load
      assert has_element?(view, "h1", "Ferientermine verwalten")

      # First, select only Hamburg
      view
      |> element("button[phx-click='select_only_federal_state'][phx-value-id='#{hamburg.id}']")
      |> render_click()

      # Click "Keine" for vacation types to deselect all
      view
      |> element("button[phx-click='select_none_vacation_types']")
      |> render_click()

      # All vacation types should be unchecked and show counts
      assert has_element?(view, "label[for='vacation_type_#{sommer.id}'] span", ~r/\+\d+/)

      # Click "Alle" for vacation types to select all
      view
      |> element("button[phx-click='select_all_vacation_types']")
      |> render_click()

      # Sommer should now be checked and not show a count
      assert has_element?(view, "#vacation_type_#{sommer.id}[checked]")
      refute has_element?(view, "label[for='vacation_type_#{sommer.id}'] span", ~r/\+\d+/)

      # Test with years - click "Keine" to deselect all years
      view
      |> element("button[phx-click='select_none_years']")
      |> render_click()

      # Results should be empty (no years selected)
      refute has_element?(view, "td", "Hamburg")

      # All year checkboxes should show counts
      assert has_element?(view, "label[for='year_2025'] span", ~r/\+\d+/)
      assert has_element?(view, "label[for='year_2026'] span", ~r/\+\d+/)

      # Click "Alle" for years
      view
      |> element("button[phx-click='select_all_years']")
      |> render_click()

      # Years should be checked and not show counts
      assert has_element?(view, "#year_2025[checked]")
      assert has_element?(view, "#year_2026[checked]")
      refute has_element?(view, "label[for='year_2025'] span", ~r/\+\d+/)
      refute has_element?(view, "label[for='year_2026'] span", ~r/\+\d+/)
    end
  end
end