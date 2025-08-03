defmodule MehrSchulferienWeb.VacationController do
  use MehrSchulferienWeb, :controller

  import Ecto.Query
  alias MehrSchulferien.{Repo, Calendars.DateHelpers, Locations}
  alias MehrSchulferien.Calendars.{HolidayOrVacationType, VacationTypes}
  alias MehrSchulferienWeb.ControllerHelpers, as: CH
  alias MehrSchulferienWeb.ViewHelpers

  # Generic vacation display action
  def show(conn, %{
        "vacation_slug" => vacation_slug,
        "federal_state_slug" => federal_state_slug,
        "year" => year
      }) do
    # Load locations
    country = Locations.get_country_by_slug("d")

    if is_nil(country) do
      conn
      |> put_status(:service_unavailable)
      |> put_view(MehrSchulferienWeb.ErrorView)
      |> render("empty_database.html")
    else
      federal_state = Locations.get_federal_state_by_slug(federal_state_slug, country)

      if is_nil(federal_state) do
        conn
        |> put_status(:service_unavailable)
        |> put_view(MehrSchulferienWeb.ErrorView)
        |> render("empty_database.html")
      else
        # Extract and load vacation type
        vacation_type_slug = String.replace(vacation_slug, "ferien", "")
        vacation_type_record = get_vacation_type_record(vacation_type_slug)

        # Handle invalid vacation type
        if is_nil(vacation_type_record) do
          redirect_to_federal_state(
            conn,
            "Diese Ferienart existiert nicht.",
            country,
            federal_state_slug,
            year,
            :error
          )
        else
          # Check if vacation type is valid for the state
          if not VacationTypes.exists_for_state?(federal_state, vacation_type_slug) do
            message = "#{vacation_type_record.colloquial} gibt es in #{federal_state.name} nicht."
            redirect_to_federal_state(conn, message, country, federal_state_slug, year, :info)
          else
            # Prepare and render vacation data
            render_vacation_page(conn, %{
              country: country,
              federal_state: federal_state,
              vacation_slug: vacation_slug,
              vacation_type_record: vacation_type_record,
              year: year
            })
          end
        end
      end
    end
  end

  # Private helper functions

  defp get_vacation_type_record(vacation_type_slug) do
    Repo.one(
      from hvt in HolidayOrVacationType,
        where: hvt.slug == ^vacation_type_slug and hvt.default_is_school_vacation == true
    )
  end

  defp redirect_to_federal_state(conn, message, country, federal_state_slug, year, flash_type) do
    conn
    |> put_flash(flash_type, message)
    |> redirect(to: ~p"/ferien/#{country.slug}/bundesland/#{federal_state_slug}/#{year}")
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
    periods_with_duration = calculate_periods_with_duration(data.periods, data.all_periods)

    # Get vacation types for the federal state
    vacation_types = get_vacation_types_for_year(federal_state, year)

    # Calculate vacation period's adjoining duration if it exists
    vacation_period_with_adjoining =
      if vacation_period do
        add_adjoining_duration(vacation_period, data.all_periods)
      else
        nil
      end

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

  defp calculate_periods_with_duration(periods, all_periods) do
    Enum.map(periods, fn period ->
      add_adjoining_duration(period, all_periods)
    end)
  end

  defp add_adjoining_duration(period, all_periods) do
    days = Date.diff(period.ends_on, period.starts_on) + 1
    effective_duration = ViewHelpers.calculate_effective_duration(period, all_periods)
    difference = effective_duration - days
    Map.put(period, :adjoining_duration, difference)
  end

  defp get_vacation_types_for_year(federal_state, year) do
    year_int = String.to_integer(year)
    # Middle of the viewed year
    reference_date = Date.new!(year_int, 6, 1)
    VacationTypes.list_for_federal_state(federal_state, reference_date)
  end

  defp build_render_assigns(params) do
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
      css_framework: :tailwind_new,
      months: get_german_month_names(),
      year: String.to_integer(params.year),
      years_with_data: MehrSchulferien.Periods.list_years_with_periods(),
      meta_title_type: :vacation,
      page_title:
        "#{params.vacation_type_record.colloquial} #{params.federal_state.name} #{params.year}"
    }
  end

  defp get_german_month_names do
    %{
      1 => "Januar",
      2 => "Februar",
      3 => "März",
      4 => "April",
      5 => "Mai",
      6 => "Juni",
      7 => "Juli",
      8 => "August",
      9 => "September",
      10 => "Oktober",
      11 => "November",
      12 => "Dezember"
    }
  end

  # Year-agnostic vacation URL (redirect to current year)
  def vacation_current(conn, %{
        "vacation_slug" => vacation_slug,
        "federal_state_slug" => federal_state_slug
      }) do
    today = DateHelpers.get_today_or_custom_date(conn)

    redirect(conn,
      to: "/#{vacation_slug}/#{federal_state_slug}/#{today.year}"
    )
  end

  # Next vacation redirect
  def next_vacation(conn, %{"federal_state_slug" => federal_state_slug}) do
    today = DateHelpers.get_today_or_custom_date(conn)
    country = Locations.get_country_by_slug!("d")
    federal_state = Locations.get_federal_state_by_slug!(federal_state_slug, country)

    location_ids = [country.id, federal_state.id]
    data = CH.prepare_show_year_data(location_ids, today.year, today)

    # Find next vacation
    next_vacation_period =
      data.periods
      |> Enum.filter(fn p ->
        p.holiday_or_vacation_type.default_is_school_vacation &&
          Date.compare(p.starts_on, today) == :gt
      end)
      |> Enum.sort_by(& &1.starts_on)
      |> List.first()

    case next_vacation_period do
      nil ->
        # No more vacations this year, check next year
        next_year_data = CH.prepare_show_year_data(location_ids, today.year + 1, today)

        first_vacation =
          next_year_data.periods
          |> Enum.filter(& &1.holiday_or_vacation_type.default_is_school_vacation)
          |> Enum.sort_by(& &1.starts_on)
          |> List.first()

        if first_vacation do
          vacation_slug = first_vacation.holiday_or_vacation_type.slug

          redirect(conn,
            to: "/#{vacation_slug}ferien/#{federal_state_slug}/#{today.year + 1}"
          )
        else
          # Fallback to federal state page
          redirect(conn,
            to: ~p"/ferien/#{country.slug}/bundesland/#{federal_state_slug}/#{today.year}"
          )
        end

      vacation ->
        vacation_slug = vacation.holiday_or_vacation_type.slug

        redirect(conn,
          to: "/#{vacation_slug}ferien/#{federal_state_slug}/#{vacation.starts_on.year}"
        )
    end
  end
end
