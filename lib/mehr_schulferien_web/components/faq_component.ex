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

  def faq(assigns) do
    sorted_periods =
      Enum.sort(
        assigns.public_periods ++ assigns.school_periods,
        &(Date.compare(&1.starts_on, &2.starts_on) == :lt)
      )

    next_schulferien_periods = MehrSchulferien.Periods.next_periods(sorted_periods, 3)
    grouped_periods = Enum.chunk_by(sorted_periods, & &1.starts_on.year)

    assigns = assign(assigns, :sorted_periods, sorted_periods)
    assigns = assign(assigns, :next_schulferien_periods, next_schulferien_periods)
    assigns = assign(assigns, :grouped_periods, grouped_periods)

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
            <div>
              <dt class="text-base font-semibold text-gray-900">
                Wann sind die nächsten Schulferien in <%= @federal_state.name %>?
              </dt>
              <dd class="mt-2 text-sm text-gray-600">
                <%= FaqViewHelpers.next_school_vacation_answer(@location, @school_periods) %>
              </dd>
            </div>

            <div>
              <dt class="text-base font-semibold text-gray-900">
                War gestern schulfrei in <%= @location.name %>?
              </dt>
              <dd class="mt-2 text-sm text-gray-600">
                <%= FaqViewHelpers.is_off_school_answer(
                  @yesterdays_school_free_periods,
                  @yesterday,
                  @location
                ) %>
              </dd>
            </div>

            <div>
              <dt class="text-base font-semibold text-gray-900">
                Ist heute schulfrei in <%= @location.name %>?
              </dt>
              <dd class="mt-2 text-sm text-gray-600">
                <%= FaqViewHelpers.is_off_school_answer(
                  @todays_school_free_periods,
                  @today,
                  @location
                ) %>
              </dd>
            </div>

            <div>
              <dt class="text-base font-semibold text-gray-900">
                Ist morgen schulfrei in <%= @location.name %>?
              </dt>
              <dd class="mt-2 text-sm text-gray-600">
                <%= FaqViewHelpers.is_off_school_answer(
                  @tomorrows_school_free_periods,
                  @tomorrow,
                  @location
                ) %>
              </dd>
            </div>

            <div>
              <dt class="text-base font-semibold text-gray-900">
                Ist übermorgen schulfrei in <%= @location.name %>?
              </dt>
              <dd class="mt-2 text-sm text-gray-600">
                <%= FaqViewHelpers.is_off_school_answer(
                  @day_after_tomorrows_school_free_periods,
                  @day_after_tomorrow,
                  @location
                ) %>
              </dd>
            </div>

            <div>
              <dt class="text-base font-semibold text-gray-900">
                Für welche Städte in <%= @federal_state.name %> gelten diese Feriendaten?
              </dt>
              <dd class="mt-2 text-sm text-gray-600">
                <%= link("Liste der Landkreise und Städte in #{@federal_state.name}.",
                  to:
                    Routes.federal_state_path(@conn, :county_show, @country.slug, @federal_state.slug),
                  class: "font-semibold text-blue-600 hover:text-blue-500"
                ) %>
              </dd>
            </div>

            <%= for periods <- @grouped_periods do %>
              <% first_period = Enum.at(periods, 0) %>
              <div>
                <dt class="text-base font-semibold text-gray-900">
                  Schulfrei <%= @location.name %> <%= first_period.starts_on.year %>
                </dt>
                <dd class="mt-2 text-sm text-gray-600">
                  <%= for period <- periods do %>
                    <span>
                      <%= period.holiday_or_vacation_type.colloquial %> &nbsp;(<%= ViewHelpers.format_date_range(
                        period.starts_on,
                        period.ends_on,
                        :short
                      ) %>)
                      <%= unless period == List.last(periods) do %>
                        ,&nbsp;
                      <% end %>
                    </span>
                  <% end %>
                </dd>
              </div>
            <% end %>
            <!-- Public Holidays Section -->
            <div class="sm:col-span-2 mt-8">
              <h3 class="text-lg font-semibold text-gray-900 mb-4">Feiertage</h3>
            </div>

            <div>
              <dt class="text-base font-semibold text-gray-900">
                War gestern ein Feiertag in <%= @location.name %>?
              </dt>
              <dd class="mt-2 text-sm text-gray-600">
                <%= FaqViewHelpers.is_public_holiday_answer(
                  @yesterdays_public_holiday_periods,
                  @yesterday,
                  @location
                ) %>
              </dd>
            </div>

            <div>
              <dt class="text-base font-semibold text-gray-900">
                Ist heute ein Feiertag in <%= @location.name %>?
              </dt>
              <dd class="mt-2 text-sm text-gray-600">
                <%= FaqViewHelpers.is_public_holiday_answer(
                  @todays_public_holiday_periods,
                  @today,
                  @location
                ) %>
              </dd>
            </div>

            <div>
              <dt class="text-base font-semibold text-gray-900">
                Ist morgen ein Feiertag in <%= @location.name %>?
              </dt>
              <dd class="mt-2 text-sm text-gray-600">
                <%= FaqViewHelpers.is_public_holiday_answer(
                  @tomorrows_public_holiday_periods,
                  @tomorrow,
                  @location
                ) %>
              </dd>
            </div>

            <div>
              <dt class="text-base font-semibold text-gray-900">
                Ist übermorgen ein Feiertag in <%= @location.name %>?
              </dt>
              <dd class="mt-2 text-sm text-gray-600">
                <%= FaqViewHelpers.is_public_holiday_answer(
                  @day_after_tomorrows_public_holiday_periods,
                  @day_after_tomorrow,
                  @location
                ) %>
              </dd>
            </div>

            <div>
              <dt class="text-base font-semibold text-gray-900">
                Wann ist der nächste Feiertag in <%= @location.name %>?
              </dt>
              <dd class="mt-2 text-sm text-gray-600">
                <% public_periods = Enum.filter(@public_periods, & &1.is_public_holiday) %>
                <%= FaqViewHelpers.next_public_holiday_answer(@location, public_periods) %>
              </dd>
            </div>
          </dl>
        </div>
      </div>
    </div>

    <.schema_org_faq
      location={@location}
      federal_state={@federal_state}
      yesterdays_school_free_periods={@yesterdays_school_free_periods}
      todays_school_free_periods={@todays_school_free_periods}
      tomorrows_school_free_periods={@tomorrows_school_free_periods}
      day_after_tomorrows_school_free_periods={@day_after_tomorrows_school_free_periods}
      yesterdays_public_holiday_periods={@yesterdays_public_holiday_periods}
      todays_public_holiday_periods={@todays_public_holiday_periods}
      tomorrows_public_holiday_periods={@tomorrows_public_holiday_periods}
      day_after_tomorrows_public_holiday_periods={@day_after_tomorrows_public_holiday_periods}
      today={@today}
      yesterday={@yesterday}
      tomorrow={@tomorrow}
      day_after_tomorrow={@day_after_tomorrow}
      school_periods={@school_periods}
      public_periods={@public_periods}
      next_schulferien_periods={@next_schulferien_periods}
      grouped_periods={@grouped_periods}
    />
    """
  end

  attr :location, :any, required: true
  attr :federal_state, :any, required: true
  attr :yesterdays_school_free_periods, :list, required: true
  attr :todays_school_free_periods, :list, required: true
  attr :tomorrows_school_free_periods, :list, required: true
  attr :day_after_tomorrows_school_free_periods, :list, required: true
  attr :yesterdays_public_holiday_periods, :list, required: true
  attr :todays_public_holiday_periods, :list, required: true
  attr :tomorrows_public_holiday_periods, :list, required: true
  attr :day_after_tomorrows_public_holiday_periods, :list, required: true
  attr :today, :any, required: true
  attr :yesterday, :any, required: true
  attr :tomorrow, :any, required: true
  attr :day_after_tomorrow, :any, required: true
  attr :school_periods, :list, required: true
  attr :public_periods, :list, required: true
  attr :next_schulferien_periods, :list, required: true
  attr :grouped_periods, :list, required: true

  def schema_org_faq(assigns) do
    ~H"""
    <script type="application/ld+json">
      {
        "@context": "https://schema.org",
        "@type": "FAQPage",
        "mainEntity": [{
          "@type": "Question",
          "name": "War gestern schulfrei in <%= @location.name %>?",
          "acceptedAnswer": {
            "@type": "Answer",
            "text": "<%= FaqViewHelpers.is_off_school_answer(@yesterdays_school_free_periods, @yesterday, @location) %> "
          }
        },
        {
            "@type": "Question",
            "name": "Ist heute schulfrei in <%= @location.name %>?",
            "acceptedAnswer": {
              "@type": "Answer",
              "text": "<%= FaqViewHelpers.is_off_school_answer(@todays_school_free_periods, @today, @location) %>"
            }
        },
        {
            "@type": "Question",
            "name": "Ist morgen schulfrei in <%= @location.name %>?",
            "acceptedAnswer": {
              "@type": "Answer",
              "text": "<%= FaqViewHelpers.is_off_school_answer(@tomorrows_school_free_periods, @tomorrow, @location) %>"
            }
        },
        {
            "@type": "Question",
            "name": "Ist übermorgen schulfrei in <%= @location.name %>?",
            "acceptedAnswer": {
              "@type": "Answer",
              "text": "<%= FaqViewHelpers.is_off_school_answer(@day_after_tomorrows_school_free_periods, @day_after_tomorrow, @location) %>"
            }
        },
        {
            "@type": "Question",
            "name": "Wann sind die nächsten Schulferien in <%= @federal_state.name %>?",
            "acceptedAnswer": {
              "@type": "Answer",
              "text": "<%= FaqViewHelpers.next_school_vacation_answer(@location, @school_periods) %>"
            }
        },
        {
            "@type": "Question",
            "name": "Schulferien <%= @location.name %>?",
            "acceptedAnswer": {
              "@type": "Answer",
              "text": "<%= Enum.map_join(@next_schulferien_periods, " ", &"#{&1.holiday_or_vacation_type.colloquial} (#{ViewHelpers.format_date_range(&1.starts_on, &1.ends_on, :short)})") %>"
            }
        },
        <%= for periods <- @grouped_periods do %>
          <% first_period = Enum.at(periods, 0) %>
          {
              "@type": "Question",
              "name": "Schulferien <%= @location.name %> <%= first_period.starts_on.year %>",
              "acceptedAnswer": {
                "@type": "Answer",
                "text": "<%= Enum.map_join(periods, " ", &"#{&1.holiday_or_vacation_type.colloquial} (#{ViewHelpers.format_date_range(&1.starts_on, &1.ends_on, :short)})") %>"
              }
          },
        <% end %>
        {
            "@type": "Question",
            "name": "War gestern ein Feiertag in <%= @location.name %>?",
            "acceptedAnswer": {
              "@type": "Answer",
              "text": "<%= FaqViewHelpers.is_public_holiday_answer(@yesterdays_public_holiday_periods, @yesterday, @location) %>"
            }
        },
        {
            "@type": "Question",
            "name": "Ist heute ein Feiertag in <%= @location.name %>?",
            "acceptedAnswer": {
              "@type": "Answer",
              "text": "<%= FaqViewHelpers.is_public_holiday_answer(@todays_public_holiday_periods, @today, @location) %>"
            }
        },
        {
            "@type": "Question",
            "name": "Ist morgen ein Feiertag in <%= @location.name %>?",
            "acceptedAnswer": {
              "@type": "Answer",
              "text": "<%= FaqViewHelpers.is_public_holiday_answer(@tomorrows_public_holiday_periods, @tomorrow, @location) %>"
            }
        },
        {
            "@type": "Question",
            "name": "Ist übermorgen ein Feiertag in <%= @location.name %>?",
            "acceptedAnswer": {
              "@type": "Answer",
              "text": "<%= FaqViewHelpers.is_public_holiday_answer(@day_after_tomorrows_public_holiday_periods, @day_after_tomorrow, @location) %>"
            }
        },
        {
            "@type": "Question",
            "name": "Wann ist der nächste Feiertag in <%= @location.name %>?",
            "acceptedAnswer": {
              "@type": "Answer",
              "text": "<%= FaqViewHelpers.next_public_holiday_answer(@location, Enum.filter(@public_periods, & &1.is_public_holiday)) %>"
            }
        }
        ]
      }
    </script>
    """
  end
end
