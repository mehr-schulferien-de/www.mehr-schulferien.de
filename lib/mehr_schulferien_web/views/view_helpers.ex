defmodule MehrSchulferienWeb.ViewHelpers do
  @moduledoc """
  Helper functions for use with views.
  """

  def format_date(date, nil) do
    format_date(date, :short) <> "#{date.year |> Integer.to_string() |> String.slice(2, 2)}"
  end

  def format_date(date, :short) do
    "#{add_padding(date.day)}.#{add_padding(date.month)}."
  end

  def format_date_range(from_date, till_date, short \\ nil)

  def format_date_range(same_date, same_date, short) do
    format_date(same_date, short)
  end

  def format_date_range(from_date, till_date, short) do
    format_date(from_date, short) <> " - " <> format_date(till_date, short)
  end

  defp add_padding(entry) do
    entry |> Integer.to_string() |> String.pad_leading(2, "0")
  end
end
