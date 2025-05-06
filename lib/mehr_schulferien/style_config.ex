defmodule MehrSchulferien.StyleConfig do
  @moduledoc """
  Central configuration for styles used across the application.
  Defines color schemes, CSS classes, and related display settings for different types of days.
  Handles both Bootstrap (legacy) and Tailwind CSS (new) styling.
  """

  # Type definitions
  @type css_framework :: :bootstrap | :tailwind
  @type day_type :: :holiday | :vacation | :weekend | :bridge_day

  # Base color definitions
  @doc """
  Returns all day type definitions with descriptive names
  """
  def day_types do
    %{
      holiday: "Feiertage",
      vacation: "Schulferien",
      weekend: "Wochenenden",
      bridge_day: "Brückentage"
    }
  end

  # Bootstrap class mappings
  @doc """
  Returns a mapping of day types to Bootstrap CSS classes
  """
  def bootstrap_classes do
    %{
      # Red for public holidays
      holiday: "danger",
      # Green for school vacations
      vacation: "success",
      # Gray for weekends
      weekend: "active",
      # Yellow for bridge days
      bridge_day: "warning"
    }
  end

  # Tailwind class mappings
  @doc """
  Returns a mapping of day types to Tailwind CSS classes
  """
  def tailwind_classes do
    %{
      # Blue for public holidays (note: different from Bootstrap)
      holiday: "bg-blue-600",
      # Green for school vacations
      vacation: "bg-green-600",
      # Gray for weekends
      weekend: "bg-gray-100",
      # Yellow for bridge days
      bridge_day: "bg-yellow-500"
    }
  end

  # Tailwind lighter class variants (for background)
  @doc """
  Returns a mapping of day types to lighter Tailwind CSS classes (for backgrounds)
  """
  def tailwind_light_classes do
    %{
      # Light blue for public holidays
      holiday: "bg-blue-100",
      # Light green for school vacations
      vacation: "bg-green-100",
      # Light gray for weekends
      weekend: "bg-gray-100",
      # Light yellow for bridge days
      bridge_day: "bg-yellow-100"
    }
  end

  # Hex color representation for potential future use
  @doc """
  Returns hex color values for each day type
  """
  def hex_colors do
    %{
      holiday: %{
        # Bootstrap danger red
        bootstrap: "#dc3545",
        # Tailwind blue-600
        tailwind: "#2563eb"
      },
      vacation: %{
        # Bootstrap success green
        bootstrap: "#28a745",
        # Tailwind green-600
        tailwind: "#16a34a"
      },
      weekend: %{
        # Bootstrap active light gray
        bootstrap: "#f8f9fa",
        # Tailwind gray-100
        tailwind: "#f3f4f6"
      },
      bridge_day: %{
        # Bootstrap warning yellow
        bootstrap: "#ffc107",
        # Tailwind yellow-500
        tailwind: "#eab308"
      }
    }
  end

  # Helper functions to get classes by type and framework
  @doc """
  Get the CSS class for a specific day type and CSS framework
  """
  @spec get_class(day_type(), css_framework(), boolean()) :: String.t()
  def get_class(day_type, css_framework \\ :bootstrap, light \\ false)

  def get_class(day_type, :bootstrap, _light) do
    Map.get(bootstrap_classes(), day_type, "")
  end

  def get_class(day_type, :tailwind, true) do
    Map.get(tailwind_light_classes(), day_type, "")
  end

  def get_class(day_type, :tailwind, false) do
    Map.get(tailwind_classes(), day_type, "")
  end

  # Helper function to convert html_class from database to day_type
  @doc """
  Converts a saved html_class value to the corresponding day_type
  """
  @spec html_class_to_day_type(String.t()) :: day_type() | nil
  def html_class_to_day_type(html_class) do
    case html_class do
      "success" -> :vacation
      "danger" -> :holiday
      "active" -> :weekend
      "warning" -> :bridge_day
      _ -> nil
    end
  end

  # Helper function to convert period to day_type
  @doc """
  Determines the day_type based on a period's attributes
  """
  @spec period_to_day_type(map()) :: day_type() | nil
  def period_to_day_type(period) when is_map(period) do
    cond do
      Map.get(period, :is_school_vacation, false) -> :vacation
      Map.get(period, :is_public_holiday, false) -> :holiday
      Map.get(period, :html_class) == "warning" -> :bridge_day
      Map.get(period, :html_class) == "active" -> :weekend
      true -> nil
    end
  end
end
