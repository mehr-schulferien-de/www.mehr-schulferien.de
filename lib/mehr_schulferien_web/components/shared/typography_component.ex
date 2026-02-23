defmodule MehrSchulferienWeb.Shared.TypographyComponent do
  @moduledoc """
  Shared typography components for consistent text styling across the application.
  Provides standardized heading, paragraph, and text components.
  """
  use Phoenix.Component
  use PhoenixHTMLHelpers

  attr :level, :integer, default: 1, values: [1, 2, 3, 4, 5, 6]
  attr :class, :string, default: ""
  attr :show_ad, :boolean, default: true
  slot :inner_block, required: true

  def heading(assigns) do
    tag = String.to_atom("h#{assigns.level}")

    base_classes =
      case assigns.level do
        1 -> "text-3xl sm:text-4xl font-bold text-gray-900 dark:text-gray-50 leading-tight"
        2 -> "text-2xl sm:text-3xl font-bold text-gray-900 dark:text-gray-50 leading-tight"
        3 -> "text-xl sm:text-2xl font-semibold text-gray-900 dark:text-gray-100 leading-snug"
        4 -> "text-lg sm:text-xl font-semibold text-gray-900 dark:text-gray-100 leading-snug"
        5 -> "text-base sm:text-lg font-medium text-gray-900 dark:text-gray-100 leading-normal"
        6 -> "text-base font-medium text-gray-900 dark:text-gray-100 leading-normal"
      end

    assigns = assign(assigns, :tag, tag)
    assigns = assign(assigns, :computed_class, "#{base_classes} #{assigns.class}")

    ~H"""
    <.dynamic tag={@tag} class={@computed_class}>
      {render_slot(@inner_block)}
    </.dynamic>
    <%= if @level == 1 and @show_ad do %>
      <div class="mt-3 mb-2">
        <div class="inline-block bg-gradient-to-r from-pink-500 to-rose-500 rounded-lg px-5 py-2.5 text-sm text-white shadow-lg shadow-pink-500/30">
          Online-Datine? Online-Dating!
          <a
            href="https://animina.de?ad=2"
            class="font-bold underline decoration-2 ml-1 hover:text-pink-100"
          >
            animina.de
          </a>
        </div>
      </div>
    <% end %>
    """
  end

  attr :variant, :string, default: "base", values: ["base", "lead", "small", "muted"]
  attr :class, :string, default: ""
  slot :inner_block, required: true

  def text(assigns) do
    base_classes =
      case assigns.variant do
        "base" -> "text-base text-gray-700 dark:text-gray-200 leading-relaxed"
        "lead" -> "text-lg text-gray-700 dark:text-gray-200 leading-relaxed"
        "small" -> "text-sm text-gray-600 dark:text-gray-300 leading-normal"
        "muted" -> "text-sm text-gray-500 dark:text-gray-400 leading-normal"
      end

    assigns = assign(assigns, :computed_class, "#{base_classes} #{assigns.class}")

    ~H"""
    <p class={@computed_class}>
      {render_slot(@inner_block)}
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
        "primary" ->
          "text-blue-700 dark:text-blue-400 hover:text-blue-900 dark:hover:text-blue-300 hover:underline focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 dark:focus:ring-offset-gray-900 rounded-sm transition-colors"

        "secondary" ->
          "text-gray-800 dark:text-gray-300 hover:text-gray-950 dark:hover:text-gray-100 hover:underline focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 dark:focus:ring-offset-gray-900 rounded-sm transition-colors"

        "muted" ->
          "text-gray-600 dark:text-gray-400 hover:text-gray-800 dark:hover:text-gray-300 hover:underline focus:outline-none focus:ring-2 focus:ring-gray-400 focus:ring-offset-2 dark:focus:ring-offset-gray-900 rounded-sm transition-colors"
      end

    assigns = assign(assigns, :computed_class, "#{base_classes} #{assigns.class}")

    ~H"""
    <a href={@href} target={@target} rel={@rel} class={@computed_class}>
      {render_slot(@inner_block)}
    </a>
    """
  end

  # Helper component for inline code
  attr :class, :string, default: ""
  slot :inner_block, required: true

  def code(assigns) do
    ~H"""
    <code class={"px-1.5 py-0.5 text-sm font-mono bg-gray-100 dark:bg-gray-800 text-gray-800 dark:text-gray-200 rounded #{@class}"}>
      {render_slot(@inner_block)}
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
      <h1 class="text-3xl font-bold text-gray-900 dark:text-gray-50 mb-2">{@title}</h1>
      <%= if @subtitle do %>
        <p class="text-lg text-gray-600 dark:text-gray-300">{@subtitle}</p>
      <% end %>
    </div>
    """
  end

  # Section heading with optional divider
  attr :title, :string, required: true
  attr :divider, :boolean, default: false
  attr :level, :integer, default: 2, values: [1, 2, 3, 4, 5, 6]
  attr :class, :string, default: ""

  def section_title(assigns) do
    tag = String.to_atom("h#{assigns.level}")
    assigns = assign(assigns, :tag, tag)

    ~H"""
    <div class={"mb-4 #{@class}"}>
      <.dynamic tag={@tag} class="text-xl font-semibold text-gray-900 dark:text-gray-50">
        {@title}
      </.dynamic>
      <%= if @divider do %>
        <div class="mt-2 border-b border-gray-200 dark:border-gray-700"></div>
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
    {content_tag(@tag, render_slot(@inner_block), class: @class)}
    """
  end
end
