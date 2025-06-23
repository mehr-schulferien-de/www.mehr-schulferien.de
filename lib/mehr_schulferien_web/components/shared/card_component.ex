defmodule MehrSchulferienWeb.Shared.CardComponent do
  @moduledoc """
  Shared card component for consistent card/panel styling across the application.
  Replaces the duplicated card patterns found throughout the templates.
  """
  use Phoenix.Component

  slot :content, required: true
  attr :class, :string, default: ""
  attr :variant, :string, default: "basic", values: ["basic", "enhanced", "rounded", "border"]
  attr :padding, :string, default: "p-4", values: ["p-2", "p-3", "p-4", "p-5", "p-6", "p-8"]

  def card(assigns) do
    base_classes = "bg-white"

    variant_classes =
      case assigns.variant do
        "basic" -> "rounded-lg shadow-sm"
        "enhanced" -> "rounded-lg shadow-sm border border-gray-200"
        "rounded" -> "rounded-xl shadow-md"
        "border" -> "rounded-lg border border-gray-200"
      end

    assigns =
      assign(
        assigns,
        :computed_class,
        "#{base_classes} #{variant_classes} #{assigns.padding} #{assigns.class}"
      )

    ~H"""
    <div class={@computed_class}>
      <%= render_slot(@content) %>
    </div>
    """
  end

  slot :header, required: false
  slot :content, required: true
  slot :footer, required: false
  attr :class, :string, default: ""
  attr :variant, :string, default: "basic"

  def card_with_sections(assigns) do
    base_classes = "bg-white overflow-hidden"

    variant_classes =
      case assigns.variant do
        "basic" -> "rounded-lg shadow-sm"
        "enhanced" -> "rounded-lg shadow-sm border border-gray-200"
        "rounded" -> "rounded-xl shadow-md"
        "border" -> "rounded-lg border border-gray-200"
      end

    assigns =
      assign(assigns, :computed_class, "#{base_classes} #{variant_classes} #{assigns.class}")

    ~H"""
    <div class={@computed_class}>
      <%= if @header != [] do %>
        <div class="px-6 py-4 border-b border-gray-200">
          <%= render_slot(@header) %>
        </div>
      <% end %>

      <div class="px-6 py-4">
        <%= render_slot(@content) %>
      </div>

      <%= if @footer != [] do %>
        <div class="px-6 py-4 bg-gray-50 border-t border-gray-200">
          <%= render_slot(@footer) %>
        </div>
      <% end %>
    </div>
    """
  end
end
