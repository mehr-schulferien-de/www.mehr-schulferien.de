defmodule MehrSchulferienWeb.CalendarHelper do

  def css_class(day, opts \\ []) do
    if opts[:target] do
      _target = opts[:target]
    else
      _target = :student
    end

    categories = for {_period, %MehrSchulferien.Timetables.Category{name: name},
         _country, _federal_state, _city, _school} <- day.periods do
      name
    end

    css_class_for_categories(categories)
  end


  def css_class_for_categories(categories) do
    case {
           Enum.member?(categories, "Wochenende"),
           Enum.member?(categories, "Schulferien") or Enum.member?(categories, "Schulfrei"),
           Enum.member?(categories, "Gesetzlicher Feiertag"),
           Enum.member?(categories, "Beweglicher Ferientag"),
           Enum.member?(categories, "Jüdischer Feiertag") or Enum.member?(categories, "Islamischer Feiertag") or
           Enum.member?(categories, "Griechisch-Orthodoxer Feiertag") or Enum.member?(categories, "Russisch-Orthodoxer Feiertag")
         } do
      # I just use the default TwitterBootstrap class names. No judgement.
      #
      {_, _, true, _, _} -> "info"
      {true, _, _, _, _} -> "active"
      {_, true, _, _, _} -> "success"
      {_, _, _, _, true} -> "danger"
      {_, _, _, true, _} -> "warning"
      _ -> ""
    end
  end

  def filtered_periods(month, categories) do
    for category <- categories do
      {category, filter_periods(month, category.name)}
    end |> Enum.reject(fn({_category, x}) -> x == [] end)
  end

  defp filter_periods(month, category_name) do
    css_class = css_class_for_categories([category_name])

    for %MehrSchulferien.Timetables.Day{periods: periods} <- month do
      for {%MehrSchulferien.Timetables.Period{name: name, starts_on: starts_on, ends_on: ends_on, length: length},
           %MehrSchulferien.Timetables.Category{name: ^category_name},
           country, federal_state, city, school} <- periods do

         location = List.first([country, federal_state, city, school] |> Enum.reject(&is_nil/1))
         {name, starts_on, ends_on, length, location, css_class}
      end
    end |> List.flatten |> Enum.uniq
  end

  def starts_in_current_month?(starts_on) do
    current_month = Date.utc_today.month
    current_year = Date.utc_today.year

    case {starts_on.month, starts_on.year} do
      {^current_month, ^current_year} -> true
      _ -> false
    end
  end

end
