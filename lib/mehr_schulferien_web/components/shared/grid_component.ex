defmodule MehrSchulferienWeb.Shared.GridComponent do
  @moduledoc """
  Shared grid layout components for consistent responsive layouts across the application.
  Provides standardized grid containers and column configurations.
  """
  use Phoenix.Component

  attr :cols, :string, default: "1", values: ["1", "2", "3", "4", "6", "auto"]
  attr :gap, :string, default: "6", values: ["2", "3", "4", "5", "6", "8"]
  attr :class, :string, default: ""
  attr :responsive, :boolean, default: true
  slot :inner_block, required: true

  def grid(assigns) do
    base_classes = "grid"
    gap_classes = "gap-#{assigns.gap}"

    cols_classes =
      if assigns.responsive do
        case assigns.cols do
          "1" -> "grid-cols-1"
          "2" -> "grid-cols-1 sm:grid-cols-2"
          "3" -> "grid-cols-1 sm:grid-cols-2 lg:grid-cols-3"
          "4" -> "grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 2xl:grid-cols-4"
          "6" -> "grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6"
          "auto" -> "grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4"
        end
      else
        "grid-cols-#{assigns.cols}"
      end

    assigns =
      assign(
        assigns,
        :computed_class,
        "#{base_classes} #{cols_classes} #{gap_classes} #{assigns.class}"
      )

    ~H"""
    <div class={@computed_class}>
      {render_slot(@inner_block)}
    </div>
    """
  end

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

  # Two column layout with sidebar
  attr :sidebar_position, :string, default: "right", values: ["left", "right"]
  attr :sidebar_width, :string, default: "1/3", values: ["1/4", "1/3", "2/5"]
  attr :gap, :string, default: "6"
  attr :class, :string, default: ""
  slot :main, required: true
  slot :sidebar, required: true

  def two_column(assigns) do
    container_classes = "flex flex-col lg:flex-row gap-#{assigns.gap}"

    {main_classes, sidebar_classes} =
      case assigns.sidebar_width do
        "1/4" -> {"lg:w-3/4", "lg:w-1/4"}
        "1/3" -> {"lg:w-2/3", "lg:w-1/3"}
        "2/5" -> {"lg:w-3/5", "lg:w-2/5"}
      end

    assigns = assign(assigns, :container_classes, "#{container_classes} #{assigns.class}")
    assigns = assign(assigns, :main_classes, main_classes)
    assigns = assign(assigns, :sidebar_classes, sidebar_classes)

    ~H"""
    <div class={@container_classes}>
      <%= if @sidebar_position == "left" do %>
        <aside class={@sidebar_classes}>
          {render_slot(@sidebar)}
        </aside>
        <main class={@main_classes}>
          {render_slot(@main)}
        </main>
      <% else %>
        <main class={@main_classes}>
          {render_slot(@main)}
        </main>
        <aside class={@sidebar_classes}>
          {render_slot(@sidebar)}
        </aside>
      <% end %>
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
