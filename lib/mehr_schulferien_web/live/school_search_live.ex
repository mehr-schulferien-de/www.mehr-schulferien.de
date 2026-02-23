defmodule MehrSchulferienWeb.SchoolSearchLive do
  use MehrSchulferienWeb, :live_view
  alias MehrSchulferienWeb.Live.Shared.LocationHistoryHelpers
  alias MehrSchulferienWeb.Live.Shared.SchoolSearchLogic
  import MehrSchulferienWeb.Shared.SchoolSearchFormComponent
  import MehrSchulferienWeb.Shared.LocationHistoryComponent

  @impl true
  def mount(_params, session, socket) do
    # Get federal states for the search form
    federal_states = SchoolSearchLogic.get_federal_states()

    # Get location history from session
    recent_locations = LocationHistoryHelpers.load_recent_locations(session["recent_locations"])

    {:ok,
     socket
     |> assign(
       page_title: "Schule suchen - Briefe erstellen",
       page_description:
         "Erstellen Sie kostenlos Entschuldigungen, Beurlaubungen und Sportbefreiungen für die Schule. Einfache Formulare, professionelle PDFs zum Download.",
       og_image: "/images/entschuldigung-dummy.png",
       search_params: %{"location" => "", "school_name" => "", "federal_state_id" => ""},
       schools: [],
       total_schools_found: 0,
       searching: false,
       sort_by: nil,
       sort_order: :asc,
       federal_states: federal_states,
       max_display_schools: 5_000,
       recent_locations: recent_locations
     )}
  end

  @impl true
  def handle_event("search", %{"search" => search_params}, socket) do
    {schools, total_schools, final_search_params} = perform_search(search_params, socket)

    {:noreply,
     assign(socket,
       schools: schools,
       total_schools_found: total_schools,
       searching: false,
       search_params: final_search_params
     )}
  end

  @impl true
  def handle_event("validate", %{"search" => search_params}, socket) do
    {schools, total_schools, final_search_params} = perform_search(search_params, socket)

    {:noreply,
     assign(socket,
       schools: schools,
       total_schools_found: total_schools,
       search_params: final_search_params
     )}
  end

  @impl true
  def handle_event("reset", _params, socket) do
    socket =
      socket
      |> assign(:search_params, %{
        "location" => "",
        "school_name" => "",
        "federal_state_id" => ""
      })
      |> assign(:schools, [])
      |> assign(:total_schools_found, 0)

    {:noreply, socket}
  end

  # Valid sort fields to prevent atom table exhaustion
  @valid_sort_fields ~w(name street zip_code city)a

  @impl true
  def handle_event("sort", %{"field" => field}, socket) do
    case validate_sort_field(field) do
      {:ok, field_atom} ->
        {sort_by, sort_order} =
          if socket.assigns.sort_by == field_atom do
            # Toggle order if clicking the same field
            {field_atom, if(socket.assigns.sort_order == :asc, do: :desc, else: :asc)}
          else
            # New field, default to ascending
            {field_atom, :asc}
          end

        sorted_schools =
          SchoolSearchLogic.sort_schools(socket.assigns.schools, sort_by, sort_order)

        {:noreply,
         assign(socket,
           schools: sorted_schools,
           sort_by: sort_by,
           sort_order: sort_order
         )}

      :error ->
        # Invalid sort field, ignore the request
        {:noreply, socket}
    end
  end

  # Unified search logic used by both "search" and "validate" events
  defp perform_search(search_params, socket) do
    location = Map.get(search_params, "location", "")
    school_name = Map.get(search_params, "school_name", "")
    federal_state_id = Map.get(search_params, "federal_state_id", "")

    search_params_for_query = SchoolSearchLogic.convert_search_params(search_params)

    {schools, updated_params} =
      cond do
        # All fields empty - clear results
        federal_state_id == "" and location == "" and school_name == "" ->
          {[], search_params}

        # Only federal state selected
        federal_state_id != "" and location == "" and school_name == "" ->
          schools = SchoolSearchLogic.search_schools_by_federal_state(federal_state_id)
          {schools, search_params}

        # Zip code search
        SchoolSearchLogic.is_partial_or_full_zip_code?(location) ->
          results =
            SchoolSearchLogic.search_schools_by_zip(location, school_name, federal_state_id)

          schools = SchoolSearchLogic.results_to_schools(results)
          updated_params = maybe_detect_federal_state(results, search_params)
          {schools, updated_params}

        # Location/school name search
        String.length(location) >= 1 or String.length(school_name) >= 1 ->
          results =
            search_by_location_or_name(search_params_for_query, school_name, federal_state_id)

          schools = SchoolSearchLogic.results_to_schools(results)

          updated_params =
            maybe_detect_federal_state(results, search_params, federal_state_id == "")

          {schools, updated_params}

        # No search criteria
        true ->
          {[], search_params}
      end

    total_schools = length(schools)

    displayed_schools =
      schools
      |> Enum.take(socket.assigns.max_display_schools)
      |> SchoolSearchLogic.sort_schools(socket.assigns.sort_by, socket.assigns.sort_order)

    {displayed_schools, total_schools, updated_params}
  end

  # Helper to search by location or school name
  defp search_by_location_or_name(search_params_for_query, school_name, federal_state_id) do
    city = search_params_for_query["city"]

    cond do
      city != "" and school_name != "" ->
        SchoolSearchLogic.search_schools_by_city(city, school_name, federal_state_id)

      city != "" ->
        SchoolSearchLogic.search_schools_by_city(city, "", federal_state_id)

      school_name != "" ->
        SchoolSearchLogic.search_schools_by_name(school_name, federal_state_id)

      true ->
        []
    end
  end

  # Helper to detect and set federal state when exactly one city in results
  defp maybe_detect_federal_state(results, search_params, check_empty_state \\ true) do
    cities_with_schools = SchoolSearchLogic.group_schools_by_city(results)

    if length(cities_with_schools) == 1 and check_empty_state do
      case SchoolSearchLogic.detect_single_federal_state(results) do
        nil -> search_params
        detected_state -> Map.put(search_params, "federal_state_id", detected_state)
      end
    else
      search_params
    end
  end

  defp validate_sort_field(field) when is_binary(field) do
    atom = String.to_existing_atom(field)
    if atom in @valid_sort_fields, do: {:ok, atom}, else: :error
  rescue
    ArgumentError -> :error
  end

  defp validate_sort_field(_), do: :error

  # Sort schools and get_federal_states now delegated to SchoolSearchLogic

  # Number formatting helper
  defp format_number(number) when is_integer(number) do
    SchoolSearchLogic.format_number(number)
  end

  # Location history helpers now delegated to LocationHistoryHelpers module

  defp should_show_recent_locations(search_params) do
    LocationHistoryHelpers.should_show_recent_locations(search_params)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <nav class="flex items-center space-x-2 text-sm text-gray-500 mb-6" aria-label="Breadcrumb">
        <a href="/" class="hover:text-gray-700">
          <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
            <path d="M10.707 2.293a1 1 0 00-1.414 0l-7 7a1 1 0 001.414 1.414L4 10.414V17a1 1 0 001 1h2a1 1 0 001-1v-2a1 1 0 011-1h2a1 1 0 011 1v2a1 1 0 001 1h2a1 1 0 001-1v-6.586l.293.293a1 1 0 001.414-1.414l-7-7z" />
          </svg>
        </a>
        <svg class="w-5 h-5 text-gray-400" fill="currentColor" viewBox="0 0 20 20">
          <path
            fill-rule="evenodd"
            d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
            clip-rule="evenodd"
          />
        </svg>
        <span class="text-gray-700">Schule suchen</span>
      </nav>

      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between mb-8">
        <div>
          <h1 class="text-3xl font-bold text-gray-900 mb-2">Schule suchen</h1>
          <p class="text-gray-600">
            Finden Sie Ihre Schule, um Entschuldigungen, Beurlaubungen oder Sportbefreiungen zu erstellen.
          </p>
        </div>
        <div class="mt-4 sm:mt-0">
          <a
            href="/wiki/schools/new"
            class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500"
          >
            <svg class="mr-2 -ml-1 w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M12 4v16m8-8H4"
              />
            </svg>
            Neue Schule anlegen
          </a>
        </div>
      </div>

      <.school_search_form
        federal_states={@federal_states}
        show_federal_state={true}
        search_params={@search_params}
        searching={@searching}
        autofocus_field={:location}
      >
        <:below_form>
          <.location_history
            recent_locations={@recent_locations}
            show={should_show_recent_locations(@search_params)}
          />
        </:below_form>
      </.school_search_form>

      <%= cond do %>
        <% @total_schools_found > @max_display_schools -> %>
          <div class="bg-blue-50 border-l-4 border-blue-400 p-4 rounded-lg">
            <div class="flex">
              <div class="flex-shrink-0">
                <svg
                  class="h-5 w-5 text-blue-400"
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                >
                  <path
                    fill-rule="evenodd"
                    d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z"
                    clip-rule="evenodd"
                  />
                </svg>
              </div>
              <div class="ml-3">
                <p class="text-sm text-blue-700">
                  {format_number(@total_schools_found)} Schulen gefunden. Bitte geben Sie genauere Suchkriterien ein.
                </p>
              </div>
            </div>
          </div>
        <% length(@schools) > 0 -> %>
          <div class="bg-white shadow-sm rounded-lg overflow-hidden">
            <div class="px-6 py-4 border-b border-gray-200">
              <h2 class="text-xl font-semibold text-gray-900">
                <%= cond do %>
                  <% String.length(@search_params["location"] || "") >= 1 and String.length(@search_params["school_name"] || "") >= 1 -> %>
                    Suchergebnisse für
                    <%= if SchoolSearchLogic.is_partial_or_full_zip_code?(@search_params["location"]) do %>
                      PLZ {@search_params["location"]}
                    <% else %>
                      "{@search_params["location"]}"
                    <% end %>
                    und "{@search_params["school_name"]}"
                  <% String.length(@search_params["location"] || "") >= 1 -> %>
                    Suchergebnisse für
                    <%= if SchoolSearchLogic.is_partial_or_full_zip_code?(@search_params["location"]) do %>
                      PLZ {@search_params["location"]}
                    <% else %>
                      "{@search_params["location"]}"
                    <% end %>
                  <% String.length(@search_params["school_name"] || "") >= 1 -> %>
                    Suchergebnisse für "{@search_params["school_name"]}"
                  <% @search_params["federal_state_id"] != "" -> %>
                    Suchergebnisse
                  <% true -> %>
                    Suchergebnisse
                <% end %>
                ({@total_schools_found} {if @total_schools_found == 1,
                  do: "Schule",
                  else: "Schulen"} gefunden)
              </h2>
            </div>
            <table class="w-full divide-y divide-gray-200 table-fixed">
              <colgroup>
                <col class="w-1/2 sm:w-2/5" />
                <col class="hidden sm:table-column sm:w-1/4" />
                <col class="w-1/6 sm:w-1/12" />
                <col class="w-1/3 sm:w-1/4" />
              </colgroup>
              <thead class="bg-gray-50">
                <tr>
                  <th
                    class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100 transition-colors"
                    phx-click="sort"
                    phx-value-field="name"
                  >
                    <div class="flex items-center space-x-1 group">
                      <span>Schulname</span>
                      <div class="flex flex-col">
                        <%= if @sort_by == :name do %>
                          <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                            <%= if @sort_order == :asc do %>
                              <path d="M5 12l5-5 5 5H5z" />
                            <% else %>
                              <path d="M15 8l-5 5-5-5h10z" />
                            <% end %>
                          </svg>
                        <% else %>
                          <svg
                            class="w-4 h-4 text-gray-400 group-hover:text-gray-600"
                            fill="currentColor"
                            viewBox="0 0 20 20"
                          >
                            <path d="M7 10l5 5 5-5H7z" />
                            <path d="M7 10l5-5 5 5H7z" opacity="0.5" />
                          </svg>
                        <% end %>
                      </div>
                    </div>
                  </th>
                  <th
                    class="hidden sm:table-cell px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100 transition-colors"
                    phx-click="sort"
                    phx-value-field="street"
                  >
                    <div class="flex items-center space-x-1 group">
                      <span>Straße</span>
                      <div class="flex flex-col">
                        <%= if @sort_by == :street do %>
                          <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                            <%= if @sort_order == :asc do %>
                              <path d="M5 12l5-5 5 5H5z" />
                            <% else %>
                              <path d="M15 8l-5 5-5-5h10z" />
                            <% end %>
                          </svg>
                        <% else %>
                          <svg
                            class="w-4 h-4 text-gray-400 group-hover:text-gray-600"
                            fill="currentColor"
                            viewBox="0 0 20 20"
                          >
                            <path d="M7 10l5 5 5-5H7z" />
                            <path d="M7 10l5-5 5 5H7z" opacity="0.5" />
                          </svg>
                        <% end %>
                      </div>
                    </div>
                  </th>
                  <th
                    class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100 transition-colors"
                    phx-click="sort"
                    phx-value-field="zip_code"
                  >
                    <div class="flex items-center space-x-1 group">
                      <span>PLZ</span>
                      <div class="flex flex-col">
                        <%= if @sort_by == :zip_code do %>
                          <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                            <%= if @sort_order == :asc do %>
                              <path d="M5 12l5-5 5 5H5z" />
                            <% else %>
                              <path d="M15 8l-5 5-5-5h10z" />
                            <% end %>
                          </svg>
                        <% else %>
                          <svg
                            class="w-4 h-4 text-gray-400 group-hover:text-gray-600"
                            fill="currentColor"
                            viewBox="0 0 20 20"
                          >
                            <path d="M7 10l5 5 5-5H7z" />
                            <path d="M7 10l5-5 5 5H7z" opacity="0.5" />
                          </svg>
                        <% end %>
                      </div>
                    </div>
                  </th>
                  <th
                    class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider cursor-pointer hover:bg-gray-100 transition-colors"
                    phx-click="sort"
                    phx-value-field="city"
                  >
                    <div class="flex items-center space-x-1 group">
                      <span>Stadt</span>
                      <div class="flex flex-col">
                        <%= if @sort_by == :city do %>
                          <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                            <%= if @sort_order == :asc do %>
                              <path d="M5 12l5-5 5 5H5z" />
                            <% else %>
                              <path d="M15 8l-5 5-5-5h10z" />
                            <% end %>
                          </svg>
                        <% else %>
                          <svg
                            class="w-4 h-4 text-gray-400 group-hover:text-gray-600"
                            fill="currentColor"
                            viewBox="0 0 20 20"
                          >
                            <path d="M7 10l5 5 5-5H7z" />
                            <path d="M7 10l5-5 5 5H7z" opacity="0.5" />
                          </svg>
                        <% end %>
                      </div>
                    </div>
                  </th>
                </tr>
              </thead>
              <tbody class="bg-white divide-y divide-gray-200">
                <%= for school <- @schools do %>
                  <tr class="hover:bg-gray-50">
                    <td class="px-4 py-3">
                      <a
                        href={"/briefe/#{school.slug}"}
                        class="text-blue-600 hover:text-blue-900 font-medium block truncate pr-2"
                        title={school.name}
                      >
                        {school.name}
                      </a>
                    </td>
                    <td class="hidden sm:table-cell px-4 py-3 text-sm text-gray-900">
                      <%= if school.address do %>
                        <span class="block truncate pr-2" title={school.address.street}>
                          {school.address.street}
                        </span>
                      <% else %>
                        <span class="text-gray-500">-</span>
                      <% end %>
                    </td>
                    <td class="px-4 py-3 text-sm text-gray-900">
                      <%= if school.address && school.address.zip_code do %>
                        {school.address.zip_code}
                      <% else %>
                        <span class="text-gray-500">-</span>
                      <% end %>
                    </td>
                    <td class="px-4 py-3 text-sm text-gray-900">
                      <%= if school.parent_location do %>
                        <span class="block truncate pr-2" title={school.parent_location.name}>
                          {school.parent_location.name}
                        </span>
                      <% else %>
                        <span class="text-gray-500">-</span>
                      <% end %>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        <% true -> %>
          <%= if @search_params != %{"location" => "", "school_name" => "", "federal_state_id" => ""} do %>
            <div class="bg-blue-50 border-l-4 border-blue-400 p-4 rounded-lg">
              <div class="flex">
                <div class="flex-shrink-0">
                  <svg
                    class="h-5 w-5 text-blue-400"
                    xmlns="http://www.w3.org/2000/svg"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z"
                      clip-rule="evenodd"
                    />
                  </svg>
                </div>
                <div class="ml-3">
                  <p class="text-sm text-blue-700">
                    Keine Schulen gefunden. Bitte versuchen Sie es mit anderen Suchkriterien.
                  </p>
                  <p class="text-sm text-blue-700 mt-1">
                    Falls Ihre Schule noch nicht in unserer Datenbank ist, können Sie diese <a
                      href="/wiki/schools/new"
                      class="underline font-medium"
                    >
                    hier anlegen
                  </a>.
                  </p>
                </div>
              </div>
            </div>
          <% end %>
      <% end %>
    </div>
    """
  end
end
