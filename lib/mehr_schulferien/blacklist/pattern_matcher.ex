defmodule MehrSchulferien.Blacklist.PatternMatcher do
  @moduledoc """
  Converts wildcard patterns to regex and performs matching.

  Pattern syntax:
  - `*` matches zero or more characters
  - `?` matches exactly one character
  - All other characters are matched literally
  - Matching is case-insensitive
  """

  @doc """
  Converts a wildcard pattern to a regex pattern string.

  ## Examples

      iex> PatternMatcher.to_regex_pattern("+49 30 1234*")
      "^\\\\+49 30 1234.*$"

      iex> PatternMatcher.to_regex_pattern("info@*.schule.de")
      "^info@.*\\\\.schule\\\\.de$"

      iex> PatternMatcher.to_regex_pattern("123?5")
      "^123.5$"
  """
  def to_regex_pattern(pattern) when is_binary(pattern) do
    pattern
    |> escape_regex_chars()
    |> String.replace("\\*", ".*")
    |> String.replace("\\?", ".")
    |> then(&"^#{&1}$")
  end

  @doc """
  Checks if a value matches the blacklist pattern (case-insensitive).

  Returns `true` if the value matches, `false` otherwise.
  """
  def matches?(nil, _regex_pattern), do: false
  def matches?("", _regex_pattern), do: false

  def matches?(value, regex_pattern) when is_binary(value) and is_binary(regex_pattern) do
    case Regex.compile(regex_pattern, [:caseless]) do
      {:ok, regex} -> Regex.match?(regex, value)
      {:error, _} -> false
    end
  end

  @doc """
  Validates a pattern to ensure it's not overly broad.

  Returns `:ok` if the pattern is acceptable, `{:error, reason}` otherwise.

  ## Examples

      iex> PatternMatcher.validate_pattern("*")
      {:error, "Das Muster ist zu allgemein. Bitte geben Sie ein spezifischeres Muster ein."}

      iex> PatternMatcher.validate_pattern("+49 30 1234*")
      :ok
  """
  def validate_pattern(pattern) when is_binary(pattern) do
    trimmed = String.trim(pattern)

    cond do
      trimmed == "" ->
        {:error, "Das Muster darf nicht leer sein."}

      trimmed in ["*", "?", "**", "??", "*?", "?*"] ->
        {:error, "Das Muster ist zu allgemein. Bitte geben Sie ein spezifischeres Muster ein."}

      trimmed == "*@*" or trimmed == "*@*.*" ->
        {:error, "Das Muster ist zu allgemein. Bitte geben Sie ein spezifischeres Muster ein."}

      String.length(trimmed) < 4 ->
        {:error, "Das Muster muss mindestens 4 Zeichen lang sein."}

      # Check for patterns that are mostly wildcards
      mostly_wildcards?(trimmed) ->
        {:error, "Das Muster enthält zu viele Platzhalter."}

      true ->
        :ok
    end
  end

  @doc """
  Compiles a wildcard pattern to a regex for efficient repeated matching.

  Returns `{:ok, regex}` on success, `{:error, reason}` on failure.
  """
  def compile_pattern(pattern) when is_binary(pattern) do
    regex_pattern = to_regex_pattern(pattern)

    case Regex.compile(regex_pattern, [:caseless]) do
      {:ok, regex} -> {:ok, regex}
      {:error, reason} -> {:error, "Ungültiges Muster: #{inspect(reason)}"}
    end
  end

  # Escape special regex characters, but leave * and ? as placeholders
  defp escape_regex_chars(pattern) do
    # First, temporarily replace * and ? with placeholders
    pattern
    |> String.replace("*", "\x00STAR\x00")
    |> String.replace("?", "\x00QUESTION\x00")
    # Escape all regex special chars
    |> Regex.escape()
    # Restore the placeholders as escaped versions (which we'll convert later)
    |> String.replace("\x00STAR\x00", "\\*")
    |> String.replace("\x00QUESTION\x00", "\\?")
  end

  # Check if a pattern is mostly wildcards (more than 50% wildcards)
  defp mostly_wildcards?(pattern) do
    total_length = String.length(pattern)
    wildcard_count = count_wildcards(pattern)

    total_length > 0 and wildcard_count / total_length > 0.5
  end

  defp count_wildcards(pattern) do
    pattern
    |> String.graphemes()
    |> Enum.count(&(&1 in ["*", "?"]))
  end
end
