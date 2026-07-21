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
        third_year: 2027,
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

    test "renders desktop navigation with 3 dropdowns and year tabs", %{
      navigation_assigns: navigation_assigns
    } do
      html = render_navigation(navigation_assigns)

      # Check dropdown buttons
      assert html =~ "Schulferien"
      assert html =~ "Brückentage"
      assert html =~ "Urlaubsplaner"

      # Check year tabs are present
      assert html =~ "data-year-tab"
      assert html =~ "data-year-content"
      assert html =~ "data-year-tabs"

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

    test "renders all federal states in dropdowns for all 3 years", %{
      navigation_assigns: navigation_assigns
    } do
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
        # The current-year tab links the evergreen (year-less) state page so
        # the sitewide nav funnels link equity to the head-term URL; future
        # years keep their year pages.
        assert html =~ ~r{href="/ferien/d/bundesland/#{slug}"}
        refute html =~ ~r{href="/ferien/d/bundesland/#{slug}/2025"}
        assert html =~ ~r{href="/ferien/d/bundesland/#{slug}/2026"}
        assert html =~ ~r{href="/ferien/d/bundesland/#{slug}/2027"}
        # Check all 3 years for Brückentage
        # Current year links the evergreen bridge day page, later years
        # keep their year pages.
        assert html =~ ~r{href="/brueckentage/d/bundesland/#{slug}"}
        refute html =~ ~r{href="/brueckentage/d/bundesland/#{slug}/2025"}
        assert html =~ ~r{href="/brueckentage/d/bundesland/#{slug}/2026"}
        assert html =~ ~r{href="/brueckentage/d/bundesland/#{slug}/2027"}
        # Check all 3 years for Urlaubsplaner
        assert html =~ ~r{href="/urlaubsplaner/#{slug}/20-tage/2025"}
        assert html =~ ~r{href="/urlaubsplaner/#{slug}/20-tage/2026"}
        assert html =~ ~r{href="/urlaubsplaner/#{slug}/20-tage/2027"}
      end
    end

    test "renders mobile navigation with nested years", %{navigation_assigns: navigation_assigns} do
      html = render_navigation(navigation_assigns)

      # Check mobile navigation uses nested details/summary for dropdowns
      assert html =~ "<details>"
      assert html =~ "<summary"

      # Check main sections are present (Schulferien, Brückentage, Urlaubsplaner)
      assert html =~ ~r/<summary[^>]*>.*?Schulferien.*?<\/summary>/s
      assert html =~ ~r/<summary[^>]*>.*?Brückentage.*?<\/summary>/s
      assert html =~ ~r/<summary[^>]*>.*?Urlaubsplaner.*?<\/summary>/s

      # Check year subsections exist (nested details)
      assert html =~ ~r/<summary[^>]*>.*?2025.*?<\/summary>/s
      assert html =~ ~r/<summary[^>]*>.*?2026.*?<\/summary>/s
      assert html =~ ~r/<summary[^>]*>.*?2027.*?<\/summary>/s
    end

    test "includes vanilla JS data attributes", %{navigation_assigns: navigation_assigns} do
      html = render_navigation(navigation_assigns)

      assert html =~ "data-dropdown-container"
      assert html =~ "data-dropdown-trigger"
      assert html =~ "data-dropdown-menu"
      assert html =~ "data-mobile-menu"
      assert html =~ "data-mobile-menu-toggle"
      assert html =~ "data-year-tabs"
      assert html =~ "data-year-tab"
      assert html =~ "data-year-content"
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
        third_year: 2027,
        conn: conn_federal_state
      }

      html = render_navigation(navigation_assigns)

      # Should show Bayern as non-clickable in 2025 panel
      assert html =~ ~r/<span[^>]*class="[^"]*text-gray-400[^"]*"[^>]*>.*Bayern.*<\/span>/s
    end

    test "highlights the evergreen state page in the current year panel", %{conn: conn} do
      conn_evergreen = get(conn, "/ferien/d/bundesland/bayern")

      navigation_assigns = %{
        current_year: 2025,
        next_year: 2026,
        third_year: 2027,
        conn: conn_evergreen
      }

      html = render_navigation(navigation_assigns)

      # The current-year panel links the evergreen page, so being on the
      # evergreen page counts as "you are here" and grays Bayern out.
      assert html =~ ~r/<span[^>]*class="[^"]*text-gray-400[^"]*"[^>]*>.*Bayern.*<\/span>/s
    end

    test "has only 4 dropdowns", %{navigation_assigns: navigation_assigns} do
      html = render_navigation(navigation_assigns)

      # Schulferien, Brückentage, Feiertage, Urlaubsplaner
      dropdown_count = html |> String.split("data-dropdown-container") |> length() |> Kernel.-(1)
      assert dropdown_count == 4
    end

    test "dropdowns have scrollable content", %{navigation_assigns: navigation_assigns} do
      html = render_navigation(navigation_assigns)

      # Check for scrollable content classes
      assert html =~ "max-h-96"
      assert html =~ "overflow-y-auto"
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
