defmodule MehrSchulferienWeb.CityController do
  use MehrSchulferienWeb, :controller

  import MehrSchulferienWeb.Authorize

  alias MehrSchulferien.{Calendars, Calendars.DateHelpers, Locations}
  alias MehrSchulferien.{Periods, Periods.Period}
  alias MehrSchulferienWeb.ControllerHelpers, as: CH
  alias MehrSchulferienWeb.Email

  plug :user_check when action in [:new_period, :create_period]

  def new_period(conn, %{"country_slug" => country_slug, "city_slug" => city_slug}) do
    user = conn.assigns.current_user

    %{country: country, federal_state: federal_state, city: city} =
      Locations.show_city_to_country_map(country_slug, city_slug)

    holiday_or_vacation_type =
      Calendars.get_holiday_or_vacation_type_by_name!(
        "Schulschließung wegen der COVID-19-Pandemie (Corona)"
      )

    changeset = Periods.change_period(%Period{})

    render(conn, "new.html",
      changeset: changeset,
      city: city,
      country: country,
      federal_state: federal_state,
      holiday_or_vacation_type_id: holiday_or_vacation_type.id,
      user_email: user.email
    )
  end

  def create_period(conn, %{
        "country_slug" => country_slug,
        "city_slug" => city_slug,
        "period" => period_params
      }) do
    case Periods.create_period(period_params) do
      {:ok, period} ->
        Email.period_added_notification(period)

        conn
        |> put_flash(
          :info,
          "Die Daten zur Schulschließung wegen der COVID-19-Pandemie wurden eingetragen."
        )
        |> redirect(to: Routes.city_path(conn, :show, country_slug, city_slug))

      {:error, %Ecto.Changeset{} = changeset} ->
        user = conn.assigns.current_user

        %{country: country, federal_state: federal_state, city: city} =
          Locations.show_city_to_country_map(country_slug, city_slug)

        holiday_or_vacation_type =
          Calendars.get_holiday_or_vacation_type_by_name!(
            "Schulschließung wegen der COVID-19-Pandemie (Corona)"
          )

        render(conn, "new.html",
          changeset: changeset,
          city: city,
          country: country,
          federal_state: federal_state,
          holiday_or_vacation_type_id: holiday_or_vacation_type.id,
          user_email: user.email
        )
    end
  end

  def show(conn, %{
        "country_slug" => country_slug,
        "city_slug" => city_slug
      }) do
    %{country: country, federal_state: federal_state, county: county, city: city} =
      Locations.show_city_to_country_map(country_slug, city_slug)

    today = DateHelpers.today_berlin()
    location_ids = [country.id, federal_state.id, county.id, city.id]
    schools = Locations.list_schools(city)

    city_name_is_similar_to_a_federal_state? =
      Enum.member?(["hessen", "hamburg", "bremen", "berlin", "bayern"], city.slug)

    assigns =
      [
        city: city,
        country: country,
        federal_state: federal_state,
        schools: schools,
        city_name_is_similar_to_a_federal_state?: city_name_is_similar_to_a_federal_state?
      ] ++
        CH.list_period_data(location_ids, today)

    render(conn, "show.html", assigns)
  end
end
