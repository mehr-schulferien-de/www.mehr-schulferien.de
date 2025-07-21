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
    # Default country is Germany
    country = Locations.get_country_by_slug!("d")
    federal_state = Locations.get_federal_state_by_slug!(federal_state_slug, country)

    # Extract vacation type from URL (remove "ferien" suffix)
    vacation_type_slug = String.replace(vacation_slug, "ferien", "")

    # Find the vacation type in the database
    vacation_type_record =
      Repo.one(
        from hvt in HolidayOrVacationType,
          where: hvt.slug == ^vacation_type_slug and hvt.default_is_school_vacation == true
      )

    if is_nil(vacation_type_record) do
      # Vacation type not found - redirect
      conn
      |> put_flash(:error, "Diese Ferienart existiert nicht.")
      |> redirect(to: ~p"/ferien/#{country.slug}/bundesland/#{federal_state_slug}/#{year}")
    else
      # Check if this vacation type is valid for the federal state
      if not VacationTypes.exists_for_state?(federal_state, vacation_type_slug) do
        # Redirect to the federal state page if vacation type is not valid
        conn
        |> put_flash(
          :info,
          "#{vacation_type_record.colloquial} gibt es in #{federal_state.name} nicht."
        )
        |> redirect(to: ~p"/ferien/#{country.slug}/bundesland/#{federal_state_slug}/#{year}")
      else
        today = DateHelpers.get_today_or_custom_date(conn)
        location_ids = [country.id, federal_state.id]

        # Get all periods for the state
        data = CH.prepare_show_year_data(location_ids, year, today)

        # Find the specific vacation period
        vacation_period =
          Enum.find(data.periods, fn period ->
            period.holiday_or_vacation_type.name == vacation_type_record.name
          end)

        # Calculate adjoining_duration for each period
        periods_with_duration =
          Enum.map(data.periods, fn period ->
            days = Date.diff(period.ends_on, period.starts_on) + 1

            effective_duration =
              ViewHelpers.calculate_effective_duration(period, data.all_periods)

            difference = effective_duration - days
            Map.put(period, :adjoining_duration, difference)
          end)

        # For SEO: Don't set 404 for future vacation pages - they're valid URLs
        # even if the dates aren't confirmed yet
        # conn = if vacation_period, do: conn, else: put_status(conn, 404)

        # Get all vacation types for this federal state
        # Use the viewed year as reference for better UX when viewing future years
        year_int = String.to_integer(year)
        # Middle of the viewed year
        reference_date = Date.new!(year_int, 6, 1)
        vacation_types = VacationTypes.list_for_federal_state(federal_state, reference_date)

        # Calculate vacation period's adjoining duration if it exists
        vacation_period_with_adjoining =
          if vacation_period do
            effective_duration =
              ViewHelpers.calculate_effective_duration(vacation_period, data.all_periods)

            days = Date.diff(vacation_period.ends_on, vacation_period.starts_on) + 1
            difference = effective_duration - days
            Map.put(vacation_period, :adjoining_duration, difference)
          else
            nil
          end

        render(
          conn,
          "show.html",
          %{
            country: country,
            federal_state: federal_state,
            vacation_type: vacation_slug,
            vacation_name: vacation_type_record.colloquial,
            vacation_period: vacation_period_with_adjoining,
            vacation_types: vacation_types,
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
            page_title: "#{vacation_type_record.colloquial} #{federal_state.name} #{year}"
          }
        )
      end
    end
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
