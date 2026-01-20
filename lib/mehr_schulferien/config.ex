defmodule MehrSchulferien.Config do
  @moduledoc """
  Configuration constants for the application.
  """

  @doc """
  The daily limit for wiki changes to prevent abuse.
  """
  def daily_change_limit, do: 250

  @doc """
  Returns whether school contact info (phone/email) display and editing is enabled.
  Set to `false` to temporarily disable for legal concerns.
  """
  def school_contact_info_enabled? do
    Application.get_env(:mehr_schulferien, :school_contact_info_enabled, true)
  end
end
