defmodule MehrSchulferienWeb.Shared.AlertComponent do
  @moduledoc """
  Shared alert and notification components for consistent messaging across the application.
  """
  use Phoenix.Component

  attr :variant, :string,
    default: "info",
    values: ["info", "success", "warning", "error"]

  attr :title, :string, default: nil
  attr :dismissible, :boolean, default: false
  attr :icon, :boolean, default: true
  attr :class, :string, default: ""
  slot :inner_block, required: true

  def alert(assigns) do
    base_classes = "rounded-lg p-4"

    variant_classes =
      case assigns.variant do
        "info" ->
          "bg-blue-50 dark:bg-blue-900/20 text-blue-800 dark:text-blue-300 border border-blue-200 dark:border-blue-800"

        "success" ->
          "bg-green-50 dark:bg-green-900/20 text-green-800 dark:text-green-300 border border-green-200 dark:border-green-800"

        "warning" ->
          "bg-yellow-50 dark:bg-yellow-900/20 text-yellow-800 dark:text-yellow-300 border border-yellow-200 dark:border-yellow-800"

        "error" ->
          "bg-red-50 dark:bg-red-900/20 text-red-800 dark:text-red-300 border border-red-200 dark:border-red-800"
      end

    assigns =
      assign(assigns, :computed_class, "#{base_classes} #{variant_classes} #{assigns.class}")

    ~H"""
    <div class={@computed_class} role="alert">
      <div class="flex">
        <%= if @icon do %>
          <div class="flex-shrink-0">
            <.alert_icon variant={@variant} />
          </div>
        <% end %>
        <div class={"#{if @icon, do: "ml-3"} flex-1"}>
          <%= if @title do %>
            <h3 class="text-sm font-medium mb-1">{@title}</h3>
          <% end %>
          <div class="text-sm">
            {render_slot(@inner_block)}
          </div>
        </div>
        <%= if @dismissible do %>
          <div class="ml-auto pl-3">
            <button
              type="button"
              class="inline-flex rounded-md p-1.5 hover:bg-white dark:hover:bg-gray-700 hover:bg-opacity-20 dark:hover:bg-opacity-50 focus:outline-none focus:ring-2 focus:ring-offset-2"
              data-dismiss-alert
            >
              <span class="sr-only">Dismiss</span>
              <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                <path
                  fill-rule="evenodd"
                  d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
                  clip-rule="evenodd"
                />
              </svg>
            </button>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  # Helper component for alert icons
  defp alert_icon(assigns) do
    assigns = assign(assigns, :icon_classes, "h-5 w-5")

    icon_svg =
      case assigns.variant do
        "info" ->
          ~H"""
          <svg class={@icon_classes} viewBox="0 0 20 20" fill="currentColor">
            <path
              fill-rule="evenodd"
              d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z"
              clip-rule="evenodd"
            />
          </svg>
          """

        "success" ->
          ~H"""
          <svg class={@icon_classes} viewBox="0 0 20 20" fill="currentColor">
            <path
              fill-rule="evenodd"
              d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
              clip-rule="evenodd"
            />
          </svg>
          """

        "warning" ->
          ~H"""
          <svg class={@icon_classes} viewBox="0 0 20 20" fill="currentColor">
            <path
              fill-rule="evenodd"
              d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"
              clip-rule="evenodd"
            />
          </svg>
          """

        "error" ->
          ~H"""
          <svg class={@icon_classes} viewBox="0 0 20 20" fill="currentColor">
            <path
              fill-rule="evenodd"
              d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
              clip-rule="evenodd"
            />
          </svg>
          """
      end

    icon_svg
  end
end
