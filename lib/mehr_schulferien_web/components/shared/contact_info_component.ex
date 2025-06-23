defmodule MehrSchulferienWeb.Shared.ContactInfoComponent do
  @moduledoc """
  Shared contact information component for displaying structured contact details.
  Replaces duplicated contact info patterns found in school templates.
  """
  use Phoenix.Component

  alias MehrSchulferienWeb.Shared.ButtonComponent

  attr :name, :string, required: true
  attr :street, :string, required: true
  attr :zip_code, :string, required: true
  attr :city, :string, required: true
  attr :email, :string, default: nil
  attr :phone, :string, default: nil
  attr :website, :string, default: nil
  attr :wikipedia_url, :string, default: nil
  attr :edit_url, :string, default: nil
  attr :show_header, :boolean, default: true
  attr :class, :string, default: ""

  def contact_info(assigns) do
    ~H"""
    <div class={@class}>
      <%= if @show_header do %>
        <h3 class="text-lg font-semibold text-gray-900 mb-3 flex items-center">
          <svg
            class="w-5 h-5 mr-2 text-gray-600"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
            xmlns="http://www.w3.org/2000/svg"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
          Kontakt
        </h3>
      <% end %>

      <div class="space-y-3 text-sm">
        <div class="flex flex-col sm:flex-row sm:items-center">
          <span class="font-medium text-gray-700 w-24 flex-shrink-0">Name:</span>
          <span class="text-gray-900"><%= @name %></span>
        </div>

        <div class="flex flex-col sm:flex-row sm:items-center">
          <span class="font-medium text-gray-700 w-24 flex-shrink-0">Adresse:</span>
          <span class="text-gray-900"><%= @street %>, <%= @zip_code %> <%= @city %></span>
        </div>

        <%= if @email do %>
          <div class="flex flex-col sm:flex-row sm:items-center">
            <span class="font-medium text-gray-700 w-24 flex-shrink-0">E-Mail:</span>
            <a
              href={"mailto:#{@email}"}
              class="text-blue-600 hover:text-blue-800 hover:underline break-all"
            >
              <%= @email %>
            </a>
          </div>
        <% end %>

        <%= if @phone do %>
          <div class="flex flex-col sm:flex-row sm:items-center">
            <span class="font-medium text-gray-700 w-24 flex-shrink-0">Telefon:</span>
            <a href={"tel:#{@phone}"} class="text-blue-600 hover:text-blue-800 hover:underline">
              <%= @phone %>
            </a>
          </div>
        <% end %>

        <%= if @website do %>
          <div class="flex flex-col sm:flex-row sm:items-center">
            <span class="font-medium text-gray-700 w-24 flex-shrink-0">Website:</span>
            <a
              href={@website}
              target="_blank"
              rel="noopener noreferrer"
              class="text-blue-600 hover:text-blue-800 hover:underline break-all"
            >
              <%= @website %>
            </a>
          </div>
        <% end %>

        <%= if @wikipedia_url do %>
          <div class="flex flex-col sm:flex-row sm:items-center">
            <span class="font-medium text-gray-700 w-24 flex-shrink-0">Wikipedia:</span>
            <a
              href={@wikipedia_url}
              target="_blank"
              rel="noopener noreferrer"
              class="text-blue-600 hover:text-blue-800 hover:underline break-all"
            >
              Wikipedia-Artikel
            </a>
          </div>
        <% end %>
      </div>

      <%= if @edit_url do %>
        <div class="mt-4 pt-4 border-t border-gray-200">
          <ButtonComponent.button
            href={@edit_url}
            variant="secondary"
            size="sm"
            class="w-full sm:w-auto"
          >
            <svg
              class="w-4 h-4 mr-2"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
              />
            </svg>
            Daten bearbeiten
          </ButtonComponent.button>
        </div>
      <% end %>
    </div>
    """
  end
end
