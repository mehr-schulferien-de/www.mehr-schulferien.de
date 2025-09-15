defmodule MehrSchulferienWeb.LayoutNavigationTest do
  use MehrSchulferienWeb.ConnCase, async: true
  import Phoenix.HTML

  alias MehrSchulferienWeb.LayoutView

  describe "navigation functionality" do
    setup do
      conn = build_conn()

      navigation_assigns = %{
        current_year: 2025,
        next_year: 2026,
        conn: conn
      }

      {:ok, navigation_assigns: navigation_assigns, conn: conn}
    end

    test "renders navigation template with proper structure", %{
      navigation_assigns: navigation_assigns
    } do
      html = render_navigation(navigation_assigns)

      # Check basic structure
      assert html =~ ~r/<header[^>]*class="[^"]*bg-white/
      assert html =~ "data-mobile-menu-toggle"
      assert html =~ "data-dropdown-container"
      assert html =~ "data-dropdown-trigger"
      assert html =~ "data-dropdown-menu"
      assert html =~ "data-mobile-menu"
    end

    test "renders desktop navigation dropdowns", %{navigation_assigns: navigation_assigns} do
      html = render_navigation(navigation_assigns)

      # Check desktop dropdown buttons
      assert html =~ "Schulferien 2025"
      assert html =~ "Schulferien 2026"
      assert html =~ "Brückentage 2025"
      assert html =~ "Brückentage 2026"

      # Check data attributes for vanilla JS
      assert html =~ "data-dropdown-container"
      assert html =~ "data-dropdown-trigger"
      assert html =~ "data-dropdown-menu"

      # Check aria-expanded attributes
      assert html =~ ~r/aria-expanded="false"/

      # Check dropdown menu classes
      assert html =~ "opacity-0 invisible hidden transition-all duration-200"
    end

    test "renders mobile menu toggle", %{navigation_assigns: navigation_assigns} do
      html = render_navigation(navigation_assigns)

      # Check mobile menu button
      assert html =~ "data-mobile-menu-toggle"
      assert html =~ "Open main menu"

      # Check mobile menu container
      assert html =~ "data-mobile-menu"
      assert html =~ "data-mobile-menu-close"
      assert html =~ "Close menu"
    end

    test "renders all federal states in dropdowns", %{navigation_assigns: navigation_assigns} do
      html = render_navigation(navigation_assigns)

      federal_states = [
        {"baden-wuerttemberg", "Baden-Württemberg"},
        {"bayern", "Bayern"},
        {"berlin", "Berlin"},
        {"brandenburg", "Brandenburg"},
        {"bremen", "Bremen"},
        {"hamburg", "Hamburg"},
        {"hessen", "Hessen"},
        {"mecklenburg-vorpommern", "Mecklenburg-Vorpommern"},
        {"niedersachsen", "Niedersachsen"},
        {"nordrhein-westfalen", "Nordrhein-Westfalen"},
        {"rheinland-pfalz", "Rheinland-Pfalz"},
        {"saarland", "Saarland"},
        {"sachsen", "Sachsen"},
        {"sachsen-anhalt", "Sachsen-Anhalt"},
        {"schleswig-holstein", "Schleswig-Holstein"},
        {"thueringen", "Thüringen"}
      ]

      for {slug, name} <- federal_states do
        assert html =~ name
        assert html =~ ~r{href="/ferien/d/bundesland/#{slug}/2025"}
        assert html =~ ~r{href="/ferien/d/bundesland/#{slug}/2026"}
        assert html =~ ~r{href="/brueckentage/d/bundesland/#{slug}/2025"}
        assert html =~ ~r{href="/brueckentage/d/bundesland/#{slug}/2026"}
      end
    end

    test "renders mobile navigation sections", %{navigation_assigns: navigation_assigns} do
      html = render_navigation(navigation_assigns)

      # Check mobile navigation uses details/summary for dropdowns
      assert html =~ "<details>"
      assert html =~ "<summary"

      # Check all mobile sections are present
      assert Regex.scan(~r/<summary[^>]*>.*?Schulferien 2025.*?<\/summary>/s, html) |> length() ==
               1

      assert Regex.scan(~r/<summary[^>]*>.*?Schulferien 2026.*?<\/summary>/s, html) |> length() ==
               1

      assert Regex.scan(~r/<summary[^>]*>.*?Brückentage 2025.*?<\/summary>/s, html) |> length() ==
               1

      assert Regex.scan(~r/<summary[^>]*>.*?Brückentage 2026.*?<\/summary>/s, html) |> length() ==
               1
    end

    test "includes vanilla JS data attributes", %{navigation_assigns: navigation_assigns} do
      html = render_navigation(navigation_assigns)

      assert html =~ "data-dropdown-container"
      assert html =~ "data-dropdown-trigger"
      assert html =~ "data-dropdown-menu"
      assert html =~ "data-mobile-menu"
      assert html =~ "data-mobile-menu-toggle"
    end

    test "renders proper ARIA attributes", %{navigation_assigns: navigation_assigns} do
      html = render_navigation(navigation_assigns)

      # Check ARIA attributes
      assert html =~ ~r/aria-label="Global"/
      assert html =~ ~r/aria-hidden="true"/
      assert html =~ "sr-only"
      assert html =~ ~r/aria-expanded="false"/
    end

    test "highlights current page in navigation", %{conn: conn} do
      # Test highlighting for federal state page
      conn_federal_state =
        conn
        |> get("/ferien/d/bundesland/bayern/2025")

      navigation_assigns = %{
        current_year: 2025,
        next_year: 2026,
        conn: conn_federal_state
      }

      html = render_navigation(navigation_assigns)

      # Should show Bayern as non-clickable in 2025 dropdown
      assert html =~ ~r/<span[^>]*class="[^"]*text-gray-400[^"]*"[^>]*>.*Bayern.*<\/span>/s
    end
  end

  defp render_navigation(assigns) do
    html = LayoutView.render("_navigation_shared.html", assigns)

    case html do
      %Phoenix.LiveView.Rendered{} = rendered ->
        Phoenix.HTML.Safe.to_iodata(rendered)
        |> IO.iodata_to_binary()

      other ->
        safe_to_string(other)
    end
  end
end
