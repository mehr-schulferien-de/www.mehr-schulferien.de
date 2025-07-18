defmodule MehrSchulferienWeb.SchoolSearchLive do
  use MehrSchulferienWeb, :live_view
  alias MehrSchulferien.Locations

  @impl true
  def mount(_params, _session, socket) do
    # Get federal states for the search form
    federal_states = get_federal_states()

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
       max_display_schools: 5_000
     )}
  end

  @impl true
  def handle_event("search", %{"search" => search_params}, socket) do
    location = Map.get(search_params, "location", "")
    school_name = Map.get(search_params, "school_name", "")
    federal_state_id = Map.get(search_params, "federal_state_id", "")

    # Convert location to appropriate field for search
    search_params_for_query = convert_search_params(search_params)

    {schools, total_schools, final_search_params} =
      cond do
        # Special case: only federal state is selected (optimize for performance)
        federal_state_id != "" and location == "" and school_name == "" ->
          schools = search_schools_by_federal_state(federal_state_id)
          {schools, length(schools), search_params}

        # Check if location is a zip code
        String.length(location) == 5 and Regex.match?(~r/^\d{5}$/, location) ->
          schools = Locations.search_schools(search_params_for_query)

          # Detect federal state from schools found
          updated_search_params =
            if length(schools) > 0 do
              federal_states =
                schools
                |> Enum.map(fn school ->
                  school.parent_location &&
                    school.parent_location.parent_location &&
                    school.parent_location.parent_location.parent_location_id
                end)
                |> Enum.filter(& &1)
                |> Enum.uniq()

              # If all schools are in the same federal state, auto-select it
              if length(federal_states) == 1 do
                Map.put(search_params, "federal_state_id", to_string(hd(federal_states)))
              else
                search_params
              end
            else
              search_params
            end

          {schools, length(schools), updated_search_params}

        # Regular search  
        true ->
          schools = Locations.search_schools(search_params_for_query)

          # Filter by federal state if selected
          schools =
            if federal_state_id != "" do
              Enum.filter(schools, fn school ->
                school.parent_location &&
                  school.parent_location.parent_location &&
                  to_string(school.parent_location.parent_location.parent_location_id) ==
                    federal_state_id
              end)
            else
              schools
            end

          {schools, length(schools), search_params}
      end

    # Limit displayed schools to max_display_schools
    displayed_schools =
      schools
      |> Enum.take(socket.assigns.max_display_schools)
      |> sort_schools(socket.assigns.sort_by, socket.assigns.sort_order)

    {:noreply,
     assign(socket,
       schools: displayed_schools,
       total_schools_found: total_schools,
       searching: false,
       search_params: final_search_params
     )}
  end

  @impl true
  def handle_event("validate", %{"search" => search_params}, socket) do
    location = Map.get(search_params, "location", "")
    school_name = Map.get(search_params, "school_name", "")
    federal_state_id = Map.get(search_params, "federal_state_id", "")

    # Convert location to appropriate field for search
    search_params_for_query = convert_search_params(search_params)

    # Trigger search if any field has sufficient characters
    socket =
      cond do
        # If all fields are empty, clear the results
        federal_state_id == "" and location == "" and school_name == "" ->
          assign(socket,
            schools: [],
            total_schools_found: 0,
            search_params: search_params
          )

        # Special case: only federal state is selected (optimize for performance)
        federal_state_id != "" and location == "" and school_name == "" ->
          schools = search_schools_by_federal_state(federal_state_id)
          total_schools = length(schools)

          # Limit displayed schools to max_display_schools
          displayed_schools =
            schools
            |> Enum.take(socket.assigns.max_display_schools)
            |> sort_schools(socket.assigns.sort_by, socket.assigns.sort_order)

          assign(socket,
            schools: displayed_schools,
            total_schools_found: total_schools,
            search_params: search_params
          )

        # Check if location is a zip code
        String.length(location) == 5 and Regex.match?(~r/^\d{5}$/, location) ->
          schools = Locations.search_schools(search_params_for_query)

          # Detect federal state from schools found
          updated_search_params =
            if length(schools) > 0 do
              federal_states =
                schools
                |> Enum.map(fn school ->
                  school.parent_location &&
                    school.parent_location.parent_location &&
                    school.parent_location.parent_location.parent_location_id
                end)
                |> Enum.filter(& &1)
                |> Enum.uniq()

              # If all schools are in the same federal state, auto-select it
              if length(federal_states) == 1 do
                Map.put(search_params, "federal_state_id", to_string(hd(federal_states)))
              else
                search_params
              end
            else
              search_params
            end

          total_schools = length(schools)

          # Limit displayed schools to max_display_schools
          displayed_schools =
            schools
            |> Enum.take(socket.assigns.max_display_schools)
            |> sort_schools(socket.assigns.sort_by, socket.assigns.sort_order)

          assign(socket,
            schools: displayed_schools,
            total_schools_found: total_schools,
            search_params: updated_search_params
          )

        # Regular search with multiple criteria
        String.length(location) >= 2 or String.length(school_name) >= 2 ->
          schools = Locations.search_schools(search_params_for_query)

          # Filter by federal state if selected
          schools =
            if federal_state_id != "" do
              Enum.filter(schools, fn school ->
                school.parent_location &&
                  school.parent_location.parent_location &&
                  to_string(school.parent_location.parent_location.parent_location_id) ==
                    federal_state_id
              end)
            else
              schools
            end

          total_schools = length(schools)

          # Limit displayed schools to max_display_schools
          displayed_schools =
            schools
            |> Enum.take(socket.assigns.max_display_schools)
            |> sort_schools(socket.assigns.sort_by, socket.assigns.sort_order)

          assign(socket,
            schools: displayed_schools,
            total_schools_found: total_schools,
            search_params: search_params
          )

        true ->
          assign(socket,
            schools: [],
            total_schools_found: 0,
            search_params: search_params
          )
      end

    {:noreply, socket}
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

  @impl true
  def handle_event("sort", %{"field" => field}, socket) do
    field_atom = String.to_atom(field)

    {sort_by, sort_order} =
      if socket.assigns.sort_by == field_atom do
        # Toggle order if clicking the same field
        {field_atom, if(socket.assigns.sort_order == :asc, do: :desc, else: :asc)}
      else
        # New field, default to ascending
        {field_atom, :asc}
      end

    sorted_schools = sort_schools(socket.assigns.schools, sort_by, sort_order)

    {:noreply,
     assign(socket,
       schools: sorted_schools,
       sort_by: sort_by,
       sort_order: sort_order
     )}
  end

  defp sort_schools(schools, nil, _order), do: schools

  defp sort_schools(schools, field, order) do
    Enum.sort_by(
      schools,
      fn school ->
        case field do
          :name ->
            school.name || ""

          :street ->
            if school.address, do: school.address.street || "", else: ""

          :zip_code ->
            if school.address, do: school.address.zip_code || "", else: ""

          :city ->
            if school.parent_location, do: school.parent_location.name || "", else: ""

          _ ->
            ""
        end
      end,
      if(order == :asc, do: &<=/2, else: &>=/2)
    )
  end

  defp get_federal_states do
    country = Locations.get_country_by_slug!("d")

    Locations.list_federal_states(country)
    |> Enum.map(fn state -> {state.name, state.id} end)
    |> Enum.sort_by(&elem(&1, 0))
  end

  defp convert_search_params(search_params) do
    location = Map.get(search_params, "location", "")

    # Determine if location is a zip code or city name
    cond do
      String.length(location) == 5 and Regex.match?(~r/^\d{5}$/, location) ->
        # It's a zip code
        search_params
        |> Map.delete("location")
        |> Map.put("zip_code", location)
        |> Map.put("city", "")

      true ->
        # It's a city name or empty
        search_params
        |> Map.delete("location")
        |> Map.put("city", location)
        |> Map.put("zip_code", "")
    end
  end

  # Number formatting helper
  defp format_number(number) when is_integer(number) do
    number
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1.")
    |> String.reverse()
  end

  # Optimized search for federal state only
  defp search_schools_by_federal_state(federal_state_id) do
    import Ecto.Query
    alias MehrSchulferien.Repo

    federal_state_id_int = String.to_integer(federal_state_id)

    # Optimized query similar to HomeLive
    query =
      from s in MehrSchulferien.Locations.Location,
        join: city in MehrSchulferien.Locations.Location,
        on: city.id == s.parent_location_id,
        join: county in MehrSchulferien.Locations.Location,
        on: county.id == city.parent_location_id,
        left_join: a in MehrSchulferien.Maps.Address,
        on: a.school_location_id == s.id,
        where: s.is_school == true,
        where: county.parent_location_id == ^federal_state_id_int,
        order_by: [city.name, s.name],
        select: %{
          id: s.id,
          name: s.name,
          slug: s.slug,
          parent_location: %{
            id: city.id,
            name: city.name,
            parent_location: %{
              id: county.id,
              parent_location: %{
                id: county.parent_location_id
              }
            }
          },
          address: %{
            street: a.street,
            zip_code: a.zip_code
          }
        }

    Repo.all(query)
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
      />

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
                  <%= format_number(@total_schools_found) %> Schulen gefunden. Bitte geben Sie genauere Suchkriterien ein.
                </p>
              </div>
            </div>
          </div>
        <% length(@schools) > 0 -> %>
          <div class="bg-white shadow-sm rounded-lg overflow-hidden">
            <div class="px-6 py-4 border-b border-gray-200">
              <h2 class="text-xl font-semibold text-gray-900">
                Suchergebnisse (<%= @total_schools_found %> <%= if @total_schools_found == 1,
                  do: "Schule",
                  else: "Schulen" %> gefunden)
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
                        <%= school.name %>
                      </a>
                    </td>
                    <td class="hidden sm:table-cell px-4 py-3 text-sm text-gray-900">
                      <%= if school.address do %>
                        <span class="block truncate pr-2" title={school.address.street}>
                          <%= school.address.street %>
                        </span>
                      <% else %>
                        <span class="text-gray-500">-</span>
                      <% end %>
                    </td>
                    <td class="px-4 py-3 text-sm text-gray-900">
                      <%= if school.address && school.address.zip_code do %>
                        <%= school.address.zip_code %>
                      <% else %>
                        <span class="text-gray-500">-</span>
                      <% end %>
                    </td>
                    <td class="px-4 py-3 text-sm text-gray-900">
                      <%= if school.parent_location do %>
                        <span class="block truncate pr-2" title={school.parent_location.name}>
                          <%= school.parent_location.name %>
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
