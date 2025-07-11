defmodule MehrSchulferienWeb.ViewHelpers do
  @moduledoc """
  Helper functions for use with views.
  """

  alias MehrSchulferien.{Calendars.DateHelpers, Periods, StyleConfig}

  @version Mix.Project.config()[:version]

  def version, do: @version

  @doc """
  Returns the number of days a holiday period lasts for.
  """
  def number_days([period]) do
    Date.diff(period.ends_on, period.starts_on) + 1
  end

  def number_days(periods) do
    Enum.reduce(periods, 0, fn period, acc ->
      Date.diff(period.ends_on, period.starts_on) + 1 + acc
    end)
  end

  @doc """
  Returns a string showing the date range in DD.MM. (`:short`) or DD.MM.YY format.

  If the from_date and till_date are the same, then just a single date is
  returned.
  """
  def format_date_range(from_date, till_date, short \\ nil)

  def format_date_range(same_date, same_date, short) do
    format_date(same_date, short)
  end

  def format_date_range(from_date, till_date, :short) do
    # format_date(from_date, :short) <> " \u2013 " <> format_date(till_date, :short)
    format_date(from_date, :short) <> " - " <> format_date(till_date, :short)
  end

  def format_date_range(from_date, till_date, short) do
    from_date_string =
      if from_date.year == till_date.year do
        format_date(from_date, :short)
      else
        format_date(from_date, nil)
      end

    # from_date_string <> " \u2013 " <> format_date(till_date, short)
    from_date_string <> " - " <> format_date(till_date, short)
  end

  @doc """
  Returns a string showing the date in DD.MM. (`:short`) or DD.MM.YY format.
  """
  def format_date(nil), do: ""

  def format_date(date) do
    format_date(date, nil)
  end

  def format_date(date, nil) do
    # format_date(date, :short) <> "\u202F#{date.year}"
    # format_date(date, :short) <> "#{date.year |> Integer.to_string() |> String.slice(2, 2)}"
    # format_date(date, :short) <> "\u202F'#{date.year |> Integer.to_string() |> String.slice(2, 2)}"
    format_date(date, :short) <> "#{date.year |> Integer.to_string() |> String.slice(2, 2)}"
  end

  def format_date(date, :short) do
    # "#{add_padding(date.day)}.\u202F#{add_padding(date.month)}."
    # "#{date.day}.\u202F#{date.month}."
    "#{date.day}.#{date.month}."
  end

  def weekday(date) do
    DateHelpers.weekday(Date.day_of_week(date), :full)
  end

  @doc """
  Returns the year based on the `starts_on` value in the first non-empty period.
  """
  def display_year([[] | rest]), do: display_year(rest)
  def display_year([[period | _] | _]), do: period.starts_on.year

  @doc """
  Abbreviates entry.
  """
  def abbreviate(name, size) when byte_size(name) > size do
    String.slice(name, 0, size - 3) <> "..."
  end

  def abbreviate(name, _size), do: name

  @doc """
  Returns the html class for a date. This is based on whether the date
  is a holiday period.

  Uses the StyleConfig module to determine the appropriate Tailwind class.
  """
  def get_html_class(date, periods) do
    case Periods.find_all_periods(periods, date) do
      [] -> ""
      [period] -> get_html_class_for_period(period)
      periods -> select_html_class(periods)
    end
  end

  defp select_html_class(periods) do
    period = periods |> Enum.sort(&(&1.display_priority >= &2.display_priority)) |> hd
    get_html_class_for_period(period)
  end

  # Helper to determine the appropriate class based on the period
  defp get_html_class_for_period(period) do
    # If html_class is not in standard format, return it as-is for backward compatibility
    day_type = StyleConfig.html_class_to_day_type(period.html_class)

    if day_type do
      # Use the new StyleConfig for standard day types
      StyleConfig.get_class(day_type, true)
    else
      # Keep original html_class for non-standard values
      period.html_class
    end
  end

  @doc """
  Returns the public holiday periods and school holiday periods for a month.
  """
  def list_month_holidays(date, public_periods, school_periods) do
    {Periods.find_periods_by_month(date, public_periods),
     Periods.find_periods_by_month(date, school_periods)}
  end

  @doc """
  Returns a comma seperated list of list elements.
  The last comma is replaced with an "und" ("and").
  """
  def comma_join_with_a_final_und(list) do
    list = Enum.filter(list, &(!is_nil(&1)))

    case Enum.count(list) do
      0 ->
        ""

      1 ->
        Enum.at(list, 0)

      _ ->
        {first_elements, last_elements} = Enum.split(list, -1)
        [last_element] = last_elements

        Enum.join(first_elements, ", ") <> " und " <> last_element
    end
  end

  @doc """
  Returns the next schoolday (the next day that is not a school / public holiday).
  """
  def next_schoolday(periods) do
    today = DateHelpers.today_berlin()

    periods
    |> Enum.filter(&(Date.compare(today, &1.ends_on) != :gt))
    |> Enum.sort(&(Date.compare(&1.starts_on, &2.starts_on) == :lt))
    |> Periods.find_next_schoolday(today)
  end

  @doc """
  Returns the zip code for a city.

  If the city only has one zip_code, then that zip_code.value is returned.
  If there are many zip_codes, then the zip code with the most schools is
  used (by searching for the `address.zip_code` in the list of schools).
  """
  def find_zip_code([], _), do: ""
  def find_zip_code([zip_code], _), do: zip_code.value
  def find_zip_code([zip_code | _], []), do: zip_code.value

  def find_zip_code(_, schools) do
    schools
    |> Enum.frequencies_by(& &1.address.zip_code)
    |> Enum.max_by(fn {_k, v} -> v end)
    |> elem(0)
  end

  @doc """
  Returns a list of dates between, and including, a period's `starts_on`
  and `ends_on` dates.
  """
  def list_period_dates(period, dates) do
    dates
    |> Enum.drop_while(&(Date.compare(&1, period.starts_on) == :lt))
    |> Enum.take_while(&(Date.compare(&1, period.ends_on) != :gt))
  end

  def truncate(text, max_length \\ 30) do
    omission = "..."

    cond do
      not String.valid?(text) ->
        text

      String.length(text) < max_length ->
        text

      true ->
        length_with_omission = max_length - String.length(omission)

        "#{String.slice(text, 0, length_with_omission)}#{omission}"
    end
  end

  @doc """
  Generates a JSON-LD BreadcrumbList string for use in meta templates.
  Takes a list of breadcrumb items (each a map with :name and :item keys, and optionally :position).
  Skips items with missing or empty name/item.
  """
  def jsonld_breadcrumb(items) when is_list(items) do
    filtered =
      items
      |> Enum.with_index(1)
      |> Enum.filter(fn {item, _pos} ->
        Map.get(item, :name) not in [nil, ""] and Map.get(item, :item) not in [nil, ""]
      end)
      |> Enum.map(fn {item, pos} ->
        %{
          "@type" => "ListItem",
          "position" => Map.get(item, :position, pos),
          "name" => item[:name],
          "item" => item[:item]
        }
      end)

    %{
      "@context" => "https://schema.org",
      "@type" => "BreadcrumbList",
      "itemListElement" => filtered
    }
    |> Jason.encode!()
  end

  @doc """
  Extracts the domain from a URL string (e.g., https://www.example.com/foo -> example.com).
  Returns nil if the URL is invalid.
  """
  def extract_domain(url) when is_binary(url) do
    case URI.parse(url) do
      %URI{host: host} when is_binary(host) ->
        # Remove www. prefix if present
        Regex.replace(~r/^www\./, host, "")

      _ ->
        nil
    end
  end

  @doc """
  Formats zip codes for a city as a comma-separated list with "und" before the last item.
  This function was duplicated across FederalStateView and CityView.
  """
  def format_zip_codes(city) do
    city.zip_codes
    |> Enum.map(& &1.value)
    |> Enum.sort()
    |> comma_join_with_a_final_und()
  end

  @doc """
  Calculate effective duration for a period, including adjacent holidays/weekends.
  This is the shared implementation used by all view modules.
  """
  def calculate_effective_duration(period, periods) do
    # Get official duration
    official_duration = Date.diff(period.ends_on, period.starts_on) + 1

    # Look for adjacent days that are already off days
    # These could be weekends or other holiday periods

    # Check days before the period start
    days_before =
      get_adjacent_days_before(period.starts_on, periods)
      |> length()

    # Check days after the period end
    days_after =
      get_adjacent_days_after(period.ends_on, periods)
      |> length()

    # Return total effective duration
    official_duration + days_before + days_after
  end

  # Get days before a date that are already non-school days
  defp get_adjacent_days_before(start_date, periods) do
    # Start checking from the day before the period
    day_before = Date.add(start_date, -1)

    # Look back up to 7 days (to catch full weekends + holidays)
    dates_to_check = for i <- 0..6, do: Date.add(day_before, -i)

    # Keep only consecutive days off
    Enum.take_while(dates_to_check, fn date ->
      # A date is a day off if:
      # 1. It's a weekend (Sat/Sun)
      # 2. It's part of another period (holiday/vacation)
      is_weekend_or_holiday?(date, periods)
    end)
  end

  # Get days after a date that are already non-school days
  defp get_adjacent_days_after(end_date, periods) do
    # Start checking from the day after the period
    day_after = Date.add(end_date, 1)

    # Look ahead up to 7 days (to catch full weekends + holidays)
    dates_to_check = for i <- 0..6, do: Date.add(day_after, i)

    # Keep only consecutive days off
    Enum.take_while(dates_to_check, fn date ->
      # A date is a day off if:
      # 1. It's a weekend (Sat/Sun)
      # 2. It's part of another period (holiday/vacation)
      is_weekend_or_holiday?(date, periods)
    end)
  end

  # Check if a date is a weekend or part of any holiday period
  defp is_weekend_or_holiday?(date, periods) do
    # Weekend check (day_of_week: 6=Saturday, 7=Sunday)
    is_weekend = Date.day_of_week(date) > 5

    # Holiday check - is this date within any period?
    is_holiday =
      Enum.any?(periods, fn p ->
        Date.compare(date, p.starts_on) in [:eq, :gt] &&
          Date.compare(date, p.ends_on) in [:lt, :eq]
      end)

    is_weekend || is_holiday
  end
end
