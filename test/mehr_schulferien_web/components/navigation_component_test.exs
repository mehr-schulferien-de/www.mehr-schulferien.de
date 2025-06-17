defmodule MehrSchulferienWeb.NavigationComponentTest do
  use MehrSchulferienWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias MehrSchulferienWeb.NavigationComponent

  describe "navigation/1" do
    test "renders the main navigation header" do
      assigns = %{socket: nil, conn: nil}

      html = render_component(&NavigationComponent.navigation/1, assigns)

      # Check that the main navigation structure is present
      assert html =~ ~r/<header[^>]*class="[^"]*bg-white[^"]*border-b[^"]*border-slate-200[^"]*"/
      assert html =~ ~r/<nav[^>]*aria-label="Global"/
    end

    test "renders the logo and brand" do
      assigns = %{socket: nil, conn: nil}

      html = render_component(&NavigationComponent.navigation/1, assigns)

      # Check logo elements
      assert html =~ "MEHR!"
      assert html =~ "Schulferien"
      assert html =~ ~r/<a[^>]*href="\/"/
      assert html =~ "Mehr Schulferien"
    end

    test "renders desktop navigation with all dropdowns" do
      assigns = %{socket: nil, conn: nil}

      html = render_component(&NavigationComponent.navigation/1, assigns)

      # Check that all dropdown buttons are present
      assert html =~ "Schulferien 2025"
      assert html =~ "Schulferien 2026"
      assert html =~ "Brückentage 2025"
      assert html =~ "Brückentage 2026"

      # Check dropdown containers
      assert html =~ ~r/class="[^"]*dropdown-container[^"]*relative[^"]*"/
      assert html =~ ~r/class="[^"]*dropdown-menu[^"]*"/
    end

    test "renders all federal states in dropdowns" do
      assigns = %{socket: nil, conn: nil}

      html = render_component(&NavigationComponent.navigation/1, assigns)

      # Check that major federal states are present
      assert html =~ "Baden-Württemberg"
      assert html =~ "Bayern"
      assert html =~ "Berlin"
      assert html =~ "Nordrhein-Westfalen"
      assert html =~ "Schleswig-Holstein"

      # Check that links are properly formatted
      assert html =~ ~r/href="\/ferien\/d\/bundesland\/baden-wuerttemberg\/2025"/
      assert html =~ ~r/href="\/ferien\/d\/bundesland\/bayern\/2026"/
      assert html =~ ~r/href="\/brueckentage\/d\/bundesland\/berlin\/2025"/
      assert html =~ ~r/href="\/brueckentage\/d\/bundesland\/hamburg\/2026"/
    end

    test "renders mobile menu structure" do
      assigns = %{socket: nil, conn: nil}

      html = render_component(&NavigationComponent.navigation/1, assigns)

      # Check mobile menu button
      assert html =~ ~r/class="[^"]*mobile-menu-toggle[^"]*"/
      assert html =~ "Open main menu"

      # Check mobile menu container
      assert html =~ ~r/class="[^"]*mobile-menu[^"]*hidden[^"]*"/
      assert html =~ "Close menu"

      # Check mobile dropdowns using details/summary
      assert html =~ "<details"
      assert html =~ "<summary"
      assert html =~ ~r/class="[^"]*mobile-dropdown[^"]*"/
    end

    test "includes CSS for dropdown behavior" do
      assigns = %{socket: nil, conn: nil}

      html = render_component(&NavigationComponent.navigation/1, assigns)

      # Check that CSS for hover behavior is included
      assert html =~ ".dropdown-container:hover .dropdown-menu"
      assert html =~ "opacity: 1"
      assert html =~ "visibility: visible"
    end

    test "includes JavaScript for mobile menu toggle" do
      assigns = %{socket: nil, conn: nil}

      html = render_component(&NavigationComponent.navigation/1, assigns)

      # Check that JavaScript for mobile functionality is included
      assert html =~ "document.addEventListener('DOMContentLoaded'"
      assert html =~ "querySelector('.mobile-menu-toggle')"
      assert html =~ "querySelector('.mobile-menu-close')"
      assert html =~ "classList.remove('hidden')"
      assert html =~ "classList.add('hidden')"
    end

    test "renders proper accessibility attributes" do
      assigns = %{socket: nil, conn: nil}

      html = render_component(&NavigationComponent.navigation/1, assigns)

      # Check accessibility attributes
      assert html =~ ~r/aria-label="Global"/
      assert html =~ ~r/aria-hidden="true"/
      assert html =~ "sr-only"
    end

    test "all federal state links are properly formatted" do
      assigns = %{socket: nil, conn: nil}

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

      # Check that each federal state appears in all four navigation sections
      for state <- federal_states do
        # Schulferien 2025
        assert html =~ ~r/href="\/ferien\/d\/bundesland\/#{state}\/2025"/
        # Schulferien 2026
        assert html =~ ~r/href="\/ferien\/d\/bundesland\/#{state}\/2026"/
        # Brückentage 2025
        assert html =~ ~r/href="\/brueckentage\/d\/bundesland\/#{state}\/2025"/
        # Brückentage 2026
        assert html =~ ~r/href="\/brueckentage\/d\/bundesland\/#{state}\/2026"/
      end
    end

    test "component handles nil socket and conn gracefully" do
      assigns = %{socket: nil, conn: nil}

      result = NavigationComponent.navigation(assigns)
      assert %Phoenix.LiveView.Rendered{} = result
    end
  end
end
