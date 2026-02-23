defmodule MehrSchulferienWeb.VacationController do
  use MehrSchulferienWeb, :controller

  import Ecto.Query
  alias MehrSchulferien.Calendars.DateHelpers
  alias MehrSchulferien.Calendars.{HolidayOrVacationType, VacationTypes}
  alias MehrSchulferien.{Locations, Repo}
  alias MehrSchulferienWeb.ControllerHelpers, as: CH
  alias MehrSchulferienWeb.ViewHelpers

  # Generic vacation display action
  def show(conn, %{
        "vacation_slug" => vacation_slug,
        "federal_state_slug" => federal_state_slug,
        "year" => year
      }) do
    vacation_type_slug = String.replace(vacation_slug, "ferien", "")

    with {:ok, country} <- fetch_country(),
         {:ok, federal_state} <- fetch_federal_state(country, federal_state_slug),
         {:ok, vacation_type_record} <- fetch_vacation_type(vacation_type_slug),
         :ok <- validate_vacation_for_state(federal_state, vacation_type_slug) do
      render_vacation_page(conn, %{
        country: country,
        federal_state: federal_state,
        vacation_slug: vacation_slug,
        vacation_type_record: vacation_type_record,
        year: year
      })
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
  end

  defp fetch_country do
    case Locations.get_country_by_slug("d") do
      nil -> {:error, :not_found}
      country -> {:ok, country}
    end
  end

  defp fetch_federal_state(country, federal_state_slug) do
    case Locations.get_federal_state_by_slug(federal_state_slug, country) do
      nil -> {:error, :not_found}
      federal_state -> {:ok, federal_state}
    end
  end

  defp fetch_vacation_type(vacation_type_slug) do
    case get_vacation_type_record(vacation_type_slug) do
      nil -> {:error, :invalid_vacation_type, Locations.get_country_by_slug("d")}
      vacation_type_record -> {:ok, vacation_type_record}
    end
  end

  defp validate_vacation_for_state(federal_state, vacation_type_slug) do
    if VacationTypes.exists_for_state?(federal_state, vacation_type_slug) do
      :ok
    else
      country = Locations.get_country_by_slug("d")
      vacation_type_record = get_vacation_type_record(vacation_type_slug)
      {:error, :vacation_not_in_state, country, federal_state, vacation_type_record}
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

    case find_next_vacation(location_ids, today) do
      {:ok, vacation} ->
        vacation_slug = vacation.holiday_or_vacation_type.slug

        redirect(conn,
          to: "/#{vacation_slug}ferien/#{federal_state_slug}/#{vacation.starts_on.year}"
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
end
