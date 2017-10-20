defmodule MehrSchulferien.CollectData do
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
     city_ids = for %MehrSchulferien.Locations.City{id: id} <- locations, do: id
     school_ids = for %MehrSchulferien.Locations.School{id: id} <- locations, do: id

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

     if opts[:categories] do
       categories = opts[:categories]
     else
       query = from(categories in Category,
                    where: categories.for_students == true and
                           categories.needs_exeat == false)
       categories = Repo.all(query)
     end
     category_ids = for %MehrSchulferien.Timetables.Category{id: id} <- categories, do: id

     query = from(
               days in Day,
               left_join: slots in Slot,
               on: days.id == slots.day_id,
               left_join: periods in Period,
               on: slots.period_id == periods.id and
                   (periods.country_id in ^country_ids or
                    periods.federal_state_id in ^federal_state_ids or
                    periods.city_id in ^city_ids or
                    periods.school_id in ^school_ids) and
                    periods.category_id in ^category_ids,
               left_join: country in Country,
               on:  periods.country_id == country.id,
               left_join: federal_state in FederalState,
               on:  periods.federal_state_id == federal_state.id,
               left_join: city in City,
               on:  periods.city_id == city.id,
               left_join: school in School,
               on:  periods.school_id == school.id,
               left_join: category in Category,
               on:  periods.category_id == category.id,
               where: days.value >= ^starts_on and
                      days.value <= ^ends_on,
               order_by: days.value,
               select: {days, periods, category, country, federal_state, city, school}
               )
     Repo.all(query)
     |> Enum.group_by(fn {date, _, _, _, _, _, _} -> date end, fn {_, period, category, country, federal_state, city, school} -> {period, category, country, federal_state, city, school} end)
     |> Enum.map(fn {date, periods} -> date
       |> Map.put(:periods, Enum.reject(periods, fn(x) -> x == {nil, nil, nil, nil, nil, nil} end)) end)
     |> Enum.sort_by(fn x -> x.slug end)
  end

  def test_foobar do
    country = MehrSchulferien.Locations.get_country!(1)
    federal_state = MehrSchulferien.Locations.get_federal_state!("hessen")
    days = MehrSchulferien.CollectData.list_days([country, federal_state], starts_on: ~D[2017-01-01], ends_on: ~D[2017-01-02])
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

end
