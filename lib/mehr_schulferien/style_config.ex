defmodule MehrSchulferien.StyleConfig do
  @moduledoc """
  Central configuration for styles used across the application.
  Defines color schemes, CSS classes, and related display settings for different types of days.
  Uses the unified design token system for consistency.
  """

  alias MehrSchulferienWeb.Shared.DesignTokens

  # Type definitions
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

  # Tailwind class mappings
  @doc """
  Returns a mapping of day types to Tailwind CSS classes.
  Uses the unified design token system for consistency.
  """
  def tailwind_classes do
    day_colors = DesignTokens.day_type_colors()

    %{
      holiday: day_colors.holiday.background,
      vacation: day_colors.vacation.background,
      weekend: day_colors.weekend.background,
      bridge_day: day_colors.bridge_day.background
    }
  end

  # Tailwind lighter class variants (for background)
  @doc """
  Returns a mapping of day types to lighter Tailwind CSS classes (for backgrounds).
  Uses the unified design token system for consistency.
  """
  def tailwind_light_classes do
    day_colors = DesignTokens.day_type_colors()

    %{
      holiday: day_colors.holiday.light_background,
      vacation: day_colors.vacation.light_background,
      weekend: day_colors.weekend.light_background,
      bridge_day: day_colors.bridge_day.light_background
    }
  end

  # Helper functions to get classes by type
  @doc """
  Get the CSS class for a specific day type
  """
  @spec get_class(day_type(), boolean()) :: String.t()
  def get_class(day_type, light \\ false)

  def get_class(day_type, true) do
    Map.get(tailwind_light_classes(), day_type, "")
  end

  def get_class(day_type, false) do
    Map.get(tailwind_classes(), day_type, "")
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
      # Bridge days are determined by special logic, not stored in database
      Map.get(period, :__struct__) == MehrSchulferien.Periods.BridgeDayPeriod -> :bridge_day
      # Weekends are determined by date, not stored as periods
      true -> nil
    end
  end
end
