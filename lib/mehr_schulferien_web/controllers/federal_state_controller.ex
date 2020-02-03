defmodule MehrSchulferienWeb.FederalStateController do
  use MehrSchulferienWeb, :controller

  import Ecto.Query
  # alias MehrSchulferien.Display
  # alias MehrSchulferien.Display.FederalState
  alias MehrSchulferien.Repo
  alias MehrSchulferien.Maps.Location
  alias MehrSchulferien.Calendars.Period
  alias MehrSchulferien.Calendars

  # def index(conn, _params) do
  #   federal_states = Display.list_federal_states()
  #   render(conn, "index.html", federal_states: federal_states)
  # end

  def show(conn, %{"id" => id}) do
    query =
      from(l in Location,
        where: l.id == ^id,
        where: l.is_federal_state == true,
        limit: 1
      )

    location = Repo.one(query)

    current_year = DateTime.utc_now().year
    current_month = DateTime.utc_now().month
    current_day = DateTime.utc_now().day

    last_year = current_year - 1
    next_year = current_year + 1

    current_school_year =
      case DateTime.utc_now().month do
        x when x < 8 ->
          [last_year, current_year]

        _ ->
          [current_year, next_year]
      end

    current_school_year_string = current_school_year |> Enum.join(" - ")

    [start_year, end_year] = current_school_year

    {:ok, _starts_on} = Date.from_erl({start_year, 8, 1})
    {:ok, _ends_on} = Date.from_erl({end_year, 7, 31})
    {:ok, today} = Date.from_erl({current_year, current_month, current_day})
    {:ok, today_next_year} = Date.from_erl({current_year + 1, current_month, current_day})
    {:ok, first_day_this_year} = Date.from_erl({current_year, 1, 1})
    {:ok, last_day_in_three_years} = Date.from_erl({current_year, 12, 31})
    next_three_years = [current_year, current_year + 1, current_year + 2] |> Enum.join(", ")

    location_ids = Calendars.recursive_location_ids(location)

    next_12_months_periods =
      Repo.all(query_periods(location_ids, today, today_next_year))
      |> Repo.preload(:holiday_or_vacation_type)

    next_3_years_periods =
      Repo.all(query_periods(location_ids, first_day_this_year, last_day_in_three_years))
      |> Repo.preload(:holiday_or_vacation_type)

    render(conn, "show.html",
      location: location,
      current_school_year_string: current_school_year_string,
      next_12_months_periods: next_12_months_periods,
      next_3_years_periods: next_3_years_periods,
      next_three_years: next_three_years
    )
  end

  def query_periods(location_ids, starts_on, ends_on) do
    from(p in Period,
      where:
        p.location_id in ^location_ids and
          p.is_valid_for_students == true and
          p.is_school_vacation == true and
          p.starts_on >= ^starts_on and p.starts_on <= ^ends_on,
      order_by: p.starts_on
    )
  end
end
