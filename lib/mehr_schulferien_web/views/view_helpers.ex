defmodule MehrSchulferienWeb.ViewHelpers do
  @moduledoc """
  Helper functions for use with views.
  """

  def format_date(date) do
    "#{Integer.to_string(date.day) |> String.pad_leading(2, "0")}.#{
      Integer.to_string(date.month) |> String.pad_leading(2, "0")
    }.#{Integer.to_string(date.year) |> String.slice(2, 2)}"
  end

  def format_date(date, :short) do
    "#{Integer.to_string(date.day) |> String.pad_leading(2, "0")}.#{
      Integer.to_string(date.month) |> String.pad_leading(2, "0")
    }."
  end

  def format_date_range(from_date, till_date) do
    case {from_date, till_date} do
      {x, x} ->
        format_date(x)

      {x, y} ->
        format_date(x) <> " - " <> format_date(y)
    end
  end

  def format_date_range(from_date, till_date, :short) do
    case {from_date, till_date} do
      {x, x} ->
        format_date(x, :short)

      {x, y} ->
        format_date(x, :short) <> " - " <> format_date(y, :short)
    end
  end
end
