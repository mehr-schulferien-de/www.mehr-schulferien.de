defmodule MehrSchulferienWeb.CalendarDownloadComponent do
  @moduledoc """
  The "Kalender zum Ausdrucken" box on state, city and school pages, the
  sibling of the iCal download box, and the paths it links to.
  """

  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: MehrSchulferienWeb.Endpoint,
    router: MehrSchulferienWeb.Router

  alias MehrSchulferien.CalendarPdf

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

  @doc """
  Links to the download pages of a federal state, one per offered year out of
  `years`, the years the page knows vacations for.
  """
  attr :country, :map, required: true
  attr :federal_state, :map, required: true
  attr :years, :list, required: true
  attr :today, Date, required: true

  def federal_state_calendar_box(assigns) do
    assigns =
      assign(
        assigns,
        :links,
        for year <- CalendarPdf.offered_years(assigns.years, assigns.today) do
          %{
            label: "PDF #{year}",
            href: download_path(assigns.country, assigns.federal_state, year)
          }
        end
      )

    ~H"""
    <.calendar_box
      text={"Schulferien #{@federal_state.name} als PDF in A3, A4, A5 und im Kreditkartenformat."}
      links={@links}
    />
    """
  end

  @doc "Links to the PDFs of a school, one per offered year and format."
  attr :country, :map, required: true
  attr :school, :map, required: true
  attr :years, :list, required: true
  attr :today, Date, required: true

  def school_calendar_box(assigns) do
    assigns =
      assign(
        assigns,
        :links,
        for year <- CalendarPdf.offered_years(assigns.years, assigns.today),
            format <- CalendarPdf.formats() do
          %{
            label: "#{year} #{short_label(format)}",
            href: school_pdf_path(assigns.country, assigns.school, year, format)
          }
        end
      )

    ~H"""
    <.calendar_box
      text="Der Ferienkalender dieser Schule als PDF, mit ihren beweglichen Ferientagen und ihrer Adresse."
      links={@links}
      rel="nofollow"
    />
    """
  end

  attr :text, :string, required: true
  attr :links, :list, required: true
  attr :rel, :string, default: nil

  defp calendar_box(assigns) do
    ~H"""
    <div
      :if={@links != []}
      class="bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg p-4 mt-4"
    >
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
      <div class="grid grid-cols-2 gap-2">
        <.link
          :for={link <- @links}
          href={link.href}
          rel={@rel}
          class="flex items-center justify-center px-3 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 hover:bg-gray-100 dark:hover:bg-gray-600 border border-gray-300 dark:border-gray-600 rounded-md transition-colors"
        >
          {link.label}
        </.link>
      </div>
    </div>
    """
  end

  defp short_label("karte"), do: "Karte"
  defp short_label(format), do: String.upcase(format)
end
