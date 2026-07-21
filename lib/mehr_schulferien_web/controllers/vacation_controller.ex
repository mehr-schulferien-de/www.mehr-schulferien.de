defmodule MehrSchulferienWeb.VacationController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Calendars
  alias MehrSchulferien.Calendars.DateHelpers
  alias MehrSchulferien.Calendars.VacationSlug
  alias MehrSchulferien.Calendars.VacationTypes
  alias MehrSchulferien.Locations
  alias MehrSchulferien.Periods
  alias MehrSchulferienWeb.ControllerHelpers, as: CH
  alias MehrSchulferienWeb.Helpers.VacationTypeHelpers
  alias MehrSchulferienWeb.ViewHelpers

  @year_regex ~r/^20[2-3][0-9]$/

  # Season page for one state and year, e.g. /osterferien/bayern/2026.
  # Legacy generated slugs ("osternferien") 301 to the canonical German
  # compound ("osterferien") so search engines consolidate the URLs.
  def show(conn, %{
        "vacation_slug" => vacation_slug,
        "federal_state_slug" => federal_state_slug,
        "year" => year
      }) do
    case VacationSlug.resolve(vacation_slug) do
      {:legacy, db_slug} ->
        permanent_redirect(
          conn,
          "/#{VacationSlug.url_slug(db_slug)}/#{federal_state_slug}/#{year}"
        )

      {:canonical, db_slug} ->
        show_canonical(conn, vacation_slug, db_slug, federal_state_slug, year)

      :error ->
        raise_not_found(conn)
    end
  end

  defp show_canonical(conn, vacation_slug, db_slug, federal_state_slug, year) do
    today = DateHelpers.get_today_or_custom_date(conn)

    # The router's year "constraints:" are decorative, so validate here.
    case CH.check_year(year) do
      {:ok, year_int} ->
        with {:ok, country} <- fetch_country(),
             {:ok, federal_state} <- fetch_federal_state(country, federal_state_slug),
             {:ok, vacation_type_record} <- fetch_vacation_type(db_slug),
             :ok <- validate_vacation_for_state(federal_state, db_slug, vacation_type_record) do
          if year_int < today.year do
            # Past seasons keep no value of their own; consolidate them
            # (and links pointing at them) into the evergreen season page.
            permanent_redirect(conn, "/#{vacation_slug}/#{federal_state.slug}")
          else
            render_vacation_page(conn, %{
              country: country,
              federal_state: federal_state,
              vacation_slug: vacation_slug,
              vacation_type_record: vacation_type_record,
              year: year
            })
          end
        else
          {:error, :not_found} ->
            CH.render_not_found_or_empty_database(conn)

          {:error, :invalid_vacation_type, country} ->
            redirect_to_federal_state(
              conn,
              "Diese Ferienart existiert nicht.",
              country,
              federal_state_slug,
              year,
              :error
            )

          {:error, :vacation_not_in_state, country, federal_state, vacation_type_record} ->
            message = "#{vacation_type_record.colloquial} gibt es in #{federal_state.name} nicht."
            redirect_to_federal_state(conn, message, country, federal_state_slug, year, :info)
        end

      {:error, :invalid_year} ->
        raise_not_found(conn)
    end
  end

  defp fetch_country, do: CH.fetch_country()

  defp fetch_federal_state(country, federal_state_slug),
    do: CH.fetch_federal_state(federal_state_slug, country)

  defp fetch_vacation_type(db_slug) do
    case Calendars.get_school_vacation_type_by_slug(db_slug) do
      nil -> {:error, :invalid_vacation_type, Locations.get_country_by_slug("d")}
      vacation_type_record -> {:ok, vacation_type_record}
    end
  end

  defp validate_vacation_for_state(federal_state, vacation_type_slug, vacation_type_record) do
    if VacationTypes.exists_for_state?(federal_state, vacation_type_slug) do
      :ok
    else
      country = Locations.get_country_by_slug("d")
      {:error, :vacation_not_in_state, country, federal_state, vacation_type_record}
    end
  end

  defp redirect_to_federal_state(conn, message, country, federal_state_slug, year, flash_type) do
    conn
    |> put_flash(flash_type, message)
    |> redirect(to: ~p"/ferien/#{country.slug}/bundesland/#{federal_state_slug}/#{year}")
  end

  defp permanent_redirect(conn, to) do
    conn
    |> put_status(:moved_permanently)
    |> redirect(to: to)
  end

  defp render_vacation_page(conn, params) do
    %{
      country: country,
      federal_state: federal_state,
      vacation_slug: vacation_slug,
      vacation_type_record: vacation_type_record,
      year: year
    } = params

    today = DateHelpers.get_today_or_custom_date(conn)
    location_ids = [country.id, federal_state.id]

    # Get all periods for the state
    data = CH.prepare_show_year_data(location_ids, year, today)

    # Find the specific vacation period
    vacation_period = find_vacation_period(data.periods, vacation_type_record.name)

    # Calculate adjoining durations for all periods
    periods_with_duration =
      ViewHelpers.add_adjoining_duration_to_periods(data.periods, data.all_periods)

    # Get vacation types for the federal state
    vacation_types = get_vacation_types_for_year(federal_state, year)

    # Find the vacation period with adjoining duration from the calculated list
    vacation_period_with_adjoining =
      if vacation_period do
        Enum.find(periods_with_duration, fn p ->
          p.holiday_or_vacation_type.name == vacation_period.holiday_or_vacation_type.name
        end)
      else
        nil
      end

    # Set 404 status if no vacation period exists for this year
    conn = if is_nil(vacation_period), do: put_status(conn, 404), else: conn

    render(
      conn,
      "show.html",
      build_render_assigns(%{
        country: country,
        federal_state: federal_state,
        vacation_slug: vacation_slug,
        vacation_type_record: vacation_type_record,
        vacation_period_with_adjoining: vacation_period_with_adjoining,
        vacation_types: vacation_types,
        periods_with_duration: periods_with_duration,
        data: data,
        today: today,
        year: year
      })
    )
  end

  defp find_vacation_period(periods, vacation_name) do
    Enum.find(periods, fn period ->
      period.holiday_or_vacation_type.name == vacation_name
    end)
  end

  defp get_vacation_types_for_year(federal_state, year) do
    # Get vacation types that actually exist for this specific year
    VacationTypes.list_for_year(federal_state, year)
  end

  defp build_render_assigns(params) do
    year_int = String.to_integer(params.year)
    previous_year = year_int - 1

    # Check if previous year vacation exists
    previous_year_exists =
      VacationTypes.exists_for_year?(
        params.federal_state,
        params.vacation_type_record.slug,
        previous_year
      )

    %{
      country: params.country,
      federal_state: params.federal_state,
      vacation_type: params.vacation_slug,
      vacation_name: params.vacation_type_record.colloquial,
      vacation_period: params.vacation_period_with_adjoining,
      vacation_types: params.vacation_types,
      periods: params.periods_with_duration,
      all_periods: params.data.all_periods,
      public_periods: params.data.public_periods,
      today: params.today,
      has_data: not is_nil(params.vacation_period_with_adjoining),
      previous_year_exists: previous_year_exists,
      months: DateHelpers.get_months_map(),
      year: year_int,
      years_with_data: MehrSchulferien.Periods.list_years_with_periods(),
      meta_title_type: :vacation,
      page_title:
        "#{params.vacation_type_record.colloquial} #{params.federal_state.name} #{params.year}"
    }
  end

  # Year-less URLs: /osterferien/bayern is the evergreen season page for a
  # state, /osterferien/2027 the national overview for one year. The second
  # segment decides which one was requested (router constraints cannot).
  def vacation_current(conn, %{
        "vacation_slug" => vacation_slug,
        "federal_state_slug" => second_segment
      }) do
    case VacationSlug.resolve(vacation_slug) do
      {:legacy, db_slug} ->
        permanent_redirect(conn, "/#{VacationSlug.url_slug(db_slug)}/#{second_segment}")

      {:canonical, db_slug} ->
        if Regex.match?(@year_regex, second_segment) do
          show_country_year(conn, vacation_slug, db_slug, second_segment)
        else
          show_evergreen(conn, vacation_slug, db_slug, second_segment)
        end

      :error ->
        raise_not_found(conn)
    end
  end

  # Evergreen season page for one state: stable URL, current and next
  # year's dates, mirroring the evergreen state pages that rank well.
  defp show_evergreen(conn, vacation_slug, db_slug, federal_state_slug) do
    today = DateHelpers.get_today_or_custom_date(conn)

    with {:ok, country} <- fetch_country(),
         {:ok, federal_state} <- fetch_federal_state(country, federal_state_slug),
         {:ok, vacation_type_record} <- fetch_vacation_type(db_slug),
         :ok <- validate_vacation_for_state(federal_state, db_slug, vacation_type_record) do
      render_evergreen(conn, country, federal_state, vacation_slug, vacation_type_record, today)
    else
      {:error, :not_found} ->
        CH.render_not_found_or_empty_database(conn)

      {:error, :invalid_vacation_type, country} ->
        conn
        |> put_flash(:error, "Diese Ferienart existiert nicht.")
        |> redirect(to: ~p"/ferien/#{country.slug}/bundesland/#{federal_state_slug}")

      {:error, :vacation_not_in_state, country, federal_state, vacation_type_record} ->
        conn
        |> put_flash(
          :info,
          "#{vacation_type_record.colloquial} gibt es in #{federal_state.name} nicht."
        )
        |> redirect(to: ~p"/ferien/#{country.slug}/bundesland/#{federal_state.slug}")
    end
  end

  defp render_evergreen(conn, country, federal_state, vacation_slug, vacation_type_record, today) do
    current_year = today.year
    next_year = current_year + 1
    location_ids = [country.id, federal_state.id]

    {:ok, window_start} = Date.new(current_year, 1, 1)
    {:ok, window_end} = Date.new(next_year, 12, 31)

    school_periods = Periods.list_school_vacation_periods(location_ids, window_start, window_end)
    public_periods = Periods.list_public_periods(location_ids, window_start, window_end)

    type_periods =
      school_periods
      |> Enum.filter(&(&1.holiday_or_vacation_type.slug == vacation_type_record.slug))
      |> Enum.sort_by(& &1.starts_on, Date)

    all_periods = school_periods ++ public_periods

    periods_with_duration =
      ViewHelpers.add_adjoining_duration_to_periods(type_periods, all_periods)

    next_period =
      Enum.find(periods_with_duration, fn period ->
        Date.compare(period.ends_on, today) != :lt
      end)

    has_data = type_periods != []
    conn = if has_data, do: conn, else: put_status(conn, 404)

    vacation_types = VacationTypes.list_for_year(federal_state, current_year)

    render(conn, "show_evergreen.html", %{
      country: country,
      federal_state: federal_state,
      vacation_type: vacation_slug,
      vacation_name: vacation_type_record.colloquial,
      vacation_type_record: vacation_type_record,
      periods: periods_with_duration,
      all_periods: all_periods,
      public_periods: public_periods,
      next_period: next_period,
      vacation_types: vacation_types,
      today: today,
      current_year: current_year,
      next_year: next_year,
      has_data: has_data,
      page_title:
        "#{vacation_type_record.colloquial} #{federal_state.name} #{current_year} & #{next_year}"
    })
  end

  # National season page for one year: /sommerferien/2027 lists the dates
  # of all 16 states, targeting the "sommerferien 2027" head terms.
  defp show_country_year(conn, vacation_slug, db_slug, year) do
    today = DateHelpers.get_today_or_custom_date(conn)

    with true <- VacationTypeHelpers.has_vacation_config?(db_slug),
         {:ok, year_int} <- CH.check_year(year) do
      if year_int < today.year do
        # Past years consolidate into the evergreen national overview.
        permanent_redirect(conn, "/#{vacation_slug}")
      else
        render_country_year(conn, vacation_slug, db_slug, year_int)
      end
    else
      _ -> raise_not_found(conn)
    end
  end

  defp render_country_year(conn, vacation_slug, db_slug, year_int) do
    config = VacationTypeHelpers.get_vacation_config(db_slug)
    states_data = VacationTypeHelpers.fetch_vacation_data_for_type(db_slug, year_int)

    has_data = Enum.any?(states_data, &(&1.period != nil))
    conn = if has_data, do: conn, else: put_status(conn, 404)

    render(conn, "show_country_year.html", %{
      vacation_type: vacation_slug,
      vacation_db_slug: db_slug,
      vacation_config: config,
      year: year_int,
      states_data: VacationTypeHelpers.format_vacation_table_data(states_data),
      raw_states_data: states_data,
      structured_data: [
        VacationTypeHelpers.generate_year_structured_data(db_slug, year_int, states_data)
      ],
      has_data: has_data,
      page_title: "#{config.name} #{year_int} – Termine aller Bundesländer"
    })
  end

  # Next vacation redirect
  def next_vacation(conn, %{"federal_state_slug" => federal_state_slug}) do
    today = DateHelpers.get_today_or_custom_date(conn)
    country = Locations.get_country_by_slug!("d")
    federal_state = Locations.get_federal_state_by_slug!(federal_state_slug, country)

    location_ids = [country.id, federal_state.id]

    case find_next_vacation(location_ids, today) do
      {:ok, vacation} ->
        vacation_slug = VacationSlug.url_slug(vacation.holiday_or_vacation_type)

        redirect(conn,
          to: "/#{vacation_slug}/#{federal_state_slug}/#{vacation.starts_on.year}"
        )

      :not_found ->
        redirect(conn,
          to: ~p"/ferien/#{country.slug}/bundesland/#{federal_state_slug}/#{today.year}"
        )
    end
  end

  defp find_next_vacation(location_ids, today) do
    data = CH.prepare_show_year_data(location_ids, today.year, today)

    case find_first_upcoming_vacation(data.periods, today) do
      nil ->
        next_year_data = CH.prepare_show_year_data(location_ids, today.year + 1, today)

        case find_first_school_vacation(next_year_data.periods) do
          nil -> :not_found
          vacation -> {:ok, vacation}
        end

      vacation ->
        {:ok, vacation}
    end
  end

  defp find_first_upcoming_vacation(periods, today) do
    periods
    |> Enum.filter(fn p ->
      p.holiday_or_vacation_type.default_is_school_vacation &&
        Date.compare(p.starts_on, today) == :gt
    end)
    |> Enum.sort_by(& &1.starts_on)
    |> List.first()
  end

  defp find_first_school_vacation(periods) do
    periods
    |> Enum.filter(& &1.holiday_or_vacation_type.default_is_school_vacation)
    |> Enum.sort_by(& &1.starts_on)
    |> List.first()
  end

  defp raise_not_found(conn) do
    conn = Plug.Conn.put_status(conn, :not_found)
    raise Phoenix.Router.NoRouteError, conn: conn, router: MehrSchulferienWeb.Router
  end
end
