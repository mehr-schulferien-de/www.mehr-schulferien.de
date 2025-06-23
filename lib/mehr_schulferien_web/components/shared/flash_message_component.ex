defmodule MehrSchulferienWeb.Shared.FlashMessageComponent do
  @moduledoc """
  Shared flash message component for consistent flash message display.
  Replaces duplicated flash message patterns across LiveView templates.
  """
  use Phoenix.Component

  attr :flash, :map, required: true

  def flash_message(assigns) do
    ~H"""
    <%= if Phoenix.Flash.get(@flash, :info) do %>
      <div class="mb-6 p-4 rounded-lg bg-emerald-50 border border-emerald-200">
        <div class="flex">
          <div class="flex-shrink-0">
            <svg
              class="h-5 w-5 text-emerald-400"
              viewBox="0 0 20 20"
              fill="currentColor"
              aria-hidden="true"
            >
              <path
                fill-rule="evenodd"
                d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.236 4.53L7.53 10.53a.75.75 0 00-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z"
                clip-rule="evenodd"
              />
            </svg>
          </div>
          <div class="ml-3">
            <p class="text-sm font-medium text-emerald-800">
              <%= Phoenix.Flash.get(@flash, :info) %>
            </p>
          </div>
        </div>
      </div>
    <% end %>

    <%= if Phoenix.Flash.get(@flash, :error) do %>
      <div class="mb-6 p-4 rounded-lg bg-red-50 border border-red-200">
        <div class="flex">
          <div class="flex-shrink-0">
            <svg
              class="h-5 w-5 text-red-400"
              viewBox="0 0 20 20"
              fill="currentColor"
              aria-hidden="true"
            >
              <path
                fill-rule="evenodd"
                d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.28 7.22a.75.75 0 00-1.06 1.06L8.94 10l-1.72 1.72a.75.75 0 101.06 1.06L10 11.06l1.72 1.72a.75.75 0 101.06-1.06L11.06 10l1.72-1.72a.75.75 0 00-1.06-1.06L10 8.94 8.28 7.22z"
                clip-rule="evenodd"
              />
            </svg>
          </div>
          <div class="ml-3">
            <p class="text-sm font-medium text-red-800">
              <%= Phoenix.Flash.get(@flash, :error) %>
            </p>
          </div>
        </div>
      </div>
    <% end %>
    """
  end
end
