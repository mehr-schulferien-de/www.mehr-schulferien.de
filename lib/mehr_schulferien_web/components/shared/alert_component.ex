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
        "info" -> "bg-blue-50 text-blue-800 border border-blue-200"
        "success" -> "bg-green-50 text-green-800 border border-green-200"
        "warning" -> "bg-yellow-50 text-yellow-800 border border-yellow-200"
        "error" -> "bg-red-50 text-red-800 border border-red-200"
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
            <h3 class="text-sm font-medium mb-1"><%= @title %></h3>
          <% end %>
          <div class="text-sm">
            <%= render_slot(@inner_block) %>
          </div>
        </div>
        <%= if @dismissible do %>
          <div class="ml-auto pl-3">
            <button
              type="button"
              class="inline-flex rounded-md p-1.5 hover:bg-white hover:bg-opacity-20 focus:outline-none focus:ring-2 focus:ring-offset-2"
              onclick="this.closest('[role=alert]').remove()"
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

  # Inline alert for form fields or small notifications
  attr :variant, :string, default: "info"
  attr :class, :string, default: ""
  slot :inner_block, required: true

  def inline_alert(assigns) do
    base_classes = "text-sm"

    variant_classes =
      case assigns.variant do
        "info" -> "text-blue-700"
        "success" -> "text-green-700"
        "warning" -> "text-yellow-700"
        "error" -> "text-red-700"
      end

    assigns =
      assign(assigns, :computed_class, "#{base_classes} #{variant_classes} #{assigns.class}")

    ~H"""
    <p class={@computed_class}>
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  # Banner alert (full width, typically at top of page)
  attr :variant, :string, default: "info"
  attr :dismissible, :boolean, default: true
  attr :class, :string, default: ""
  slot :inner_block, required: true

  def banner_alert(assigns) do
    variant_classes =
      case assigns.variant do
        "info" -> "bg-blue-600 text-white"
        "success" -> "bg-green-600 text-white"
        "warning" -> "bg-yellow-500 text-white"
        "error" -> "bg-red-600 text-white"
      end

    assigns = assign(assigns, :variant_classes, variant_classes)

    ~H"""
    <div class={"relative #{@variant_classes} #{@class}"} role="banner">
      <div class="max-w-7xl mx-auto py-3 px-3 sm:px-6 lg:px-8">
        <div class="pr-16 sm:text-center sm:px-16">
          <p class="font-medium">
            <%= render_slot(@inner_block) %>
          </p>
        </div>
        <%= if @dismissible do %>
          <div class="absolute inset-y-0 right-0 pt-1 pr-1 flex items-start sm:pt-1 sm:pr-2 sm:items-start">
            <button
              type="button"
              class="flex p-2 rounded-md hover:bg-white hover:bg-opacity-20 focus:outline-none focus:ring-2 focus:ring-white"
              onclick="this.closest('[role=banner]').remove()"
            >
              <span class="sr-only">Dismiss</span>
              <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M6 18L18 6M6 6l12 12"
                />
              </svg>
            </button>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  # Toast notification (positioned fixed)
  attr :variant, :string, default: "info"

  attr :position, :string,
    default: "top-right",
    values: ["top-right", "top-left", "bottom-right", "bottom-left"]

  attr :title, :string, required: true
  attr :message, :string, default: nil
  attr :auto_dismiss, :integer, default: 5000
  attr :class, :string, default: ""

  def toast(assigns) do
    position_classes =
      case assigns.position do
        "top-right" -> "top-4 right-4"
        "top-left" -> "top-4 left-4"
        "bottom-right" -> "bottom-4 right-4"
        "bottom-left" -> "bottom-4 left-4"
      end

    assigns = assign(assigns, :position_classes, position_classes)

    ~H"""
    <div
      class={"fixed #{@position_classes} z-50 #{@class}"}
      x-data="{ show: true }"
      x-show="show"
      x-init={"setTimeout(() => show = false, #{@auto_dismiss})"}
      x-transition:enter="transform ease-out duration-300 transition"
      x-transition:enter-start="translate-y-2 opacity-0 sm:translate-y-0 sm:translate-x-2"
      x-transition:enter-end="translate-y-0 opacity-100 sm:translate-x-0"
      x-transition:leave="transition ease-in duration-100"
      x-transition:leave-start="opacity-100"
      x-transition:leave-end="opacity-0"
    >
      <div class="max-w-sm w-full bg-white shadow-lg rounded-lg pointer-events-auto ring-1 ring-black ring-opacity-5 overflow-hidden">
        <div class="p-4">
          <div class="flex items-start">
            <div class="flex-shrink-0">
              <.alert_icon variant={@variant} />
            </div>
            <div class="ml-3 w-0 flex-1 pt-0.5">
              <p class="text-sm font-medium text-gray-900"><%= @title %></p>
              <%= if @message do %>
                <p class="mt-1 text-sm text-gray-500"><%= @message %></p>
              <% end %>
            </div>
            <div class="ml-4 flex-shrink-0 flex">
              <button
                @click="show = false"
                class="rounded-md inline-flex text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
              >
                <span class="sr-only">Close</span>
                <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                  <path
                    fill-rule="evenodd"
                    d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
                    clip-rule="evenodd"
                  />
                </svg>
              </button>
            </div>
          </div>
        </div>
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
