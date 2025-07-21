defmodule MehrSchulferienWeb.Shared.TypographyComponent do
  @moduledoc """
  Shared typography components for consistent text styling across the application.
  Provides standardized heading, paragraph, and text components.
  """
  use Phoenix.Component

  attr :level, :integer, default: 1, values: [1, 2, 3, 4, 5, 6]
  attr :class, :string, default: ""
  slot :inner_block, required: true

  def heading(assigns) do
    tag = String.to_atom("h#{assigns.level}")

    base_classes =
      case assigns.level do
        1 -> "text-3xl sm:text-4xl font-bold text-gray-900"
        2 -> "text-2xl sm:text-3xl font-bold text-gray-900"
        3 -> "text-xl sm:text-2xl font-semibold text-gray-900"
        4 -> "text-lg sm:text-xl font-semibold text-gray-900"
        5 -> "text-base sm:text-lg font-medium text-gray-900"
        6 -> "text-sm sm:text-base font-medium text-gray-900"
      end

    assigns = assign(assigns, :tag, tag)
    assigns = assign(assigns, :computed_class, "#{base_classes} #{assigns.class}")

    ~H"""
    <.dynamic tag={@tag} class={@computed_class}>
      <%= render_slot(@inner_block) %>
    </.dynamic>
    """
  end

  attr :variant, :string, default: "base", values: ["base", "lead", "small", "muted"]
  attr :class, :string, default: ""
  slot :inner_block, required: true

  def text(assigns) do
    base_classes =
      case assigns.variant do
        "base" -> "text-base text-gray-700"
        "lead" -> "text-lg text-gray-700"
        "small" -> "text-sm text-gray-600"
        "muted" -> "text-sm text-gray-500"
      end

    assigns = assign(assigns, :computed_class, "#{base_classes} #{assigns.class}")

    ~H"""
    <p class={@computed_class}>
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  attr :href, :string, required: true
  attr :class, :string, default: ""
  attr :target, :string, default: nil
  attr :rel, :string, default: nil
  attr :variant, :string, default: "primary", values: ["primary", "secondary", "muted"]
  slot :inner_block, required: true

  def link(assigns) do
    base_classes =
      case assigns.variant do
        "primary" -> "text-blue-600 hover:text-blue-800 hover:underline transition-colors"
        "secondary" -> "text-gray-700 hover:text-gray-900 hover:underline transition-colors"
        "muted" -> "text-gray-500 hover:text-gray-700 hover:underline transition-colors"
      end

    assigns = assign(assigns, :computed_class, "#{base_classes} #{assigns.class}")

    ~H"""
    <a href={@href} target={@target} rel={@rel} class={@computed_class}>
      <%= render_slot(@inner_block) %>
    </a>
    """
  end

  # Helper component for inline code
  attr :class, :string, default: ""
  slot :inner_block, required: true

  def code(assigns) do
    ~H"""
    <code class={"px-1.5 py-0.5 text-sm font-mono bg-gray-100 text-gray-800 rounded #{@class}"}>
      <%= render_slot(@inner_block) %>
    </code>
    """
  end

  # Page title component that combines heading with optional subtitle
  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :class, :string, default: ""

  def page_title(assigns) do
    ~H"""
    <div class={"mb-6 #{@class}"}>
      <h1 class="text-3xl font-bold text-gray-900 mb-2"><%= @title %></h1>
      <%= if @subtitle do %>
        <p class="text-lg text-gray-600"><%= @subtitle %></p>
      <% end %>
    </div>
    """
  end

  # Section heading with optional divider
  attr :title, :string, required: true
  attr :divider, :boolean, default: false
  attr :class, :string, default: ""

  def section_title(assigns) do
    ~H"""
    <div class={"mb-4 #{@class}"}>
      <h2 class="text-xl font-semibold text-gray-900"><%= @title %></h2>
      <%= if @divider do %>
        <div class="mt-2 border-b border-gray-200"></div>
      <% end %>
    </div>
    """
  end

  # Dynamic tag component helper
  attr :tag, :atom, required: true
  attr :class, :string, default: ""
  slot :inner_block, required: true

  defp dynamic(assigns) do
    ~H"""
    <%= Phoenix.HTML.Tag.content_tag(@tag, render_slot(@inner_block), class: @class) %>
    """
  end
end
