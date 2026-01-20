defmodule MehrSchulferienWeb.VacationTypeFaqComponent do
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: MehrSchulferienWeb.Endpoint,
    router: MehrSchulferienWeb.Router

  import MehrSchulferienWeb.Shared.TypographyComponent

  attr :vacation_type, :string, required: true
  attr :vacation_config, :map, required: true
  attr :current_year, :integer, required: true
  attr :next_year, :integer, required: true
  attr :current_year_data, :list, required: true
  attr :next_year_data, :list, required: true

  def vacation_type_faq(assigns) do
    ~H"""
    <div class="mt-12 bg-white p-6 rounded-lg shadow-sm">
      <.heading level={2} class="text-2xl mb-4">
        Häufig gestellte Fragen zu {@vacation_config.name}
      </.heading>

      <div class="space-y-6">
        <div>
          <.heading level={3} class="text-lg font-semibold text-gray-900 mb-2">
            Wann sind {@vacation_config.name} {@current_year}?
          </.heading>
          <p class="text-gray-700">
            {faq_answer_dates(@current_year_data, @vacation_config.name, @current_year)}
          </p>
        </div>

        <div>
          <.heading level={3} class="text-lg font-semibold text-gray-900 mb-2">
            Wann sind {@vacation_config.name} {@next_year}?
          </.heading>
          <p class="text-gray-700">
            {faq_answer_dates(@next_year_data, @vacation_config.name, @next_year)}
          </p>
        </div>

        <div>
          <.heading level={3} class="text-lg font-semibold text-gray-900 mb-2">
            Welches Bundesland hat die frühesten {@vacation_config.name}?
          </.heading>
          <p class="text-gray-700">
            {faq_answer_earliest(@current_year_data, @vacation_config.name, @current_year)}
          </p>
        </div>

        <div>
          <.heading level={3} class="text-lg font-semibold text-gray-900 mb-2">
            Welches Bundesland hat die spätesten {@vacation_config.name}?
          </.heading>
          <p class="text-gray-700">
            {faq_answer_latest(@current_year_data, @vacation_config.name, @current_year)}
          </p>
        </div>

        <div>
          <.heading level={3} class="text-lg font-semibold text-gray-900 mb-2">
            Wie lange dauern die {@vacation_config.name}?
          </.heading>
          <p class="text-gray-700">
            {faq_answer_duration(@current_year_data, @vacation_config.name)}
          </p>
        </div>

        <div>
          <.heading level={3} class="text-lg font-semibold text-gray-900 mb-2">
            Warum haben nicht alle Bundesländer gleichzeitig {@vacation_config.name}?
          </.heading>
          <p class="text-gray-700">
            {faq_answer_rotation_system(@vacation_config.name)}
          </p>
        </div>

        <div>
          <.heading level={3} class="text-lg font-semibold text-gray-900 mb-2">
            Welches Bundesland hat die längsten {@vacation_config.name}?
          </.heading>
          <p class="text-gray-700">
            {faq_answer_longest(@current_year_data, @vacation_config.name, @current_year)}
          </p>
        </div>

        <div>
          <.heading level={3} class="text-lg font-semibold text-gray-900 mb-2">
            Kann ich {@vacation_config.name} mit Brückentagen kombinieren?
          </.heading>
          <p class="text-gray-700">
            {faq_answer_bridge_days(@vacation_config.name)}
          </p>
        </div>

        <div>
          <.heading level={3} class="text-lg font-semibold text-gray-900 mb-2">
            Wann ist die beste Reisezeit während der {@vacation_config.name}?
          </.heading>
          <p class="text-gray-700">
            {faq_answer_travel_time(@vacation_type, @vacation_config.name)}
          </p>
        </div>

        <div>
          <.heading level={3} class="text-lg font-semibold text-gray-900 mb-2">
            Wie werden die {@vacation_config.name} festgelegt?
          </.heading>
          <p class="text-gray-700">
            {faq_answer_determination(@vacation_config.name)}
          </p>
        </div>
      </div>

      {vacation_faq_schema(assigns)}
    </div>
    """
  end

  # Filters states_data to only include entries with valid periods
  defp filter_valid_periods(states_data) do
    Enum.filter(states_data, &(&1.period != nil))
  end

  defp faq_answer_dates(states_data, vacation_name, year) do
    case filter_valid_periods(states_data) do
      [] ->
        "Die Termine für #{vacation_name} #{year} werden etwa 12-18 Monate im Voraus von den Kultusministerien der Länder festgelegt."

      valid_periods ->
        earliest = List.first(valid_periods)
        latest = Enum.max_by(valid_periods, fn %{period: p} -> p.starts_on end)

        earliest_date = Calendar.strftime(earliest.period.starts_on, "%-d. %B")
        latest_date = Calendar.strftime(latest.period.starts_on, "%-d. %B")

        "Die #{vacation_name} #{year} beginnen je nach Bundesland zwischen dem #{earliest_date} (#{earliest.state.name}) und dem #{latest_date} (#{latest.state.name})."
    end
  end

  defp faq_answer_earliest(states_data, vacation_name, year) do
    case filter_valid_periods(states_data) do
      [] ->
        "Die Termine für #{vacation_name} #{year} sind noch nicht bekannt."

      valid_periods ->
        earliest = List.first(valid_periods)
        date = Calendar.strftime(earliest.period.starts_on, "%-d. %B %Y")

        "#{earliest.state.name} hat #{year} die frühesten #{vacation_name}. Sie beginnen am #{date}."
    end
  end

  defp faq_answer_latest(states_data, vacation_name, year) do
    case filter_valid_periods(states_data) do
      [] ->
        "Die Termine für #{vacation_name} #{year} sind noch nicht bekannt."

      valid_periods ->
        latest = Enum.max_by(valid_periods, fn %{period: p} -> p.starts_on end)
        date = Calendar.strftime(latest.period.starts_on, "%-d. %B %Y")

        "#{latest.state.name} hat #{year} die spätesten #{vacation_name}. Sie beginnen am #{date}."
    end
  end

  defp faq_answer_duration(states_data, vacation_name) do
    case filter_valid_periods(states_data) do
      [] ->
        "Die Dauer variiert je nach Bundesland."

      valid_periods ->
        durations = Enum.map(valid_periods, & &1.duration)
        {min_duration, max_duration} = Enum.min_max(durations, fn -> {0, 0} end)

        cond do
          min_duration == 0 and max_duration == 0 ->
            "Die Dauer variiert je nach Bundesland."

          min_duration == max_duration ->
            "Die #{vacation_name} dauern in allen Bundesländern #{min_duration} Tage."

          true ->
            "Die #{vacation_name} dauern je nach Bundesland zwischen #{min_duration} und #{max_duration} Tagen."
        end
    end
  end

  defp faq_answer_rotation_system(vacation_name) do
    "Die Kultusminister der Länder koordinieren die #{vacation_name} über ein Rotationssystem. Dies verhindert Überlastungen auf Autobahnen und in Urlaubsgebieten. Deutschland ist dafür in fünf Gruppen eingeteilt, die jährlich rotieren. So haben nie alle 16 Bundesländer gleichzeitig Ferien."
  end

  defp faq_answer_longest(states_data, vacation_name, year) do
    # Filter for periods with positive duration
    valid_periods =
      states_data
      |> filter_valid_periods()
      |> Enum.filter(&(&1.duration > 0))

    case valid_periods do
      [] ->
        "Die Daten für #{vacation_name} #{year} sind noch nicht vollständig verfügbar."

      periods ->
        longest = Enum.max_by(periods, & &1.duration)

        "#{longest.state.name} hat #{year} mit #{longest.duration} Tagen die längsten #{vacation_name}."
    end
  end

  defp faq_answer_bridge_days(vacation_name) do
    "Ja, #{vacation_name} lassen sich oft gut mit Brückentagen kombinieren. Feiertage wie Christi Himmelfahrt, Fronleichnam oder der Tag der Deutschen Einheit fallen manchmal in die Nähe von Schulferien. Mit wenigen Urlaubstagen können Sie so längere zusammenhängende Freizeit planen. Nutzen Sie unseren Brückentage-Rechner für optimale Planung."
  end

  defp faq_answer_travel_time(vacation_type, vacation_name) do
    case vacation_type do
      "sommer" ->
        "Der beste Reisezeitpunkt während der #{vacation_name} hängt vom Reiseziel ab. Für Mittelmeerländer sind Juni und September angenehmer (weniger Hitze, günstigere Preise). Nordeuropa ist im Juli und August ideal. Bundesländer mit frühen #{vacation_name} profitieren oft von niedrigeren Preisen."

      "oster" ->
        "Die #{vacation_name} fallen oft mit dem Frühlingsanfang zusammen. Für Skiurlaub sind die ersten Tage oft noch gut geeignet. Städtereisen und Wanderurlaub werden zum Ende der Ferien attraktiver, wenn es wärmer wird."

      "herbst" ->
        "Die #{vacation_name} eignen sich hervorragend für Städtereisen, Wellnessurlaub oder späte Strandurlaube am Mittelmeer. In Deutschland ist dies auch die Zeit für Herbstwanderungen mit buntem Laub."

      "weihnachts" ->
        "Die #{vacation_name} sind ideal für Winterurlaub in den Alpen, Weihnachtsmärkte oder Silvesterreisen. Alternativ bieten sich Fernreisen in wärmere Gefilde an. Buchen Sie frühzeitig, da dies eine beliebte Reisezeit ist."

      "winter" ->
        "Die #{vacation_name} sind perfekt für Skiurlaub, da die Schneeverhältnisse meist optimal sind. Alternativ eignet sich diese Zeit für Städtereisen oder Wellness, wenn man dem Winter entfliehen möchte."

      "pfingst" ->
        "Die #{vacation_name} bieten angenehmes Frühsommerwetter für Aktivurlaub, Radtouren oder erste Strandurlaube. Die Preise sind oft noch moderater als in den Sommerferien."

      _ ->
        "Der optimale Reisezeitpunkt während der #{vacation_name} hängt von Ihrem Reiseziel und Ihren Präferenzen ab. Frühzeitige Buchung sichert oft bessere Preise."
    end
  end

  defp faq_answer_determination(vacation_name) do
    "Die #{vacation_name} werden von den Kultusministerien der einzelnen Bundesländer festgelegt. Bei den Sommerferien koordiniert die Kultusministerkonferenz (KMK) die Termine bundesweit, um Reisechaos zu vermeiden. Die Termine werden meist mehrere Jahre im Voraus veröffentlicht."
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
      <%= Phoenix.HTML.raw(Jason.encode!(@schema_data)) %>
    </script>
    """
  end

  defp build_faq_questions(assigns) do
    [
      %{
        "@type" => "Question",
        "name" => "Wann sind #{assigns.vacation_config.name} #{assigns.current_year}?",
        "acceptedAnswer" => %{
          "@type" => "Answer",
          "text" =>
            faq_answer_dates(
              assigns.current_year_data,
              assigns.vacation_config.name,
              assigns.current_year
            )
        }
      },
      %{
        "@type" => "Question",
        "name" => "Wann sind #{assigns.vacation_config.name} #{assigns.next_year}?",
        "acceptedAnswer" => %{
          "@type" => "Answer",
          "text" =>
            faq_answer_dates(
              assigns.next_year_data,
              assigns.vacation_config.name,
              assigns.next_year
            )
        }
      },
      %{
        "@type" => "Question",
        "name" => "Welches Bundesland hat die frühesten #{assigns.vacation_config.name}?",
        "acceptedAnswer" => %{
          "@type" => "Answer",
          "text" =>
            faq_answer_earliest(
              assigns.current_year_data,
              assigns.vacation_config.name,
              assigns.current_year
            )
        }
      },
      %{
        "@type" => "Question",
        "name" => "Welches Bundesland hat die spätesten #{assigns.vacation_config.name}?",
        "acceptedAnswer" => %{
          "@type" => "Answer",
          "text" =>
            faq_answer_latest(
              assigns.current_year_data,
              assigns.vacation_config.name,
              assigns.current_year
            )
        }
      },
      %{
        "@type" => "Question",
        "name" => "Wie lange dauern die #{assigns.vacation_config.name}?",
        "acceptedAnswer" => %{
          "@type" => "Answer",
          "text" => faq_answer_duration(assigns.current_year_data, assigns.vacation_config.name)
        }
      },
      %{
        "@type" => "Question",
        "name" =>
          "Warum haben nicht alle Bundesländer gleichzeitig #{assigns.vacation_config.name}?",
        "acceptedAnswer" => %{
          "@type" => "Answer",
          "text" => faq_answer_rotation_system(assigns.vacation_config.name)
        }
      },
      %{
        "@type" => "Question",
        "name" => "Welches Bundesland hat die längsten #{assigns.vacation_config.name}?",
        "acceptedAnswer" => %{
          "@type" => "Answer",
          "text" =>
            faq_answer_longest(
              assigns.current_year_data,
              assigns.vacation_config.name,
              assigns.current_year
            )
        }
      },
      %{
        "@type" => "Question",
        "name" => "Kann ich #{assigns.vacation_config.name} mit Brückentagen kombinieren?",
        "acceptedAnswer" => %{
          "@type" => "Answer",
          "text" => faq_answer_bridge_days(assigns.vacation_config.name)
        }
      },
      %{
        "@type" => "Question",
        "name" => "Wann ist die beste Reisezeit während der #{assigns.vacation_config.name}?",
        "acceptedAnswer" => %{
          "@type" => "Answer",
          "text" => faq_answer_travel_time(assigns.vacation_type, assigns.vacation_config.name)
        }
      },
      %{
        "@type" => "Question",
        "name" => "Wie werden die #{assigns.vacation_config.name} festgelegt?",
        "acceptedAnswer" => %{
          "@type" => "Answer",
          "text" => faq_answer_determination(assigns.vacation_config.name)
        }
      }
    ]
  end
end
