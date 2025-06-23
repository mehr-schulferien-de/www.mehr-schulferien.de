defmodule MehrSchulferienWeb.Shared.BreadcrumbComponent do
  @moduledoc """
  Shared breadcrumb component for use across the application.
  Replaces the 138-line duplicated breadcrumb code found in LiveView form templates.
  """
  use Phoenix.Component

  attr :breadcrumbs, :list, required: true
  attr :socket_or_conn, :any, required: true

  def breadcrumb(assigns) do
    ~H"""
    <nav aria-label="Breadcrumb" class="flex-1 min-w-0">
      <!-- Mobile breadcrumbs (show only last 2 items) -->
      <ol class="flex items-center space-x-1 md:hidden">
        <% visible_breadcrumbs_mobile =
          Enum.slice(@breadcrumbs, max(length(@breadcrumbs) - 2, 0), 2) %>
        <%= for {{label, path}, index} <- visible_breadcrumbs_mobile |> Enum.with_index() do %>
          <%= if index > 0 do %>
            <li>
              <svg
                class="w-5 h-5 text-gray-400"
                fill="currentColor"
                viewBox="0 0 20 20"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path
                  fill-rule="evenodd"
                  d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
                  clip-rule="evenodd"
                >
                </path>
              </svg>
            </li>
          <% end %>
          <li class="flex">
            <%= if path do %>
              <a
                href={path}
                class="text-gray-500 hover:text-gray-700 text-sm font-medium truncate max-w-[120px]"
              >
                <%= label %>
              </a>
            <% else %>
              <span class="text-gray-900 text-sm font-medium truncate max-w-[120px]">
                <%= label %>
              </span>
            <% end %>
          </li>
        <% end %>
      </ol>
      <!-- Desktop breadcrumbs (show all items) -->
      <ol class="hidden md:flex items-center space-x-1">
        <%= for {{label, path}, index} <- @breadcrumbs |> Enum.with_index() do %>
          <%= if index > 0 do %>
            <li>
              <svg
                class="w-5 h-5 text-gray-400"
                fill="currentColor"
                viewBox="0 0 20 20"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path
                  fill-rule="evenodd"
                  d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z"
                  clip-rule="evenodd"
                >
                </path>
              </svg>
            </li>
          <% end %>
          <li class="flex">
            <%= if path do %>
              <a
                href={path}
                class="text-gray-500 hover:text-gray-700 text-sm font-medium truncate max-w-[200px]"
              >
                <%= label %>
              </a>
            <% else %>
              <span class="text-gray-900 text-sm font-medium truncate max-w-[200px]">
                <%= label %>
              </span>
            <% end %>
          </li>
        <% end %>
      </ol>
    </nav>
    """
  end
end
