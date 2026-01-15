defmodule MehrSchulferienWeb.WikiMaintenanceLive do
  @moduledoc """
  Maintenance page shown when wiki functionality is temporarily disabled.

  To enable maintenance mode: Uncomment the catch-all route in router.ex
  To disable maintenance mode: Comment out the catch-all route in router.ex
  """
  use MehrSchulferienWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Wiki wird aktualisiert")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-[60vh] flex items-center justify-center">
      <div class="max-w-md w-full bg-white dark:bg-gray-800 rounded-lg shadow-lg p-8 text-center">
        <div class="mx-auto w-16 h-16 bg-amber-100 dark:bg-amber-900/30 rounded-full flex items-center justify-center mb-6">
          <svg
            class="w-8 h-8 text-amber-600 dark:text-amber-400"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
            />
          </svg>
        </div>
        <h1 class="text-2xl font-bold text-gray-900 dark:text-gray-100 mb-4">
          Wiki-Bereich wird aktualisiert
        </h1>
        <p class="text-gray-600 dark:text-gray-400 mb-6">
          Der Wiki-Bereich wird gerade aktualisiert und steht vorübergehend nicht zur Verfügung.
          Bitte versuchen Sie es später erneut.
        </p>
        <a
          href="/"
          class="inline-block bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition-colors"
        >
          Zur Startseite
        </a>
      </div>
    </div>
    """
  end
end
