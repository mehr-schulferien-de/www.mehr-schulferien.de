defmodule MehrSchulferienWeb.Shared.TableComponent do
  @moduledoc """
  Shared table components for consistent table styling across the application.
  Provides responsive and accessible table layouts.
  """
  use Phoenix.Component

  attr :class, :string, default: ""
  attr :striped, :boolean, default: true
  attr :hover, :boolean, default: true
  attr :compact, :boolean, default: false
  attr :caption, :string, default: nil
  attr :"aria-label", :string, default: nil
  attr :id, :string, default: nil
  slot :inner_block, required: true

  def table(assigns) do
    base_classes = "min-w-full divide-y divide-gray-200 dark:divide-gray-700"

    assigns = assign(assigns, :computed_class, "#{base_classes} #{assigns.class}")

    ~H"""
    <div
      class="overflow-x-auto rounded-lg border border-gray-200 dark:border-gray-700"
      role="region"
      aria-label={assigns[:"aria-label"] || "Table"}
    >
      <table class={@computed_class} id={@id}>
        <%= if @caption do %>
          <caption class="sr-only">{@caption}</caption>
        <% end %>
        {render_slot(@inner_block)}
      </table>
    </div>
    """
  end

  attr :class, :string, default: ""
  slot :inner_block, required: true

  def thead(assigns) do
    ~H"""
    <thead class={"bg-gray-50 dark:bg-gray-800 #{@class}"}>
      {render_slot(@inner_block)}
    </thead>
    """
  end

  attr :class, :string, default: ""
  attr :striped, :boolean, default: true
  slot :inner_block, required: true

  def tbody(assigns) do
    base_classes = "bg-white dark:bg-gray-900 divide-y divide-gray-200 dark:divide-gray-700"

    assigns = assign(assigns, :computed_class, "#{base_classes} #{assigns.class}")

    ~H"""
    <tbody class={@computed_class}>
      {render_slot(@inner_block)}
    </tbody>
    """
  end

  attr :class, :string, default: ""
  attr :variant, :string, default: "default", values: ["default", "header"]
  attr :align, :string, default: "left", values: ["left", "center", "right"]
  attr :padding, :string, default: "default", values: ["compact", "default", "spacious"]
  slot :inner_block, required: true

  def th(assigns) do
    base_classes = "font-medium tracking-wider text-xs uppercase"

    variant_classes =
      case assigns.variant do
        "default" -> "text-gray-500 dark:text-gray-400"
        "header" -> "text-gray-700 dark:text-gray-300"
      end

    align_classes =
      case assigns.align do
        "left" -> "text-left"
        "center" -> "text-center"
        "right" -> "text-right"
      end

    padding_classes =
      case assigns.padding do
        "compact" -> "px-3 py-2"
        "default" -> "px-6 py-3"
        "spacious" -> "px-6 py-4"
      end

    assigns =
      assign(
        assigns,
        :computed_class,
        "#{base_classes} #{variant_classes} #{align_classes} #{padding_classes} #{assigns.class}"
      )

    ~H"""
    <th scope="col" class={@computed_class}>
      {render_slot(@inner_block)}
    </th>
    """
  end

  attr :class, :string, default: ""
  attr :align, :string, default: "left", values: ["left", "center", "right"]
  attr :padding, :string, default: "default", values: ["compact", "default", "spacious"]
  attr :variant, :string, default: "default", values: ["default", "strong"]
  slot :inner_block, required: true

  def td(assigns) do
    base_classes = "whitespace-nowrap text-sm"

    variant_classes =
      case assigns.variant do
        "default" -> "text-gray-900 dark:text-gray-100"
        "strong" -> "text-gray-900 dark:text-gray-100 font-medium"
      end

    align_classes =
      case assigns.align do
        "left" -> "text-left"
        "center" -> "text-center"
        "right" -> "text-right"
      end

    padding_classes =
      case assigns.padding do
        "compact" -> "px-3 py-2"
        "default" -> "px-6 py-4"
        "spacious" -> "px-6 py-5"
      end

    assigns =
      assign(
        assigns,
        :computed_class,
        "#{base_classes} #{variant_classes} #{align_classes} #{padding_classes} #{assigns.class}"
      )

    ~H"""
    <td class={@computed_class}>
      {render_slot(@inner_block)}
    </td>
    """
  end

  attr :class, :string, default: ""
  attr :hover, :boolean, default: true
  attr :striped_index, :integer, default: nil
  slot :inner_block, required: true

  def tr(assigns) do
    base_classes = ""

    hover_classes = if assigns.hover, do: "hover:bg-gray-50 dark:hover:bg-gray-800", else: ""

    striped_classes =
      if assigns.striped_index do
        if rem(assigns.striped_index, 2) == 0,
          do: "bg-gray-50 dark:bg-gray-800",
          else: "bg-white dark:bg-gray-900"
      else
        ""
      end

    assigns =
      assign(
        assigns,
        :computed_class,
        "#{base_classes} #{hover_classes} #{striped_classes} #{assigns.class}"
      )

    ~H"""
    <tr class={@computed_class}>
      {render_slot(@inner_block)}
    </tr>
    """
  end
end
