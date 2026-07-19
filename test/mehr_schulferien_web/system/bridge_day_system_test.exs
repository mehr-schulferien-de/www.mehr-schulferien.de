defmodule MehrSchulferienWeb.BridgeDaySystemTest do
  use MehrSchulferienWeb.ConnCase
  import Phoenix.ConnTest
  import MehrSchulferien.Factory
  import MehrSchulferien.TestHelpers

  @current_year Date.utc_today().year
  @future_year @current_year + 1
  @past_year @current_year - 100

  setup %{conn: conn} do
    {:ok, %{conn: conn}}
  end

  describe "bridge days for federal state" do
    setup [:add_federal_state, :add_periods]

    test "old route redirects to new route", %{
      conn: conn,
      country: country,
      federal_state: federal_state
    } do
      # Test old route format redirects
      conn = get(conn, "/land/#{country.slug}/bundesland/#{federal_state.slug}/brueckentage")

      # We expect a 301 permanent redirect
      assert conn.status == 301

      # The redirect URL should contain the correct base path
      redirect_path = redirected_to(conn, 301)

      assert redirect_path =~
               "/ferien/#{country.slug}/bundesland/#{federal_state.slug}/brueckentage"
    end

    test "complete bridge day page functionality", %{
      conn: conn,
      country: country,
      federal_state: federal_state
    } do
      # Test page loads with data
      conn =
        get(
          conn,
          ~p"/brueckentage/#{country.slug}/bundesland/#{federal_state.slug}/#{@future_year}"
        )

      html = html_response(conn, 200)

      # Basic content
      assert html =~ "Brückentage #{@future_year} in"
      assert html =~ "Tipps"
      assert html =~ "Die "
      assert html =~ "besten Tipps für"

      # Template specific checks
      assert html =~ ~s(<p class="text-gray-700 dark:text-gray-300 mb-8">)
      assert html =~ "Nicht nur klassische Brückentage, sondern auch Super-Brückentage"
      assert html =~ "Brückentag"

      # Check flag image if applicable
      if code = federal_state.code do
        if MehrSchulferien.Locations.Flag.get_flag(code) do
          assert html =~ ~s(class="rounded shadow-sm")
          assert html =~ ~s(alt="Landesflage #{federal_state.name}")
        end
      end

      # Schema.org JSON-LD
      assert html =~ ~s(<script type="application/ld+json">)
      assert html =~ ~s("@context":"https://schema.org")
    end

    test "SEO title, description and canonical target the searcher's benefit", %{
      conn: conn,
      country: country,
      federal_state: federal_state
    } do
      conn =
        get(
          conn,
          ~p"/brueckentage/#{country.slug}/bundesland/#{federal_state.slug}/#{@future_year}"
        )

      html = html_response(conn, 200)

      assert html =~ ~r/<title>\s*Brückentage #{federal_state.name} #{@future_year}:/
      assert html =~ "Chancen für mehr Urlaub"
      assert html =~ "Jetzt Urlaub clever planen"
      assert html =~ ~s(rel="canonical")

      assert html =~
               "/brueckentage/#{country.slug}/bundesland/#{federal_state.slug}/#{@future_year}\""
    end

    test "navigation arrows and year links", %{
      conn: conn,
      country: country,
      federal_state: federal_state
    } do
      # Test current year page
      conn =
        get(
          conn,
          ~p"/brueckentage/#{country.slug}/bundesland/#{federal_state.slug}/#{@current_year}"
        )

      html = html_response(conn, 200)

      # Should show link to future year
      assert html =~
               ~s(href="/brueckentage/#{country.slug}/bundesland/#{federal_state.slug}/#{@future_year}")

      # Past year should not be linked (no data)
      past_year = @current_year - 1

      refute html =~
               ~s(href="/brueckentage/#{country.slug}/bundesland/#{federal_state.slug}/#{past_year}")

      # Check disabled arrow styling
      assert html =~ ~s(cursor-not-allowed)
    end

    test "404 for years without data", %{
      conn: conn,
      country: country,
      federal_state: federal_state
    } do
      conn =
        get(
          conn,
          ~p"/brueckentage/#{country.slug}/bundesland/#{federal_state.slug}/#{@past_year}"
        )

      assert html_response(conn, 404)
    end

    test "handles invalid year formats", %{
      conn: conn,
      country: country,
      federal_state: federal_state
    } do
      conn = get(conn, "/brueckentage/#{country.slug}/bundesland/#{federal_state.slug}/foobar")
      assert conn.status == 404
    end

    # The year gate never reads the real clock: each request pins "today"
    # via the ?today= override provided by DateAssignsPlug.
    test "a past year 301-redirects to the current year page", %{
      conn: conn,
      country: country,
      federal_state: federal_state
    } do
      conn =
        get(
          conn,
          "/brueckentage/#{country.slug}/bundesland/#{federal_state.slug}/2021?today=15.06.2026"
        )

      assert redirected_to(conn, 301) ==
               "/brueckentage/#{country.slug}/bundesland/#{federal_state.slug}/2026"
    end

    test "the current year does not redirect even without data", %{
      conn: conn,
      country: country,
      federal_state: federal_state
    } do
      conn =
        get(
          conn,
          "/brueckentage/#{country.slug}/bundesland/#{federal_state.slug}/2030?today=15.06.2030"
        )

      assert conn.status == 404
    end
  end

  describe "national bridge day overview" do
    setup [:add_federal_state, :add_periods]

    test "renders per-state cards linking the state bridge day pages", %{
      conn: conn,
      country: country,
      federal_state: federal_state
    } do
      conn = get(conn, "/brueckentage/#{country.slug}/#{@current_year}")
      html = html_response(conn, 200)

      assert html =~ "Brückentage #{@current_year}"
      assert html =~ federal_state.name

      assert html =~
               "/brueckentage/#{country.slug}/bundesland/#{federal_state.slug}/#{@current_year}"
    end

    test "has an SEO title with the year and a self-referencing canonical", %{
      conn: conn,
      country: country
    } do
      conn = get(conn, "/brueckentage/#{country.slug}/#{@current_year}")
      html = html_response(conn, 200)

      assert html =~ "<title>"
      assert html =~ "Brückentage #{@current_year}"
      assert html =~ ~s(rel="canonical")
      assert html =~ "/brueckentage/#{country.slug}/#{@current_year}\""
    end

    test "a past year 301-redirects to the current year", %{
      conn: conn,
      country: country
    } do
      conn = get(conn, "/brueckentage/#{country.slug}/2021?today=15.06.2026")

      assert redirected_to(conn, 301) == "/brueckentage/#{country.slug}/2026"
    end

    test "404 for years without any bridge days", %{conn: conn, country: country} do
      conn = get(conn, "/brueckentage/#{country.slug}/2035?today=15.06.2035")

      assert conn.status == 404
    end
  end

  # Setup functions
  defp add_federal_state(_) do
    country = get_or_create_deutschland()

    federal_state =
      insert(:federal_state, %{
        parent_location_id: country.id,
        slug: "brandenburg",
        name: "Brandenburg"
      })

    {:ok, %{country: country, federal_state: federal_state}}
  end

  defp add_periods(context) do
    federal_state = context[:federal_state] || raise "federal_state not found in context"
    _public_periods = add_public_periods(%{location: federal_state})
    {:ok, context}
  end
end
