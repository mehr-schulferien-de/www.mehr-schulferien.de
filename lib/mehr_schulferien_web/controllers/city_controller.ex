defmodule MehrSchulferienWeb.CityController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars, Calendars.Period, Locations}
  alias MehrSchulferienWeb.ControllerHelpers, as: CH
  alias MehrSchulferienWeb.Email

  def new_period(conn, %{"country_slug" => country_slug, "city_slug" => city_slug}) do
    %{country: country, federal_state: federal_state, city: city} =
      Locations.show_city_to_country_map(country_slug, city_slug)

    holiday_or_vacation_type =
      Calendars.get_holiday_or_vacation_type_by_name!(
        "Schulschließung wegen der COVID-19-Pandemie (Corona)"
      )

    changeset = Calendars.change_period(%Period{})

    render(conn, "new.html",
      changeset: changeset,
      country_slug: country_slug,
      city_slug: city_slug,
      city_id: city.id,
      holiday_or_vacation_type_id: holiday_or_vacation_type.id,
      city: city,
      country: country,
      federal_state: federal_state
    )
  end

  def create_period(conn, %{
        "country_slug" => country_slug,
        "city_slug" => city_slug,
        "period" => period_params
      }) do
    case Calendars.create_period(period_params) do
      {:ok, period} ->
        Email.period_added_notification(period)

        conn
        |> put_flash(
          :info,
          "Die Daten zur Schulschließung wegen der COVID-19-Pandemie wurden eingetragen."
        )
        |> redirect(to: Routes.city_path(conn, :show, country_slug, city_slug))

      {:error, %Ecto.Changeset{} = changeset} ->
        %{country: country, federal_state: federal_state, city: city} =
          Locations.show_city_to_country_map(country_slug, city_slug)

        holiday_or_vacation_type =
          Calendars.get_holiday_or_vacation_type_by_name!(
            "Schulschließung wegen der COVID-19-Pandemie (Corona)"
          )

        render(conn, "new.html",
          changeset: changeset,
          country_slug: country_slug,
          city_slug: city_slug,
          city_id: city.id,
          holiday_or_vacation_type_id: holiday_or_vacation_type.id,
          city: city,
          country: country,
          federal_state: federal_state
        )
    end
  end

  def show(conn, %{
        "country_slug" => country_slug,
        "city_slug" => city_slug
      }) do
    %{country: country, federal_state: federal_state, county: county, city: city} =
      Locations.show_city_to_country_map(country_slug, city_slug)

    today = Date.utc_today()
    location_ids = [country.id, federal_state.id, county.id, city.id]
    schools = Locations.list_schools(city)

    assigns =
      [city: city, country: country, federal_state: federal_state, schools: schools] ++
        CH.show_period_data(location_ids, today)

    render(conn, "show.html", assigns)
  end
end
