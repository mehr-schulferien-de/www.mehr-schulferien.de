defmodule MehrSchulferienWeb.Components.Faq.FaqDataBuilder do
  @moduledoc """
  Builds FAQ data structure from assigns.
  Extracted from FaqComponent to improve maintainability.
  """

  alias MehrSchulferienWeb.FaqViewHelpers
  alias MehrSchulferienWeb.ViewHelpers
  alias MehrSchulferienWeb.Helpers.PeriodHelpers
  alias MehrSchulferien.Periods
  alias MehrSchulferien.Calendars.DateHelpers

  def build(assigns) do
    location = assigns.location
    is_school_page = Map.has_key?(assigns, :school) && assigns.school != nil
    location_prep = location_preposition(location, is_school_page)

    # Sort all periods by start date
    sorted_periods =
      Enum.sort(
        assigns.public_periods ++ assigns.school_periods,
        &(Date.compare(&1.starts_on, &2.starts_on) == :lt)
      )

    # Get next periods and group by year
    next_schulferien_periods = Periods.next_periods(sorted_periods, 3)
    grouped_periods = Enum.chunk_by(sorted_periods, & &1.starts_on.year)

    # Build questions
    school_free_questions = build_school_free_questions(assigns, location, location_prep)
    holiday_questions = build_holiday_questions(assigns, location, location_prep)

    yearly_periods_questions =
      build_yearly_periods_questions(grouped_periods, assigns, location, location_prep)

    next_vacation_question = build_next_vacation_question(location, location_prep, assigns)

    schulferien_question =
      build_schulferien_question(location, location_prep, next_schulferien_periods)

    next_holiday_question = build_next_holiday_question(location, location_prep, assigns)

    schools_question = build_schools_question(assigns)
    nearby_schools_question = build_nearby_schools_question(assigns)

    # Build weekday-specific questions (Monday and Friday)
    weekday_school_questions = build_weekday_school_questions(assigns, location, location_prep)

    # Collect all questions for schema.org
    all_questions =
      [next_vacation_question] ++
        school_free_questions ++
        weekday_school_questions ++
        filter_nil([schools_question]) ++
        filter_nil([nearby_schools_question]) ++
        [schulferien_question] ++
        yearly_periods_questions ++
        holiday_questions ++
        [next_holiday_question]

    %{
      sorted_periods: sorted_periods,
      next_schulferien_periods: next_schulferien_periods,
      grouped_periods: grouped_periods,
      school_free_questions: school_free_questions,
      weekday_school_questions: weekday_school_questions,
      holiday_questions: holiday_questions,
      yearly_periods_questions: yearly_periods_questions,
      next_vacation_question: next_vacation_question,
      schulferien_question: schulferien_question,
      next_holiday_question: next_holiday_question,
      schools_question: schools_question,
      nearby_schools_question: nearby_schools_question,
      all_questions: all_questions
    }
  end

  defp build_school_free_questions(assigns, location, location_prep) do
    day_data = [
      %{
        label: "gestern",
        date: assigns.yesterday,
        school_periods: assigns.yesterdays_school_free_periods,
        holiday_periods: assigns.yesterdays_public_holiday_periods
      },
      %{
        label: "heute",
        date: assigns.today,
        school_periods: assigns.todays_school_free_periods,
        holiday_periods: assigns.todays_public_holiday_periods
      },
      %{
        label: "morgen",
        date: assigns.tomorrow,
        school_periods: assigns.tomorrows_school_free_periods,
        holiday_periods: assigns.tomorrows_public_holiday_periods
      },
      %{
        label: "übermorgen",
        date: assigns.day_after_tomorrow,
        school_periods: assigns.day_after_tomorrows_school_free_periods,
        holiday_periods: assigns.day_after_tomorrows_public_holiday_periods
      }
    ]

    Enum.map(day_data, fn %{label: label, date: date, school_periods: periods} ->
      question = "#{label_to_question(label)} schulfrei #{location_prep} #{location.name}?"
      answer = FaqViewHelpers.is_off_school_answer(periods, date, location)

      %{
        title: question,
        answer: answer,
        day_label: label,
        day_date: date,
        periods: periods
      }
    end)
  end

  defp build_holiday_questions(assigns, location, location_prep) do
    day_data = [
      %{
        label: "gestern",
        date: assigns.yesterday,
        holiday_periods: assigns.yesterdays_public_holiday_periods
      },
      %{
        label: "heute",
        date: assigns.today,
        holiday_periods: assigns.todays_public_holiday_periods
      },
      %{
        label: "morgen",
        date: assigns.tomorrow,
        holiday_periods: assigns.tomorrows_public_holiday_periods
      },
      %{
        label: "übermorgen",
        date: assigns.day_after_tomorrow,
        holiday_periods: assigns.day_after_tomorrows_public_holiday_periods
      }
    ]

    Enum.map(day_data, fn %{label: label, date: date, holiday_periods: periods} ->
      question = "#{label_to_question(label)} ein Feiertag #{location_prep} #{location.name}?"
      answer = FaqViewHelpers.is_public_holiday_answer(periods, date, location)

      %{
        title: question,
        answer: answer,
        day_label: label,
        day_date: date,
        periods: periods
      }
    end)
  end

  defp build_weekday_school_questions(assigns, location, location_prep) do
    today = assigns.today

    # Define weekdays to check: Monday (1) and Friday (5)
    weekday_data = [
      %{day_of_week: 1, weekday_name: "Montag"},
      %{day_of_week: 5, weekday_name: "Freitag"}
    ]

    Enum.map(weekday_data, fn %{day_of_week: day_of_week, weekday_name: weekday_name} ->
      target_date = DateHelpers.next_weekday(day_of_week, today)
      is_today = Date.compare(target_date, today) == :eq

      # Get school-free periods for the target date
      # Reuse existing data if the target date matches one of the pre-computed days
      periods = get_school_free_periods_for_date(assigns, target_date)

      question = "Ist am #{weekday_name} Schule #{location_prep} #{location.name}?"

      answer =
        FaqViewHelpers.is_school_on_weekday_answer(
          periods,
          target_date,
          location,
          weekday_name,
          is_today
        )

      %{
        title: question,
        answer: answer,
        day_label: String.downcase(weekday_name),
        day_date: target_date,
        periods: periods,
        is_today: is_today
      }
    end)
  end

  # Get school-free periods for a specific date, reusing pre-computed data when possible
  defp get_school_free_periods_for_date(assigns, target_date) do
    cond do
      Date.compare(target_date, assigns.yesterday) == :eq ->
        assigns.yesterdays_school_free_periods

      Date.compare(target_date, assigns.today) == :eq ->
        assigns.todays_school_free_periods

      Date.compare(target_date, assigns.tomorrow) == :eq ->
        assigns.tomorrows_school_free_periods

      Date.compare(target_date, assigns.day_after_tomorrow) == :eq ->
        assigns.day_after_tomorrows_school_free_periods

      true ->
        # For dates not pre-computed (Monday/Friday might be up to 6 days away),
        # combine school_periods and public_periods and filter for the target date.
        # Since Monday/Friday are weekdays, we don't need to check for weekends.
        all_periods = assigns.school_periods ++ assigns.public_periods
        Periods.find_all_periods(all_periods, target_date)
    end
  end

  defp build_yearly_periods_questions(grouped_periods, assigns, location, location_prep) do
    current_year_periods =
      Enum.find(grouped_periods, fn periods ->
        first_period = Enum.at(periods, 0)
        first_period.starts_on.year == assigns.current_year
      end)

    if current_year_periods do
      year = assigns.current_year
      title = "Schulfrei #{location_prep} #{location.name} #{year}"
      answer = format_periods_answer(current_year_periods)

      [
        %{
          title: title,
          answer: answer,
          year: year,
          periods: current_year_periods
        }
      ]
    else
      []
    end
  end

  defp build_next_vacation_question(location, location_prep, assigns) do
    next_vacation_answer =
      FaqViewHelpers.next_school_vacation_answer(location, assigns.school_periods, assigns.today)

    %{
      title: "Wann sind die nächsten Schulferien #{location_prep} #{location.name}?",
      answer: next_vacation_answer
    }
  end

  defp build_schulferien_question(location, location_prep, next_schulferien_periods) do
    %{
      title: "Schulferien #{location_prep} #{location.name}?",
      answer: format_periods_answer(next_schulferien_periods)
    }
  end

  defp build_next_holiday_question(location, location_prep, assigns) do
    public_holiday_periods = PeriodHelpers.public_holiday_periods(assigns.public_periods)

    next_holiday_answer =
      FaqViewHelpers.next_public_holiday_answer(location, public_holiday_periods, assigns.today)

    %{
      title: "Wann ist der nächste Feiertag #{location_prep} #{location.name}?",
      answer: next_holiday_answer,
      filtered_periods: public_holiday_periods
    }
  end

  defp build_schools_question(assigns) do
    if assigns.city && length(assigns.schools) > 0 do
      schools_answer = Enum.map_join(assigns.schools, ", ", fn school -> school.name end)

      %{
        title: "Welche Schulen gibt es in #{assigns.city.name}?",
        answer: schools_answer
      }
    else
      nil
    end
  end

  defp build_nearby_schools_question(assigns) do
    if assigns.nearby_schools && length(assigns.nearby_schools) > 0 do
      sorted_schools =
        Enum.sort_by(assigns.nearby_schools, fn {school, _distance} -> school.name end)

      nearby_schools_answer = format_nearby_schools_answer(sorted_schools)

      %{
        title: "Welche weiteren Schulen sind im Umkreis von 3km?",
        answer: nearby_schools_answer
      }
    else
      nil
    end
  end

  defp format_nearby_schools_answer(sorted_schools) do
    alias MehrSchulferienWeb.Helpers.DistanceHelpers

    if length(sorted_schools) == 1 do
      {school, distance} = hd(sorted_schools)
      distance_text = DistanceHelpers.format_distance(distance)
      "#{school.name} (#{distance_text})"
    else
      {schools_except_last, [last_school_tuple]} = Enum.split(sorted_schools, -1)
      {last_school, last_distance} = last_school_tuple

      last_distance_text = DistanceHelpers.format_distance(last_distance)

      schools_text =
        Enum.map_join(schools_except_last, ", ", fn {school, distance} ->
          distance_text = DistanceHelpers.format_distance(distance)
          "#{school.name} (#{distance_text})"
        end)

      if length(schools_except_last) > 0 do
        "#{schools_text} und #{last_school.name} (#{last_distance_text})"
      else
        "#{last_school.name} (#{last_distance_text})"
      end
    end
  end

  defp format_periods_answer(periods) do
    period_texts =
      Enum.map(
        periods,
        &"#{&1.holiday_or_vacation_type.colloquial} (#{ViewHelpers.format_date_range(&1.starts_on, &1.ends_on, :short)})"
      )

    # Join with commas and "und" before the last item
    case period_texts do
      [] ->
        ""

      [single] ->
        single

      _ ->
        {last, rest} = List.pop_at(period_texts, -1)
        Enum.join(rest, ", ") <> " und " <> last
    end
  end

  def location_preposition(location, is_school_page) do
    if is_school_page do
      location_name = location.name
      downcased_name = String.downcase(location_name)

      cond do
        String.ends_with?(downcased_name, "schule") -> "in der"
        String.ends_with?(downcased_name, "gymnasium") -> "im"
        true -> "in"
      end
    else
      "in"
    end
  end

  defp label_to_question("gestern"), do: "War gestern"
  defp label_to_question("heute"), do: "Ist heute"
  defp label_to_question("morgen"), do: "Ist morgen"
  defp label_to_question("übermorgen"), do: "Ist übermorgen"

  defp filter_nil(list), do: Enum.filter(list, & &1)
end
