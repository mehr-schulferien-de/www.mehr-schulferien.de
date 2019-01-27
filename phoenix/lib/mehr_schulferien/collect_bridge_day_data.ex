defmodule MehrSchulferien.CollectBridgeDayData do
  alias MehrSchulferien.Timetables
  alias MehrSchulferien.Locations
  alias MehrSchulferien.Repo
  alias MehrSchulferien.Timetables.Day
  alias MehrSchulferien.Timetables.Slot
  alias MehrSchulferien.Timetables.Period
  alias MehrSchulferien.Locations.Country
  alias MehrSchulferien.Locations.FederalState
  alias MehrSchulferien.Locations.City
  alias MehrSchulferien.Locations.School
  alias MehrSchulferien.Timetables.Category
  import Ecto.Query

  def list_days(locations, opts \\ []) do
     country_ids = for %MehrSchulferien.Locations.Country{id: id} <- locations, do: id
     federal_state_ids = for %MehrSchulferien.Locations.FederalState{id: id} <- locations, do: id

     if opts[:starts_on] do
       starts_on = opts[:starts_on]
     else
       {:ok, starts_on} = Date.from_erl({Date.utc_today.year, 1, 1})
     end

     if opts[:ends_on] do
       ends_on = opts[:ends_on]
     else
       {:ok, ends_on} = Date.from_erl({starts_on.year, 12, 31})
     end

     # Feiertage und Wochenenden
     #
     query = from(categories in Category,
                  where: categories.for_anybody == true,
                  select: categories.id)
     category_ids = Repo.all(query)

     query = from(
               days in Day,
               left_join: slots in Slot,
               on: days.id == slots.day_id,
               left_join: periods in Period,
               on: slots.period_id == periods.id and
                   (periods.country_id in ^country_ids or
                    periods.federal_state_id in ^federal_state_ids) and
                    periods.category_id in ^category_ids,
               left_join: country in Country,
               on:  periods.country_id == country.id,
               left_join: federal_state in FederalState,
               on:  periods.federal_state_id == federal_state.id,
               left_join: category in Category,
               on:  periods.category_id == category.id,
               where: days.value >= ^starts_on and
                      days.value <= ^ends_on,
               order_by: days.value,
               select: {days, periods, category, country, federal_state}
               )
     Repo.all(query)
     |> Enum.group_by(fn {date, _, _, _, _} -> date end, fn {_, period, category, country, federal_state} -> {period, category, country, federal_state} end)
     |> Enum.map(fn {date, periods} -> date
       |> Map.put(:periods, Enum.reject(periods, fn(x) -> x == {nil, nil, nil, nil} end)) end)
     |> Enum.sort_by(fn x -> x.slug end)
  end

  # Find bridge days
  # https://stackoverflow.com/questions/46992652/find-bridge-days-in-a-list-of-days
  #
  def optimal_bridge_days_start_position(days, number_of_days_to_invest) do
    boolean_days = Enum.map(days, fn(x) -> length(x.periods) > 0 end)
    0..(length(boolean_days) - 1)
      |> Enum.max_by(fn from ->
        boolean_days |> Enum.drop(from) |> Enum.reduce_while({0, 0}, fn holiday?, {collected, taken} ->
          cond do
            # If it's a holiday, we've collected one day without consuming more vacations.
            holiday? -> {:cont, {collected + 1, taken}}
            # If we've taken all vacations possible, we halt.
            number_of_days_to_invest == taken -> {:halt, {collected, taken}}
            # Otherwise, we collect another day and also consume one vacation day.
            true -> {:cont, {collected + 1, taken + 1}}
          end
        end)
        |> elem(0)
      end)
  end

  def optimal_bridge_days(days, number_of_days_to_invest) do
    start_position = optimal_bridge_days_start_position(days, number_of_days_to_invest)
    for {day, index} <- Enum.with_index(days) do
        if index > (start_position - 1) do
          case length(day.periods) do
            0 -> day.value
            _ -> nil
          end
        end
      end |> Enum.reject(&is_nil/1)
          |> Enum.chunk_every(number_of_days_to_invest)
          |> List.first
  end

  def search_again_for_bridge_days(days, number_of_days_to_invest, last_search_result) do
    first_vacation_day_value = Enum.at(days, last_search_result[:start_position]).value
    last_vacation_day_value = Date.add(first_vacation_day_value, last_search_result[:bridge_day_vacation_length])
    vacation_days = Date.range(first_vacation_day_value, last_vacation_day_value)

    days = Enum.reject(days, fn(x) -> Enum.member?(vacation_days, x.value) end)

    start_position = optimal_bridge_days_start_position(days, number_of_days_to_invest)
    bridge_days = optimal_bridge_days(days, number_of_days_to_invest)
    bridge_day_vacation_length = bridge_day_vacation_length(days, number_of_days_to_invest)

    {days, %{start_position: start_position, bridge_days: bridge_days, bridge_day_vacation_length: bridge_day_vacation_length}}
  end

  def compiled_optimal_bridge_days(days, number_of_days_to_invest) do
    start_position = optimal_bridge_days_start_position(days, number_of_days_to_invest)
    bridge_days = optimal_bridge_days(days, number_of_days_to_invest)
    bridge_day_vacation_length = bridge_day_vacation_length(days, number_of_days_to_invest)

    searchresult = %{start_position: start_position, bridge_days: bridge_days, bridge_day_vacation_length: bridge_day_vacation_length}
    result = [searchresult]

    # TO-DO: Fix this quick and dirty approach for bridge days.
    #
    {days, searchresult} = search_again_for_bridge_days(days, number_of_days_to_invest, searchresult)
    result = result ++ [searchresult]

    {days, searchresult} = search_again_for_bridge_days(days, number_of_days_to_invest, searchresult)
    result = result ++ [searchresult]

    {days, searchresult} = search_again_for_bridge_days(days, number_of_days_to_invest, searchresult)
    result = result ++ [searchresult]

    {days, searchresult} = search_again_for_bridge_days(days, number_of_days_to_invest, searchresult)
    result = result ++ [searchresult]

    {days, searchresult} = search_again_for_bridge_days(days, number_of_days_to_invest, searchresult)
    result = result ++ [searchresult]

    {days, searchresult} = search_again_for_bridge_days(days, number_of_days_to_invest, searchresult)
    result = result ++ [searchresult]

    {days, searchresult} = search_again_for_bridge_days(days, number_of_days_to_invest, searchresult)
    result = result ++ [searchresult]

    {days, searchresult} = search_again_for_bridge_days(days, number_of_days_to_invest, searchresult)
    result = result ++ [searchresult]

    {days, searchresult} = search_again_for_bridge_days(days, number_of_days_to_invest, searchresult)
    result = result ++ [searchresult]

    {days, searchresult} = search_again_for_bridge_days(days, number_of_days_to_invest, searchresult)
    result = result ++ [searchresult]

    {days, searchresult} = search_again_for_bridge_days(days, number_of_days_to_invest, searchresult)
    result = result ++ [searchresult]

    {days, searchresult} = search_again_for_bridge_days(days, number_of_days_to_invest, searchresult)
    result = result ++ [searchresult]

    {days, searchresult} = search_again_for_bridge_days(days, number_of_days_to_invest, searchresult)
    result = result ++ [searchresult]

    {days, searchresult} = search_again_for_bridge_days(days, number_of_days_to_invest, searchresult)
    result = result ++ [searchresult]

    vacation_length_list = Enum.map(result, fn(x) -> x.bridge_day_vacation_length end)
                           |> Enum.sort
                           |> Enum.uniq

    [greatest|tail] = Enum.reverse(vacation_length_list)
    [second_greatest|tail] = tail
    [third_greatest|tail] = tail
    
    Enum.filter(result, fn(x) -> Enum.member?([greatest, second_greatest, third_greatest], x.bridge_day_vacation_length) end)
    |> Enum.sort(&(&1.bridge_day_vacation_length <= &2.bridge_day_vacation_length))
    |> Enum.reverse
  end

  def bridge_day_vacation_length(days, number_of_days_to_invest) do
    start_position = optimal_bridge_days_start_position(days, number_of_days_to_invest)
    optimal_bridge_days = optimal_bridge_days(days, number_of_days_to_invest)
    optimal_bridge_days_start_position = optimal_bridge_days_start_position(days, number_of_days_to_invest)

    Enum.reduce_while(optimal_bridge_days_start_position..(length(days) - 1), 0, fn i, acc ->
      if ((length(Enum.at(days, i).periods) > 0) or (Enum.member?(optimal_bridge_days, Enum.at(days, i).value))), do: {:cont, acc + 1}, else: {:halt, acc}
    end)
  end

  def test_foobar do
    country = MehrSchulferien.Locations.get_country!(1)
    federal_state = MehrSchulferien.Locations.get_federal_state!("hessen")
    days = MehrSchulferien.CollectBridgeDayData.list_days([country, federal_state], starts_on: ~D[2017-04-01], ends_on: ~D[2017-04-30])

    number_of_days_to_invest = 3
    start_position = MehrSchulferien.CollectBridgeDayData.optimal_bridge_days_start_position(days, number_of_days_to_invest)
    optimal_bridge_days = MehrSchulferien.CollectBridgeDayData.optimal_bridge_days(days, number_of_days_to_invest)

    test = MehrSchulferien.CollectBridgeDayData.compiled_optimal_bridge_days(days, number_of_days_to_invest)
  end

  def ramp_up_to_full_months(starts_on, ends_on) do
    {:ok, starts_on} = Date.from_erl({starts_on.year, starts_on.month, 1})
    {:ok, ends_on} = case {ends_on.month, Date.leap_year?(ends_on)} do
      {1, _} -> Date.from_erl({ends_on.year, ends_on.month, 31})
      {2, false} -> Date.from_erl({ends_on.year, ends_on.month, 28})
      {2, true} -> Date.from_erl({ends_on.year, ends_on.month, 29})
      {3, _} -> Date.from_erl({ends_on.year, ends_on.month, 31})
      {4, _} -> Date.from_erl({ends_on.year, ends_on.month, 30})
      {5, _} -> Date.from_erl({ends_on.year, ends_on.month, 31})
      {6, _} -> Date.from_erl({ends_on.year, ends_on.month, 30})
      {7, _} -> Date.from_erl({ends_on.year, ends_on.month, 31})
      {8, _} -> Date.from_erl({ends_on.year, ends_on.month, 31})
      {9, _} -> Date.from_erl({ends_on.year, ends_on.month, 30})
      {10, _} -> Date.from_erl({ends_on.year, ends_on.month, 31})
      {11, _} -> Date.from_erl({ends_on.year, ends_on.month, 30})
      {12, _} -> Date.from_erl({ends_on.year, ends_on.month, 31})
    end
    {starts_on, ends_on}
  end

  @doc """
  Calculate optimal bridge days for each investable day (1...5)
  the returned value format %{investable_day: [bridge_days], ...}
  """
  def compiled_optimal_bridge_days_by_each_investable_day(days) do
    Enum.reduce(1..6, %{}, fn number_of_day_to_invest, best_bridge_days ->
      days
        |> compiled_optimal_bridge_days(number_of_day_to_invest)
        |> Enum.take(1) # take the top 1 of each list of optimal bridge days
        |> set_optimal_bridge_days(number_of_day_to_invest, best_bridge_days)
    end)
  end

  defp set_optimal_bridge_days(optimal_bridge_days, number_of_day_to_invest, best_bridge_days) do
    Map.put(best_bridge_days, number_of_day_to_invest, optimal_bridge_days)
  end

end
