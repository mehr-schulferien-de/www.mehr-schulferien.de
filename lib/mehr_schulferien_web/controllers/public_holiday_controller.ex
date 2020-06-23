defmodule MehrSchulferienWeb.PublicHolidayController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{
    Calendars,
    Calendars.HolidayOrVacationType,
    Calendars.DateHelpers,
    Locations,
    Periods.Period
  }

  alias MehrSchulferien.Repo

  import Ecto.Query

  def show_within_federal_state(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug,
        "holiday_or_vacation_type_slug" => holiday_or_vacation_type_slug
      }) do
    country = Locations.get_country_by_slug!(country_slug)
    federal_state = Locations.get_federal_state_by_slug!(federal_state_slug, country)
    today = DateHelpers.today_berlin()

    holiday_or_vacation_type =
      Calendars.get_holiday_or_vacation_type_by_slug!(holiday_or_vacation_type_slug)

    query =
      from(p in Period,
        join: h in HolidayOrVacationType,
        on: h.id == p.holiday_or_vacation_type_id,
        where:
          h.slug == ^holiday_or_vacation_type_slug and
            p.is_public_holiday == true and
            p.location_id == ^federal_state.id and
            p.ends_on >= ^today,
        order_by: p.starts_on
      )

    periods = Repo.all(query) |> Repo.preload([:holiday_or_vacation_type])
    months = DateHelpers.get_months_map()

    assigns = [
      country: country,
      federal_state: federal_state,
      today: today,
      periods: periods,
      holiday_or_vacation_type: holiday_or_vacation_type,
      months: months
    ]

    render(conn, "show_within_federal_state.html", assigns)
  end
end
