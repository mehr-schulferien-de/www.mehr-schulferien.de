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
  import MehrSchulferienWeb.DeveloperSectionComponent
  import MehrSchulferienWeb.FaqComponent
  import MehrSchulferienWeb.FederalState.FaqSchemaComponent
  import MehrSchulferienWeb.FederalState.ItemListSchemaComponent
  import MehrSchulferienWeb.FederalState.LastUpdatedComponent

  def format_zip_codes(city) do
    MehrSchulferienWeb.ViewHelpers.format_zip_codes(city)
  end

  defdelegate dynamic_federal_state_description(state_name, year, periods, today),
    to: MehrSchulferienWeb.FederalStateHTML

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
