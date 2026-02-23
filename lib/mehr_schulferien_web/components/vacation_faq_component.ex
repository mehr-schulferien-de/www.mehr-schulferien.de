defmodule MehrSchulferienWeb.VacationFaqComponent do
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: MehrSchulferienWeb.Endpoint,
    router: MehrSchulferienWeb.Router

  import Phoenix.HTML, only: [raw: 1]

  attr :vacation_period, :any, required: true
  attr :vacation_name, :any, required: true
  attr :federal_state, :any, required: true
  attr :year, :integer, required: true
  attr :all_periods, :list, default: []

  def vacation_faq(assigns) do
    ~H"""
    <div class="mt-8 bg-white p-4 rounded-lg shadow-sm">
      <div class="mx-auto px-4 py-8 sm:py-12">
        <h2 class="text-xl sm:text-2xl font-bold text-gray-900 mb-4" id="faq">
          Häufig gestellte Fragen zu {@vacation_name} {@federal_state.name}
        </h2>
        <p class="mt-3 max-w-3xl text-sm text-gray-600">
          Antworten zu häufigen Fragen über {@vacation_name} in {@federal_state.name} {@year}.
        </p>

        <div class="mt-6">
          <dl class="space-y-8 sm:grid sm:grid-cols-2 sm:gap-x-6 sm:gap-y-8 sm:space-y-0">
            <%= if @vacation_period do %>
              <.faq_question
                title={"Wann sind #{@vacation_name} in #{@federal_state.name} #{@year}?"}
                answer={
                  vacation_dates_answer(@vacation_period, @vacation_name, @federal_state, @year)
                }
              />

              <.faq_question
                title={"Wie lange sind die #{@vacation_name} in #{@federal_state.name}?"}
                answer={vacation_duration_answer(@vacation_period, @vacation_name, @all_periods)}
              />

              <.faq_question
                title={"Wann beginnen die #{@vacation_name} in #{@federal_state.name}?"}
                answer={vacation_start_answer(@vacation_period, @vacation_name, @all_periods)}
              />

              <.faq_question
                title={"Wann enden die #{@vacation_name} in #{@federal_state.name}?"}
                answer={vacation_end_answer(@vacation_period, @vacation_name, @all_periods)}
              />
            <% else %>
              <.faq_question
                title={"Wann sind #{@vacation_name} in #{@federal_state.name} #{@year}?"}
                answer={no_data_answer(@vacation_name, @federal_state, @year)}
              />
            <% end %>

            <.faq_question
              title={"Für welche Städte in #{@federal_state.name} gelten diese Ferientermine?"}
              answer={cities_answer(@federal_state)}
            />
          </dl>
        </div>
      </div>
    </div>

    <%= if @vacation_period do %>
      <.vacation_faq_schema
        vacation_period={@vacation_period}
        vacation_name={@vacation_name}
        federal_state={@federal_state}
        year={@year}
        all_periods={@all_periods}
      />
    <% end %>
    """
  end

  defp faq_question(assigns) do
    ~H"""
    <div>
      <dt class="text-base font-semibold text-gray-900">
        {@title}
      </dt>
      <dd class="mt-2 text-sm text-gray-600">
        {raw(@answer)}
      </dd>
    </div>
    """
  end

  defp vacation_dates_answer(vacation_period, vacation_name, federal_state, year) do
    start_date =
      MehrSchulferienWeb.Formatters.DateFormatter.format_date_full(vacation_period.starts_on)

    end_date =
      MehrSchulferienWeb.Formatters.DateFormatter.format_date_full(vacation_period.ends_on)

    duration = Date.diff(vacation_period.ends_on, vacation_period.starts_on) + 1

    "Die #{vacation_name} #{year} in #{federal_state.name} sind vom <strong>#{start_date}</strong> bis zum <strong>#{end_date}</strong>. Das sind insgesamt #{duration} Tage Schulferien."
  end

  defp vacation_duration_answer(vacation_period, vacation_name, all_periods) do
    duration = Date.diff(vacation_period.ends_on, vacation_period.starts_on) + 1
    weeks = div(duration, 7)
    remaining_days = rem(duration, 7)

    duration_text =
      if weeks > 0 do
        if remaining_days > 0 do
          "#{weeks} #{if weeks == 1, do: "Woche", else: "Wochen"} und #{remaining_days} #{if remaining_days == 1, do: "Tag", else: "Tage"}"
        else
          "#{weeks} #{if weeks == 1, do: "Woche", else: "Wochen"}"
        end
      else
        "#{duration} #{if duration == 1, do: "Tag", else: "Tage"}"
      end

    # Calculate effective duration with adjacent weekends/holidays
    effective_duration =
      if Map.has_key?(vacation_period, :adjoining_duration) &&
           vacation_period.adjoining_duration > 0 do
        total_days = duration + vacation_period.adjoining_duration
        adjacent_info = analyze_adjacent_periods(vacation_period, all_periods)

        extra_info =
          if adjacent_info.has_weekend || adjacent_info.adjacent_holidays != [] do
            weekend_parts =
              if adjacent_info.has_weekend, do: ["angrenzende Wochenenden"], else: []

            holiday_parts =
              if adjacent_info.adjacent_holidays != [] do
                Enum.map(adjacent_info.adjacent_holidays, fn h ->
                  h.holiday_or_vacation_type.colloquial
                end)
              else
                []
              end

            all_parts = weekend_parts ++ holiday_parts

            " Durch #{Enum.join(all_parts, " und ")} haben die Schüler insgesamt <strong>#{total_days} zusammenhängende freie Tage</strong>."
          else
            " Mit angrenzenden Wochenenden sind es insgesamt <strong>#{total_days} zusammenhängende freie Tage</strong>."
          end

        extra_info
      else
        ""
      end

    "Die #{vacation_name} dauern offiziell <strong>#{duration_text}</strong> (#{duration} Tage).#{effective_duration}"
  end

  defp vacation_start_answer(vacation_period, vacation_name, all_periods) do
    start_date =
      MehrSchulferienWeb.Formatters.DateFormatter.format_date_full(vacation_period.starts_on)

    weekday = MehrSchulferienWeb.Formatters.DateFormatter.weekday_name(vacation_period.starts_on)

    # Check what comes before
    day_before = Date.add(vacation_period.starts_on, -1)
    before_info = check_adjacent_days_before(vacation_period.starts_on, all_periods)

    extra_info =
      cond do
        before_info.consecutive_days > 0 && before_info.has_holiday ->
          holiday_name = hd(before_info.holidays).holiday_or_vacation_type.colloquial
          " Davor liegt #{holiday_name}, sodass die Schüler bereits früher frei haben."

        before_info.consecutive_days > 0 && Date.day_of_week(day_before) == 7 ->
          " Da die Ferien nach einem Wochenende beginnen, haben die Schüler bereits ab Samstag frei."

        before_info.consecutive_days > 0 ->
          " Zusammen mit dem vorherigen Wochenende beginnt die schulfreie Zeit bereits früher."

        true ->
          ""
      end

    "Die #{vacation_name} beginnen am <strong>#{weekday}, den #{start_date}</strong>.#{extra_info}"
  end

  defp vacation_end_answer(vacation_period, vacation_name, all_periods) do
    end_date =
      MehrSchulferienWeb.Formatters.DateFormatter.format_date_full(vacation_period.ends_on)

    weekday = MehrSchulferienWeb.Formatters.DateFormatter.weekday_name(vacation_period.ends_on)

    # Check what comes after
    day_after = Date.add(vacation_period.ends_on, 1)
    after_info = check_adjacent_days_after(vacation_period.ends_on, all_periods)

    extra_info =
      cond do
        after_info.consecutive_days > 0 && after_info.has_holiday ->
          holiday_name = hd(after_info.holidays).holiday_or_vacation_type.colloquial
          " Danach folgt #{holiday_name}, wodurch die schulfreie Zeit verlängert wird."

        after_info.consecutive_days > 0 && Date.day_of_week(day_after) == 6 ->
          " Da danach ein Wochenende folgt, geht die Schule erst am Montag wieder los."

        after_info.consecutive_days > 0 ->
          " Die schulfreie Zeit verlängert sich durch das folgende Wochenende."

        true ->
          ""
      end

    "Die #{vacation_name} enden am <strong>#{weekday}, den #{end_date}</strong>.#{extra_info}"
  end

  defp no_data_answer(vacation_name, federal_state, year) do
    if year > Date.utc_today().year do
      "Die Termine für #{vacation_name} #{year} in #{federal_state.name} werden etwa 12-18 Monate im Voraus vom Kultusministerium festgelegt."
    else
      "Die Termine für #{vacation_name} #{year} in #{federal_state.name} werden in Kürze vom Kultusministerium veröffentlicht."
    end
  end

  defp cities_answer(federal_state) do
    "Die Ferientermine gelten für alle Städte und Gemeinden in #{federal_state.name}. Eine vollständige Liste finden Sie auf der Seite <a href=\"/ferien/d/bundesland/#{federal_state.slug}/landkreise-und-staedte\" class=\"text-blue-600 hover:text-blue-500\">Landkreise und Städte in #{federal_state.name}</a>."
  end

  # Schema.org FAQ structured data
  defp vacation_faq_schema(assigns) do
    questions = build_faq_questions(assigns)

    schema_data = %{
      "@context" => "https://schema.org",
      "@type" => "FAQPage",
      "mainEntity" => questions
    }

    assigns = assign(assigns, :schema_data, schema_data)

    ~H"""
    <script type="application/ld+json">
      <%= Jason.encode!(@schema_data) |> raw() %>
    </script>
    """
  end

  defp build_faq_questions(assigns) do
    vacation_questions =
      if assigns.vacation_period do
        [
          %{
            "@type" => "Question",
            "name" =>
              "Wann sind #{assigns.vacation_name} in #{assigns.federal_state.name} #{assigns.year}?",
            "acceptedAnswer" => %{
              "@type" => "Answer",
              "text" =>
                strip_html(
                  vacation_dates_answer(
                    assigns.vacation_period,
                    assigns.vacation_name,
                    assigns.federal_state,
                    assigns.year
                  )
                )
            }
          },
          %{
            "@type" => "Question",
            "name" =>
              "Wie lange sind die #{assigns.vacation_name} in #{assigns.federal_state.name}?",
            "acceptedAnswer" => %{
              "@type" => "Answer",
              "text" =>
                strip_html(
                  vacation_duration_answer(
                    assigns.vacation_period,
                    assigns.vacation_name,
                    assigns.all_periods
                  )
                )
            }
          },
          %{
            "@type" => "Question",
            "name" =>
              "Wann beginnen die #{assigns.vacation_name} in #{assigns.federal_state.name}?",
            "acceptedAnswer" => %{
              "@type" => "Answer",
              "text" =>
                strip_html(
                  vacation_start_answer(
                    assigns.vacation_period,
                    assigns.vacation_name,
                    assigns.all_periods
                  )
                )
            }
          },
          %{
            "@type" => "Question",
            "name" => "Wann enden die #{assigns.vacation_name} in #{assigns.federal_state.name}?",
            "acceptedAnswer" => %{
              "@type" => "Answer",
              "text" =>
                strip_html(
                  vacation_end_answer(
                    assigns.vacation_period,
                    assigns.vacation_name,
                    assigns.all_periods
                  )
                )
            }
          }
        ]
      else
        [
          %{
            "@type" => "Question",
            "name" =>
              "Wann sind #{assigns.vacation_name} in #{assigns.federal_state.name} #{assigns.year}?",
            "acceptedAnswer" => %{
              "@type" => "Answer",
              "text" =>
                strip_html(
                  no_data_answer(assigns.vacation_name, assigns.federal_state, assigns.year)
                )
            }
          }
        ]
      end

    vacation_questions ++
      [
        %{
          "@type" => "Question",
          "name" =>
            "Für welche Städte in #{assigns.federal_state.name} gelten diese Ferientermine?",
          "acceptedAnswer" => %{
            "@type" => "Answer",
            "text" => strip_html(cities_answer(assigns.federal_state))
          }
        }
      ]
  end

  defp strip_html(text) do
    text
    |> String.replace(~r/<[^>]*>/, "")
    |> String.replace("&nbsp;", " ")
    |> String.trim()
  end

  # Helper functions to analyze adjacent periods
  defp analyze_adjacent_periods(vacation_period, all_periods) do
    before_info = check_adjacent_days_before(vacation_period.starts_on, all_periods)
    after_info = check_adjacent_days_after(vacation_period.ends_on, all_periods)

    %{
      has_weekend: before_info.has_weekend || after_info.has_weekend,
      adjacent_holidays: before_info.holidays ++ after_info.holidays
    }
  end

  defp check_adjacent_days_before(start_date, periods) do
    # Check up to 7 days before
    dates_to_check = for i <- 1..7, do: Date.add(start_date, -i)

    {consecutive_days, holidays, has_weekend} =
      Enum.reduce_while(dates_to_check, {0, [], false}, fn date,
                                                           {count, holidays_acc, weekend_acc} ->
        is_weekend = Date.day_of_week(date) > 5
        holiday = find_holiday_on_date(date, periods)

        if is_weekend || holiday do
          new_holidays = if holiday, do: [holiday | holidays_acc], else: holidays_acc
          new_weekend = weekend_acc || is_weekend
          {:cont, {count + 1, new_holidays, new_weekend}}
        else
          {:halt, {count, holidays_acc, weekend_acc}}
        end
      end)

    %{
      consecutive_days: consecutive_days,
      holidays: Enum.reverse(holidays),
      has_holiday: holidays != [],
      has_weekend: has_weekend
    }
  end

  defp check_adjacent_days_after(end_date, periods) do
    # Check up to 7 days after
    dates_to_check = for i <- 1..7, do: Date.add(end_date, i)

    {consecutive_days, holidays, has_weekend} =
      Enum.reduce_while(dates_to_check, {0, [], false}, fn date,
                                                           {count, holidays_acc, weekend_acc} ->
        is_weekend = Date.day_of_week(date) > 5
        holiday = find_holiday_on_date(date, periods)

        if is_weekend || holiday do
          new_holidays = if holiday, do: [holiday | holidays_acc], else: holidays_acc
          new_weekend = weekend_acc || is_weekend
          {:cont, {count + 1, new_holidays, new_weekend}}
        else
          {:halt, {count, holidays_acc, weekend_acc}}
        end
      end)

    %{
      consecutive_days: consecutive_days,
      holidays: Enum.reverse(holidays),
      has_holiday: holidays != [],
      has_weekend: has_weekend
    }
  end

  defp find_holiday_on_date(date, periods) do
    Enum.find(periods, fn period ->
      # Only look for public holidays, not other vacations
      period.holiday_or_vacation_type.default_is_public_holiday &&
        Date.compare(date, period.starts_on) in [:eq, :gt] &&
        Date.compare(date, period.ends_on) in [:lt, :eq]
    end)
  end
end
