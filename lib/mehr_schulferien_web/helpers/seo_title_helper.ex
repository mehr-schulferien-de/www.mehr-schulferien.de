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
  Truncates school names intelligently while maintaining readability.
  """
  def truncate_school_name(name, max_length \\ @max_school_name_length) do
    # First, try simple term replacement
    abbreviated =
      name
      |> replace_common_terms()
      |> String.trim()

    if String.length(abbreviated) <= max_length do
      abbreviated
    else
      # If still too long, use smart truncation
      smart_truncate(name, max_length)
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

  defp smart_truncate(name, max_length) do
    # Remove common descriptive phrases first
    cleaned = remove_descriptors(name)

    # Try with just cleaning
    if String.length(cleaned) <= max_length do
      cleaned
    else
      # Extract main name and location
      {main_name, location} = extract_name_and_location(cleaned)

      # Replace common terms in main name
      main_abbreviated = replace_common_terms(main_name)

      # Try with abbreviated main name + location
      with_location =
        if location && String.length(location) <= 15 do
          "#{main_abbreviated} #{location}"
        else
          main_abbreviated
        end

      if String.length(with_location) <= max_length do
        with_location
      else
        # Last resort: truncate the main name more aggressively
        truncate_main_name(main_abbreviated, max_length)
      end
    end
  end

  defp remove_descriptors(name) do
    # Remove common administrative/descriptive phrases
    descriptors = [
      "Staatliche anerkannte",
      "Staatlich anerkannte",
      "Städtische",
      "Städtisches",
      "Staatliche",
      "Staatliches",
      "katholische freie Schule",
      "evangelische freie Schule",
      "katholische Schule",
      "evangelische Schule",
      "freie Schule",
      "Privates",
      "Private",
      "Bischöfliche",
      "Bischöfliches",
      "Erzbischöfliche",
      "Erzbischöfliches"
    ]

    Enum.reduce(descriptors, name, fn descriptor, acc ->
      String.replace(acc, descriptor, "")
    end)
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp extract_name_and_location(name) do
    # Common location indicators
    location_patterns = [
      ~r/\s+(Bad\s+\w+)$/,
      ~r/\s+(am\s+\w+)$/,
      ~r/\s+(im\s+\w+)$/,
      ~r/\s+(in\s+\w+)$/,
      ~r/\s+(\w+burg)$/,
      ~r/\s+(\w+stadt)$/,
      ~r/\s+(\w+hausen)$/,
      ~r/\s+(\w+heim)$/,
      ~r/\s+(\w+dorf)$/
    ]

    # Try to extract location from the end
    location =
      Enum.find_value(location_patterns, fn pattern ->
        case Regex.run(pattern, name) do
          [_, loc] -> loc
          _ -> nil
        end
      end)

    if location do
      main = String.replace(name, location, "") |> String.trim()
      {main, location}
    else
      # Check if last word might be a city name (capitalized, not a school type)
      parts = String.split(name, " ")
      last_word = List.last(parts)

      school_types = [
        "Gymnasium",
        "Grundschule",
        "Realschule",
        "Hauptschule",
        "Gesamtschule",
        "Mittelschule",
        "Oberschule",
        "Berufsschule",
        "Förderschule",
        "Gemeinschaftsschule",
        "Schule"
      ]

      if length(parts) > 2 && last_word not in school_types &&
           String.match?(last_word, ~r/^[A-Z]/) do
        main = parts |> Enum.drop(-1) |> Enum.join(" ")
        {main, last_word}
      else
        {name, nil}
      end
    end
  end

  defp truncate_main_name(name, max_length) do
    # Smart truncation for the main name
    if String.contains?(name, "-") do
      # For hyphenated names, try to keep the pattern recognizable
      parts = String.split(name, "-")

      if length(parts) == 2 do
        # e.g., "Albertus-Magnus-Gym" -> keep first part full, abbreviate second
        [first, second] = parts

        abbreviated_second =
          if String.length(second) > 6 do
            String.slice(second, 0, 3) <> "."
          else
            second
          end

        result = "#{first}-#{abbreviated_second}"

        if String.length(result) <= max_length do
          result
        else
          # Still too long, abbreviate first part too
          truncate_with_ellipsis(name, max_length)
        end
      else
        # Multiple hyphens, keep first two parts if possible
        important_parts = Enum.take(parts, 2) |> Enum.join("-")

        if String.length(important_parts) <= max_length do
          important_parts <> "..."
        else
          truncate_with_ellipsis(name, max_length)
        end
      end
    else
      truncate_with_ellipsis(name, max_length)
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
