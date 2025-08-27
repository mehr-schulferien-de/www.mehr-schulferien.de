defmodule MehrSchulferienWeb.Shared.ButtonComponent do
  @moduledoc """
  Shared button component for consistent button styling across the application.
  Replaces duplicated button patterns found throughout the templates.
  """
  use Phoenix.Component

  attr :type, :string, default: "button", values: ["button", "submit", "reset"]

  attr :variant, :string,
    default: "primary",
    values: ["primary", "secondary", "teal", "purple", "danger"]

  attr :size, :string, default: "base", values: ["sm", "base", "lg"]
  attr :href, :string, default: nil
  attr :target, :string, default: nil
  attr :onclick, :string, default: nil
  attr :disabled, :boolean, default: false
  attr :class, :string, default: ""
  attr :"aria-label", :string, default: nil
  attr :"aria-pressed", :string, default: nil
  slot :inner_block, required: true

  def button(assigns) do
    base_classes =
      "inline-flex items-center justify-center font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"

    size_classes =
      case assigns.size do
        "sm" -> "px-3 py-1.5 text-sm rounded-md"
        "base" -> "px-4 py-2 text-sm rounded-lg"
        "lg" -> "px-6 py-3 text-base rounded-lg"
      end

    variant_classes =
      case assigns.variant do
        "primary" ->
          "text-white bg-blue-600 dark:bg-blue-500 hover:bg-blue-700 dark:hover:bg-blue-600 focus:ring-blue-500 dark:focus:ring-blue-400"

        "secondary" ->
          "text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700 focus:ring-blue-500 dark:focus:ring-blue-400"

        "teal" ->
          "text-white bg-teal-600 dark:bg-teal-500 hover:bg-teal-700 dark:hover:bg-teal-600 focus:ring-teal-500 dark:focus:ring-teal-400"

        "purple" ->
          "text-white bg-purple-600 dark:bg-purple-500 hover:bg-purple-700 dark:hover:bg-purple-600 focus:ring-purple-500 dark:focus:ring-purple-400"

        "danger" ->
          "text-white bg-red-600 dark:bg-red-500 hover:bg-red-700 dark:hover:bg-red-600 focus:ring-red-500 dark:focus:ring-red-400"
      end

    assigns =
      assign(
        assigns,
        :computed_class,
        "#{base_classes} #{size_classes} #{variant_classes} #{assigns.class}"
      )

    ~H"""
    <%= if @href do %>
      <a
        href={@href}
        target={@target}
        class={@computed_class}
        onclick={@onclick}
        aria-label={assigns[:"aria-label"]}
      >
        {render_slot(@inner_block)}
      </a>
    <% else %>
      <button
        type={@type}
        disabled={@disabled}
        class={@computed_class}
        onclick={@onclick}
        aria-label={assigns[:"aria-label"]}
        aria-pressed={assigns[:"aria-pressed"]}
      >
        {render_slot(@inner_block)}
      </button>
    <% end %>
    """
  end

  attr :href, :string, required: true
  attr :class, :string, default: ""
  attr :target, :string, default: nil
  attr :"aria-label", :string, default: nil
  slot :inner_block, required: true

  def link_button(assigns) do
    ~H"""
    <a
      href={@href}
      target={@target}
      aria-label={assigns[:"aria-label"]}
      class={"text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 hover:underline focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 dark:focus:ring-offset-gray-900 rounded-sm cursor-pointer transition-colors #{@class}"}
    >
      {render_slot(@inner_block)}
    </a>
    """
  end
end
