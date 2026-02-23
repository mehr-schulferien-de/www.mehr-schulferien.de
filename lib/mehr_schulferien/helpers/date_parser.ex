defmodule MehrSchulferien.Helpers.DateParser do
  @moduledoc """
  Parses various date formats for bewegliche Ferientage input.

  Supported formats:
  - Single date: "16.02.2026" or "16.2.2026"
  - Date range: "16.-20.02.2026" or "16.-20.2.2026"
  - Multiple dates: "16.02.2026, 18.03.2026"
  - Multiple dates and ranges: "16.02.2026, 18.-22.03.2026, 01.04.2026"
  """

  @doc """
  Parses a date string and returns a list of dates.

  ## Examples

      iex> DateParser.parse_dates("16.02.2026")
      {:ok, [~D[2026-02-16]]}
      
      iex> DateParser.parse_dates("16.-20.02.2026")
      {:ok, [~D[2026-02-16], ~D[2026-02-17], ~D[2026-02-18], ~D[2026-02-19], ~D[2026-02-20]]}
      
      iex> DateParser.parse_dates("16.02.2026, 18.03.2026")
      {:ok, [~D[2026-02-16], ~D[2026-03-18]]}
      
      iex> DateParser.parse_dates("invalid")
      {:error, "Ungültiges Datumsformat"}
  """
  def parse_dates(date_string) when is_binary(date_string) do
    date_string
    |> String.trim()
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.reduce({:ok, []}, fn date_part, acc ->
      case acc do
        {:error, _} = error ->
          error

        {:ok, dates} ->
          case parse_single_date_or_range(date_part) do
            {:ok, new_dates} -> {:ok, dates ++ new_dates}
            error -> error
          end
      end
    end)
    |> case do
      {:ok, dates} -> {:ok, dates |> Enum.uniq() |> Enum.sort(Date)}
      error -> error
    end
  end

  defp parse_single_date_or_range(date_string) do
    if String.contains?(date_string, ".-") do
      # Check for range format: "16.-20.02.2026"
      parse_date_range(date_string)
    else
      # Single date
      case parse_single_date(date_string) do
        {:ok, date} -> {:ok, [date]}
        error -> error
      end
    end
  end

  defp parse_date_range(range_string) do
    case Regex.run(~r/^(\d{1,2})\.?-(\d{1,2})\.(\d{1,2})\.(\d{4})$/, range_string) do
      [_, start_day, end_day, month, year] ->
        start_day = String.to_integer(start_day)
        end_day = String.to_integer(end_day)
        month = String.to_integer(month)
        year = String.to_integer(year)

        if start_day <= end_day do
          dates =
            for day <- start_day..end_day do
              Date.new(year, month, day)
            end

          # Check if all dates are valid
          case Enum.find(dates, &(elem(&1, 0) == :error)) do
            nil -> {:ok, Enum.map(dates, &elem(&1, 1))}
            _ -> {:error, "Ungültiger Datumsbereich"}
          end
        else
          {:error, "Startdatum muss vor Enddatum liegen"}
        end

      _ ->
        {:error, "Ungültiges Bereichsformat. Verwenden Sie z.B. '16.-20.02.2026'"}
    end
  end

  defp parse_single_date(date_string) do
    case Regex.run(~r/^(\d{1,2})\.(\d{1,2})\.(\d{4})$/, date_string) do
      [_, day, month, year] ->
        day = String.to_integer(day)
        month = String.to_integer(month)
        year = String.to_integer(year)

        case Date.new(year, month, day) do
          {:ok, date} -> {:ok, date}
          {:error, _} -> {:error, "Ungültiges Datum: #{date_string}"}
        end

      _ ->
        {:error, "Ungültiges Datumsformat. Verwenden Sie TT.MM.JJJJ"}
    end
  end

  @doc """
  Formats a list of dates into a human-readable string.
  Groups consecutive dates into ranges.

  ## Examples

      iex> DateParser.format_dates([~D[2026-02-16], ~D[2026-02-17], ~D[2026-02-18]])
      "16.-18.02.2026"
      
      iex> DateParser.format_dates([~D[2026-02-16], ~D[2026-03-18]])
      "16.02.2026, 18.03.2026"
  """
  def format_dates(dates) when is_list(dates) do
    dates
    |> Enum.sort(Date)
    |> group_consecutive_dates()
    |> Enum.map_join(", ", &format_date_group/1)
  end

  defp group_consecutive_dates(dates) do
    Enum.reduce(dates, [], fn date, acc ->
      case acc do
        [] ->
          [[date]]

        [current_group | rest] ->
          last_date = List.last(current_group)

          if Date.diff(date, last_date) == 1 do
            # Consecutive date, add to current group
            [current_group ++ [date] | rest]
          else
            # Non-consecutive, start new group
            [[date] | [current_group | rest]]
          end
      end
    end)
    |> Enum.reverse()
  end

  defp format_date_group([single_date]) do
    format_date(single_date)
  end

  defp format_date_group(dates) do
    first = List.first(dates)
    last = List.last(dates)

    if first.month == last.month && first.year == last.year do
      # Same month and year: "16.-20.02.2026"
      "#{first.day}.-#{last.day}.#{pad(first.month)}.#{first.year}"
    else
      # Different months: show as separate dates
      Enum.map_join(dates, ", ", &format_date/1)
    end
  end

  defp format_date(date) do
    "#{pad(date.day)}.#{pad(date.month)}.#{date.year}"
  end

  defp pad(number) when number < 10, do: "0#{number}"
  defp pad(number), do: "#{number}"
end
