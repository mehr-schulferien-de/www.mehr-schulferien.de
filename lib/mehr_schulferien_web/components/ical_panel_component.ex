defmodule MehrSchulferienWeb.ICalPanelComponent do
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: MehrSchulferienWeb.Endpoint,
    router: MehrSchulferienWeb.Router

  attr :conn, :map, required: true
  attr :entity_slug, :string, required: true
  attr :entity_name, :string, required: true
  attr :year, :integer, required: true
  attr :entity_type, :string, default: nil
  attr :api_version, :string, default: "v2.1"

  def ical_panel(assigns) do
    assigns =
      assigns
      |> assign_new(:ical_urls, fn %{
                                     entity_slug: slug,
                                     entity_type: type,
                                     year: year,
                                     api_version: version
                                   } ->
        generate_ical_urls(slug, type, year, version)
      end)

    ~H"""
    <div class="bg-white p-4 rounded-lg shadow-sm">
      <h2 class="text-xl font-bold text-gray-900 mb-3">Feriendaten im iCal-Format</h2>
      <p class="text-gray-700 mb-3 text-sm">
        Importieren Sie die Schulferiendaten in Ihren Terminkalender:
      </p>
      <ul class="space-y-2 list-disc pl-5 text-sm">
        <li>
          <.link
            href={@ical_urls.calendar_year}
            class="text-blue-600 hover:text-blue-800 cursor-pointer"
          >
            iCal Schulferien {@entity_name} {@year}
          </.link>
        </li>
        <li>
          <.link
            href={@ical_urls.school_year_previous}
            class="text-blue-600 hover:text-blue-800 cursor-pointer"
          >
            iCal Schuljahr {@year - 1}/{@year} {@entity_name}
          </.link>
        </li>
        <li>
          <.link
            href={@ical_urls.school_year_current}
            class="text-blue-600 hover:text-blue-800 cursor-pointer"
          >
            iCal Schuljahr {@year}/{@year + 1} {@entity_name}
          </.link>
        </li>
      </ul>
    </div>
    """
  end

  defp generate_ical_urls(slug, type, year, "v2.1") do
    base_path = get_v21_base_path(type)

    if base_path do
      %{
        calendar_year:
          "#{base_path}/#{slug}/icalendar?vacation_types=school&year=#{year}&calendar_year=true",
        school_year_previous:
          "#{base_path}/#{slug}/icalendar?vacation_types=school&year=#{year - 1}",
        school_year_current: "#{base_path}/#{slug}/icalendar?vacation_types=school&year=#{year}"
      }
    else
      # Fallback to v2.0 if type is not supported
      generate_ical_urls(slug, type, year, "v2.0")
    end
  end

  defp generate_ical_urls(slug, _type, year, _version) do
    # Fallback to v2.0 API
    %{
      calendar_year:
        ~p"/api/v2.0/icalendars/location/#{slug}?vacation_types=school&year=#{year}&calendar_year=true",
      school_year_previous:
        ~p"/api/v2.0/icalendars/location/#{slug}?vacation_types=school&year=#{year - 1}",
      school_year_current:
        ~p"/api/v2.0/icalendars/location/#{slug}?vacation_types=school&year=#{year}"
    }
  end

  defp get_v21_base_path("school"), do: "/api/v2.1/schools"
  defp get_v21_base_path("city"), do: "/api/v2.1/cities"
  defp get_v21_base_path("federal_state"), do: "/api/v2.1/federal-states"
  defp get_v21_base_path("county"), do: "/api/v2.1/counties"
  defp get_v21_base_path(_), do: nil
end
