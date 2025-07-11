defmodule MehrSchulferienWeb.Shared.BadgeComponent do
  @moduledoc """
  Shared badge components for consistent status indicators and labels.
  """
  use Phoenix.Component
  alias MehrSchulferienWeb.Shared.DesignTokens

  attr :variant, :string,
    default: "default",
    values: ["default", "primary", "success", "warning", "danger"]

  attr :size, :string, default: "default", values: ["sm", "default", "lg"]
  attr :pill, :boolean, default: true
  attr :class, :string, default: ""
  slot :inner_block, required: true

  def badge(assigns) do
    base_classes = "inline-flex items-center font-medium"

    size_classes =
      case assigns.size do
        "sm" -> "px-2 py-0.5 text-xs"
        "default" -> "px-2.5 py-0.5 text-xs"
        "lg" -> "px-3 py-1 text-sm"
      end

    variant_classes =
      case assigns.variant do
        "default" -> "bg-gray-100 text-gray-800"
        "primary" -> "bg-blue-100 text-blue-800"
        "success" -> "bg-green-100 text-green-800"
        "warning" -> "bg-yellow-100 text-yellow-800"
        "danger" -> "bg-red-100 text-red-800"
      end

    radius_classes = if assigns.pill, do: "rounded-full", else: "rounded"

    assigns =
      assign(
        assigns,
        :computed_class,
        "#{base_classes} #{size_classes} #{variant_classes} #{radius_classes} #{assigns.class}"
      )

    ~H"""
    <span class={@computed_class}>
      <%= render_slot(@inner_block) %>
    </span>
    """
  end

  # Day type badge using the unified color system
  attr :day_type, :atom, required: true, values: [:holiday, :vacation, :weekend, :bridge_day]
  attr :text, :string, required: true
  attr :size, :string, default: "default"
  attr :class, :string, default: ""

  def day_type_badge(assigns) do
    colors = DesignTokens.day_type_colors()[assigns.day_type]

    assigns =
      assign(assigns, :badge_class, "#{colors.light_background} #{colors.text} #{colors.border}")

    ~H"""
    <.badge variant="default" size={@size} class={"border #{@badge_class} #{@class}"}>
      <%= @text %>
    </.badge>
    """
  end

  # Count badge (e.g., for showing numbers)
  attr :count, :integer, required: true
  attr :variant, :string, default: "default"
  attr :max, :integer, default: 99
  attr :class, :string, default: ""

  def count_badge(assigns) do
    display_count =
      if assigns.count > assigns.max, do: "#{assigns.max}+", else: "#{assigns.count}"

    assigns = assign(assigns, :display_count, display_count)

    ~H"""
    <.badge variant={@variant} size="sm" class={@class}>
      <%= @display_count %>
    </.badge>
    """
  end

  # Status badge
  attr :status, :string, required: true
  attr :class, :string, default: ""

  def status_badge(assigns) do
    variant =
      case String.downcase(assigns.status) do
        status when status in ["active", "aktiv", "verfügbar"] -> "success"
        status when status in ["pending", "ausstehend"] -> "warning"
        status when status in ["inactive", "inaktiv", "nicht verfügbar"] -> "danger"
        _ -> "default"
      end

    assigns = assign(assigns, :variant, variant)

    ~H"""
    <.badge variant={@variant} class={@class}>
      <%= @status %>
    </.badge>
    """
  end

  # Icon badge with optional text
  attr :variant, :string, default: "default"
  attr :icon_name, :string, required: true
  attr :text, :string, default: nil
  attr :class, :string, default: ""

  def icon_badge(assigns) do
    ~H"""
    <.badge variant={@variant} class={"flex items-center gap-1 #{@class}"}>
      <.icon name={@icon_name} class="w-3 h-3" />
      <%= if @text do %>
        <span><%= @text %></span>
      <% end %>
    </.badge>
    """
  end

  # Helper component for icon (you may need to adjust based on your icon system)
  defp icon(assigns) do
    ~H"""
    <svg class={@class} fill="currentColor" viewBox="0 0 20 20">
      <%= case @name do %>
        <% "check" -> %>
          <path
            fill-rule="evenodd"
            d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
            clip-rule="evenodd"
          />
        <% "x" -> %>
          <path
            fill-rule="evenodd"
            d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
            clip-rule="evenodd"
          />
        <% _ -> %>
          <circle cx="10" cy="10" r="8" />
      <% end %>
    </svg>
    """
  end
end
