defmodule MehrSchulferienWeb.Formatter do

  def truncate(text, opts \\ []) do
    max_length  = opts[:max_length] || 10
    omission    = opts[:omission] || "..."

    cond do
      not String.valid?(text) ->
        text
      String.length(text) < max_length ->
        text
      true ->
        length_with_omission = max_length - String.length(omission)

        "#{String.slice(text, 0, length_with_omission)}#{omission}"
    end
  end

  def starts_to_ends_heading(starts_on, ends_on) do
    case {starts_on.month, starts_on.year, ends_on.month, ends_on.year} do
      {1, x, 12, x} -> Integer.to_string(starts_on.year)
      _ -> three_letter_month(starts_on) <> Integer.to_string(starts_on.year) <> " - " <>
           three_letter_month(ends_on) <> Integer.to_string(ends_on.year)
    end
  end

  def three_letter_month(date) do
    case date.month do
      1 -> "Jan. "
      2 -> "Feb. "
      3 -> "Mär. "
      4 -> "Apr. "
      5 -> "Mai "
      6 -> "Juni "
      7 -> "Juli "
      8 -> "Aug. "
      9 -> "Sep. "
      10 -> "Okt. "
      11 -> "Nov. "
      _ -> "Dez. "
    end
  end

  def starts_on_to_ends_on(starts_on, ends_on) do
    case starts_on.year == ends_on.year do
      true ->  Integer.to_string(starts_on.day) <> "." <>
               Integer.to_string(starts_on.month) <> ". - " <>
               Integer.to_string(ends_on.day) <> "." <>
               Integer.to_string(ends_on.month) <> "." <>
               Integer.to_string(ends_on.year)
      false -> Integer.to_string(starts_on.day) <> "." <>
               Integer.to_string(starts_on.month) <> "." <>
               Integer.to_string(starts_on.year) <> ". - " <>
               Integer.to_string(ends_on.day) <> "." <>
               Integer.to_string(ends_on.month) <> "." <>
               Integer.to_string(ends_on.year)
    end
  end
end
