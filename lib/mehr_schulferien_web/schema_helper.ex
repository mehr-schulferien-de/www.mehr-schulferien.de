defmodule MehrSchulferienWeb.SchemaHelper do

  def event_schema_periods(days, category_whitelist \\ ["Schulferien"]) do
    for %MehrSchulferien.Timetables.Day{periods: periods} <- days do
      for {%MehrSchulferien.Timetables.Period{name: name, starts_on: starts_on, ends_on: ends_on, length: length},
           %MehrSchulferien.Timetables.Category{name: category_name},
           country, federal_state, city, school} <- periods do

         location = List.first([country, federal_state, city, school] |> Enum.reject(&is_nil/1))
         {name, starts_on, ends_on, length, location, category_name}
      end
    end |> List.flatten |> Enum.uniq |> Enum.reject(fn({name, starts_on, ends_on, length, location, category_name}) -> !Enum.member?(category_whitelist, category_name) end)
  end

end
