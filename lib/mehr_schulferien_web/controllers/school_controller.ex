defmodule MehrSchulferienWeb.SchoolController do
  use MehrSchulferienWeb, :controller

  import MehrSchulferienWeb.Authorize

  alias MehrSchulferien.{Calendars, Calendars.Period, Locations}
  alias MehrSchulferienWeb.ControllerHelpers, as: CH
  alias MehrSchulferienWeb.Email

  plug :user_check when action in [:new_period, :create_period]

  def new_period(conn, %{"country_slug" => country_slug, "school_slug" => school_slug}) do
    user = conn.assigns.current_user

    %{country: country, federal_state: federal_state, city: city, school: school} =
      Locations.show_school_to_country_map(country_slug, school_slug)

    holiday_or_vacation_type =
      Calendars.get_holiday_or_vacation_type_by_name!(
        "Schulschließung wegen der COVID-19-Pandemie (Corona)"
      )

    changeset = Calendars.change_period(%Period{})

    render(conn, "new.html",
      changeset: changeset,
      city: city,
      country: country,
      federal_state: federal_state,
      school: school,
      holiday_or_vacation_type_id: holiday_or_vacation_type.id,
      user_email: user.email
    )
  end

  def create_period(conn, %{
        "country_slug" => country_slug,
        "school_slug" => school_slug,
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
        |> redirect(to: Routes.school_path(conn, :show, country_slug, school_slug))

      {:error, %Ecto.Changeset{} = changeset} ->
        user = conn.assigns.current_user

        %{
          country: country,
          federal_state: federal_state,
          city: city,
          school: school
        } = Locations.show_school_to_country_map(country_slug, school_slug)

        holiday_or_vacation_type =
          Calendars.get_holiday_or_vacation_type_by_name!(
            "Schulschließung wegen der COVID-19-Pandemie (Corona)"
          )

        render(conn, "new.html",
          changeset: changeset,
          city: city,
          country: country,
          federal_state: federal_state,
          school: school,
          holiday_or_vacation_type_id: holiday_or_vacation_type.id,
          user_email: user.email
        )
    end
  end

  def show(conn, %{"country_slug" => country_slug, "school_slug" => school_slug}) do
    %{country: country, federal_state: federal_state, county: county, city: city, school: school} =
      Locations.show_school_to_country_map(country_slug, school_slug)

    today = Date.utc_today()
    location_ids = [country.id, federal_state.id, county.id, city.id, school.id]

    assigns =
      [city: city, country: country, federal_state: federal_state, school: school] ++
        CH.show_period_data(location_ids, today)

    render(conn, "show.html", assigns)
  end
end
