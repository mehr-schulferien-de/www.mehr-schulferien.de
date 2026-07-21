defmodule MehrSchulferienWeb.FeiertagController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars.DateHelpers, Locations, Periods}
  alias MehrSchulferienWeb.ControllerHelpers, as: CH

  @doc """
  Evergreen national Feiertage page: all public holidays of the current
  and next year across the federal states, on a stable year-less URL.
  """
  def show_country(conn, %{"country_slug" => country_slug}) do
    today = DateHelpers.get_today_or_custom_date(conn)

    case CH.fetch_country(country_slug) do
      {:ok, country} ->
        years = [today.year, today.year + 1]
        states = Locations.list_federal_states(country)

        holidays_by_year =
          for year <- years, do: {year, national_holiday_rows(country, states, year)}

        has_data = Enum.any?(holidays_by_year, fn {_year, rows} -> rows != [] end)
        conn = if has_data, do: conn, else: put_status(conn, 404)

        render(conn, "show_country.html", %{
          country: country,
          states: states,
          holidays_by_year: holidays_by_year,
          current_year: today.year,
          next_year: today.year + 1,
          today: today,
          has_data: has_data,
          evergreen: true
        })

      {:error, :not_found} ->
        CH.render_not_found_or_empty_database(conn)
    end
  end

  @doc """
  National Feiertage page for one year: every public holiday with the
  states it applies to, targeting the "feiertage <jahr>" head terms.
  """
  def index_country(conn, %{"country_slug" => country_slug, "year" => year}) do
    today = DateHelpers.get_today_or_custom_date(conn)

    with {:ok, country} <- CH.fetch_country(country_slug),
         {:ok, year_int} <- CH.check_year(year) do
      if year_int < today.year do
        # Past years consolidate into the evergreen national page.
        permanent_redirect(conn, ~p"/feiertage/#{country.slug}")
      else
        states = Locations.list_federal_states(country)
        rows = national_holiday_rows(country, states, year_int)

        conn = if rows == [], do: put_status(conn, 404), else: conn

        render(conn, "index_country.html", %{
          country: country,
          states: states,
          year: year_int,
          holiday_rows: rows,
          today: today,
          has_data: rows != []
        })
      end
    else
      {:error, :not_found} -> CH.render_not_found_or_empty_database(conn)
      {:error, :invalid_year} -> raise_not_found(conn)
    end
  end

  @doc """
  Evergreen Feiertage page for one state: current and next year on a
  stable year-less URL, mirroring the evergreen state pages.
  """
  def index_within_federal_state(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug
      }) do
    today = DateHelpers.get_today_or_custom_date(conn)

    with {:ok, country} <- CH.fetch_country(country_slug),
         {:ok, federal_state} <- CH.fetch_federal_state(federal_state_slug, country) do
      years = [today.year, today.year + 1]

      holidays_by_year =
        for year <- years,
            do: {year, state_holidays(country, federal_state, year)}

      has_data = Enum.any?(holidays_by_year, fn {_year, periods} -> periods != [] end)
      conn = if has_data, do: conn, else: put_status(conn, 404)

      render(conn, "index_within_federal_state.html", %{
        country: country,
        federal_state: federal_state,
        holidays_by_year: holidays_by_year,
        current_year: today.year,
        next_year: today.year + 1,
        today: today,
        has_data: has_data
      })
    else
      {:error, :not_found} -> CH.render_not_found_or_empty_database(conn)
    end
  end

  @doc """
  Feiertage page for one state and year.
  """
  def show_within_federal_state(conn, %{
        "country_slug" => country_slug,
        "federal_state_slug" => federal_state_slug,
        "year" => year
      }) do
    today = DateHelpers.get_today_or_custom_date(conn)

    with {:ok, country} <- CH.fetch_country(country_slug),
         {:ok, federal_state} <- CH.fetch_federal_state(federal_state_slug, country),
         {:ok, year_int} <- CH.check_year(year) do
      if year_int < today.year do
        # Past years consolidate into the evergreen state page.
        permanent_redirect(
          conn,
          ~p"/feiertage/#{country.slug}/bundesland/#{federal_state.slug}"
        )
      else
        holidays = state_holidays(country, federal_state, year_int)

        conn = if holidays == [], do: put_status(conn, 404), else: conn

        render(conn, "show_within_federal_state.html", %{
          country: country,
          federal_state: federal_state,
          year: year_int,
          holidays: holidays,
          today: today,
          has_data: holidays != []
        })
      end
    else
      {:error, :not_found} -> CH.render_not_found_or_empty_database(conn)
      {:error, :invalid_year} -> raise_not_found(conn)
    end
  end

  # All public holidays of one state (including country-wide ones),
  # deduplicated and sorted by date.
  defp state_holidays(country, federal_state, year) do
    {:ok, start_date} = Date.new(year, 1, 1)
    {:ok, end_date} = Date.new(year, 12, 31)

    [country.id, federal_state.id]
    |> Periods.list_public_periods(start_date, end_date)
    |> Enum.uniq_by(&{&1.holiday_or_vacation_type_id, &1.starts_on})
    |> Enum.sort_by(& &1.starts_on, Date)
  end

  # One row per (holiday, date) with the list of states it applies to.
  # Holidays attached to the country location count as country-wide.
  defp national_holiday_rows(country, states, year) do
    {:ok, start_date} = Date.new(year, 1, 1)
    {:ok, end_date} = Date.new(year, 12, 31)

    country_periods = Periods.list_public_periods([country.id], start_date, end_date)

    state_periods =
      for state <- states,
          period <- Periods.list_public_periods([state.id], start_date, end_date),
          do: {state, period}

    country_rows =
      Enum.map(country_periods, fn period ->
        %{period: period, states: :all}
      end)

    state_rows =
      state_periods
      |> Enum.group_by(fn {_state, period} ->
        {period.holiday_or_vacation_type_id, period.starts_on}
      end)
      |> Enum.map(fn {_key, entries} ->
        {_state, period} = hd(entries)
        states_for_row = entries |> Enum.map(&elem(&1, 0)) |> Enum.sort_by(& &1.name)

        states_value =
          if length(states_for_row) == length(states) and states != [],
            do: :all,
            else: states_for_row

        %{period: period, states: states_value}
      end)

    (country_rows ++ state_rows)
    |> Enum.uniq_by(&{&1.period.holiday_or_vacation_type_id, &1.period.starts_on})
    |> Enum.sort_by(& &1.period.starts_on, Date)
  end

  defp permanent_redirect(conn, to) do
    conn
    |> put_status(:moved_permanently)
    |> redirect(to: to)
  end

  defp raise_not_found(conn) do
    conn = Plug.Conn.put_status(conn, :not_found)
    raise Phoenix.Router.NoRouteError, conn: conn, router: MehrSchulferienWeb.Router
  end
end
