defmodule MehrSchulferienWeb.CalendarHelper do
  alias MehrSchulferien.Repo
  alias MehrSchulferien.Timetables.Day

  import Ecto.Query

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

  def calendar_sub_heading(starts_on, ends_on, categories \\ []) do
    current_month = Date.utc_today.month
    current_year = Date.utc_today.year

    categories_string = for category <- categories do
      category.name_plural
    end |> Enum.join(", ")

    starts_year = starts_on.year
    starts_year_plus_1 = starts_year + 1 # to case a Schuljahr

    heading = case {starts_on.month, starts_on.year, ends_on.month, ends_on.year} do
      {1, x, 12, x} -> Integer.to_string(starts_on.year) <> " (inkl. " <> categories_string <>")"
      {8, ^starts_year, 7, ^starts_year_plus_1} ->
                       "Schuljahr " <> Integer.to_string(starts_year - 2000) <> "/" <> Integer.to_string(starts_year - 1999) <> " (inkl. " <> categories_string <>")"
      {^current_month, ^current_year, month, year} ->
                       query = from(
                                    days in Day,
                                    where: days.value >= ^starts_on and
                                        days.value <= ^ends_on and
                                        days.day_of_month == 1,
                                    select: count("*")
                                   )
                       number_of_months = Repo.one(query)
                       "Die nächsten " <> Integer.to_string(number_of_months) <> " Monate (inkl. " <> categories_string <>")."
      _ -> three_letter_month(starts_on) <> Integer.to_string(starts_on.year) <> " - " <>
           three_letter_month(ends_on) <> Integer.to_string(ends_on.year) <> " (inkl. " <> categories_string <>")."
    end |> String.replace(" (inkl. )", "")
  end

  def three_letter_month(date) do
    case date.month do
      1 -> "Jan. "
      2 -> "Feb. "
      3 -> "Mär. "
      4 -> "Apr. "
      5 -> "Mai "
      6 -> "Juni "
      7 -> "Juli "
      8 -> "Aug. "
      9 -> "Sep. "
      10 -> "Okt. "
      11 -> "Nov. "
      _ -> "Dez. "
    end
  end

  def starts_on_to_ends_on(starts_on, ends_on) do
    case starts_on.year == ends_on.year do
      true ->  Integer.to_string(starts_on.day) <> "." <>
               Integer.to_string(starts_on.month) <> ". - " <>
               Integer.to_string(ends_on.day) <> "." <>
               Integer.to_string(ends_on.month) <> "." <>
               Integer.to_string(ends_on.year)
      false -> Integer.to_string(starts_on.day) <> "." <>
               Integer.to_string(starts_on.month) <> "." <>
               Integer.to_string(starts_on.year) <> ". - " <>
               Integer.to_string(ends_on.day) <> "." <>
               Integer.to_string(ends_on.month) <> "." <>
               Integer.to_string(ends_on.year)
    end
  end

  def fill_up_month_to_have_complete_weeks(days) do
    # Fill days with empty elements for the calendar blanks in
    # the first and last line of it.
    #
    head_fill = case List.first(days).weekday do
      1 -> nil
      2 -> [nil]
      3 -> [nil,nil]
      4 -> [nil,nil,nil]
      5 -> [nil,nil,nil,nil]
      6 -> [nil,nil,nil,nil,nil]
      7 -> [nil,nil,nil,nil,nil,nil]
    end

    tail_fill = case List.last(days).weekday do
      7 -> nil
      6 -> [nil]
      5 -> [nil,nil]
      4 -> [nil,nil,nil]
      3 -> [nil,nil,nil,nil]
      2 -> [nil,nil,nil,nil,nil]
      1 -> [nil,nil,nil,nil,nil,nil]
    end

    days = case {head_fill, tail_fill} do
      {nil, nil} -> days
      {nil, _} -> Enum.concat(days, tail_fill)
      {_, nil} -> Enum.concat(head_fill, days)
      {_, _} -> Enum.concat(Enum.concat(head_fill, days), tail_fill)
    end
  end

  def location_path(location) do
    case {location} do
       {%MehrSchulferien.Locations.School{}} -> "schools"
       {%MehrSchulferien.Locations.City{}} -> "cities"
       {%MehrSchulferien.Locations.FederalState{}} -> "federal_states"
        _ -> ""
    end
  end

end
