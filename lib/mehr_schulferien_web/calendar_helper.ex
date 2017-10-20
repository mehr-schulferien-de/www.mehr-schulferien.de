defmodule MehrSchulferienWeb.CalendarHelper do

  def css_class(day, opts \\ []) do
    if opts[:target] do
      target = opts[:target]
    else
      target = :student
    end

    categories = for {_period, %MehrSchulferien.Timetables.Category{name: name},
         _country, _federal_state, _city, _school} <- day.periods do
      name
    end

    css_class = case {
           Enum.member?(categories, "Wochenende"),
           Enum.member?(categories, "Schulferien"),
           Enum.member?(categories, "Gesetzlicher Feiertag"),
           Enum.member?(categories, "Beweglicher Ferientag"),
           Enum.member?(categories, "Religiöser Feiertag")
         } do
      # I just use the default TwitterBootstrap class names. No judgement.
      #
      {_, _, true, _, _} -> "info"
      {true, _, _, _, _} -> "active"
      {_, true, _, _, _} -> "success"
      {_, _, _, _, true} -> "danger"
      {_, _, _, true, _} -> "warning"
      {_, _, _, _, _} -> ""
    end
  end

  def school_holidays(month) do
    for %MehrSchulferien.Timetables.Day{periods: periods} <- month do
      for {%MehrSchulferien.Timetables.Period{name: name, starts_on: starts_on,
           ends_on: ends_on, length: length},
           %MehrSchulferien.Timetables.Category{name: "Schulferien"},
           _country,
           %MehrSchulferien.Locations.FederalState{name: federal_state_name,
           slug: federal_state_slug}, _city, _school} <- periods do
         {name, starts_on, ends_on, length, federal_state_name, federal_state_slug}
      end
    end |> List.flatten |> Enum.uniq
  end

end
