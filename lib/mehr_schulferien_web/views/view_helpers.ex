defmodule MehrSchulferienWeb.ViewHelpers do
  @moduledoc """
  Helper functions for use with views.
  """

  def format_date(date) do
    "#{date.day}.#{date.month}.#{date.year}"
  end
end
