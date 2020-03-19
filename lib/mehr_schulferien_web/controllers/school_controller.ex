defmodule MehrSchulferienWeb.SchoolController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars, Calendars.Period, Locations}
  alias MehrSchulferienWeb.ControllerHelpers, as: CH
  alias MehrSchulferienWeb.Email

  def new_period(conn, %{"country_slug" => country_slug, "school_slug" => school_slug}) do
    %{school: school} = Locations.show_school_to_country_map(country_slug, school_slug)

    holiday_or_vacation_type =
      Calendars.get_holiday_or_vacation_type_by_name!("Corona Virus Quarantäne")

    changeset = Calendars.change_period(%Period{})

    render(conn, "new.html",
      changeset: changeset,
      country_slug: country_slug,
      school_slug: school_slug,
      school_id: school.id,
      holiday_or_vacation_type_id: holiday_or_vacation_type.id
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
        |> put_flash(:info, "Period created successfully.")
        |> redirect(to: Routes.school_path(conn, :show, country_slug, school_slug))

      {:error, %Ecto.Changeset{} = changeset} ->
        %{school: school} = Locations.show_school_to_country_map(country_slug, school_slug)

        holiday_or_vacation_type =
          Calendars.get_holiday_or_vacation_type_by_name!("Corona Virus Quarantäne")

        render(conn, "new.html",
          changeset: changeset,
          country_slug: country_slug,
          school_slug: school_slug,
          school_id: school.id,
          holiday_or_vacation_type_id: holiday_or_vacation_type.id
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
