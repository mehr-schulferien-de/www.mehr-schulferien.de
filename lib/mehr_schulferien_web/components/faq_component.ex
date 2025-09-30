defmodule MehrSchulferienWeb.FaqComponent do
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: MehrSchulferienWeb.Endpoint,
    router: MehrSchulferienWeb.Router

  alias MehrSchulferienWeb.Helpers.DistanceHelpers
  alias MehrSchulferienWeb.Components.Faq.{FaqDataBuilder, FaqSchemaComponent}
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
    faq_data = FaqDataBuilder.build(assigns)

    # Check if we're on a school page by looking for a school attribute
    is_school_page = Map.has_key?(assigns, :school) && assigns.school != nil

    # Get correct preposition for this location
    location_prep = FaqDataBuilder.location_preposition(assigns.location, is_school_page)

    # Merge data into assigns for rendering
    assigns =
      assigns
      |> assign(:faq_data, faq_data)
      |> assign(:is_school_page, is_school_page)
      |> assign(:location_prep, location_prep)

    ~H"""
    <div class="mt-8 bg-white dark:bg-gray-800 p-4 rounded-lg shadow-sm">
      <div class="mx-auto px-4 py-6">
        <h2 class="text-xl sm:text-2xl font-bold text-gray-900 dark:text-gray-100 mb-4" id="faq">
          Ferien FAQ
        </h2>
        <p class="mt-3 max-w-3xl text-sm text-gray-600 dark:text-gray-400">
          Antworten zu häufigen Fragen zum Thema Schulferien und Feiertagen {@location_prep} {@location.name}.
        </p>

        <div class="mt-6">
          <dl class="space-y-6 sm:grid sm:grid-cols-2 sm:gap-x-6 sm:gap-y-6 sm:space-y-0">
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
              <!-- Date Query Tools Section -->
              <.section_header title="Schnelle Abfragen" />

              <.date_query_links federal_state={@federal_state} />
            <% end %>
          </dl>
        </div>
      </div>
    </div>

    <FaqSchemaComponent.faq_schema faq_data={@faq_data} is_school_page={@is_school_page} />
    """
  end

  # Component functions for individual FAQ sections
  defp faq_question(assigns) do
    ~H"""
    <div>
      <dt class="text-base font-semibold text-gray-900 dark:text-gray-100">
        {@question.title}
      </dt>
      <dd class="mt-2 text-sm text-gray-600 dark:text-gray-400">
        {raw(@question.answer)}
      </dd>
    </div>
    """
  end

  # Individual FAQ question components
  defp section_header(assigns) do
    ~H"""
    <div class="sm:col-span-2 mt-3">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-2">{@title}</h3>
    </div>
    """
  end

  defp schools_in_city(assigns) do
    sorted_schools = Enum.sort_by(assigns.schools, & &1.name)
    assigns = assign(assigns, :sorted_schools, sorted_schools)

    ~H"""
    <div>
      <dt class="text-base font-semibold text-gray-900 dark:text-gray-100">
        {@schools_question.title}
      </dt>
      <dd class="mt-2 text-sm text-gray-600 dark:text-gray-400">
        <%= if length(@sorted_schools) == 1 do %>
          <.link
            navigate={~p"/ferien/#{@country.slug}/schule/#{hd(@sorted_schools).slug}"}
            class="text-blue-600 dark:text-blue-400 hover:text-blue-500 dark:hover:text-blue-300"
          >
            {hd(@sorted_schools).name}
          </.link>
        <% else %>
          <% {schools_except_last, [last_school]} = Enum.split(@sorted_schools, -1) %>
          <%= for {school, index} <- Enum.with_index(schools_except_last) do %>
            <.link
              navigate={~p"/ferien/#{@country.slug}/schule/#{school.slug}"}
              class="text-blue-600 dark:text-blue-400 hover:text-blue-500 dark:hover:text-blue-300"
            >
              {school.name}
            </.link>
            {if index < length(schools_except_last) - 1, do: ", ", else: ""}
          <% end %>
          <%= if length(schools_except_last) > 0 do %>
            und
          <% end %>
          <.link
            navigate={~p"/ferien/#{@country.slug}/schule/#{last_school.slug}"}
            class="text-blue-600 dark:text-blue-400 hover:text-blue-500 dark:hover:text-blue-300"
          >
            {last_school.name}
          </.link>
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
      <dt class="text-base font-semibold text-gray-900 dark:text-gray-100">
        {@nearby_schools_question.title}
      </dt>
      <dd class="mt-2 text-sm text-gray-600 dark:text-gray-400">
        <%= if length(@sorted_schools) == 1 do %>
          <% {school, distance} = hd(@sorted_schools) %>
          <.link
            navigate={~p"/ferien/#{@country.slug}/schule/#{school.slug}"}
            class="text-blue-600 dark:text-blue-400 hover:text-blue-500 dark:hover:text-blue-300"
          >
            {school.name}
          </.link>
          ({DistanceHelpers.format_distance(distance)})
        <% else %>
          <% {schools_except_last, [last_school_tuple]} = Enum.split(@sorted_schools, -1) %>
          <%= for {{school, distance}, index} <- Enum.with_index(schools_except_last) do %>
            <.link
              navigate={~p"/ferien/#{@country.slug}/schule/#{school.slug}"}
              class="text-blue-600 dark:text-blue-400 hover:text-blue-500 dark:hover:text-blue-300"
            >
              {school.name}
            </.link>
            ({DistanceHelpers.format_distance(distance)}){if index <
                                                               length(schools_except_last) - 1,
                                                             do: ", ",
                                                             else: ""}
          <% end %>
          <%= if length(schools_except_last) > 0 do %>
            und
          <% end %>
          <% {last_school, last_distance} = last_school_tuple %>
          <.link
            navigate={~p"/ferien/#{@country.slug}/schule/#{last_school.slug}"}
            class="text-blue-600 dark:text-blue-400 hover:text-blue-500 dark:hover:text-blue-300"
          >
            {last_school.name}
          </.link>
          ({DistanceHelpers.format_distance(last_distance)})
        <% end %>
      </dd>
    </div>
    """
  end

  defp cities_in_federal_state(assigns) do
    ~H"""
    <div>
      <dt class="text-base font-semibold text-gray-900 dark:text-gray-100">
        Für welche Städte in {@federal_state.name} gelten diese Feriendaten?
      </dt>
      <dd class="mt-2 text-sm text-gray-600 dark:text-gray-400">
        <.link
          navigate={
            ~p"/ferien/#{@country.slug}/bundesland/#{@federal_state.slug}/landkreise-und-staedte"
          }
          class="font-semibold text-blue-600 dark:text-blue-400 hover:text-blue-500 dark:hover:text-blue-300"
        >
          Liste der Landkreise und Städte in {@federal_state.name}.
        </.link>
      </dd>
    </div>
    """
  end

  defp date_query_links(assigns) do
    ~H"""
    <div class="sm:col-span-2">
      <dd class="text-sm text-gray-600 dark:text-gray-400">
        <p class="mb-3">
          Schnelle Antworten auf häufige Fragen zu Feiertagen und Schultagen:
        </p>
        <ul class="list-disc ml-5 space-y-2">
          <li>
            <.link
              navigate={~p"/ist-heute-feiertag/#{@federal_state.slug}"}
              class="text-blue-600 dark:text-blue-400 hover:text-blue-500 dark:hover:text-blue-300"
            >
              Ist heute ein Feiertag in {@federal_state.name}?
            </.link>
          </li>
          <li>
            <.link
              navigate={~p"/ist-heute-schulfrei/#{@federal_state.slug}"}
              class="text-blue-600 dark:text-blue-400 hover:text-blue-500 dark:hover:text-blue-300"
            >
              Ist heute schulfrei in {@federal_state.name}?
            </.link>
          </li>
        </ul>
      </dd>
    </div>
    """
  end
end
