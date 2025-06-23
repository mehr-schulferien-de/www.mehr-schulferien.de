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
          "text-white bg-blue-600 hover:bg-blue-700 focus:ring-blue-500"

        "secondary" ->
          "text-gray-700 bg-white border border-gray-300 hover:bg-gray-50 focus:ring-blue-500"

        "teal" ->
          "text-white bg-teal-600 hover:bg-teal-700 focus:ring-teal-500"

        "purple" ->
          "text-white bg-purple-600 hover:bg-purple-700 focus:ring-purple-500"

        "danger" ->
          "text-white bg-red-600 hover:bg-red-700 focus:ring-red-500"
      end

    assigns =
      assign(
        assigns,
        :computed_class,
        "#{base_classes} #{size_classes} #{variant_classes} #{assigns.class}"
      )

    ~H"""
    <%= if @href do %>
      <a href={@href} target={@target} class={@computed_class} onclick={@onclick}>
        <%= render_slot(@inner_block) %>
      </a>
    <% else %>
      <button type={@type} disabled={@disabled} class={@computed_class} onclick={@onclick}>
        <%= render_slot(@inner_block) %>
      </button>
    <% end %>
    """
  end

  attr :href, :string, required: true
  attr :class, :string, default: ""
  attr :target, :string, default: nil
  slot :inner_block, required: true

  def link_button(assigns) do
    ~H"""
    <a
      href={@href}
      target={@target}
      class={"text-blue-600 hover:text-blue-800 hover:underline cursor-pointer #{@class}"}
    >
      <%= render_slot(@inner_block) %>
    </a>
    """
  end
end
