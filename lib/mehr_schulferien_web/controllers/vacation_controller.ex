defmodule MehrSchulferienWeb.VacationController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.{Calendars.DateHelpers, Locations}
  alias MehrSchulferienWeb.ControllerHelpers, as: CH
  alias MehrSchulferienWeb.ViewHelpers

  @vacation_types %{
    "sommerferien" => "Sommerferien",
    "osterferien" => "Osterferien",
    "herbstferien" => "Herbstferien",
    "weihnachtsferien" => "Weihnachtsferien",
    "winterferien" => "Winterferien",
    "pfingstferien" => "Pfingstferien"
  }

  # Main vacation display actions
  def sommerferien(conn, params), do: show_vacation(conn, params, "sommerferien")
  def osterferien(conn, params), do: show_vacation(conn, params, "osterferien")
  def herbstferien(conn, params), do: show_vacation(conn, params, "herbstferien")
  def weihnachtsferien(conn, params), do: show_vacation(conn, params, "weihnachtsferien")
  def winterferien(conn, params), do: show_vacation(conn, params, "winterferien")
  def pfingstferien(conn, params), do: show_vacation(conn, params, "pfingstferien")

  # Year-agnostic vacation URLs (redirect to current year)
  def sommerferien_current(conn, %{"federal_state_slug" => slug}) do
    redirect_to_current_year(conn, :sommerferien, slug)
  end

  def osterferien_current(conn, %{"federal_state_slug" => slug}) do
    redirect_to_current_year(conn, :osterferien, slug)
  end

  def herbstferien_current(conn, %{"federal_state_slug" => slug}) do
    redirect_to_current_year(conn, :herbstferien, slug)
  end

  def weihnachtsferien_current(conn, %{"federal_state_slug" => slug}) do
    redirect_to_current_year(conn, :weihnachtsferien, slug)
  end

  def winterferien_current(conn, %{"federal_state_slug" => slug}) do
    redirect_to_current_year(conn, :winterferien, slug)
  end

  def pfingstferien_current(conn, %{"federal_state_slug" => slug}) do
    redirect_to_current_year(conn, :pfingstferien, slug)
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
        p.holiday_or_vacation_type.is_school_vacation && Date.compare(p.starts_on, today) == :gt
      end)
      |> Enum.sort_by(& &1.starts_on)
      |> List.first()

    case next_vacation_period do
      nil ->
        # No more vacations this year, check next year
        next_year_data = CH.prepare_show_year_data(location_ids, today.year + 1, today)

        first_vacation =
          next_year_data.periods
          |> Enum.filter(& &1.holiday_or_vacation_type.is_school_vacation)
          |> Enum.sort_by(& &1.starts_on)
          |> List.first()

        if first_vacation do
          vacation_type = vacation_type_from_name(first_vacation.holiday_or_vacation_type.name)

          redirect(conn,
            to: Routes.vacation_path(conn, vacation_type, federal_state_slug, today.year + 1)
          )
        else
          # Fallback to federal state page
          redirect(conn,
            to:
              Routes.federal_state_path(
                conn,
                :show_year,
                country.slug,
                federal_state_slug,
                today.year
              )
          )
        end

      vacation ->
        vacation_type = vacation_type_from_name(vacation.holiday_or_vacation_type.name)

        redirect(conn,
          to:
            Routes.vacation_path(conn, vacation_type, federal_state_slug, vacation.starts_on.year)
        )
    end
  end

  # Private functions
  defp redirect_to_current_year(conn, vacation_action, federal_state_slug) do
    today = DateHelpers.get_today_or_custom_date(conn)

    redirect(conn,
      to: Routes.vacation_path(conn, vacation_action, federal_state_slug, today.year)
    )
  end

  defp vacation_type_from_name(name) do
    case name do
      "Sommerferien" -> :sommerferien
      "Osterferien" -> :osterferien
      "Herbstferien" -> :herbstferien
      "Weihnachtsferien" -> :weihnachtsferien
      "Winterferien" -> :winterferien
      "Pfingstferien" -> :pfingstferien
      # Fallback
      _ -> :sommerferien
    end
  end

  defp show_vacation(
         conn,
         %{"federal_state_slug" => federal_state_slug, "year" => year},
         vacation_type
       ) do
    # Default country is Germany
    country = Locations.get_country_by_slug!("d")
    federal_state = Locations.get_federal_state_by_slug!(federal_state_slug, country)

    today = DateHelpers.get_today_or_custom_date(conn)
    location_ids = [country.id, federal_state.id]

    # Get all periods for the state
    data = CH.prepare_show_year_data(location_ids, year, today)

    # Filter for the specific vacation type
    vacation_name = @vacation_types[vacation_type]

    vacation_period =
      Enum.find(data.periods, fn period ->
        period.holiday_or_vacation_type.name == vacation_name
      end)

    # Calculate adjoining_duration for each period
    periods_with_duration =
      Enum.map(data.periods, fn period ->
        days = Date.diff(period.ends_on, period.starts_on) + 1
        effective_duration = ViewHelpers.calculate_effective_duration(period, data.all_periods)
        difference = effective_duration - days
        Map.put(period, :adjoining_duration, difference)
      end)

    # Set 404 if vacation not found
    conn = if vacation_period, do: conn, else: put_status(conn, 404)

    render(
      conn,
      "show.html",
      %{
        country: country,
        federal_state: federal_state,
        vacation_type: vacation_type,
        vacation_name: vacation_name,
        vacation_period: vacation_period,
        periods: periods_with_duration,
        all_periods: data.all_periods,
        public_periods: data.public_periods,
        today: today,
        has_data: not is_nil(vacation_period),
        css_framework: :tailwind_new,
        months: %{
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
        },
        year: String.to_integer(year),
        years_with_data: MehrSchulferien.Periods.list_years_with_periods(),
        meta_title_type: :vacation,
        page_title: "#{vacation_name} #{federal_state.name} #{year}"
      }
    )
  end
end
