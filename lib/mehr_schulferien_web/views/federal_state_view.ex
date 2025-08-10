defmodule MehrSchulferienWeb.FederalStateView do
  use MehrSchulferienWeb, :view

  alias MehrSchulferien.Calendars.DateHelpers

  # Import the components we need for our templates
  import MehrSchulferienWeb.Shared.GenericPaginationComponent
  import MehrSchulferienWeb.FederalState.PeriodsTableComponent
  import MehrSchulferienWeb.FederalState.CalendarLegendComponent
  import MehrSchulferienWeb.FederalState.MonthCalendarComponent
  import MehrSchulferienWeb.FederalState.NoDataComponent
  import MehrSchulferienWeb.FederalState.PartialDataComponent
  import MehrSchulferienWeb.FederalStateComponents
  import MehrSchulferienWeb.FaqComponent
  import MehrSchulferienWeb.FederalState.FaqSchemaComponent
  import MehrSchulferienWeb.FederalState.ItemListSchemaComponent
  import MehrSchulferienWeb.FederalState.LastUpdatedComponent

  def format_zip_codes(city) do
    MehrSchulferienWeb.ViewHelpers.format_zip_codes(city)
  end

  @doc """
  Generates dynamic meta description for federal state pages based on vacation proximity
  """
  def dynamic_federal_state_description(state_name, year, periods, today) do
    vacation_periods =
      Enum.filter(periods, & &1.holiday_or_vacation_type.default_is_school_vacation)

    # Find current or next vacation
    current_vacation =
      Enum.find(vacation_periods, fn p ->
        Date.compare(today, p.starts_on) != :lt && Date.compare(today, p.ends_on) != :gt
      end)

    next_vacation =
      if is_nil(current_vacation) do
        vacation_periods
        |> Enum.filter(fn p -> Date.compare(p.starts_on, today) == :gt end)
        |> Enum.sort_by(& &1.starts_on)
        |> List.first()
      end

    cond do
      current_vacation ->
        days_left = Date.diff(current_vacation.ends_on, today)

        "🎉 #{current_vacation.holiday_or_vacation_type.name} in #{state_name} laufen noch #{days_left} Tage! Alle Schulferien #{year}: Termine, Kalender, iCal-Export & Brückentage."

      next_vacation && Date.diff(next_vacation.starts_on, today) <= 30 ->
        days_until = Date.diff(next_vacation.starts_on, today)

        "⏰ Nur noch #{days_until} Tage bis #{next_vacation.holiday_or_vacation_type.name} #{state_name}! Alle Schulferien #{year} mit Kalender, iCal & Reiseplanung."

      true ->
        vacation_summary =
          vacation_periods
          |> Enum.take(4)
          |> Enum.map(fn p ->
            "✓ #{p.holiday_or_vacation_type.name} (#{Calendar.strftime(p.starts_on, "%d.%m.")}-#{Calendar.strftime(p.ends_on, "%d.%m.")})"
          end)
          |> Enum.join(" ")

        "Schulferien #{state_name} #{year}: #{vacation_summary}. Plus Feiertage, Brückentage, iCal-Export und Kalenderansicht."
    end
  end

  def get_vacation_type_days([period]), do: get_period_days(period)

  def get_vacation_type_days(periods) do
    periods |> Enum.map(&get_period_days/1) |> Enum.uniq_by(&hd/1) |> flatten()
  end

  defp flatten([]), do: []
  defp flatten([first | rest]), do: first ++ flatten(rest)

  defp get_period_days(period) do
    start_month = period.starts_on.month
    end_month = period.ends_on.month

    if start_month == end_month do
      [DateHelpers.create_month(period.starts_on.year, start_month)]
    else
      end_month =
        if period.starts_on.year < period.ends_on.year do
          end_month + 12
        else
          end_month
        end

      for month <- start_month..end_month do
        DateHelpers.create_month(period.starts_on.year, month)
      end
    end
  end
end
