defmodule MehrSchulferienWeb.FaqComponent do
  use Phoenix.Component
  alias MehrSchulferienWeb.FaqViewHelpers
  alias MehrSchulferienWeb.ViewHelpers
  alias MehrSchulferienWeb.Router.Helpers, as: Routes
  import Phoenix.HTML.Link
  import Phoenix.HTML, only: [raw: 1]

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
  attr :nearby_schools, :list, default: []

  def faq(assigns) do
    # Process all FAQ data once
    faq_data = prepare_faq_data(assigns)

    # Check if we're on a school page by looking for a school attribute
    is_school_page = Map.has_key?(assigns, :school) && assigns.school != nil

    # Get correct preposition for this location
    location_prep = location_preposition(assigns.location, is_school_page)

    # Merge data into assigns for rendering
    assigns =
      assigns
      |> assign(:faq_data, faq_data)
      |> assign(:is_school_page, is_school_page)
      |> assign(:location_prep, location_prep)

    ~H"""
    <div class="mt-8 bg-white p-4 rounded-lg shadow-sm">
      <div class="mx-auto px-4 py-8 sm:py-12">
        <h2 class="text-xl sm:text-2xl font-bold text-gray-900 mb-4" id="faq">Ferien FAQ</h2>
        <p class="mt-3 max-w-3xl text-sm text-gray-600">
          Antworten zu häufigen Fragen zum Thema Schulferien und Feiertagen <%= @location_prep %> <%= @location.name %>.
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

            <%= if @nearby_schools && length(@nearby_schools) > 0 do %>
              <.nearby_schools
                conn={@conn}
                country={@country}
                nearby_schools={@nearby_schools}
                nearby_schools_question={@faq_data.nearby_schools_question}
              />
            <% end %>

            <%= unless @is_school_page do %>
              <.cities_in_federal_state
                federal_state={@federal_state}
                conn={@conn}
                country={@country}
              />
            <% end %>

            <%= for question <- @faq_data.yearly_periods_questions do %>
              <.faq_question question={question} />
            <% end %>

            <%= unless @is_school_page do %>
              <!-- Public Holidays Section -->
              <.section_header title="Feiertage" />

              <%= for question <- @faq_data.holiday_questions do %>
                <.faq_question question={question} />
              <% end %>

              <.faq_question question={@faq_data.next_holiday_question} />
            <% end %>
          </dl>
        </div>
      </div>
    </div>

    <.schema_org_faq faq_data={@faq_data} is_school_page={@is_school_page} />
    """
  end

  # Helper function to determine the correct preposition for a location name
  defp location_preposition(location, is_school_page) do
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

  # Helper function to prepare all data needed for FAQ rendering
  defp prepare_faq_data(assigns) do
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

    # Generate answers for each day's holiday status
    holiday_questions =
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

    # Generate yearly periods questions - only for current year
    current_year_periods =
      Enum.find(grouped_periods, fn periods ->
        first_period = Enum.at(periods, 0)
        first_period.starts_on.year == assigns.current_year
      end)

    yearly_periods_questions =
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

    # Generate next vacation question
    next_vacation_answer =
      FaqViewHelpers.next_school_vacation_answer(location, assigns.school_periods, assigns.today)

    next_vacation_question = %{
      title: "Wann sind die nächsten Schulferien #{location_prep} #{location.name}?",
      answer: next_vacation_answer
    }

    # General schulferien question
    schulferien_question = %{
      title: "Schulferien #{location_prep} #{location.name}?",
      answer: format_periods_answer(next_schulferien_periods)
    }

    # Next holiday question
    public_holiday_periods = Enum.filter(assigns.public_periods, & &1.is_public_holiday)

    next_holiday_answer =
      FaqViewHelpers.next_public_holiday_answer(location, public_holiday_periods, assigns.today)

    next_holiday_question = %{
      title: "Wann ist der nächste Feiertag #{location_prep} #{location.name}?",
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

    # Nearby schools question (if applicable)
    nearby_schools_question =
      if assigns.nearby_schools && length(assigns.nearby_schools) > 0 do
        # Generate text answer for nearby schools
        sorted_schools =
          Enum.sort_by(assigns.nearby_schools, fn {school, _distance} -> school.name end)

        nearby_schools_answer =
          if length(sorted_schools) == 1 do
            {school, distance} = hd(sorted_schools)

            distance_text =
              if distance < 1000,
                do: "#{round(distance)} m",
                else: "#{Float.round(distance / 1000, 1)} km"

            "#{school.name} (#{distance_text})"
          else
            {schools_except_last, [last_school_tuple]} = Enum.split(sorted_schools, -1)
            {last_school, last_distance} = last_school_tuple

            last_distance_text =
              if last_distance < 1000,
                do: "#{round(last_distance)} m",
                else: "#{Float.round(last_distance / 1000, 1)} km"

            schools_text =
              Enum.map_join(schools_except_last, ", ", fn {school, distance} ->
                distance_text =
                  if distance < 1000,
                    do: "#{round(distance)} m",
                    else: "#{Float.round(distance / 1000, 1)} km"

                "#{school.name} (#{distance_text})"
              end)

            if length(schools_except_last) > 0 do
              "#{schools_text} und #{last_school.name} (#{last_distance_text})"
            else
              "#{last_school.name} (#{last_distance_text})"
            end
          end

        %{
          title: "Welche weiteren Schulen sind im Umkreis von 3km?",
          answer: nearby_schools_answer
        }
      else
        nil
      end

    # Collect all questions for schema.org
    all_questions =
      [next_vacation_question] ++
        school_free_questions ++
        if(schools_question, do: [schools_question], else: []) ++
        if(nearby_schools_question, do: [nearby_schools_question], else: []) ++
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
      nearby_schools_question: nearby_schools_question,
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
        <%= raw(@question.answer) %>
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
            to: Routes.school_path(@conn, :show, @country.slug, hd(@sorted_schools).slug),
            class: "text-blue-600 hover:text-blue-500"
          ) %>
        <% else %>
          <% {schools_except_last, [last_school]} = Enum.split(@sorted_schools, -1) %>
          <%= for {school, index} <- Enum.with_index(schools_except_last) do %>
            <%= link(school.name,
              to: Routes.school_path(@conn, :show, @country.slug, school.slug),
              class: "text-blue-600 hover:text-blue-500"
            ) %><%= if index < length(schools_except_last) - 1, do: ", ", else: "" %>
          <% end %>
          <%= if length(schools_except_last) > 0 do %>
            und
          <% end %>
          <%= link(last_school.name,
            to: Routes.school_path(@conn, :show, @country.slug, last_school.slug),
            class: "text-blue-600 hover:text-blue-500"
          ) %>
        <% end %>
      </dd>
    </div>
    """
  end

  defp nearby_schools(assigns) do
    sorted_schools =
      Enum.sort_by(assigns.nearby_schools, fn {school, _distance} -> school.name end)

    assigns = assign(assigns, :sorted_schools, sorted_schools)

    ~H"""
    <div>
      <dt class="text-base font-semibold text-gray-900">
        <%= @nearby_schools_question.title %>
      </dt>
      <dd class="mt-2 text-sm text-gray-600">
        <%= if length(@sorted_schools) == 1 do %>
          <% {school, distance} = hd(@sorted_schools) %>
          <%= link(school.name,
            to: Routes.school_path(@conn, :show, @country.slug, school.slug),
            class: "text-blue-600 hover:text-blue-500"
          ) %> (<%= format_distance(distance) %>)
        <% else %>
          <% {schools_except_last, [last_school_tuple]} = Enum.split(@sorted_schools, -1) %>
          <%= for {{school, distance}, index} <- Enum.with_index(schools_except_last) do %>
            <%= link(school.name,
              to: Routes.school_path(@conn, :show, @country.slug, school.slug),
              class: "text-blue-600 hover:text-blue-500"
            ) %> (<%= format_distance(distance) %>)<%= if index < length(schools_except_last) - 1,
              do: ", ",
              else: "" %>
          <% end %>
          <%= if length(schools_except_last) > 0 do %>
            und
          <% end %>
          <% {last_school, last_distance} = last_school_tuple %>
          <%= link(last_school.name,
            to: Routes.school_path(@conn, :show, @country.slug, last_school.slug),
            class: "text-blue-600 hover:text-blue-500"
          ) %> (<%= format_distance(last_distance) %>)
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

  defp format_distance(distance) when distance < 1000 do
    "#{round(distance)} m"
  end

  defp format_distance(distance) do
    "#{Float.round(distance / 1000, 1)} km"
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
  attr :is_school_page, :boolean, required: true

  def schema_org_faq(assigns) do
    # Filter out holiday questions if location is a school
    filtered_questions =
      if assigns.is_school_page do
        Enum.reject(assigns.faq_data.all_questions, fn question ->
          Enum.member?(assigns.faq_data.holiday_questions, question) ||
            question == assigns.faq_data.next_holiday_question
        end)
      else
        assigns.faq_data.all_questions
      end

    # Filter out questions with empty answers and escape JSON properly
    valid_questions =
      Enum.filter(filtered_questions, fn question ->
        question && question.answer && String.trim(question.answer) != ""
      end)
      |> Enum.map(fn question ->
        # Clean HTML tags and escape JSON properly
        clean_answer =
          question.answer
          # Remove HTML tags
          |> String.replace(~r/<[^>]*>/, "")
          # Properly escape JSON special characters
          # Escape backslashes first
          |> String.replace("\\", "\\\\")
          # Escape quotes
          |> String.replace("\"", "\\\"")
          # Escape newlines
          |> String.replace("\n", "\\n")
          # Escape carriage returns
          |> String.replace("\r", "\\r")
          # Escape tabs
          |> String.replace("\t", "\\t")
          |> String.trim()

        clean_title =
          question.title
          # Escape backslashes first
          |> String.replace("\\", "\\\\")
          # Escape quotes
          |> String.replace("\"", "\\\"")
          # Escape newlines
          |> String.replace("\n", "\\n")
          # Escape carriage returns
          |> String.replace("\r", "\\r")
          # Escape tabs
          |> String.replace("\t", "\\t")

        %{question | answer: clean_answer, title: clean_title}
      end)

    # Only render if we have valid questions
    if length(valid_questions) > 0 do
      assigns = assign(assigns, :valid_questions, valid_questions)

      ~H"""
      <script type="application/ld+json">
        <%= Jason.encode!(%{
          "@context" => "https://schema.org",
          "@type" => "FAQPage",
          "mainEntity" => Enum.map(@valid_questions, fn question ->
            %{
              "@type" => "Question",
              "name" => question.title,
              "acceptedAnswer" => %{
                "@type" => "Answer",
                "text" => question.answer
              }
            }
          end)
        }) %>
      </script>
      """
    else
      ~H""
    end
  end

  # Helper to convert day labels to question form
  defp label_to_question("gestern"), do: "War gestern"
  defp label_to_question("heute"), do: "Ist heute"
  defp label_to_question("morgen"), do: "Ist morgen"
  defp label_to_question("übermorgen"), do: "Ist übermorgen"
end
