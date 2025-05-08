defmodule MehrSchulferienWeb.FaqComponent do
  use Phoenix.Component
  alias MehrSchulferienWeb.FaqViewHelpers
  alias MehrSchulferienWeb.ViewHelpers
  alias MehrSchulferienWeb.Router.Helpers, as: Routes
  import Phoenix.HTML.Link

  attr :conn, :any, required: true
  attr :country, :any, required: true
  attr :federal_state, :any, required: true
  attr :location, :any, required: true
  attr :next_schoolday, :any, required: true
  attr :current_year, :integer, required: true
  attr :today, :any, required: true
  attr :yesterday, :any, required: true
  attr :tomorrow, :any, required: true
  attr :day_after_tomorrow, :any, required: true
  attr :school_periods, :list, required: true
  attr :public_periods, :list, required: true
  attr :months, :map, required: true
  attr :yesterdays_school_free_periods, :list, required: true
  attr :todays_school_free_periods, :list, required: true
  attr :tomorrows_school_free_periods, :list, required: true
  attr :day_after_tomorrows_school_free_periods, :list, required: true
  attr :yesterdays_public_holiday_periods, :list, required: true
  attr :todays_public_holiday_periods, :list, required: true
  attr :tomorrows_public_holiday_periods, :list, required: true
  attr :day_after_tomorrows_public_holiday_periods, :list, required: true
  attr :city, :any, default: nil
  attr :schools, :list, default: []

  def faq(assigns) do
    # Process all FAQ data once
    faq_data = prepare_faq_data(assigns)

    # Merge data into assigns for rendering
    assigns =
      assigns
      |> assign(:faq_data, faq_data)

    ~H"""
    <div class="mt-8 bg-white p-4 rounded-lg shadow-sm">
      <div class="mx-auto px-4 py-8 sm:py-12">
        <h2 class="text-xl sm:text-2xl font-bold text-gray-900 mb-4" id="faq">Ferien FAQ</h2>
        <p class="mt-3 max-w-3xl text-sm text-gray-600">
          Antworten zu häufigen Fragen zum Thema Schulferien und Feiertagen in <%= @location.name %>.
        </p>

        <div class="mt-6">
          <dl class="space-y-8 sm:grid sm:grid-cols-2 sm:gap-x-6 sm:gap-y-8 sm:space-y-0">
            <!-- School Vacation FAQ Section -->
            <.faq_question question={@faq_data.next_vacation_question} />

            <%= for question <- @faq_data.school_free_questions do %>
              <.faq_question question={question} />
            <% end %>

            <%= if @city && length(@schools) > 0 do %>
              <.schools_in_city
                city={@city}
                schools={@schools}
                conn={@conn}
                country={@country}
                schools_question={@faq_data.schools_question}
              />
            <% end %>

            <.cities_in_federal_state federal_state={@federal_state} conn={@conn} country={@country} />

            <%= for question <- @faq_data.yearly_periods_questions do %>
              <.faq_question question={question} />
            <% end %>
            <!-- Public Holidays Section -->
            <.section_header title="Feiertage" />

            <%= for question <- @faq_data.holiday_questions do %>
              <.faq_question question={question} />
            <% end %>

            <.faq_question question={@faq_data.next_holiday_question} />
          </dl>
        </div>
      </div>
    </div>

    <.schema_org_faq faq_data={@faq_data} />
    """
  end

  # Helper function to prepare all data needed for FAQ rendering
  defp prepare_faq_data(assigns) do
    location = assigns.location

    # Sort all periods by start date
    sorted_periods =
      Enum.sort(
        assigns.public_periods ++ assigns.school_periods,
        &(Date.compare(&1.starts_on, &2.starts_on) == :lt)
      )

    # Get next periods and group by year
    next_schulferien_periods = MehrSchulferien.Periods.next_periods(sorted_periods, 3)
    grouped_periods = Enum.chunk_by(sorted_periods, & &1.starts_on.year)

    # Build school free questions for each day
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

    # Generate answers for each day's school free status
    school_free_questions =
      Enum.map(day_data, fn %{label: label, date: date, school_periods: periods} ->
        question = "#{label_to_question(label)} schulfrei in #{location.name}?"
        answer = FaqViewHelpers.is_off_school_answer(periods, date, location)

        %{
          title: question,
          answer: answer,
          day_label: label,
          day_date: date,
          periods: periods
        }
      end)

    # Generate answers for each day's holiday status
    holiday_questions =
      Enum.map(day_data, fn %{label: label, date: date, holiday_periods: periods} ->
        question = "#{label_to_question(label)} ein Feiertag in #{location.name}?"
        answer = FaqViewHelpers.is_public_holiday_answer(periods, date, location)

        %{
          title: question,
          answer: answer,
          day_label: label,
          day_date: date,
          periods: periods
        }
      end)

    # Generate yearly periods questions
    yearly_periods_questions =
      Enum.map(grouped_periods, fn periods ->
        first_period = Enum.at(periods, 0)
        year = first_period.starts_on.year
        title = "Schulfrei #{location.name} #{year}"
        answer = format_periods_answer(periods)

        %{
          title: title,
          answer: answer,
          year: year,
          periods: periods
        }
      end)

    # Generate next vacation question
    next_vacation_answer =
      FaqViewHelpers.next_school_vacation_answer(location, assigns.school_periods, assigns.today)

    next_vacation_question = %{
      title: "Wann sind die nächsten Schulferien in #{location.name}?",
      answer: next_vacation_answer
    }

    # General schulferien question
    schulferien_question = %{
      title: "Schulferien #{location.name}?",
      answer: format_periods_answer(next_schulferien_periods)
    }

    # Next holiday question
    public_holiday_periods = Enum.filter(assigns.public_periods, & &1.is_public_holiday)

    next_holiday_answer =
      FaqViewHelpers.next_public_holiday_answer(location, public_holiday_periods, assigns.today)

    next_holiday_question = %{
      title: "Wann ist der nächste Feiertag in #{location.name}?",
      answer: next_holiday_answer,
      filtered_periods: public_holiday_periods
    }

    # Schools in city question (if applicable)
    schools_question =
      if assigns.city && length(assigns.schools) > 0 do
        schools_answer = Enum.map_join(assigns.schools, ", ", fn school -> school.name end)

        %{
          title: "Welche Schulen gibt es in #{assigns.city.name}?",
          answer: schools_answer
        }
      else
        nil
      end

    # Collect all questions for schema.org
    all_questions =
      [next_vacation_question] ++
        school_free_questions ++
        if(schools_question, do: [schools_question], else: []) ++
        [schulferien_question] ++
        yearly_periods_questions ++
        holiday_questions ++
        [next_holiday_question]

    # Return complete FAQ data structure
    %{
      sorted_periods: sorted_periods,
      next_schulferien_periods: next_schulferien_periods,
      grouped_periods: grouped_periods,
      school_free_questions: school_free_questions,
      holiday_questions: holiday_questions,
      yearly_periods_questions: yearly_periods_questions,
      next_vacation_question: next_vacation_question,
      schulferien_question: schulferien_question,
      next_holiday_question: next_holiday_question,
      schools_question: schools_question,
      all_questions: all_questions
    }
  end

  # Generic FAQ question component
  defp faq_question(assigns) do
    ~H"""
    <div>
      <dt class="text-base font-semibold text-gray-900">
        <%= @question.title %>
      </dt>
      <dd class="mt-2 text-sm text-gray-600">
        <%= @question.answer %>
      </dd>
    </div>
    """
  end

  # Individual FAQ question components
  defp section_header(assigns) do
    ~H"""
    <div class="sm:col-span-2 mt-8">
      <h3 class="text-lg font-semibold text-gray-900 mb-4"><%= @title %></h3>
    </div>
    """
  end

  defp schools_in_city(assigns) do
    sorted_schools = Enum.sort_by(assigns.schools, & &1.name)
    assigns = assign(assigns, :sorted_schools, sorted_schools)

    ~H"""
    <div>
      <dt class="text-base font-semibold text-gray-900">
        <%= @schools_question.title %>
      </dt>
      <dd class="mt-2 text-sm text-gray-600">
        <%= if length(@sorted_schools) == 1 do %>
          <%= link(hd(@sorted_schools).name,
            to: Routes.old_school_path(@conn, :show, @country.slug, hd(@sorted_schools).slug),
            class: "text-blue-600 hover:text-blue-500"
          ) %>
        <% else %>
          <% {schools_except_last, [last_school]} = Enum.split(@sorted_schools, -1) %>
          <%= for {school, index} <- Enum.with_index(schools_except_last) do %>
            <%= link(school.name,
              to: Routes.old_school_path(@conn, :show, @country.slug, school.slug),
              class: "text-blue-600 hover:text-blue-500"
            ) %><%= if index < length(schools_except_last) - 1, do: ", ", else: "" %>
          <% end %>
          <%= if length(schools_except_last) > 0 do %>
            und
          <% end %>
          <%= link(last_school.name,
            to: Routes.old_school_path(@conn, :show, @country.slug, last_school.slug),
            class: "text-blue-600 hover:text-blue-500"
          ) %>
        <% end %>
      </dd>
    </div>
    """
  end

  defp cities_in_federal_state(assigns) do
    ~H"""
    <div>
      <dt class="text-base font-semibold text-gray-900">
        Für welche Städte in <%= @federal_state.name %> gelten diese Feriendaten?
      </dt>
      <dd class="mt-2 text-sm text-gray-600">
        <%= link("Liste der Landkreise und Städte in #{@federal_state.name}.",
          to: Routes.federal_state_path(@conn, :county_show, @country.slug, @federal_state.slug),
          class: "font-semibold text-blue-600 hover:text-blue-500"
        ) %>
      </dd>
    </div>
    """
  end

  # Helper to format periods for answer text
  defp format_periods_answer(periods) do
    Enum.map_join(
      periods,
      " ",
      &"#{&1.holiday_or_vacation_type.colloquial} (#{ViewHelpers.format_date_range(&1.starts_on, &1.ends_on, :short)})"
    )
  end

  # Schema.org FAQ page component
  attr :faq_data, :map, required: true

  def schema_org_faq(assigns) do
    ~H"""
    <script type="application/ld+json">
      {
        "@context": "https://schema.org",
        "@type": "FAQPage",
        "mainEntity": [
          <%= for {question, index} <- Enum.with_index(@faq_data.all_questions) do %>
            {
              "@type": "Question",
              "name": "<%= question.title %>",
              "acceptedAnswer": {
                "@type": "Answer",
                "text": "<%= question.answer %>"
              }
            }<%= if index < length(@faq_data.all_questions) - 1, do: ",", else: "" %>
          <% end %>
        ]
      }
    </script>
    """
  end

  # Helper to convert day labels to question form
  defp label_to_question("gestern"), do: "War gestern"
  defp label_to_question("heute"), do: "Ist heute"
  defp label_to_question("morgen"), do: "Ist morgen"
  defp label_to_question("übermorgen"), do: "Ist übermorgen"
end
