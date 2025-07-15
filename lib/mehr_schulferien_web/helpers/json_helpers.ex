defmodule MehrSchulferienWeb.Helpers.JsonHelpers do
  @moduledoc """
  JSON escaping utilities to avoid duplication across components.
  """

  @doc """
  Properly escape a string for use in JSON.
  This handles all special characters that need escaping in JSON strings.
  """
  def escape_for_json(string) when is_binary(string) do
    string
    # Escape backslashes first to avoid double-escaping
    |> String.replace("\\", "\\\\")
    # Escape quotes
    |> String.replace("\"", "\\\"")
    # Escape newlines
    |> String.replace("\n", "\\n")
    # Escape carriage returns
    |> String.replace("\r", "\\r")
    # Escape tabs
    |> String.replace("\t", "\\t")
  end

  def escape_for_json(nil), do: ""

  @doc """
  Strip HTML tags from a string and escape for JSON.
  Useful for preparing content that may contain HTML for JSON-LD schemas.
  """
  def strip_html_and_escape(string) when is_binary(string) do
    string
    |> String.replace(~r/<[^>]*>/, "")
    |> escape_for_json()
    |> String.trim()
  end

  def strip_html_and_escape(nil), do: ""
end
