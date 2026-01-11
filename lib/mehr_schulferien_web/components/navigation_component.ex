defmodule MehrSchulferienWeb.NavigationComponent do
  use Phoenix.Component

  alias MehrSchulferienWeb.NavigationHelper

  @doc """
  Renders the main navigation header for LiveView pages.

  ## Example
      <.navigation socket={@socket} conn={@conn} today={~D[2025-06-23]} />
  """
  attr :socket, :any, default: nil
  attr :conn, :any, default: nil
  attr :today, Date, required: true

  def navigation(assigns) do
    {current_year, next_year, third_year} = NavigationHelper.get_navigation_years(assigns.today)
    federal_states = NavigationHelper.federal_states()

    assigns =
      Map.merge(assigns, %{
        current_year: current_year,
        next_year: next_year,
        third_year: third_year,
        federal_states: federal_states,
        years: [current_year, next_year, third_year]
      })

    ~H"""
    <header class="bg-white dark:bg-gray-800 border-b border-slate-200 dark:border-gray-700">
      <nav
        class="mx-auto flex max-w-7xl items-center justify-between px-4 sm:px-6 lg:px-8 py-6"
        aria-label="Global"
      >
        <div class="flex lg:flex-1">
          <.logo_link />
        </div>
        <div class="flex lg:hidden">
          <button
            type="button"
            class="-m-2.5 inline-flex items-center justify-center rounded-md p-2.5 text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700"
            data-mobile-menu-toggle
          >
            <span class="sr-only">Open main menu</span>
            <.hamburger_icon />
          </button>
        </div>
        <div class="hidden lg:flex lg:gap-x-8">
          <.desktop_dropdown
            label="Schulferien"
            path_prefix="/ferien/d/bundesland"
            years={@years}
            federal_states={@federal_states}
            position="left"
          />
          <.desktop_dropdown
            label="Brückentage"
            path_prefix="/brueckentage/d/bundesland"
            years={@years}
            federal_states={@federal_states}
            position="left"
          />
          <.desktop_dropdown
            label="Urlaubsplaner"
            path_builder={fn state, year -> "/urlaubsplaner/#{state}/20-tage/#{year}" end}
            years={@years}
            federal_states={@federal_states}
            position="right"
          />
        </div>
      </nav>
      <.mobile_menu years={@years} federal_states={@federal_states} />
    </header>
    """
  end

  # Private components

  defp logo_link(assigns) do
    ~H"""
    <a href="/" class="-m-1.5 p-1.5 flex items-center">
      <span class="sr-only">Mehr Schulferien</span>
      <div class="flex items-center">
        <div class="bg-blue-600 dark:bg-blue-500 text-white font-bold px-3 py-1 rounded-md flex items-center">
          <span class="text-lg tracking-wide">MEHR!</span>
        </div>
        <div class="ml-2 text-black dark:text-white font-black text-2xl">
          <span class="italic">Schulferien</span>
        </div>
      </div>
    </a>
    """
  end

  defp hamburger_icon(assigns) do
    ~H"""
    <svg
      class="size-6"
      fill="none"
      viewBox="0 0 24 24"
      stroke-width="1.5"
      stroke="currentColor"
      aria-hidden="true"
      data-slot="icon"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5"
      />
    </svg>
    """
  end

  defp close_icon(assigns) do
    ~H"""
    <svg
      class="size-6"
      fill="none"
      viewBox="0 0 24 24"
      stroke-width="1.5"
      stroke="currentColor"
      aria-hidden="true"
      data-slot="icon"
    >
      <path stroke-linecap="round" stroke-linejoin="round" d="m6 18 12-12M6 6l12 12" />
    </svg>
    """
  end

  defp chevron_icon(assigns) do
    ~H"""
    <svg
      class="size-5 flex-none text-gray-400 dark:text-gray-500"
      viewBox="0 0 20 20"
      fill="currentColor"
      aria-hidden="true"
      data-slot="icon"
    >
      <path
        fill-rule="evenodd"
        d="M5.22 8.22a.75.75 0 0 1 1.06 0L10 11.94l3.72-3.72a.75.75 0 1 1 1.06 1.06l-4.25 4.25a.75.75 0 0 1-1.06 0L5.22 9.28a.75.75 0 0 1 0-1.06Z"
        clip-rule="evenodd"
      />
    </svg>
    """
  end

  attr :label, :string, required: true
  attr :path_prefix, :string, default: nil
  attr :path_builder, :any, default: nil
  attr :years, :list, required: true
  attr :federal_states, :list, required: true
  attr :position, :string, default: "left"

  defp desktop_dropdown(assigns) do
    menu_position_class =
      if assigns.position == "right", do: "right-0", else: "-left-8"

    assigns = assign(assigns, :menu_position_class, menu_position_class)

    ~H"""
    <div class="relative" data-dropdown-container>
      <button
        type="button"
        class="flex items-center gap-x-1 text-sm/6 font-semibold text-gray-900 dark:text-gray-100 px-2 py-1 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 dark:focus:ring-offset-gray-900 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
        data-dropdown-trigger
        aria-expanded="false"
      >
        {@label}
        <.chevron_icon />
      </button>

      <div
        class={"absolute top-full #{@menu_position_class} z-10 mt-3 w-72 overflow-hidden rounded-3xl bg-white dark:bg-gray-800 shadow-lg ring-1 ring-gray-900/5 dark:ring-gray-700 opacity-0 invisible hidden transition-all duration-200"}
        data-dropdown-menu
        data-year-tabs
      >
        <.year_tabs years={@years} />
        <.year_content_panels
          years={@years}
          federal_states={@federal_states}
          path_prefix={@path_prefix}
          path_builder={@path_builder}
        />
      </div>
    </div>
    """
  end

  attr :years, :list, required: true

  defp year_tabs(assigns) do
    ~H"""
    <div class="flex border-b border-gray-200 dark:border-gray-700">
      <%= for {year, index} <- Enum.with_index(@years) do %>
        <% corner_class = year_tab_corner_class(index, length(@years)) %>
        <button
          type="button"
          class={year_tab_class(index == 0, corner_class)}
          data-year-tab={year}
        >
          {year}
        </button>
      <% end %>
    </div>
    """
  end

  defp year_tab_corner_class(0, _total), do: "rounded-tl-3xl"
  defp year_tab_corner_class(index, total) when index == total - 1, do: "rounded-tr-3xl"
  defp year_tab_corner_class(_index, _total), do: ""

  defp year_tab_class(true, corner_class) do
    "flex-1 px-4 py-2 text-sm font-medium bg-blue-600 text-white #{corner_class}"
  end

  defp year_tab_class(false, corner_class) do
    "flex-1 px-4 py-2 text-sm font-medium text-gray-600 hover:text-gray-900 hover:bg-gray-100 dark:text-gray-400 dark:hover:text-gray-100 dark:hover:bg-gray-700 #{corner_class}"
  end

  attr :years, :list, required: true
  attr :federal_states, :list, required: true
  attr :path_prefix, :string, default: nil
  attr :path_builder, :any, default: nil

  defp year_content_panels(assigns) do
    ~H"""
    <%= for {year, index} <- Enum.with_index(@years) do %>
      <div
        class={"p-2 max-h-96 overflow-y-auto #{if index > 0, do: "hidden", else: ""}"}
        data-year-content={year}
      >
        <%= for {federal_state, display_name} <- @federal_states do %>
          <a
            href={build_path(@path_prefix, @path_builder, federal_state, year)}
            class="block rounded-lg px-3 py-1.5 text-sm text-gray-900 dark:text-gray-100 hover:bg-gray-50 dark:hover:bg-gray-700"
          >
            {display_name}
          </a>
        <% end %>
      </div>
    <% end %>
    """
  end

  defp build_path(nil, path_builder, state, year) when is_function(path_builder) do
    path_builder.(state, year)
  end

  defp build_path(prefix, _path_builder, state, year) do
    "#{prefix}/#{state}/#{year}"
  end

  attr :years, :list, required: true
  attr :federal_states, :list, required: true

  defp mobile_menu(assigns) do
    [current_year | _] = assigns.years

    assigns = assign(assigns, :current_year, current_year)

    ~H"""
    <div
      class="lg:hidden fixed inset-0 z-50 bg-white dark:bg-gray-900 hidden"
      data-mobile-menu
    >
      <div class="px-6 py-6">
        <div class="flex items-center justify-between">
          <.logo_link />
          <button
            type="button"
            class="-m-2.5 rounded-md p-2.5 text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700"
            data-mobile-menu-close
          >
            <span class="sr-only">Close menu</span>
            <.close_icon />
          </button>
        </div>
        <div class="mt-6 space-y-2">
          <.mobile_section
            title="Schulferien"
            years={@years}
            federal_states={@federal_states}
            path_prefix="/ferien/d/bundesland"
          />
          <.mobile_section
            title="Brückentage"
            years={@years}
            federal_states={@federal_states}
            path_prefix="/brueckentage/d/bundesland"
          />
          <.mobile_section_simple
            title="Urlaubsplaner"
            federal_states={@federal_states}
            path_builder={fn state -> "/urlaubsplaner/#{state}/20-tage/#{@current_year}" end}
          />
        </div>
      </div>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :years, :list, required: true
  attr :federal_states, :list, required: true
  attr :path_prefix, :string, required: true

  defp mobile_section(assigns) do
    ~H"""
    <details>
      <summary class="font-semibold text-gray-900 dark:text-gray-100 py-2 cursor-pointer">
        {@title}
      </summary>
      <div class="ml-4">
        <%= for year <- @years do %>
          <details>
            <summary class="font-medium text-gray-700 dark:text-gray-300 py-1.5 cursor-pointer">
              {year}
            </summary>
            <div class="ml-4 space-y-1">
              <%= for {federal_state, display_name} <- @federal_states do %>
                <a
                  href={"#{@path_prefix}/#{federal_state}/#{year}"}
                  class="block py-1 text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100"
                >
                  {display_name}
                </a>
              <% end %>
            </div>
          </details>
        <% end %>
      </div>
    </details>
    """
  end

  attr :title, :string, required: true
  attr :federal_states, :list, required: true
  attr :path_builder, :any, required: true

  defp mobile_section_simple(assigns) do
    ~H"""
    <details>
      <summary class="font-semibold text-gray-900 dark:text-gray-100 py-2 cursor-pointer">
        {@title}
      </summary>
      <div class="ml-4 space-y-1">
        <%= for {federal_state, display_name} <- @federal_states do %>
          <a
            href={@path_builder.(federal_state)}
            class="block py-1 text-gray-700 dark:text-gray-300 hover:text-gray-900 dark:hover:text-gray-100"
          >
            {display_name}
          </a>
        <% end %>
      </div>
    </details>
    """
  end
end
