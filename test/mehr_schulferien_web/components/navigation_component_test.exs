defmodule MehrSchulferienWeb.NavigationComponentTest do
  use MehrSchulferienWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias MehrSchulferienWeb.NavigationComponent

  describe "navigation/1" do
    test "renders the main navigation header" do
      assigns = %{socket: nil, conn: nil, today: ~D[2025-06-23]}

      html = render_component(&NavigationComponent.navigation/1, assigns)

      # Check that the main navigation structure is present
      assert html =~ ~r/<header[^>]*class="[^"]*bg-white[^"]*border-b[^"]*border-slate-200[^"]*"/
      assert html =~ ~r/<nav[^>]*aria-label="Global"/
    end

    test "renders the logo and brand" do
      assigns = %{socket: nil, conn: nil, today: ~D[2025-06-23]}

      html = render_component(&NavigationComponent.navigation/1, assigns)

      # Check logo elements
      assert html =~ "MEHR!"
      assert html =~ "Schulferien"
      assert html =~ ~r/<a[^>]*href="\/"/
      assert html =~ "Mehr Schulferien"
    end

    test "renders desktop navigation with 3 dropdowns" do
      assigns = %{socket: nil, conn: nil, today: ~D[2025-06-23]}

      html = render_component(&NavigationComponent.navigation/1, assigns)

      # Check that the 3 main dropdown buttons are present
      assert html =~ "Schulferien"
      assert html =~ "Brückentage"
      assert html =~ "Urlaubsplaner"

      # Check that year tabs appear in dropdowns
      assert html =~ "data-year-tab"
      assert html =~ "data-year-content"

      # Check dropdown containers using data attributes
      assert html =~ ~r/data-dropdown-container/
      assert html =~ ~r/data-dropdown-menu/
      assert html =~ ~r/data-dropdown-trigger/
    end

    test "renders year tabs in dropdowns" do
      assigns = %{socket: nil, conn: nil, today: ~D[2025-06-23]}

      html = render_component(&NavigationComponent.navigation/1, assigns)

      # Check year tabs are present
      assert html =~ ~r/data-year-tab="2025"/
      assert html =~ ~r/data-year-tab="2026"/
      assert html =~ ~r/data-year-tab="2027"/

      # Check year content panels are present
      assert html =~ ~r/data-year-content="2025"/
      assert html =~ ~r/data-year-content="2026"/
      assert html =~ ~r/data-year-content="2027"/
    end

    test "renders all federal states in dropdowns" do
      assigns = %{socket: nil, conn: nil, today: ~D[2025-06-23]}

      html = render_component(&NavigationComponent.navigation/1, assigns)

      # Check that major federal states are present
      assert html =~ "Baden-Württemberg"
      assert html =~ "Bayern"
      assert html =~ "Berlin"
      assert html =~ "Nordrhein-Westfalen"
      assert html =~ "Schleswig-Holstein"

      # Check that links are properly formatted. The current-year tab links
      # the evergreen (year-less) state page, future years keep year pages.
      assert html =~ ~r/href="\/ferien\/d\/bundesland\/baden-wuerttemberg"/
      assert html =~ ~r/href="\/ferien\/d\/bundesland\/bayern\/2026"/
      assert html =~ ~r/href="\/ferien\/d\/bundesland\/berlin\/2027"/
      assert html =~ ~r/href="\/brueckentage\/d\/bundesland\/hamburg"/
      assert html =~ ~r/href="\/brueckentage\/d\/bundesland\/hessen\/2026"/
    end

    test "renders mobile menu structure with nested years" do
      assigns = %{socket: nil, conn: nil, today: ~D[2025-06-23]}

      html = render_component(&NavigationComponent.navigation/1, assigns)

      # Check mobile menu button
      assert html =~ ~r/data-mobile-menu-toggle/
      assert html =~ "Open main menu"

      # Check mobile menu container
      assert html =~ ~r/data-mobile-menu/
      assert html =~ "Close menu"

      # Check mobile dropdowns using nested details/summary
      assert html =~ "<details"
      assert html =~ "<summary"

      # Check that years appear in mobile menu too
      assert html =~ ~r/<summary[^>]*>.*2025.*<\/summary>/s
      assert html =~ ~r/<summary[^>]*>.*2026.*<\/summary>/s
      assert html =~ ~r/<summary[^>]*>.*2027.*<\/summary>/s
    end

    test "uses data attributes for JavaScript interaction" do
      assigns = %{socket: nil, conn: nil, today: ~D[2025-06-23]}

      html = render_component(&NavigationComponent.navigation/1, assigns)

      # Check that data attributes are present for JS hooks
      assert html =~ ~r/data-dropdown-container/
      assert html =~ ~r/data-dropdown-trigger/
      assert html =~ ~r/data-dropdown-menu/
      assert html =~ ~r/data-mobile-menu-toggle/
      assert html =~ ~r/data-mobile-menu-close/
      assert html =~ ~r/data-mobile-menu[^-]/
      assert html =~ ~r/data-year-tabs/
      assert html =~ ~r/data-year-tab/
      assert html =~ ~r/data-year-content/
    end

    test "renders proper accessibility attributes" do
      assigns = %{socket: nil, conn: nil, today: ~D[2025-06-23]}

      html = render_component(&NavigationComponent.navigation/1, assigns)

      # Check accessibility attributes
      assert html =~ ~r/aria-label="Global"/
      assert html =~ ~r/aria-hidden="true"/
      assert html =~ "sr-only"
      assert html =~ ~r/aria-expanded="false"/
    end

    test "all federal state links are properly formatted for all 3 years" do
      assigns = %{socket: nil, conn: nil, today: ~D[2025-06-23]}

      html = render_component(&NavigationComponent.navigation/1, assigns)

      federal_states = [
        "baden-wuerttemberg",
        "bayern",
        "berlin",
        "brandenburg",
        "bremen",
        "hamburg",
        "hessen",
        "mecklenburg-vorpommern",
        "niedersachsen",
        "nordrhein-westfalen",
        "rheinland-pfalz",
        "saarland",
        "sachsen",
        "sachsen-anhalt",
        "schleswig-holstein",
        "thueringen"
      ]

      # Check that each federal state appears in all navigation sections for all 3 years
      for state <- federal_states do
        # Schulferien - evergreen page for the current year, then year pages
        assert html =~ ~r/href="\/ferien\/d\/bundesland\/#{state}"/
        refute html =~ ~r/href="\/ferien\/d\/bundesland\/#{state}\/2025"/
        assert html =~ ~r/href="\/ferien\/d\/bundesland\/#{state}\/2026"/
        assert html =~ ~r/href="\/ferien\/d\/bundesland\/#{state}\/2027"/
        # Brückentage - evergreen page for the current year, then year pages
        assert html =~ ~r/href="\/brueckentage\/d\/bundesland\/#{state}"/
        refute html =~ ~r/href="\/brueckentage\/d\/bundesland\/#{state}\/2025"/
        assert html =~ ~r/href="\/brueckentage\/d\/bundesland\/#{state}\/2026"/
        assert html =~ ~r/href="\/brueckentage\/d\/bundesland\/#{state}\/2027"/
        # Urlaubsplaner - all 3 years
        assert html =~ ~r/href="\/urlaubsplaner\/#{state}\/20-tage\/2025"/
        assert html =~ ~r/href="\/urlaubsplaner\/#{state}\/20-tage\/2026"/
        assert html =~ ~r/href="\/urlaubsplaner\/#{state}\/20-tage\/2027"/
      end
    end

    test "component handles nil socket and conn gracefully" do
      assigns = %{socket: nil, conn: nil, today: ~D[2025-06-23]}

      result = NavigationComponent.navigation(assigns)
      assert %Phoenix.LiveView.Rendered{} = result
    end

    test "navigation uses dynamic years based on today parameter" do
      # Test with 2024 as today - should show 2024, 2025, 2026
      assigns_2024 = %{socket: nil, conn: nil, today: ~D[2024-03-15]}
      html_2024 = render_component(&NavigationComponent.navigation/1, assigns_2024)

      # Check year tabs
      assert html_2024 =~ ~r/data-year-tab="2024"/
      assert html_2024 =~ ~r/data-year-tab="2025"/
      assert html_2024 =~ ~r/data-year-tab="2026"/
      # Current year links the evergreen page, future years keep year pages
      assert html_2024 =~ ~r/href="\/ferien\/d\/bundesland\/bayern"/
      refute html_2024 =~ ~r/href="\/ferien\/d\/bundesland\/bayern\/2024"/
      assert html_2024 =~ ~r/href="\/ferien\/d\/bundesland\/bayern\/2025"/
      assert html_2024 =~ ~r/href="\/ferien\/d\/bundesland\/bayern\/2026"/

      # Test with 2026 as today - should show 2026, 2027, 2028
      assigns_2026 = %{socket: nil, conn: nil, today: ~D[2026-08-10]}
      html_2026 = render_component(&NavigationComponent.navigation/1, assigns_2026)

      # Check year tabs
      assert html_2026 =~ ~r/data-year-tab="2026"/
      assert html_2026 =~ ~r/data-year-tab="2027"/
      assert html_2026 =~ ~r/data-year-tab="2028"/
      # Current year links the evergreen page, future years keep year pages
      assert html_2026 =~ ~r/href="\/ferien\/d\/bundesland\/berlin"/
      refute html_2026 =~ ~r/href="\/ferien\/d\/bundesland\/berlin\/2026"/
      assert html_2026 =~ ~r/href="\/ferien\/d\/bundesland\/berlin\/2027"/
      assert html_2026 =~ ~r/href="\/ferien\/d\/bundesland\/berlin\/2028"/
    end

    test "renders Urlaubsplaner dropdown with all federal states and year tabs" do
      assigns = %{socket: nil, conn: nil, today: ~D[2025-06-23]}

      html = render_component(&NavigationComponent.navigation/1, assigns)

      # Check Urlaubsplaner dropdown is present
      assert html =~ "Urlaubsplaner"

      # Check Urlaubsplaner links for all 3 years
      assert html =~ ~r/href="\/urlaubsplaner\/bayern\/20-tage\/2025"/
      assert html =~ ~r/href="\/urlaubsplaner\/bayern\/20-tage\/2026"/
      assert html =~ ~r/href="\/urlaubsplaner\/bayern\/20-tage\/2027"/
      assert html =~ ~r/href="\/urlaubsplaner\/berlin\/20-tage\/2025"/
      assert html =~ ~r/href="\/urlaubsplaner\/hessen\/20-tage\/2026"/
    end

    test "has only 4 dropdowns (Schulferien, Brückentage, Feiertage, Urlaubsplaner)" do
      assigns = %{socket: nil, conn: nil, today: ~D[2025-06-23]}

      html = render_component(&NavigationComponent.navigation/1, assigns)

      # Count data-dropdown-container occurrences (should be exactly 4)
      dropdown_count = html |> String.split("data-dropdown-container") |> length() |> Kernel.-(1)
      assert dropdown_count == 4
    end

    test "dropdown has scrollable content area" do
      assigns = %{socket: nil, conn: nil, today: ~D[2025-06-23]}

      html = render_component(&NavigationComponent.navigation/1, assigns)

      # Check for max-height and overflow scroll classes
      assert html =~ "max-h-96"
      assert html =~ "overflow-y-auto"
    end
  end
end
