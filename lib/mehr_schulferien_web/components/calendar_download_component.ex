defmodule MehrSchulferienWeb.CalendarDownloadComponent do
  @moduledoc """
  The "Kalender zum Ausdrucken" box on state, city and school pages, the
  sibling of the iCal download box, with the paths it links to and the names
  of the formats.
  """

  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: MehrSchulferienWeb.Endpoint,
    router: MehrSchulferienWeb.Router

  alias MehrSchulferien.CalendarPdf

  # The format most people want comes first; it is the one the preview shows.
  @main_format "a4"
  @formats [
    %{
      key: "a4",
      name: "DIN A4",
      hint: "Passt auf jeden Drucker",
      description:
        "Die Jahresübersicht im Querformat, mit Ferien- und Feiertagsnamen in den Tagen. Passt auf jeden Drucker."
    },
    %{
      key: "a3",
      name: "DIN A3",
      hint: "Wandkalender",
      description:
        "Wandkalender im Querformat, 420 × 297 mm. Für Kopierer und Drucker mit A3-Fach."
    },
    %{
      key: "a5",
      name: "DIN A5",
      hint: "Für Heft und Planer",
      description: "Kompakte Jahresübersicht für Hausaufgabenheft und Planer."
    },
    %{
      key: "karte",
      name: "Kreditkartenformat",
      hint: "Fürs Portemonnaie",
      description:
        "Vier Karten auf einem A4-Blatt, je 85,6 × 54 mm, mit Schnittmarken. Ausschneiden, falten, ins Portemonnaie stecken."
    }
  ]

  if Enum.sort(Enum.map(@formats, & &1.key)) != Enum.sort(CalendarPdf.formats()) do
    raise "CalendarDownloadComponent describes other formats than CalendarPdf.formats/0 offers"
  end

  @doc "The formats with the name, short hint and description shown for them."
  def formats, do: @formats

  @doc "Path of the download page of a federal state."
  def download_path(country, federal_state, year) do
    ~p"/ferien/#{country.slug}/bundesland/#{federal_state.slug}/#{year}/download"
  end

  @doc "Path of a calendar PDF of a federal state."
  def federal_state_pdf_path(country, federal_state, year, format) do
    ~p"/ferien/#{country.slug}/bundesland/#{federal_state.slug}/#{year}/download/#{format <> ".pdf"}"
  end

  @doc "Path of a calendar PDF of a school."
  def school_pdf_path(country, school, year, format) do
    ~p"/ferien/#{country.slug}/schule/#{school.slug}/#{year}/download/#{format <> ".pdf"}"
  end

  @doc "Path of the preview image of a school's year planner."
  def school_preview_path(country, school, year) do
    ~p"/ferien/#{country.slug}/schule/#{school.slug}/#{year}/download/vorschau.svg"
  end

  @doc """
  Links to the download pages of a federal state, one per offered year out of
  `years`, the years the page knows vacations for.
  """
  attr :country, :map, required: true
  attr :federal_state, :map, required: true
  attr :years, :list, required: true
  attr :today, Date, required: true

  def federal_state_calendar_box(assigns) do
    assigns = assign(assigns, :years, CalendarPdf.offered_years(assigns.years, assigns.today))

    ~H"""
    <.calendar_box
      :if={@years != []}
      text={"Schulferien #{@federal_state.name} als PDF in A3, A4, A5 und im Kreditkartenformat."}
    >
      <div class="grid grid-cols-2 gap-2">
        <.link
          :for={year <- @years}
          href={download_path(@country, @federal_state, year)}
          class="flex items-center justify-center px-3 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 hover:bg-gray-100 dark:hover:bg-gray-600 border border-gray-300 dark:border-gray-600 rounded-md transition-colors"
        >
          PDF {year}
        </.link>
      </div>
    </.calendar_box>
    """
  end

  # The year switch works without JavaScript: a radio per year, and the panel
  # of the checked one is shown through :has(). Tailwind only generates
  # classes it finds spelled out, hence one literal pair per position; three
  # are enough for the years CalendarPdf offers.
  @year_classes [
    {"cal-year-0", "group-has-[.cal-year-0:checked]/cal:block"},
    {"cal-year-1", "group-has-[.cal-year-1:checked]/cal:block"},
    {"cal-year-2", "group-has-[.cal-year-2:checked]/cal:block"}
  ]

  @doc """
  The calendar of a school: a preview of the year planner, a switch between
  the offered years out of `years`, and the four PDFs of the chosen year.
  """
  attr :country, :map, required: true
  attr :school, :map, required: true
  attr :years, :list, required: true
  attr :today, Date, required: true

  def school_calendar_box(assigns) do
    offered = CalendarPdf.offered_years(assigns.years, assigns.today)

    assigns =
      assign(assigns,
        years: Enum.zip(offered, @year_classes),
        suggested: CalendarPdf.suggested_year(offered, assigns.today),
        formats: @formats,
        main_format: @main_format
      )

    ~H"""
    <.calendar_box
      :if={@years != []}
      class="group/cal"
      text="Der Ferienkalender dieser Schule als PDF, mit ihren beweglichen Ferientagen und ihrer Adresse."
    >
      <div class="flex flex-col sm:flex-row gap-4">
        <div class="sm:w-5/12 shrink-0">
          <.link
            :for={{year, {_input_class, panel_class}} <- @years}
            href={school_pdf_path(@country, @school, year, @main_format)}
            rel="nofollow"
            class={["hidden", panel_class]}
          >
            <img
              src={school_preview_path(@country, @school, year)}
              width="297"
              height="210"
              loading="lazy"
              alt={"Vorschau: Ferienkalender #{year}"}
              class="w-full h-auto bg-white border border-gray-300 dark:border-gray-600 rounded-sm shadow-md"
            />
          </.link>
        </div>
        <div class="flex-1 min-w-0">
          <div
            role="radiogroup"
            aria-label="Jahr"
            class={[
              "inline-flex mb-3 rounded-md border border-gray-300 dark:border-gray-600 overflow-hidden divide-x divide-gray-300 dark:divide-gray-600",
              length(@years) == 1 && "hidden"
            ]}
          >
            <label :for={{year, {input_class, _panel_class}} <- @years} class="cursor-pointer">
              <input
                type="radio"
                name="calendar-year"
                value={year}
                checked={year == @suggested}
                class={["peer sr-only", input_class]}
              />
              <span class="block px-3 py-1.5 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 hover:bg-gray-100 dark:hover:bg-gray-600 peer-checked:bg-blue-600 peer-checked:text-white peer-checked:hover:bg-blue-600 peer-focus-visible:ring-2 peer-focus-visible:ring-inset peer-focus-visible:ring-blue-400">
                {year}
              </span>
            </label>
          </div>
          <div
            :for={{year, {_input_class, panel_class}} <- @years}
            class={["hidden space-y-1.5", panel_class]}
          >
            <.link
              :for={format <- @formats}
              href={school_pdf_path(@country, @school, year, format.key)}
              rel="nofollow"
              class={[
                "flex items-baseline justify-between gap-3 px-3 py-2 text-sm font-medium rounded-md border transition-colors hover:bg-gray-100 dark:hover:bg-gray-600",
                if(format.key == @main_format,
                  do:
                    "text-blue-900 dark:text-blue-100 bg-blue-50 dark:bg-blue-900 border-blue-600 dark:border-blue-400",
                  else:
                    "text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 border-gray-300 dark:border-gray-600"
                )
              ]}
            >
              <span>{format.name}</span>
              <span class="text-xs font-normal text-gray-500 dark:text-gray-400">{format.hint}</span>
            </.link>
          </div>
        </div>
      </div>
    </.calendar_box>
    """
  end

  attr :text, :string, required: true
  attr :class, :string, default: nil
  slot :inner_block, required: true

  defp calendar_box(assigns) do
    ~H"""
    <div class={[
      "bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg p-4 mt-4",
      @class
    ]}>
      <h2 class="text-sm font-medium text-gray-900 dark:text-gray-100 mb-1 flex items-center">
        <svg
          class="w-4 h-4 mr-2 text-gray-600 dark:text-gray-400"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4H7v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"
          />
        </svg>
        Kalender zum Ausdrucken
      </h2>
      <p class="text-sm text-gray-600 dark:text-gray-400 mb-3">{@text}</p>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
