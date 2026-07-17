defmodule MehrSchulferienWeb.Shared.BadgeComponent do
  @moduledoc """
  Shared badge components for consistent status indicators and labels.
  """
  use Phoenix.Component

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
        "default" -> "bg-gray-100 dark:bg-gray-700 text-gray-800 dark:text-gray-200"
        "primary" -> "bg-blue-100 dark:bg-blue-900/30 text-blue-800 dark:text-blue-300"
        "success" -> "bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-300"
        "warning" -> "bg-yellow-100 dark:bg-yellow-900/30 text-yellow-800 dark:text-yellow-300"
        "danger" -> "bg-red-100 dark:bg-red-900/30 text-red-800 dark:text-red-300"
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
      {render_slot(@inner_block)}
    </span>
    """
  end
end
