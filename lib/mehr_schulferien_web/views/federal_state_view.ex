defmodule MehrSchulferienWeb.FederalStateView do
  use MehrSchulferienWeb, :view

  alias MehrSchulferien.Calendars.DateHelpers

  def format_zip_codes(city) do
    "#{Enum.map(city.zip_codes, & &1.value) |> Enum.sort() |> MehrSchulferienWeb.ViewHelpers.comma_join_with_a_final_und()}"
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
        create_month_days(period.starts_on.year, month)
      end
    end
  end

  defp create_month_days(year, month) do
    if month > 12 do
      DateHelpers.create_month(year + 1, month - 12)
    else
      DateHelpers.create_month(year, month)
    end
  end
end
