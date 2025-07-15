defmodule MehrSchulferienWeb.SharedComponents.IconComponent do
  @moduledoc """
  Reusable accessible SVG icon components with proper ARIA attributes.
  """
  use Phoenix.Component

  @doc """
  Info icon component
  """
  attr :class, :string, default: "h-5 w-5"
  attr :aria_label, :string, default: nil

  def info_icon(assigns) do
    ~H"""
    <svg
      class={@class}
      viewBox="0 0 20 20"
      fill="currentColor"
      aria-hidden={if @aria_label, do: "false", else: "true"}
      role={if @aria_label, do: "img", else: nil}
      aria-label={@aria_label}
    >
      <title>Information</title>
      <path
        fill-rule="evenodd"
        d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z"
        clip-rule="evenodd"
      />
    </svg>
    """
  end

  @doc """
  Location/Map pin icon
  """
  attr :class, :string, default: "h-5 w-5"
  attr :aria_label, :string, default: nil

  def location_icon(assigns) do
    ~H"""
    <svg
      class={@class}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      aria-hidden={if @aria_label, do: "false", else: "true"}
      role={if @aria_label, do: "img", else: nil}
      aria-label={@aria_label}
    >
      <title>Standort</title>
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"
      />
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"
      />
    </svg>
    """
  end

  @doc """
  Calendar icon
  """
  attr :class, :string, default: "h-5 w-5"
  attr :aria_label, :string, default: nil

  def calendar_icon(assigns) do
    ~H"""
    <svg
      class={@class}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      aria-hidden={if @aria_label, do: "false", else: "true"}
      role={if @aria_label, do: "img", else: nil}
      aria-label={@aria_label}
    >
      <title>Kalender</title>
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
      />
    </svg>
    """
  end

  @doc """
  Email icon
  """
  attr :class, :string, default: "h-5 w-5"
  attr :aria_label, :string, default: nil

  def email_icon(assigns) do
    ~H"""
    <svg
      class={@class}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      aria-hidden={if @aria_label, do: "false", else: "true"}
      role={if @aria_label, do: "img", else: nil}
      aria-label={@aria_label}
    >
      <title>E-Mail</title>
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
      />
    </svg>
    """
  end

  @doc """
  Phone icon
  """
  attr :class, :string, default: "h-5 w-5"
  attr :aria_label, :string, default: nil

  def phone_icon(assigns) do
    ~H"""
    <svg
      class={@class}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      aria-hidden={if @aria_label, do: "false", else: "true"}
      role={if @aria_label, do: "img", else: nil}
      aria-label={@aria_label}
    >
      <title>Telefon</title>
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"
      />
    </svg>
    """
  end

  @doc """
  Link/External link icon
  """
  attr :class, :string, default: "h-5 w-5"
  attr :aria_label, :string, default: nil

  def link_icon(assigns) do
    ~H"""
    <svg
      class={@class}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      aria-hidden={if @aria_label, do: "false", else: "true"}
      role={if @aria_label, do: "img", else: nil}
      aria-label={@aria_label}
    >
      <title>Link</title>
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width="2"
        d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1"
      />
    </svg>
    """
  end

  @doc """
  Check/Success icon
  """
  attr :class, :string, default: "h-5 w-5"
  attr :aria_label, :string, default: nil

  def check_icon(assigns) do
    ~H"""
    <svg
      class={@class}
      viewBox="0 0 20 20"
      fill="currentColor"
      aria-hidden={if @aria_label, do: "false", else: "true"}
      role={if @aria_label, do: "img", else: nil}
      aria-label={@aria_label}
    >
      <title>Erfolgreich</title>
      <path
        fill-rule="evenodd"
        d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
        clip-rule="evenodd"
      />
    </svg>
    """
  end

  @doc """
  Warning icon
  """
  attr :class, :string, default: "h-5 w-5"
  attr :aria_label, :string, default: nil

  def warning_icon(assigns) do
    ~H"""
    <svg
      class={@class}
      viewBox="0 0 20 20"
      fill="currentColor"
      aria-hidden={if @aria_label, do: "false", else: "true"}
      role={if @aria_label, do: "img", else: nil}
      aria-label={@aria_label}
    >
      <title>Warnung</title>
      <path
        fill-rule="evenodd"
        d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"
        clip-rule="evenodd"
      />
    </svg>
    """
  end

  @doc """
  Error/X icon
  """
  attr :class, :string, default: "h-5 w-5"
  attr :aria_label, :string, default: nil

  def error_icon(assigns) do
    ~H"""
    <svg
      class={@class}
      viewBox="0 0 20 20"
      fill="currentColor"
      aria-hidden={if @aria_label, do: "false", else: "true"}
      role={if @aria_label, do: "img", else: nil}
      aria-label={@aria_label}
    >
      <title>Fehler</title>
      <path
        fill-rule="evenodd"
        d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z"
        clip-rule="evenodd"
      />
    </svg>
    """
  end

  @doc """
  Close/X icon for closing modals, alerts etc.
  """
  attr :class, :string, default: "h-5 w-5"
  attr :aria_label, :string, default: "Schließen"

  def close_icon(assigns) do
    ~H"""
    <svg
      class={@class}
      viewBox="0 0 20 20"
      fill="currentColor"
      aria-hidden="false"
      role="img"
      aria-label={@aria_label}
    >
      <title><%= @aria_label %></title>
      <path
        fill-rule="evenodd"
        d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
        clip-rule="evenodd"
      />
    </svg>
    """
  end

  @doc """
  Chevron left icon
  """
  attr :class, :string, default: "h-5 w-5"
  attr :aria_label, :string, default: nil

  def chevron_left_icon(assigns) do
    ~H"""
    <svg
      class={@class}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      aria-hidden={if @aria_label, do: "false", else: "true"}
      role={if @aria_label, do: "img", else: nil}
      aria-label={@aria_label}
    >
      <title>Zurück</title>
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
    </svg>
    """
  end

  @doc """
  Chevron right icon
  """
  attr :class, :string, default: "h-5 w-5"
  attr :aria_label, :string, default: nil

  def chevron_right_icon(assigns) do
    ~H"""
    <svg
      class={@class}
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      aria-hidden={if @aria_label, do: "false", else: "true"}
      role={if @aria_label, do: "img", else: nil}
      aria-label={@aria_label}
    >
      <title>Weiter</title>
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
    </svg>
    """
  end
end
