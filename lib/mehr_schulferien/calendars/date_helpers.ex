defmodule MehrSchulferien.Calendars.DateHelpers do
  @moduledoc """
  Date helper functions.
  """

  @months %{
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

  def today_berlin do
    {:ok, today_datetime} = DateTime.now("Europe/Berlin")
    DateTime.to_date(today_datetime)
  end

  @doc """
  Returns the effective today date, considering a custom date from conn if available.

  This function checks if a custom date is set in the conn assigns and returns it if present.
  Otherwise, it returns the current date in Berlin time.

  ## Parameters
    - conn: The connection struct (optional)

  ## Examples
    iex> get_today_or_custom_date(conn_with_custom_date)
    ~D[2025-01-01]
    
    iex> get_today_or_custom_date()
    ~D[2023-06-15] # Current date in Berlin timezone
  """
  def get_today_or_custom_date(conn \\ nil) do
    case conn do
      %{assigns: %{custom_date: date}} when not is_nil(date) -> date
      _ -> today_berlin()
    end
  end

  @doc """
  Returns 3 years of dates.
  """
  def create_3_years(year) do
    create_year(year) ++ create_year(year + 1) ++ create_year(year + 2)
  end

  @doc """
  Returns a list of lists of dates for a certain year.
  """
  def create_year(year) do
    for month <- 1..12, do: create_month(year, month)
  end

  @doc """
  Returns a list of dates for a certain month.
  """
  def create_month(year, month) do
    # Normalize month and year if month > 12
    {actual_year, actual_month} =
      if month <= 12 do
        {year, month}
      else
        {year + 1, month - 12}
      end

    days_in_month = Date.days_in_month(Date.new!(actual_year, actual_month, 1))

    for day <- 1..days_in_month do
      %Date{year: actual_year, month: actual_month, day: day, calendar: Calendar.ISO}
    end
  end

  @doc """
  Returns a list containing a certain number of dates.
  """
  def create_days(nil, number_days) do
    # Use today's date if nil is passed
    create_days(today_berlin(), number_days)
  end

  def create_days(date, nil) do
    # Default to 90 days if nil is passed
    create_days(date, 90)
  end

  def create_days(nil, nil) do
    # Handle both parameters being nil
    create_days(today_berlin(), 90)
  end

  def create_days(date, number_days) when is_integer(number_days) and number_days > 0 do
    [date] ++
      for i <- 1..(number_days - 1) do
        Date.add(date, i)
      end
  end

  # Catch any other invalid cases
  def create_days(_date, _number_days) do
    # Default to today and 90 days
    create_days(today_berlin(), 90)
  end

  @weekdays_full %{
    1 => "Montag",
    2 => "Dienstag",
    3 => "Mittwoch",
    4 => "Donnerstag",
    5 => "Freitag",
    6 => "Samstag",
    7 => "Sonntag"
  }

  @weekdays_short %{
    1 => "Mo",
    2 => "Di",
    3 => "Mi",
    4 => "Do",
    5 => "Fr",
    6 => "Sa",
    7 => "So"
  }

  @doc """
  Returns a map of abbreviated day names, with day numbers (1-7) as keys.
  """
  def short_days_map, do: @weekdays_short

  @doc """
  Converts a day of week number (1-7) to a German weekday name in different formats.

  ## Format options:
  - :full - Full name (e.g., "Montag")
  - :short - Short name without dot (e.g., "Mo")
  - :short_with_dot - Short name with dot (e.g., "Mo.")
  """
  def weekday(day_of_week, format \\ :full)
  def weekday(day_of_week, :full), do: @weekdays_full[day_of_week]
  def weekday(day_of_week, :short), do: @weekdays_short[day_of_week]
  def weekday(day_of_week, :short_with_dot), do: @weekdays_short[day_of_week] <> "."

  @doc """
  Returns a map containing the month numbers as keys and the month German
  names as values.
  """
  def get_months_map, do: @months

  @month_abbreviations %{
    1 => "Jan.",
    2 => "Feb.",
    3 => "Mär.",
    4 => "Apr.",
    5 => "Mai",
    6 => "Jun.",
    7 => "Jul.",
    8 => "Aug.",
    9 => "Sep.",
    10 => "Okt.",
    11 => "Nov.",
    12 => "Dez."
  }

  @doc """
  Returns the German three-letter abbreviation for a month number,
  e.g. `month_abbreviation(12)` -> "Dez.".
  """
  def month_abbreviation(month), do: @month_abbreviations[month]

  @month_slugs %{
    1 => "januar",
    2 => "februar",
    3 => "maerz",
    4 => "april",
    5 => "mai",
    6 => "juni",
    7 => "juli",
    8 => "august",
    9 => "september",
    10 => "oktober",
    11 => "november",
    12 => "dezember"
  }

  @doc """
  URL-safe lowercase month slug for anchors and ids, e.g. `month_slug(3)` ->
  "maerz". Anchor links and element ids must use the same transliteration,
  otherwise deep links (e.g. "#maerz2026") never match.
  """
  def month_slug(month), do: @month_slugs[month]

  @doc """
  Formats a date in German long form, e.g. "3. August" or, with `:with_year`,
  "3. August 2026". `Calendar.strftime/2` with "%B" would produce English
  month names, which must never appear in the German UI texts.
  """
  def german_date(date), do: "#{date.day}. #{@months[date.month]}"
  def german_date(date, :with_year), do: german_date(date) <> " #{date.year}"

  @doc """
  Compares two days by comparing just month and year.

  Returns :gt, :eq or :lt - like Date.compare/2.
  """
  def compare_by_month(%Date{month: month, year: year}, %Date{month: month, year: year}) do
    :eq
  end

  def compare_by_month(%Date{month: month_1, year: year}, %Date{month: month_2, year: year}) do
    if month_1 > month_2, do: :gt, else: :lt
  end

  def compare_by_month(%Date{year: year_1}, %Date{year: year_2}) do
    if year_1 > year_2, do: :gt, else: :lt
  end

  @doc """
  Returns the next occurrence of a given day of week (1=Monday, 7=Sunday).
  If today IS that day, returns today.

  ## Parameters
    - day_of_week: The target day of week (1=Monday through 7=Sunday)
    - today: The reference date (defaults to today in Berlin)

  ## Examples

      iex> DateHelpers.next_weekday(1, ~D[2026-01-12])  # Monday, asking for Monday
      ~D[2026-01-12]

      iex> DateHelpers.next_weekday(1, ~D[2026-01-13])  # Tuesday, asking for Monday
      ~D[2026-01-19]
  """
  def next_weekday(day_of_week, today \\ today_berlin()) do
    current_day_of_week = Date.day_of_week(today)

    if current_day_of_week == day_of_week do
      today
    else
      days_until = rem(day_of_week - current_day_of_week + 7, 7)
      Date.add(today, days_until)
    end
  end

  @doc """
  Returns the next Monday. If today is Monday, returns today.

  ## Examples

      iex> DateHelpers.next_monday(~D[2026-01-12])  # A Monday
      ~D[2026-01-12]

      iex> DateHelpers.next_monday(~D[2026-01-11])  # A Sunday
      ~D[2026-01-12]
  """
  def next_monday(today \\ today_berlin()), do: next_weekday(1, today)

  @doc """
  Returns the next Friday. If today is Friday, returns today.

  ## Examples

      iex> DateHelpers.next_friday(~D[2026-01-16])  # A Friday
      ~D[2026-01-16]

      iex> DateHelpers.next_friday(~D[2026-01-12])  # A Monday
      ~D[2026-01-16]
  """
  def next_friday(today \\ today_berlin()), do: next_weekday(5, today)
end
