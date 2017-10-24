defmodule MehrSchulferienWeb.SchemaOrgHelper do

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

  def address(location) do
    case location do
      %MehrSchulferien.Locations.Country{} ->
        %{:streetAddress => "",
        :addressLocality => "Deutschland",
        :postalCode => "",
        :addressRegion => "",
        :addressCountry => "DE"}
      %MehrSchulferien.Locations.FederalState{} ->
        %{:streetAddress => "",
        :addressLocality => location.name,
        :postalCode => "",
        :addressRegion => location.name,
        :addressCountry => "DE"}
      %MehrSchulferien.Locations.City{} ->
        %{:streetAddress => "",
        :addressLocality => location.name,
        :postalCode => location.zip_code,
        :addressRegion => location.name,
        :addressCountry => "DE"}
      %MehrSchulferien.Locations.School{} ->
        federal_state = MehrSchulferien.Locations.get_federal_state!(location.federal_state_id)
        %{:streetAddress => location.address_street,
        :addressLocality => location.address_line1,
        :postalCode => location.address_zip_code,
        :addressRegion => federal_state.name,
        :addressCountry => "DE"}
    end
  end

end
