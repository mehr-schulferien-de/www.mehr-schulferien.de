defmodule MehrSchulferienWeb.ViewHelpers do
  @moduledoc """
  Helper functions for use with views.
  """

  def format_date(date) do
    "#{Integer.to_string(date.day) |> String.pad_leading(2, "0")}.#{
      Integer.to_string(date.month) |> String.pad_leading(2, "0")
    }.#{Integer.to_string(date.year) |> String.slice(2, 2)}"
  end
end
