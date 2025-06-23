defmodule MehrSchulferienWeb.Shared.SectionHeadingComponent do
  @moduledoc """
  Shared section heading component for consistent heading styles across the application.
  Replaces duplicated heading patterns found throughout the templates.
  """
  use Phoenix.Component

  attr :level, :integer, default: 2, values: [1, 2, 3, 4, 5, 6]
  attr :text, :string, required: true
  attr :icon, :string, default: nil
  attr :class, :string, default: ""
  attr :responsive, :boolean, default: false
  slot :actions, required: false

  def section_heading(assigns) do
    base_classes = "font-bold text-gray-900 flex items-center"

    size_classes =
      case {assigns.level, assigns.responsive} do
        {1, false} -> "text-3xl mb-6"
        {1, true} -> "text-2xl sm:text-3xl mb-6"
        {2, false} -> "text-xl mb-4"
        {2, true} -> "text-xl sm:text-2xl mb-4"
        {3, false} -> "text-lg mb-3"
        {3, true} -> "text-lg sm:text-xl mb-3"
        {4, false} -> "text-base mb-3"
        {4, true} -> "text-base sm:text-lg mb-3"
        {5, false} -> "text-sm mb-2"
        {5, true} -> "text-sm sm:text-base mb-2"
        {6, false} -> "text-xs mb-2"
        {6, true} -> "text-xs sm:text-sm mb-2"
      end

    assigns = assign(assigns, :computed_class, "#{base_classes} #{size_classes} #{assigns.class}")
    assigns = assign(assigns, :tag, "h#{assigns.level}")

    ~H"""
    <div class="flex items-center justify-between">
      <.heading_tag name={@tag} class={@computed_class}>
        <%= if @icon do %>
          <svg
            class="w-5 h-5 mr-2 text-gray-600"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
            xmlns="http://www.w3.org/2000/svg"
          >
            <%= Phoenix.HTML.raw(@icon) %>
          </svg>
        <% end %>
        <%= @text %>
      </.heading_tag>

      <%= if @actions != [] do %>
        <div class="flex items-center space-x-2">
          <%= render_slot(@actions) %>
        </div>
      <% end %>
    </div>
    """
  end

  slot :inner_block, required: true
  attr :class, :string, required: true
  attr :name, :string, required: true

  defp heading_tag(assigns) do
    ~H"""
    <%= case @name do %>
      <% "h1" -> %>
        <h1 class={@class}><%= render_slot(@inner_block) %></h1>
      <% "h2" -> %>
        <h2 class={@class}><%= render_slot(@inner_block) %></h2>
      <% "h3" -> %>
        <h3 class={@class}><%= render_slot(@inner_block) %></h3>
      <% "h4" -> %>
        <h4 class={@class}><%= render_slot(@inner_block) %></h4>
      <% "h5" -> %>
        <h5 class={@class}><%= render_slot(@inner_block) %></h5>
      <% "h6" -> %>
        <h6 class={@class}><%= render_slot(@inner_block) %></h6>
    <% end %>
    """
  end
end
