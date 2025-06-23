defmodule MehrSchulferienWeb.Shared.DownloadButtonComponent do
  @moduledoc """
  Shared download button component with consistent styling and download icon.
  Replaces duplicated download button patterns across LiveView templates.
  """
  use Phoenix.Component

  attr :text, :string, default: "PDF herunterladen"
  attr :onclick, :string, default: ""
  attr :class, :string, default: ""
  attr :disabled, :boolean, default: false

  def download_button(assigns) do
    ~H"""
    <button
      type="submit"
      onclick={@onclick}
      disabled={@disabled}
      class={"w-full flex justify-center items-center px-6 py-3 border border-transparent text-base font-medium rounded-lg text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors #{@class}"}
    >
      <svg
        class="w-5 h-5 mr-2"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
        xmlns="http://www.w3.org/2000/svg"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
        />
      </svg>
      <%= @text %>
    </button>
    """
  end
end
