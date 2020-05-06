defmodule MehrSchulferien.Periods do
  @moduledoc """
  The Periods context.
  """

  import Ecto.Query, warn: false

  alias MehrSchulferien.Calendars.{DateHelpers, Period}
  alias MehrSchulferien.Repo

  @doc """
  Takes a year's periods, from `start_date`, and groups them based on
  the holiday_or_vacation_type.
  """
  def group_periods_single_year(periods, start_date \\ DateHelpers.today_berlin()) do
    end_date = Date.add(start_date, 365)

    periods
    |> Enum.drop_while(&(Date.compare(&1.ends_on, start_date) == :lt))
    |> Enum.take_while(&(Date.compare(&1.starts_on, end_date) != :gt))
    |> Enum.chunk_by(& &1.holiday_or_vacation_type.name)
  end

  @doc """
  Groups periods with same holiday_or_vacation_type. This function
  works for many years and returns a `{headers, periods}` tuple.
  """
  def group_periods_multi_year(periods) do
    headers =
      periods
      |> Enum.uniq_by(& &1.holiday_or_vacation_type.name)
      |> Enum.sort(&(Date.day_of_year(&1.starts_on) <= Date.day_of_year(&2.starts_on)))

    periods =
      for period_list <- Enum.chunk_by(periods, & &1.starts_on.year) do
        create_year_periods(period_list, headers)
      end

    {headers, periods}
  end

  defp create_year_periods(periods, headers) do
    for title <- headers do
      Enum.filter(
        periods,
        &(&1.holiday_or_vacation_type.name == title.holiday_or_vacation_type.name)
      )
    end
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
  Returns a list of public holiday periods, including weekends,
  for a certain time frame.
  """
  def list_public_periods(location_ids, starts_on, ends_on) do
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

  # NOTE: riverrun (2020-05-06)
  # CHANGE THIS TO TAKE periods AS INPUT
  # AND ADD START_DATE AND END_DATE, SO THAT WE CAN QUERY
  # ALL THE NEEDED DAYS AT ONCE
  @doc """
  Returns a list of public holiday periods for a given date and location_ids.
  """
  def list_public_holiday_periods(location_ids, date) do
    from(p in Period,
      where:
        p.location_id in ^location_ids and
          p.is_public_holiday == true and
          p.ends_on >= ^date and
          p.starts_on <= ^date,
      order_by: p.display_priority
    )
    |> Repo.all()
    |> Repo.preload(:holiday_or_vacation_type)
  end

  def list_public_holiday_periods(location_ids, starts_on, ends_on) do
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

  # NOTE: riverrun (2020-05-06)
  # CHANGE THIS TO TAKE periods AS INPUT
  @doc """
  Returns a list of periods which indicate that this day is school
  free for students for a given date and location_ids.
  """
  def list_school_free_periods(location_ids, date) do
    location_ids
    |> school_free_periods_query(date, date)
    |> Repo.all()
    |> Repo.preload(:holiday_or_vacation_type)
  end

  @doc """
  Returns a list of periods for which this date range is a holiday
  period for students.
  """
  def list_school_free_periods(location_ids, starts_on, ends_on) do
    location_ids
    |> school_free_periods_query(starts_on, ends_on)
    |> Repo.all()
    |> Repo.preload(:holiday_or_vacation_type)
  end

  defp school_free_periods_query(location_ids, starts_on, ends_on) do
    from(p in Period,
      where:
        p.location_id in ^location_ids and
          (p.is_valid_for_students == true or
             p.is_valid_for_everybody == true) and
          p.ends_on >= ^starts_on and
          p.starts_on <= ^ends_on,
      order_by: p.display_priority
    )
  end

  # NOTE: riverrun (2020-05-06)
  # CHANGE THIS TO TAKE periods AS INPUT
  @doc """
  Returns the next school vacation period that is greater than today.
  """
  def next_school_vacation_period(location_ids) do
    next_school_vacation_period(location_ids, DateHelpers.today_berlin())
  end

  # NOTE: riverrun (2020-05-06)
  # CHANGE THIS TO TAKE periods AS INPUT
  @doc """
  Returns the next school vacation period that is greater than date.
  """
  def next_school_vacation_period(location_ids, date) do
    from(p in Period,
      where:
        p.location_id in ^location_ids and
          p.is_school_vacation == true and
          p.starts_on > ^date,
      order_by: p.starts_on,
      limit: 1
    )
    |> Repo.one()
    |> Repo.preload(:holiday_or_vacation_type)
  end

  # NOTE: riverrun (2020-05-06)
  # CHANGE THIS TO TAKE periods AS INPUT
  @doc """
  Returns the next public holiday that is greater than today.
  """
  def next_public_holiday_period(location_ids) do
    next_public_holiday_period(location_ids, DateHelpers.today_berlin())
  end

  # NOTE: riverrun (2020-05-06)
  # CHANGE THIS TO TAKE periods AS INPUT
  @doc """
  Returns the next public holiday that is greater than date.
  """
  def next_public_holiday_period(location_ids, date) do
    from(p in Period,
      where:
        p.location_id in ^location_ids and
          p.is_public_holiday == true and
          p.starts_on > ^date,
      order_by: p.starts_on,
      limit: 1
    )
    |> Repo.one()
    |> Repo.preload(:holiday_or_vacation_type)
  end
end
