defmodule MehrSchulferienWeb.Shared.DesignTokens do
  @moduledoc """
  Central design token system for the application.
  Defines colors, spacing, typography, and other design constants.
  """

  # Color palette
  def colors do
    %{
      primary: %{
        50 => "bg-blue-50",
        100 => "bg-blue-100",
        200 => "bg-blue-200",
        300 => "bg-blue-300",
        400 => "bg-blue-400",
        500 => "bg-blue-500",
        600 => "bg-blue-600",
        700 => "bg-blue-700",
        800 => "bg-blue-800",
        900 => "bg-blue-900"
      },
      gray: %{
        50 => "bg-gray-50",
        100 => "bg-gray-100",
        200 => "bg-gray-200",
        300 => "bg-gray-300",
        400 => "bg-gray-400",
        500 => "bg-gray-500",
        600 => "bg-gray-600",
        700 => "bg-gray-700",
        800 => "bg-gray-800",
        900 => "bg-gray-900"
      },
      success: %{
        light: "bg-green-100",
        default: "bg-green-600",
        dark: "bg-green-800"
      },
      warning: %{
        light: "bg-yellow-100",
        default: "bg-yellow-500",
        dark: "bg-yellow-700"
      },
      danger: %{
        light: "bg-red-100",
        default: "bg-red-600",
        dark: "bg-red-800"
      }
    }
  end

  # Text colors
  def text_colors do
    %{
      primary: "text-blue-600 dark:text-blue-400",
      primary_hover: "text-blue-800 dark:text-blue-300",
      heading: "text-gray-900 dark:text-gray-100",
      body: "text-gray-700 dark:text-gray-300",
      muted: "text-gray-500 dark:text-gray-400",
      white: "text-white"
    }
  end

  # Spacing scale
  def spacing do
    %{
      # 8px
      xs: "0.5rem",
      # 12px
      sm: "0.75rem",
      # 16px
      md: "1rem",
      # 24px
      lg: "1.5rem",
      # 32px
      xl: "2rem",
      # 48px
      xxl: "3rem"
    }
  end

  # Border radius
  def radius do
    %{
      none: "rounded-none",
      sm: "rounded",
      default: "rounded-md",
      lg: "rounded-lg",
      xl: "rounded-xl",
      full: "rounded-full"
    }
  end

  # Shadow scale
  def shadows do
    %{
      none: "shadow-none",
      sm: "shadow-sm",
      default: "shadow",
      md: "shadow-md",
      lg: "shadow-lg",
      xl: "shadow-xl"
    }
  end

  # Common component styles
  def component_styles do
    %{
      card: %{
        base: "bg-white dark:bg-gray-800 rounded-lg shadow-sm",
        enhanced:
          "bg-white dark:bg-gray-800 rounded-lg shadow-sm border border-gray-200 dark:border-gray-700",
        compact: "bg-white dark:bg-gray-800 rounded-md shadow-sm p-4",
        spacious: "bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6"
      },
      button: %{
        base:
          "inline-flex items-center justify-center font-medium rounded-md transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2",
        primary:
          "text-white bg-blue-600 dark:bg-blue-500 hover:bg-blue-700 dark:hover:bg-blue-600 focus:ring-blue-500 dark:focus:ring-blue-400",
        secondary:
          "text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 hover:bg-gray-50 dark:hover:bg-gray-700 focus:ring-blue-500 dark:focus:ring-blue-400"
      },
      link: %{
        primary:
          "text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 hover:underline transition-colors",
        muted:
          "text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300 hover:underline transition-colors"
      },
      badge: %{
        default: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium",
        primary: "bg-blue-100 dark:bg-blue-900/30 text-blue-800 dark:text-blue-300",
        success: "bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-300",
        warning: "bg-yellow-100 dark:bg-yellow-900/30 text-yellow-800 dark:text-yellow-300",
        danger: "bg-red-100 dark:bg-red-900/30 text-red-800 dark:text-red-300"
      }
    }
  end

  # Typography scale
  def typography do
    %{
      h1: "text-3xl sm:text-4xl font-bold text-gray-900 dark:text-gray-100",
      h2: "text-2xl sm:text-3xl font-bold text-gray-900 dark:text-gray-100",
      h3: "text-xl sm:text-2xl font-semibold text-gray-900 dark:text-gray-100",
      h4: "text-lg sm:text-xl font-semibold text-gray-900 dark:text-gray-100",
      h5: "text-base sm:text-lg font-medium text-gray-900 dark:text-gray-100",
      h6: "text-sm sm:text-base font-medium text-gray-900 dark:text-gray-100",
      body: "text-base text-gray-700 dark:text-gray-300",
      small: "text-sm text-gray-600 dark:text-gray-400",
      muted: "text-sm text-gray-500 dark:text-gray-400"
    }
  end

  # Layout breakpoints
  def breakpoints do
    %{
      sm: "640px",
      md: "768px",
      lg: "1024px",
      xl: "1280px",
      "2xl": "1536px"
    }
  end

  # Z-index scale
  def z_index do
    %{
      dropdown: "1000",
      sticky: "1020",
      fixed: "1030",
      modal_backdrop: "1040",
      modal: "1050",
      popover: "1060",
      tooltip: "1070"
    }
  end

  # Common animations
  def animations do
    %{
      fade_in: "transition-opacity duration-150 ease-in-out",
      slide_down: "transition-all duration-200 ease-out transform",
      scale: "transition-transform duration-150 ease-in-out"
    }
  end

  # Day type colors (consistent with StyleConfig)
  def day_type_colors do
    %{
      holiday: %{
        background: "bg-blue-600 dark:bg-blue-500",
        light_background: "bg-blue-100 dark:bg-blue-900/30",
        text: "text-blue-800 dark:text-blue-300",
        border: "border-blue-200 dark:border-blue-800"
      },
      vacation: %{
        background: "bg-green-600 dark:bg-green-500",
        light_background: "bg-green-100 dark:bg-green-900/30",
        text: "text-green-800 dark:text-green-300",
        border: "border-green-200 dark:border-green-800"
      },
      weekend: %{
        background: "bg-gray-100 dark:bg-gray-700",
        light_background: "bg-gray-50 dark:bg-gray-800",
        text: "text-gray-700 dark:text-gray-300",
        border: "border-gray-200 dark:border-gray-600"
      },
      bridge_day: %{
        background: "bg-yellow-500 dark:bg-yellow-600",
        light_background: "bg-yellow-100 dark:bg-yellow-900/30",
        text: "text-yellow-800 dark:text-yellow-300",
        border: "border-yellow-200 dark:border-yellow-800"
      }
    }
  end
end
