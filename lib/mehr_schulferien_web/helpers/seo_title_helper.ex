defmodule MehrSchulferienWeb.Helpers.SeoTitleHelper do
  @moduledoc """
  Helper functions for optimizing SEO titles to stay within recommended length limits.
  """

  @max_title_length 60
  @max_school_name_length 25

  @doc """
  Optimizes a title to fit within SEO recommended length.
  """
  def optimize_title(title, max_length \\ @max_title_length) do
    if String.length(title) <= max_length do
      title
    else
      truncate_with_ellipsis(title, max_length)
    end
  end

  @doc """
  Formats a year range for titles, converting full years to abbreviated format.
  Examples:
    - "2025/2026" -> "25/26"
    - "2025" -> "2025"
  """
  def format_year_range(year1, year2) when is_integer(year1) and is_integer(year2) do
    if year2 == year1 + 1 do
      "#{rem(year1, 100)}/#{rem(year2, 100)}"
    else
      "#{year1}/#{year2}"
    end
  end

  def format_year_range(year_string) when is_binary(year_string) do
    case String.split(year_string, "/") do
      [year1, year2] ->
        case {Integer.parse(year1), Integer.parse(year2)} do
          {{y1, ""}, {y2, ""}} -> format_year_range(y1, y2)
          _ -> year_string
        end

      _ ->
        year_string
    end
  end

  def format_year_range(year) when is_integer(year), do: "#{year}"

  @doc """
  Truncates school names intelligently with common abbreviations.
  """
  def truncate_school_name(name, max_length \\ @max_school_name_length) do
    abbreviated =
      name
      |> replace_common_terms()
      |> String.trim()

    if String.length(abbreviated) <= max_length do
      abbreviated
    else
      abbreviate_name_parts(abbreviated, max_length)
    end
  end

  @doc """
  Formats a vacation type title concisely.
  """
  def format_vacation_title(vacation_name, location, year) do
    "#{vacation_name} #{location} #{format_year_for_title(year)}"
  end

  defp format_year_for_title(year) when is_binary(year), do: year
  defp format_year_for_title(year) when is_integer(year), do: "#{year}"

  defp replace_common_terms(name) do
    name
    |> String.replace("Grundschule", "GS")
    |> String.replace("Gymnasium", "Gym")
    |> String.replace("Realschule", "RS")
    |> String.replace("Hauptschule", "HS")
    |> String.replace("Gesamtschule", "GesS")
    |> String.replace("Berufsschule", "BS")
    |> String.replace("Förderschule", "FS")
    |> String.replace("Mittelschule", "MS")
    |> String.replace("Oberschule", "OS")
    |> String.replace("Gemeinschaftsschule", "GemS")
    |> String.replace("Sankt", "St.")
    |> String.replace("Saint", "St.")
  end

  defp abbreviate_name_parts(name, max_length) do
    parts = String.split(name, [" ", "-"], trim: true)

    abbreviated =
      if length(parts) > 2 do
        parts
        |> Enum.map(&abbreviate_part/1)
        |> Enum.join("-")
      else
        name
      end

    if String.length(abbreviated) <= max_length do
      abbreviated
    else
      truncate_with_ellipsis(abbreviated, max_length)
    end
  end

  defp abbreviate_part(part) do
    cond do
      String.length(part) <= 3 -> part
      String.match?(part, ~r/^[A-Z]/) -> String.first(part) <> "."
      true -> String.slice(part, 0, 3)
    end
  end

  defp truncate_with_ellipsis(text, max_length) when max_length > 3 do
    if String.length(text) <= max_length do
      text
    else
      String.slice(text, 0, max_length - 3) <> "..."
    end
  end

  defp truncate_with_ellipsis(text, max_length) do
    String.slice(text, 0, max_length)
  end
end
