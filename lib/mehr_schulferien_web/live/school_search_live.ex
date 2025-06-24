defmodule MehrSchulferienWeb.SchoolSearchLive do
  use MehrSchulferienWeb, :live_view
  alias MehrSchulferien.Locations

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       page_title: "Schule suchen - Briefe erstellen",
       page_description:
         "Erstellen Sie kostenlos Entschuldigungen, Beurlaubungen und Sportbefreiungen für die Schule. Einfache Formulare, professionelle PDFs zum Download.",
       og_image: "/images/entschuldigung-dummy.png",
       search_params: %{"zip_code" => "", "city" => "", "school_name" => ""},
       schools: [],
       searching: false,
       sort_by: nil,
       sort_order: :asc
     )}
  end

  @impl true
  def handle_event("search", %{"search" => search_params}, socket) do
    schools = Locations.search_schools(search_params)
    sorted_schools = sort_schools(schools, socket.assigns.sort_by, socket.assigns.sort_order)

    {:noreply,
     assign(socket,
       schools: sorted_schools,
       searching: false,
       search_params: search_params
     )}
  end

  @impl true
  def handle_event("validate", %{"search" => search_params}, socket) do
    zip_code = Map.get(search_params, "zip_code", "")
    city = Map.get(search_params, "city", "")
    school_name = Map.get(search_params, "school_name", "")

    # Trigger search if any field has 3 or more characters
    socket =
      if String.length(zip_code) >= 3 or String.length(city) >= 3 or
           String.length(school_name) >= 3 do
        schools = Locations.search_schools(search_params)
        sorted_schools = sort_schools(schools, socket.assigns.sort_by, socket.assigns.sort_order)
        assign(socket, schools: sorted_schools, search_params: search_params)
      else
        assign(socket, search_params: search_params)
      end

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

      <form phx-submit="search" phx-change="validate" class="mb-8 bg-white shadow-sm rounded-lg p-6">
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div>
            <label for="search_zip_code" class="block text-sm font-medium text-gray-700 mb-2">
              Postleitzahl
            </label>
            <input
              type="text"
              name="search[zip_code]"
              value={@search_params["zip_code"]}
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
              placeholder="z.B. 10115"
              id="search_zip_code"
              phx-debounce="300"
              autofocus
            />
          </div>
          <div>
            <label for="search_city" class="block text-sm font-medium text-gray-700 mb-2">
              Stadt
            </label>
            <input
              type="text"
              name="search[city]"
              value={@search_params["city"]}
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
              placeholder="z.B. Berlin"
              id="search_city"
              phx-debounce="300"
            />
          </div>
          <div>
            <label for="search_school_name" class="block text-sm font-medium text-gray-700 mb-2">
              Schulname
            </label>
            <input
              type="text"
              name="search[school_name]"
              value={@search_params["school_name"]}
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-blue-500 focus:border-blue-500"
              placeholder="z.B. Gymnasium"
              id="search_school_name"
              phx-debounce="300"
            />
          </div>
        </div>
        <div class="mt-6">
          <button
            type="submit"
            class="px-6 py-2 bg-blue-600 text-white font-medium rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
            disabled={@searching}
          >
            <%= if @searching, do: "Suche läuft...", else: "Suchen" %>
          </button>
        </div>
      </form>

      <%= if length(@schools) > 0 do %>
        <div class="bg-white shadow-sm rounded-lg overflow-hidden">
          <div class="px-6 py-4 border-b border-gray-200">
            <h2 class="text-xl font-semibold text-gray-900">
              Suchergebnisse (<%= length(@schools) %> Schulen gefunden)
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
      <% else %>
        <%= if @search_params != %{"zip_code" => "", "city" => "", "school_name" => ""} do %>
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
