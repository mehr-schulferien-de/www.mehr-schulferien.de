defmodule MehrSchulferien.Periods do
  @moduledoc """
  The Periods context.
  """

  import Ecto.Query, warn: false

  alias MehrSchulferien.Calendars
  alias MehrSchulferien.Calendars.{DateHelpers, HolidayOrVacationType}
  alias MehrSchulferien.Periods.{BridgeDayPeriod, Period}
  alias MehrSchulferien.Repo

  @doc """
  Returns the list of periods.
  """
  def list_periods do
    Repo.all(Period)
  end

  @doc """
  Returns a list of previous periods for a federal_state.
  """
  def list_previous_periods(federal_state, holiday_or_vacation_type) do
    today = DateHelpers.today_berlin()

    from(p in Period,
      where:
        p.location_id == ^federal_state.id and
          p.holiday_or_vacation_type_id == ^holiday_or_vacation_type.id and
          p.ends_on < ^today,
      order_by: [desc: p.starts_on]
    )
    |> Repo.all()
    |> Repo.preload([:holiday_or_vacation_type])
  end

  @doc """
  Returns a list of current and future periods for a federal_state.
  """
  def list_current_and_future_periods(federal_state, holiday_or_vacation_type) do
    today = DateHelpers.today_berlin()

    from(p in Period,
      where:
        p.location_id == ^federal_state.id and
          p.holiday_or_vacation_type_id == ^holiday_or_vacation_type.id and
          p.ends_on >= ^today,
      order_by: p.starts_on
    )
    |> Repo.all()
    |> Repo.preload([:holiday_or_vacation_type])
  end

  @doc """
  Gets a single period.

  Raises `Ecto.NoResultsError` if the Period does not exist.
  """
  def get_period!(id), do: Repo.get!(Period, id)

  @doc """
  Creates a period.
  """
  def create_period(%{"holiday_or_vacation_type_id" => holiday_or_vacation_type_id} = attrs)
      when not is_nil(holiday_or_vacation_type_id) do
    %HolidayOrVacationType{
      id: id,
      default_html_class: html_class,
      default_is_listed_below_month: is_listed_below_month,
      default_is_public_holiday: is_public_holiday,
      default_is_school_vacation: is_school_vacation,
      default_is_valid_for_everybody: is_valid_for_everybody,
      default_is_valid_for_students: is_valid_for_students,
      default_religion_id: religion_id,
      default_display_priority: display_priority
    } = Calendars.get_holiday_or_vacation_type!(holiday_or_vacation_type_id)

    attrs =
      Map.merge(
        %{
          "holiday_or_vacation_type_id" => id,
          "html_class" => html_class,
          "is_listed_below_month" => is_listed_below_month,
          "is_public_holiday" => is_public_holiday,
          "is_school_vacation" => is_school_vacation,
          "is_valid_for_everybody" => is_valid_for_everybody,
          "is_valid_for_students" => is_valid_for_students,
          "religion_id" => religion_id,
          "display_priority" => display_priority
        },
        attrs
      )

    %Period{}
    |> Period.changeset(attrs)
    |> Repo.insert()
  end

  def create_period(%{holiday_or_vacation_type_id: holiday_or_vacation_type_id} = attrs)
      when not is_nil(holiday_or_vacation_type_id) do
    attrs = for {key, val} <- attrs, into: %{}, do: {to_string(key), val}
    create_period(attrs)
  end

  def create_period(attrs) do
    %Period{}
    |> Period.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a period.
  """
  def update_period(%Period{} = period, attrs) do
    period
    |> Period.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a period.
  """
  def delete_period(%Period{} = period) do
    Repo.delete(period)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking period changes.
  """
  def change_period(%Period{} = period) do
    Period.changeset(period, %{})
  end

  @doc """
  Finds all the holiday periods for a certain date.
  """
  def find_all_periods(periods, date) do
    Enum.filter(periods, &is_holiday?(&1, date))
  end

  @doc """
  Returns the next schoolday (the next day that is not a holiday).
  """
  def find_next_schoolday([], _), do: nil

  def find_next_schoolday([first | rest], date) do
    if is_holiday?(first, date) do
      new_date = Date.add(first.ends_on, 1)
      find_next_schoolday(rest, new_date)
    else
      if check_ends_on(date, first) do
        date
      else
        find_next_schoolday(rest, date)
      end
    end
  end

  defp is_holiday?(period, date) do
    case Date.compare(date, period.starts_on) do
      :lt -> false
      :eq -> true
      :gt -> check_ends_on(date, period)
    end
  end

  defp check_ends_on(date, first) do
    case Date.compare(date, first.ends_on) do
      :gt -> nil
      _ -> first
    end
  end

  @doc """
  Returns the holiday periods for a certain date's month.
  """
  def find_periods_by_month(_date, []), do: []

  def find_periods_by_month(date, [first | rest]) do
    if DateHelpers.compare_by_month(date, first.starts_on) == :lt do
      []
    else
      if DateHelpers.compare_by_month(date, first.ends_on) == :gt do
        find_periods_by_month(date, rest)
      else
        [first | find_periods_by_month(date, rest)]
      end
    end
  end

  @doc """
  Returns the periods for a certain date range.

  The periods need to be sorted (by the `starts_on` date) before calling
  this function.
  """
  def find_periods_for_date_range(periods, start_date, end_date) do
    periods
    |> Enum.drop_while(&(Date.compare(&1.ends_on, start_date) == :lt))
    |> Enum.take_while(&(Date.compare(&1.starts_on, end_date) != :gt))
  end

  @doc """
  Takes a year's periods, from `start_date`, and groups them based on
  the holiday_or_vacation_type.

  The single year starts with the `start_date`, which is usually the current
  date and continues until August 1, the following year (the next year's
  summer vacation).
  """
  def group_periods_single_year(periods, start_date \\ DateHelpers.today_berlin()) do
    {:ok, end_date} = Date.new(start_date.year + 1, 8, 1)

    periods
    |> Enum.drop_while(&(Date.compare(&1.ends_on, start_date) == :lt))
    |> Enum.take_while(&(Date.compare(&1.starts_on, end_date) != :gt))
    |> Enum.chunk_by(& &1.holiday_or_vacation_type.name)
  end

  @doc """
  Returns a list of periods, sorted by the holiday_or_vacation_type names.
  """
  def list_periods_by_vacation_names(periods) do
    periods
    |> Enum.uniq_by(& &1.holiday_or_vacation_type.name)
    |> Enum.sort(&(Date.day_of_year(&1.starts_on) <= Date.day_of_year(&2.starts_on)))
  end

  @doc """
  Returns a list of school vacation periods for a certain time frame.
  """
  def list_school_periods(location_ids, starts_on, ends_on) do
    from(p in Period,
      where:
        p.location_id in ^location_ids and
          p.is_valid_for_students == true and
          p.is_school_vacation == true and
          p.ends_on >= ^starts_on and
          p.starts_on <= ^ends_on,
      order_by: p.starts_on
    )
    |> Repo.all()
    |> Repo.preload(:holiday_or_vacation_type)
  end

  @doc """
  Returns a list of public holiday periods, and periods that are valid
  for everybody, for a certain time frame.

  This function also returns periods that are valid for everybody, such as
  weekends. If you want to see just the public holiday periods, use
  `list_public_periods` instead.
  """
  def list_public_everybody_periods(location_ids, starts_on, ends_on) do
    from(p in Period,
      where:
        p.location_id in ^location_ids and
          (p.is_public_holiday == true or
             p.is_valid_for_everybody == true) and
          p.ends_on >= ^starts_on and
          p.starts_on <= ^ends_on,
      order_by: p.starts_on
    )
    |> Repo.all()
    |> Repo.preload(:holiday_or_vacation_type)
  end

  @doc """
  Returns a list of public holiday periods for a certain time frame.
  """
  def list_public_periods(location_ids, starts_on, ends_on) do
    from(p in Period,
      where:
        p.location_id in ^location_ids and
          p.is_public_holiday == true and
          p.ends_on >= ^starts_on and
          p.starts_on <= ^ends_on,
      order_by: p.display_priority
    )
    |> Repo.all()
    |> Repo.preload(:holiday_or_vacation_type)
  end

  @doc """
  Returns a list of periods that are non-school days for a certain date
  range.
  """
  def list_school_free_periods(location_ids, starts_on, ends_on) do
    from(p in Period,
      where:
        p.location_id in ^location_ids and
          (p.is_valid_for_students == true or
             p.is_valid_for_everybody == true) and
          p.ends_on >= ^starts_on and
          p.starts_on <= ^ends_on,
      order_by: p.display_priority
    )
    |> Repo.all()
    |> Repo.preload(:holiday_or_vacation_type)
  end

  @doc """
  Returns the first period after a certain date (the default date is today).

  The periods need to be sorted (by the `starts_on` date) before calling
  this function.
  """
  def next_periods(periods, today \\ DateHelpers.today_berlin(), number) do
    periods
    |> Enum.drop_while(&(Date.compare(&1.ends_on, today) == :lt))
    |> Enum.take(number)
  end

  @doc """
  Returns the most recently ended period.
  """
  def find_most_recent_period(periods, today \\ DateHelpers.today_berlin()) do
    periods
    |> Enum.sort(&(Date.compare(&1.starts_on, &2.starts_on) == :lt))
    |> Enum.take_while(&(Date.compare(&1.ends_on, today) == :lt))
    |> List.last()
  end

  @doc """
  Returns a map containing periods that are separated by 1..4 days.

  This is used for calculating bridge days.
  """
  def group_by_interval(periods) do
    periods
    |> Enum.reduce(%{}, fn period, acc ->
      acc =
        if last_period = acc["last_period"] do
          diff = Date.diff(period.starts_on, last_period.ends_on)

          case {diff, acc} do
            {diff, _} when diff not in 2..5 ->
              acc

            {_, %{^diff => value}} ->
              %{acc | diff => value ++ [BridgeDayPeriod.create(last_period, period, diff)]}

            {_, %{}} ->
              Map.put(acc, diff, [BridgeDayPeriod.create(last_period, period, diff)])
          end
        else
          %{}
        end

      Map.put(acc, "last_period", period)
    end)
    |> Map.delete("last_period")
  end

  def list_periods_with_bridge_day(periods, bridge_day) do
    [before_bd | query_periods] = Enum.drop_while(periods, &(&1.id != bridge_day.last_period_id))
    after_bd_periods = list_consecutive_periods(query_periods)
    query_periods = Enum.take_while(periods, &(&1.id != bridge_day.last_period_id))

    before_bd_periods =
      reverse_list_consecutive_periods([before_bd | Enum.reverse(query_periods)])

    before_bd_periods ++ [bridge_day | after_bd_periods]
  end

  defp list_consecutive_periods([first | rest]) do
    list_consecutive_periods(rest, [first])
  end

  defp list_consecutive_periods([], output), do: output

  defp list_consecutive_periods([first | rest], output) do
    if Date.diff(first.starts_on, List.last(output).ends_on) < 2 do
      list_consecutive_periods(rest, output ++ [first])
    else
      output
    end
  end

  defp reverse_list_consecutive_periods([first | rest]) do
    reverse_list_consecutive_periods(rest, [first])
  end

  defp reverse_list_consecutive_periods([], output), do: output

  defp reverse_list_consecutive_periods([first | rest], output) do
    if Date.diff(List.last(output).starts_on, first.ends_on) < 2 do
      reverse_list_consecutive_periods(rest, [first | output])
    else
      output
    end
  end
end
