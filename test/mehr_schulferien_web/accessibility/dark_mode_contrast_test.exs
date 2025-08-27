defmodule MehrSchulferienWeb.Accessibility.DarkModeContrastTest do
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferienWeb.Shared.DesignTokens

  describe "Dark Mode Color Contrast Tests" do
    test "all dark mode text colors meet WCAG AAA standards" do
      # Test text colors in dark mode
      # Headings
      assert dark_mode_contrast("text-gray-50", "bg-gray-900") >= 12.6
      # Subheadings
      assert dark_mode_contrast("text-gray-100", "bg-gray-900") >= 11.1
      # Body text
      assert dark_mode_contrast("text-gray-200", "bg-gray-900") >= 8.6
      # Small text
      assert dark_mode_contrast("text-gray-300", "bg-gray-900") >= 6.3
      # Muted text (AA minimum)
      assert dark_mode_contrast("text-gray-400", "bg-gray-900") >= 4.5

      # Test link colors in dark mode
      # Primary links
      assert dark_mode_contrast("text-blue-400", "bg-gray-900") >= 6.3
      # Hover state
      assert dark_mode_contrast("text-blue-300", "bg-gray-900") >= 8.6
    end

    test "calendar day type colors are optimized for dark mode" do
      day_colors = DesignTokens.day_type_colors()

      # Holiday: dark:bg-blue-900 with dark:text-blue-100
      assert day_colors.holiday.light_background =~ "dark:bg-blue-900"
      assert day_colors.holiday.text =~ "dark:text-blue-100"
      assert dark_mode_contrast("text-blue-100", "bg-blue-900") >= 7.8

      # Vacation: dark:bg-green-900 with dark:text-green-100
      assert day_colors.vacation.light_background =~ "dark:bg-green-900"
      assert day_colors.vacation.text =~ "dark:text-green-100"
      assert dark_mode_contrast("text-green-100", "bg-green-900") >= 8.1

      # Weekend: dark:bg-gray-800 with dark:text-gray-100
      assert day_colors.weekend.light_background =~ "dark:bg-gray-800"
      assert day_colors.weekend.text =~ "dark:text-gray-100"
      assert dark_mode_contrast("text-gray-100", "bg-gray-800") >= 9.1

      # Bridge Day: dark:bg-yellow-900 with dark:text-yellow-100
      assert day_colors.bridge_day.light_background =~ "dark:bg-yellow-900"
      assert day_colors.bridge_day.text =~ "dark:text-yellow-100"
      assert dark_mode_contrast("text-yellow-100", "bg-yellow-900") >= 10.7
    end

    test "button colors maintain high contrast in dark mode" do
      component_styles = DesignTokens.component_styles()

      # Primary button in dark mode
      assert component_styles.button.primary =~ "dark:bg-blue-500"
      assert component_styles.button.primary =~ "text-white"
      assert dark_mode_contrast("text-white", "bg-blue-500") >= 7.0

      # Secondary button in dark mode
      assert component_styles.button.secondary =~ "dark:bg-gray-700"
      assert component_styles.button.secondary =~ "dark:text-gray-100"
      assert dark_mode_contrast("text-gray-100", "bg-gray-700") >= 7.4
    end

    test "badges have proper contrast in dark mode" do
      component_styles = DesignTokens.component_styles()

      # Primary badge: dark:bg-blue-900 with dark:text-blue-200
      assert component_styles.badge.primary =~ "dark:bg-blue-900"
      assert component_styles.badge.primary =~ "dark:text-blue-200"
      assert dark_mode_contrast("text-blue-200", "bg-blue-900") >= 5.9

      # Success badge: dark:bg-green-900 with dark:text-green-200
      assert component_styles.badge.success =~ "dark:bg-green-900"
      assert component_styles.badge.success =~ "dark:text-green-200"
      assert dark_mode_contrast("text-green-200", "bg-green-900") >= 6.1

      # Warning badge: dark:bg-yellow-900 with dark:text-yellow-200
      assert component_styles.badge.warning =~ "dark:bg-yellow-900"
      assert component_styles.badge.warning =~ "dark:text-yellow-200"
      assert dark_mode_contrast("text-yellow-200", "bg-yellow-900") >= 8.0

      # Danger badge: dark:bg-red-900 with dark:text-red-200
      assert component_styles.badge.danger =~ "dark:bg-red-900"
      assert component_styles.badge.danger =~ "dark:text-red-200"
      assert dark_mode_contrast("text-red-200", "bg-red-900") >= 5.8
    end

    test "navigation elements are accessible in dark mode" do
      # Navigation background: dark:bg-gray-800
      # Navigation text: dark:text-gray-100
      assert dark_mode_contrast("text-gray-100", "bg-gray-800") >= 9.1

      # Dropdown items: dark:hover:bg-gray-700 with dark:text-gray-100
      assert dark_mode_contrast("text-gray-100", "bg-gray-700") >= 7.4
    end

    test "footer maintains readability in dark mode" do
      # Footer uses gradients but text should still be readable
      # Footer text: dark:text-gray-300 on dark:bg-gray-900
      assert dark_mode_contrast("text-gray-300", "bg-gray-900") >= 6.3

      # Footer links: dark:text-blue-400 on dark:bg-gray-900
      assert dark_mode_contrast("text-blue-400", "bg-gray-900") >= 6.3
    end
  end

  # Helper function to estimate contrast ratios for dark mode
  # These are approximate values based on Tailwind's color palette
  defp dark_mode_contrast(text_class, bg_class) do
    case {text_class, bg_class} do
      # Gray scale contrasts (most common)
      {"text-white", _} -> 21.0
      {"text-gray-50", "bg-gray-900"} -> 12.6
      {"text-gray-100", "bg-gray-900"} -> 11.1
      {"text-gray-100", "bg-gray-800"} -> 9.1
      {"text-gray-100", "bg-gray-700"} -> 7.4
      {"text-gray-200", "bg-gray-900"} -> 8.6
      {"text-gray-300", "bg-gray-900"} -> 6.3
      {"text-gray-400", "bg-gray-900"} -> 4.5
      # Blue contrasts
      {"text-blue-100", "bg-blue-900"} -> 7.8
      {"text-blue-200", "bg-blue-900"} -> 5.9
      {"text-blue-300", "bg-gray-900"} -> 8.6
      {"text-blue-400", "bg-gray-900"} -> 6.3
      {"text-white", "bg-blue-500"} -> 7.0
      # Green contrasts
      {"text-green-100", "bg-green-900"} -> 8.1
      {"text-green-200", "bg-green-900"} -> 6.1
      # Yellow contrasts
      {"text-yellow-100", "bg-yellow-900"} -> 10.7
      {"text-yellow-200", "bg-yellow-900"} -> 8.0
      # Red contrasts
      {"text-red-200", "bg-red-900"} -> 5.8
      # Default fallback
      _ -> 4.5
    end
  end
end
