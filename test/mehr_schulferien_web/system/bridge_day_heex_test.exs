defmodule MehrSchulferienWeb.BridgeDayHEExSystemTest do
  use MehrSchulferienWeb.ConnCase
  import Phoenix.ConnTest

  import MehrSchulferien.Factory

  @current_year Date.utc_today().year
  @future_year @current_year + 1

  setup %{conn: conn} do
    {:ok, %{conn: conn}}
  end

  describe "bridge days HEEx template" do
    setup [:add_federal_state, :add_periods]

    test "shows the bridge days page with properly formatted content", %{
      conn: conn,
      country: country,
      federal_state: federal_state
    } do
      conn =
        get(
          conn,
          Routes.bridge_day_path(
            conn,
            :show_within_federal_state,
            country.slug,
            federal_state.slug,
            @future_year
          )
        )

      # Verify basic page content
      assert html_response(conn, 200) =~ "Brückentage #{@future_year} in"
      assert html_response(conn, 200) =~ "Die "
      assert html_response(conn, 200) =~ "besten Tipps für"

      # Check flag image is properly formatted with HEEx syntax
      if code = federal_state.code do
        if MehrSchulferien.Locations.Flag.get_flag(code) do
          html = html_response(conn, 200)
          assert html =~ ~s(class="rounded shadow-sm")
          # Test for the complete alt attribute which confirms HEEx conversion
          assert html =~ ~s(alt="Landesflage #{federal_state.name}")
        end
      end

      # Test the intro paragraph
      assert html_response(conn, 200) =~ ~s(<p class="text-gray-700 mb-8">)
      assert html_response(conn, 200) =~ "Unser Spezial-Algorithmus findet"

      # Verify bridge day sections are rendered
      assert html_response(conn, 200) =~ "Brückentag"
    end

    test "displays the FAQ section with proper schema markup", %{
      conn: conn,
      country: country,
      federal_state: federal_state
    } do
      conn =
        get(
          conn,
          Routes.bridge_day_path(
            conn,
            :show_within_federal_state,
            country.slug,
            federal_state.slug,
            @future_year
          )
        )

      html = html_response(conn, 200)

      # Check for FAQ content
      if html =~ "Brückentag-FAQ" do
        assert html =~ ~s(<dt class="text-lg font-medium text-gray-800">Wie viele Brückentage)
        assert html =~ ~s(<dd class="mt-2 text-gray-700">)

        # Check for Schema.org JSON-LD
        assert html =~ ~s(<script type="application/ld+json">)
        assert html =~ ~s("@context": "https://schema.org")
        assert html =~ ~s("@type": "FAQPage")
      end
    end
  end

  defp add_federal_state(_) do
    country = insert(:country, %{slug: "d", name: "Deutschland", code: "DE"})

    federal_state =
      insert(:federal_state, %{
        parent_location_id: country.id,
        slug: "brandenburg",
        name: "Brandenburg",
        code: "BB"
      })

    {:ok, %{country: country, federal_state: federal_state}}
  end

  defp add_periods(%{federal_state: federal_state}) do
    _public_periods = add_public_periods(%{location: federal_state})
    {:ok, %{federal_state: federal_state}}
  end
end
