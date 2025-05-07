defmodule MehrSchulferien.Calendars.DateHelpers do
  @moduledoc """
  Date helper functions.
  """

  require Logger

  @leap_years [2020, 2024, 2028, 2032, 2036, 2040, 2044, 2048]
  @days_in_month %{
    1 => 31,
    2 => 28,
    3 => 31,
    4 => 30,
    5 => 31,
    6 => 30,
    7 => 31,
    8 => 31,
    9 => 30,
    10 => 31,
    11 => 30,
    12 => 31
  }
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
    cond do
      # If conn is passed and has custom_date in assigns
      conn && Map.has_key?(conn.assigns, :custom_date) && conn.assigns.custom_date != nil ->
        conn.assigns.custom_date

      # Default to current date in Berlin
      true ->
        today_berlin()
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
    days_in_month =
      if month <= 12 do
        get_days_in_month(year, month)
      else
        Logger.warning(fn ->
          "#################### Huh? Month #{inspect(month)} out of range 1-12 for create_month( #{inspect(year)}, #{inspect(month)} ). Running get_days_in_month( #{inspect(year + 1)}, #{inspect(month - 12)} )"
        end)

        get_days_in_month(year + 1, month - 12)
      end

    if !days_in_month do
      Logger.warning(fn ->
        "#################### Huh? No days in month #{inspect(month)}/#{inspect(year)}"
      end)
    end

    for day <- 1..days_in_month do
      %Date{year: year, month: month, day: day, calendar: Calendar.ISO}
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

  @doc """
  Returns a map of abbreviated day names, with day numbers (1-7) as keys.
  """
  def short_days_map do
    %{1 => "Mo", 2 => "Di", 3 => "Mi", 4 => "Do", 5 => "Fr", 6 => "Sa", 7 => "So"}
  end

  @doc """
  Converts a day of week number (1-7) to a German weekday name in different formats.

  ## Format options:
  - :full - Full name (e.g., "Montag")
  - :short - Short name without dot (e.g., "Mo")
  - :short_with_dot - Short name with dot (e.g., "Mo.")
  """
  def weekday(day_of_week, format \\ :full) do
    case format do
      :full ->
        case day_of_week do
          1 -> "Montag"
          2 -> "Dienstag"
          3 -> "Mittwoch"
          4 -> "Donnerstag"
          5 -> "Freitag"
          6 -> "Samstag"
          7 -> "Sonntag"
        end

      :short ->
        case day_of_week do
          1 -> "Mo"
          2 -> "Di"
          3 -> "Mi"
          4 -> "Do"
          5 -> "Fr"
          6 -> "Sa"
          7 -> "So"
        end

      :short_with_dot ->
        case day_of_week do
          1 -> "Mo."
          2 -> "Di."
          3 -> "Mi."
          4 -> "Do."
          5 -> "Fr."
          6 -> "Sa."
          7 -> "So."
        end
    end
  end

  @doc """
  Returns a map containing the month numbers as keys and the month German
  names as values.
  """
  def get_months_map, do: @months

  defp get_days_in_month(year, month) when month == 2 and year in @leap_years, do: 29
  defp get_days_in_month(_, month), do: @days_in_month[month]

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
end
