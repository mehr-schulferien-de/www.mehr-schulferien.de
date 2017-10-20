defmodule MehrSchulferienWeb.CalendarHelper do

  def css_class(day, opts \\ []) do
    if opts[:target] do
      target = opts[:target]
    else
      target = :student
    end

    categories = for {_, %MehrSchulferien.Timetables.Category{name: name},
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
  
end
