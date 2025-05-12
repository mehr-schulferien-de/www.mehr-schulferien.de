defmodule MehrSchulferienWeb.PublicHolidaySystemTest do
  use MehrSchulferienWeb.ConnCase
  import Phoenix.ConnTest
  import MehrSchulferien.Factory

  @current_year Date.utc_today().year

  setup %{conn: conn} do
    {:ok, %{conn: conn}}
  end

  describe "public holiday page for federal state" do
    setup [:add_federal_state_with_public_holiday]

    test "shows the public holiday page for a federal state", %{
      conn: conn,
      country: country,
      federal_state: federal_state,
      holiday_type: holiday_type
    } do
      conn =
        get(
          conn,
          Routes.public_holiday_path(
            conn,
            :show_within_federal_state,
            country.slug,
            federal_state.slug,
            holiday_type.slug
          )
        )

      # Check HTTP status
      assert html_response(conn, 200)

      # Check page title
      assert html_response(conn, 200) =~ "#{holiday_type.name} (#{federal_state.name})"

      # Check breadcrumb navigation
      assert html_response(conn, 200) =~ "Start"
      assert html_response(conn, 200) =~ country.name
      assert html_response(conn, 200) =~ federal_state.name
      assert html_response(conn, 200) =~ holiday_type.name

      # Check that holiday table exists
      assert html_response(conn, 200) =~ "Feiertag"
      assert html_response(conn, 200) =~ "Datum"

      # Check that FAQ section exists
      assert html_response(conn, 200) =~ "FAQ"
      assert html_response(conn, 200) =~ "Wann ist #{holiday_type.name} in #{federal_state.name}?"

      # Check that schema.org JSON-LD markup exists
      assert html_response(conn, 200) =~ "application/ld+json"
      assert html_response(conn, 200) =~ "FAQPage"
      assert html_response(conn, 200) =~ "Event"
    end
  end

  defp add_federal_state_with_public_holiday(_) do
    country = insert(:country, %{slug: "d", name: "Deutschland"})

    federal_state =
      insert(:federal_state, %{
        parent_location_id: country.id,
        slug: "brandenburg",
        name: "Brandenburg",
        code: "BB"
      })

    holiday_type =
      insert(:holiday_or_vacation_type, %{
        name: "Neujahr",
        colloquial: "Neujahr",
        country_location_id: country.id,
        slug: "neujahr",
        default_is_public_holiday: true
      })

    # Create current year and next year holidays
    [
      # Current year
      Date.new!(@current_year, 1, 1),
      # Next year
      Date.new!(@current_year + 1, 1, 1)
    ]
    |> Enum.each(fn date ->
      create_period(%{
        created_by_email_address: "test@example.com",
        location_id: federal_state.id,
        holiday_or_vacation_type_id: holiday_type.id,
        starts_on: date,
        ends_on: date,
        is_public_holiday: true,
        is_valid_for_everybody: true
      })
    end)

    {:ok, %{country: country, federal_state: federal_state, holiday_type: holiday_type}}
  end

  defp create_period(attrs) do
    {:ok, period} = MehrSchulferien.Periods.create_period(attrs)
    period
  end
end
