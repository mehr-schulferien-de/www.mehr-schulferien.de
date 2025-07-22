defmodule MehrSchulferien.Config do
  @moduledoc """
  Configuration constants for the application.
  """

  @doc """
  The daily limit for wiki changes to prevent abuse.
  """
  def daily_change_limit, do: 250
end
