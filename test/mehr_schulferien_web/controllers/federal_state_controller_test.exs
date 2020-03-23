defmodule MehrSchulferienWeb.FederalStateControllerTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Calendars

  describe "read federal state data" do
    setup [:add_federal_state, :add_periods]

    test "shows info for a specific federal state", %{
      conn: conn,
      country: country,
      federal_state: federal_state
    } do
      conn = get(conn, Routes.federal_state_path(conn, :show, country.slug, federal_state.slug))
      assert html_response(conn, 200) =~ federal_state.name
    end

    test "custom meta tags are generated", %{
      conn: conn,
      country: country,
      federal_state: federal_state
    } do
      conn = get(conn, Routes.federal_state_path(conn, :show, country.slug, federal_state.slug))
      assert html_response(conn, 200) =~ "Schulferienkalender für #{federal_state.name}"
    end

    test "shows schema.org events for school holiday periods", %{
      conn: conn,
      country: country,
      federal_state: federal_state
    } do
      conn = get(conn, Routes.federal_state_path(conn, :show, country.slug, federal_state.slug))
      response = html_response(conn, 200)
      assert response =~ ~s("@context": "http://schema.org")
      assert response =~ ~s("name": "#{federal_state.name}")
    end
  end

  describe "write holiday period" do
    setup [:add_federal_state]

    test "creates new period for federal_state", %{
      conn: conn,
      country: country,
      federal_state: federal_state
    } do
      holiday_or_vacation_type =
        insert(:holiday_or_vacation_type, %{country_location_id: country.id})

      today = Date.utc_today()

      attrs = %{
        "created_by_email_address" => "froderick@example.com",
        "ends_on" => Date.add(today, 6),
        "location_id" => federal_state.id,
        "holiday_or_vacation_type_id" => holiday_or_vacation_type.id,
        "starts_on" => Date.add(today, 1)
      }

      conn =
        post(
          conn,
          Routes.federal_state_path(conn, :create_period, country.slug, federal_state.slug),
          period: attrs
        )

      assert redirected_to(conn) ==
               Routes.federal_state_path(conn, :show, country.slug, federal_state.slug)

      assert get_flash(conn, :info) =~
               "Die Daten zur Schulschließung wegen der COVID-19-Pandemie wurden eingetragen."

      assert [period] = Calendars.list_periods()
      assert period.created_by_email_address == "froderick@example.com"
      assert period.holiday_or_vacation_type_id == holiday_or_vacation_type.id
    end
  end

  defp add_federal_state(_) do
    country = insert(:country, %{slug: "d"})
    federal_state = insert(:federal_state, %{parent_location_id: country.id, slug: "berlin"})
    {:ok, %{country: country, federal_state: federal_state}}
  end

  defp add_periods(%{federal_state: federal_state}) do
    _school_periods = add_school_periods(%{location: federal_state})
    _public_periods = add_public_periods(%{location: federal_state})
    {:ok, %{federal_state: federal_state}}
  end
end
