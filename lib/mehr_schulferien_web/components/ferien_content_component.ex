defmodule MehrSchulferienWeb.FerienContentComponent do
  use Phoenix.Component
  alias MehrSchulferien.Calendars.VacationSlug
  alias MehrSchulferienWeb.FerienContent

  attr :periods, :list, required: true
  attr :today, :any, required: true
  attr :federal_state, :any, required: true

  def next_vacation(assigns) do
    assigns = assign(assigns, :period, FerienContent.next_period(assigns.periods, assigns.today))

    ~H"""
    <section
      :if={@period}
      id="naechste-ferien"
      aria-labelledby="naechste-ferien-titel"
      class="mb-6 border-b border-gray-200 dark:border-gray-700 pb-5"
    >
      <h2 id="naechste-ferien-titel" class="text-lg font-semibold text-gray-900 dark:text-gray-100">
        {if Date.compare(@period.starts_on, @today) == :gt,
          do: "Nächste Ferien",
          else: "Aktuelle Ferien"}: {FerienContent.period_name(@period)}
      </h2>
      <p class="mt-2 text-xl font-semibold tabular-nums text-gray-900 dark:text-gray-100">
        <time datetime={@period.starts_on}>{Calendar.strftime(@period.starts_on, "%d.%m.%Y")}</time>
        bis <time datetime={@period.ends_on}>{Calendar.strftime(@period.ends_on, "%d.%m.%Y")}</time>
      </p>
      <a
        href={"/#{VacationSlug.url_slug(@period.holiday_or_vacation_type)}/#{@federal_state.slug}/#{@period.starts_on.year}"}
        class="mt-2 inline-block text-blue-700 dark:text-blue-300 underline underline-offset-4 hover:text-blue-900 dark:hover:text-blue-200 focus-visible:outline focus-visible:outline-2"
      >
        {FerienContent.period_name(@period)} in {@federal_state.name}: Kalender und Details
      </a>
    </section>
    """
  end

  attr :federal_state, :any, required: true

  def source_note(assigns) do
    {label, url, note} = FerienContent.source(assigns.federal_state.slug)
    assigns = assign(assigns, label: label, source_url: url, note: note)

    ~H"""
    <section
      class="mt-6 border-t border-gray-200 dark:border-gray-700 pt-5 text-sm text-gray-700 dark:text-gray-300"
      aria-label="Quellen und Hinweise"
    >
      <h2 class="font-semibold text-gray-900 dark:text-gray-100">
        Gut zu wissen für {@federal_state.name}
      </h2>
      <p :if={@note} class="mt-2 max-w-prose">{@note}</p>
      <p class="mt-2 max-w-prose">
        Die Tabelle nennt den ersten und letzten Ferientag. Die Tageszahl kann angrenzende Wochenenden und Feiertage einschließen. Schulindividuelle freie Tage erfragen Sie bitte bei Ihrer Schule.
      </p>
      <p class="mt-2">
        Amtliche Angaben: <a
          href={@source_url}
          class="text-blue-700 dark:text-blue-300 underline underline-offset-4 hover:text-blue-900 dark:hover:text-blue-200"
        >{@label}</a>.
      </p>
    </section>
    """
  end

  attr :periods, :list, required: true
  attr :all_periods, :list, required: true
  attr :today, :any, required: true
  attr :city, :any, required: true

  def school_return(assigns) do
    assigns =
      assign(
        assigns,
        :return_info,
        FerienContent.school_return(assigns.periods, assigns.all_periods, assigns.today)
      )

    ~H"""
    <section
      :if={@return_info}
      id="schulbeginn"
      class="mb-6 text-gray-700 dark:text-gray-300"
      aria-labelledby="schulbeginn-titel"
    >
      <% {period, first_day} = @return_info %>
      <h2 id="schulbeginn-titel" class="text-lg font-semibold text-gray-900 dark:text-gray-100">
        Wann beginnt die Schule in {@city.name} wieder?
      </h2>
      <p class="mt-2">
        Nach den {FerienContent.period_name(period)} ({FerienContent.dates(period)}) {if Date.compare(
                                                                                           first_day,
                                                                                           @today
                                                                                         ) == :lt,
                                                                                         do: "war",
                                                                                         else: "ist"} der erste reguläre Schultag <strong><time datetime={
            first_day
          }>{Calendar.strftime(first_day, "%d.%m.%Y")}</time></strong>.
      </p>
      <p class="mt-1 text-sm">
        Wochenenden und hinterlegte Feiertage sind berücksichtigt. Bewegliche Ferientage und Sondertermine Ihrer Schule können abweichen.
      </p>
    </section>
    """
  end

  attr :federal_state, :any, required: true
  attr :country, :any, required: true
  attr :place, :string, default: nil

  def state_link(assigns) do
    ~H"""
    <p class="my-4 text-sm text-gray-700 dark:text-gray-300">
      <span :if={@place}>{"Für #{@place} gelten die landesweiten Ferientermine."}</span>
      <a
        href={"/ferien/#{@country.slug}/bundesland/#{@federal_state.slug}"}
        class="text-blue-700 dark:text-blue-300 underline underline-offset-4 hover:text-blue-900 dark:hover:text-blue-200"
      >Alle Schulferien in {@federal_state.name}</a>.
      Bewegliche Ferientage können je nach Schule abweichen.
    </p>
    """
  end

  attr :vacation_type, :string, required: true
  attr :vacation_name, :string, required: true
  attr :year, :integer, required: true

  def national_link(assigns) do
    ~H"""
    <p class="my-4 text-sm">
      <a
        href={"/#{@vacation_type}/#{@year}"}
        class="text-blue-700 dark:text-blue-300 underline underline-offset-4 hover:text-blue-900 dark:hover:text-blue-200"
      >
        {@vacation_name} {@year} in allen Bundesländern vergleichen
      </a>
    </p>
    """
  end

  attr :year, :integer, required: true

  def national_seasons(assigns) do
    ~H"""
    <section class="my-6" aria-labelledby="ferien-vergleichen">
      <h2 id="ferien-vergleichen" class="text-xl font-semibold text-gray-900 dark:text-gray-100">
        Ferien in allen Bundesländern vergleichen
      </h2>
      <ul class="mt-3 flex flex-wrap gap-x-6 gap-y-3 text-sm">
        <%= for {slug, label} <- [{"osterferien", "Osterferien"}, {"sommerferien", "Sommerferien"}, {"herbstferien", "Herbstferien"}, {"weihnachtsferien", "Weihnachtsferien"}], year <- [@year, @year + 1] do %>
          <li>
            <a
              href={"/#{slug}/#{year}"}
              class="text-blue-700 dark:text-blue-300 underline underline-offset-4 hover:text-blue-900 dark:hover:text-blue-200"
            >
              {label} {year}
            </a>
          </li>
        <% end %>
      </ul>
      <p class="mt-4 text-sm">
        <a href="/ferien-widget" class="text-blue-700 dark:text-blue-300 underline underline-offset-4">
          Für Schulwebsites: Ferienkalender kostenlos einbinden
        </a>
      </p>
    </section>
    """
  end
end
