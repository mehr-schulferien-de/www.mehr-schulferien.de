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
