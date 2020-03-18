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
        post(conn, Routes.federal_state_path(conn, :create, country.slug, federal_state.slug),
          period: attrs
        )

      assert redirected_to(conn) ==
               Routes.federal_state_path(conn, :show, country.slug, federal_state.slug)

      assert get_flash(conn, :info) =~ "Period created successfully"
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
    dates = [
      {~D[2019-04-06], ~D[2019-04-18]},
      {~D[2019-10-31], ~D[2019-10-31]},
      {~D[2019-12-23], ~D[2020-01-04]},
      {~D[2020-04-06], ~D[2020-04-18]},
      {~D[2020-10-31], ~D[2020-10-31]},
      {~D[2020-12-23], ~D[2021-01-04]},
      {~D[2021-04-06], ~D[2021-04-18]},
      {~D[2021-10-31], ~D[2021-10-31]},
      {~D[2021-12-23], ~D[2022-01-04]}
    ]

    periods =
      for {starts_on, ends_on} <- dates do
        insert(:period, %{
          is_school_vacation: true,
          is_valid_for_students: true,
          location_id: federal_state.id,
          starts_on: starts_on,
          ends_on: ends_on
        })
      end

    other_period =
      insert(:period, %{
        is_school_vacation: true,
        is_valid_for_students: true,
        starts_on: ~D[2020-10-31],
        ends_on: ~D[2020-10-31]
      })

    today = Date.utc_today()

    public_period =
      insert(:period, %{
        is_public_holiday: true,
        location_id: federal_state.id,
        starts_on: Date.add(today, 1),
        ends_on: Date.add(today, 1)
      })

    {:ok,
     %{
       federal_state: federal_state,
       periods: periods,
       other_period: other_period,
       public_period: public_period
     }}
  end
end
