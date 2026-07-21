defmodule MehrSchulferienWeb.FederalState.FaqSchemaComponent do
  use Phoenix.Component

  attr :federal_state, :any, required: true
  attr :year, :integer, required: true
  attr :periods, :list, required: true

  def faq_schema(assigns) do
    # Generate common questions based on vacation periods
    vacation_questions =
      assigns.periods
      |> Enum.filter(fn p -> p.holiday_or_vacation_type.default_is_school_vacation end)
      # Take main vacation types
      |> Enum.take(6)
      |> Enum.map(fn period ->
        # Use the period's own year: on evergreen pages the periods span
        # two years and would otherwise all be labeled with the page year.
        period_year = period.starts_on.year

        %{
          "@type" => "Question",
          "name" =>
            "Wann sind #{period.holiday_or_vacation_type.name} #{period_year} in #{assigns.federal_state.name}?",
          "acceptedAnswer" => %{
            "@type" => "Answer",
            "text" =>
              "Die #{period.holiday_or_vacation_type.name} #{period_year} in #{assigns.federal_state.name} sind vom #{Calendar.strftime(period.starts_on, "%d.%m.%Y")} bis #{Calendar.strftime(period.ends_on, "%d.%m.%Y")} (#{Date.diff(period.ends_on, period.starts_on) + 1} Tage)."
          }
        }
      end)

    # Add general questions
    general_questions = [
      %{
        "@type" => "Question",
        "name" =>
          "Wie viele Ferientage gibt es #{assigns.year} in #{assigns.federal_state.name}?",
        "acceptedAnswer" => %{
          "@type" => "Answer",
          "text" =>
            "In #{assigns.federal_state.name} gibt es #{assigns.year} insgesamt #{count_vacation_days(assigns.periods)} Ferientage verteilt auf #{count_vacation_periods(assigns.periods)} Ferienabschnitte."
        }
      },
      %{
        "@type" => "Question",
        "name" => "Wann beginnen die nächsten Schulferien in #{assigns.federal_state.name}?",
        "acceptedAnswer" => %{
          "@type" => "Answer",
          "text" => next_vacation_answer(assigns.periods, assigns.federal_state, Date.utc_today())
        }
      }
    ]

    assigns = assign(assigns, :vacation_questions, vacation_questions)
    assigns = assign(assigns, :general_questions, general_questions)

    ~H"""
    <script type="application/ld+json">
      <%= Phoenix.HTML.raw(Jason.encode!(%{
        "@context" => "https://schema.org",
        "@type" => "FAQPage",
        "mainEntity" => @vacation_questions ++ @general_questions
      })) %>
    </script>
    """
  end

  defp count_vacation_days(periods) do
    periods
    |> Enum.filter(fn p -> p.holiday_or_vacation_type.default_is_school_vacation end)
    |> Enum.map(fn p -> Date.diff(p.ends_on, p.starts_on) + 1 end)
    |> Enum.sum()
  end

  defp count_vacation_periods(periods) do
    Enum.count(periods, fn p -> p.holiday_or_vacation_type.default_is_school_vacation end)
  end

  defp next_vacation_answer(periods, federal_state, today) do
    next_vacation =
      periods
      |> Enum.filter(fn p ->
        p.holiday_or_vacation_type.default_is_school_vacation &&
          Date.compare(p.starts_on, today) == :gt
      end)
      |> Enum.sort_by(& &1.starts_on)
      |> List.first()

    case next_vacation do
      nil ->
        "Für das aktuelle Jahr sind keine weiteren Schulferien in #{federal_state.name} geplant."

      vacation ->
        days_until = Date.diff(vacation.starts_on, today)

        "Die nächsten Schulferien in #{federal_state.name} sind die #{vacation.holiday_or_vacation_type.name} vom #{Calendar.strftime(vacation.starts_on, "%d.%m.%Y")} bis #{Calendar.strftime(vacation.ends_on, "%d.%m.%Y")} (in #{days_until} Tagen)."
    end
  end
end
