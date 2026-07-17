defmodule MehrSchulferienWeb.Shared.GridComponent do
  @moduledoc """
  Shared grid layout components for consistent responsive layouts across the application.
  Provides standardized grid containers and column configurations.
  """
  use Phoenix.Component

  # Specific grid for cards/panels
  attr :variant, :string, default: "default", values: ["default", "compact", "wide"]
  attr :class, :string, default: ""
  slot :inner_block, required: true

  def card_grid(assigns) do
    grid_classes =
      case assigns.variant do
        "default" -> "grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3 2xl:grid-cols-4"
        "compact" -> "grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4"
        "wide" -> "grid grid-cols-1 gap-6 md:grid-cols-2 xl:grid-cols-3"
      end

    assigns = assign(assigns, :computed_class, "#{grid_classes} #{assigns.class}")

    ~H"""
    <div class={@computed_class}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # Container component for consistent max-width and padding
  attr :size, :string, default: "default", values: ["default", "narrow", "wide", "full"]
  attr :padding, :boolean, default: true
  attr :class, :string, default: ""
  slot :inner_block, required: true

  def container(assigns) do
    size_classes =
      case assigns.size do
        "narrow" -> "max-w-4xl"
        "default" -> "max-w-7xl"
        "wide" -> "max-w-screen-2xl"
        "full" -> "max-w-full"
      end

    padding_classes = if assigns.padding, do: "px-4 sm:px-6 lg:px-8", else: ""

    assigns =
      assign(
        assigns,
        :computed_class,
        "mx-auto #{size_classes} #{padding_classes} #{assigns.class}"
      )

    ~H"""
    <div class={@computed_class}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # Stack component for vertical layouts
  attr :spacing, :string, default: "4", values: ["2", "3", "4", "6", "8"]
  attr :class, :string, default: ""
  slot :inner_block, required: true

  def stack(assigns) do
    ~H"""
    <div class={"space-y-#{@spacing} #{@class}"}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
