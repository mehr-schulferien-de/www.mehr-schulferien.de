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
      </div>

      {vacation_faq_schema(assigns)}
    </div>
    """
  end

  defp faq_answer_dates(states_data, vacation_name, year) do
    valid_periods = Enum.filter(states_data, &(&1.period != nil))

    if Enum.empty?(valid_periods) do
      "Die Termine für #{vacation_name} #{year} werden etwa 12-18 Monate im Voraus von den Kultusministerien der Länder festgelegt."
    else
      earliest = List.first(valid_periods)
      latest = Enum.max_by(valid_periods, fn %{period: p} -> p.starts_on end)

      earliest_date = Calendar.strftime(earliest.period.starts_on, "%-d. %B")
      latest_date = Calendar.strftime(latest.period.starts_on, "%-d. %B")

      "Die #{vacation_name} #{year} beginnen je nach Bundesland zwischen dem #{earliest_date} (#{earliest.state.name}) und dem #{latest_date} (#{latest.state.name})."
    end
  end

  defp faq_answer_earliest(states_data, vacation_name, year) do
    valid_periods = Enum.filter(states_data, &(&1.period != nil))

    if Enum.empty?(valid_periods) do
      "Die Termine für #{vacation_name} #{year} sind noch nicht bekannt."
    else
      earliest = List.first(valid_periods)
      date = Calendar.strftime(earliest.period.starts_on, "%-d. %B %Y")

      "#{earliest.state.name} hat #{year} die frühesten #{vacation_name}. Sie beginnen am #{date}."
    end
  end

  defp faq_answer_latest(states_data, vacation_name, year) do
    valid_periods = Enum.filter(states_data, &(&1.period != nil))

    if Enum.empty?(valid_periods) do
      "Die Termine für #{vacation_name} #{year} sind noch nicht bekannt."
    else
      latest = Enum.max_by(valid_periods, fn %{period: p} -> p.starts_on end)
      date = Calendar.strftime(latest.period.starts_on, "%-d. %B %Y")

      "#{latest.state.name} hat #{year} die spätesten #{vacation_name}. Sie beginnen am #{date}."
    end
  end

  defp faq_answer_duration(states_data, vacation_name) do
    valid_periods = Enum.filter(states_data, &(&1.period != nil))

    if Enum.empty?(valid_periods) do
      "Die Dauer variiert je nach Bundesland."
    else
      durations = Enum.map(valid_periods, & &1.duration)
      min_duration = Enum.min(durations, fn -> 0 end)
      max_duration = Enum.max(durations, fn -> 0 end)

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
      }
    ]
  end
end
