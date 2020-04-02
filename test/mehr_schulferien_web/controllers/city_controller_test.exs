defmodule MehrSchulferienWeb.CityControllerTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferien.Calendars

  setup %{conn: conn} do
    conn = conn |> bypass_through(MehrSchulferienWeb.Router, [:browser]) |> get("/users")
    {:ok, %{conn: conn}}
  end

  describe "read city data" do
    setup [:add_city, :add_periods]

    test "shows info for a specific city", %{conn: conn, city: city, country: country} do
      conn = get(conn, Routes.city_path(conn, :show, country.slug, city.slug))
      assert html_response(conn, 200) =~ city.name
    end

    test "custom meta tags are generated", %{conn: conn, city: city, country: country} do
      conn = get(conn, Routes.city_path(conn, :show, country.slug, city.slug))
      assert html_response(conn, 200) =~ "Schulferientermine für #{city.name}"
    end

    test "returns 404 if country is not the root parent of the school", %{conn: conn, city: city} do
      assert_error_sent 404, fn ->
        get(conn, Routes.school_path(conn, :show, "ch", city.slug))
      end
    end
  end

  describe "write holiday period" do
    setup [:add_city]

    test "creates new period for city", %{
      conn: conn,
      country: country,
      city: city
    } do
      user = add_user("reg@example.com")
      conn = conn |> add_session(user) |> send_resp(:ok, "/users")

      holiday_or_vacation_type =
        insert(:holiday_or_vacation_type, %{country_location_id: country.id})

      today = Date.utc_today()

      attrs = %{
        "created_by_email_address" => "froderick@example.com",
        "ends_on" => Date.add(today, 6),
        "location_id" => city.id,
        "holiday_or_vacation_type_id" => holiday_or_vacation_type.id,
        "starts_on" => Date.add(today, 1)
      }

      conn =
        post(conn, Routes.city_path(conn, :create_period, country.slug, city.slug), period: attrs)

      assert redirected_to(conn) == Routes.city_path(conn, :show, country.slug, city.slug)

      assert get_flash(conn, :info) =~
               "Die Daten zur Schulschließung wegen der COVID-19-Pandemie wurden eingetragen."

      assert [period] = Calendars.list_periods()
      assert period.created_by_email_address == "froderick@example.com"
      assert period.holiday_or_vacation_type_id == holiday_or_vacation_type.id
    end
  end

  defp add_city(_) do
    country = insert(:country, %{slug: "d"})
    federal_state = insert(:federal_state, %{parent_location_id: country.id, slug: "berlin"})
    county = insert(:county, %{parent_location_id: federal_state.id, slug: "berlin"})
    city = insert(:city, %{parent_location_id: county.id, slug: "berlin"})
    {:ok, %{city: city, country: country}}
  end

  defp add_periods(%{city: city, country: country}) do
    _school_periods = add_school_periods(%{location: city})
    _public_periods = add_public_periods(%{location: city})
    {:ok, %{city: city, country: country}}
  end
end
