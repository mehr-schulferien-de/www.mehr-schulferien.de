defmodule MehrSchulferien.SlugGenerator do
  @moduledoc """
  Custom slug generation module to replace the slugger package.
  Handles German text properly with umlaut conversion.
  """

  @doc """
  Converts a string to a URL-friendly slug in lowercase.

  ## Examples

      iex> MehrSchulferien.SlugGenerator.slugify_downcase("Hello World")
      "hello-world"
      
      iex> MehrSchulferien.SlugGenerator.slugify_downcase("Schöne Grüße")
      "schoene-gruesse"
      
      iex> MehrSchulferien.SlugGenerator.slugify_downcase("München")
      "muenchen"
      
      iex> MehrSchulferien.SlugGenerator.slugify_downcase("Straße 123")
      "strasse-123"
  """
  def slugify_downcase(string) when is_binary(string) do
    string
    |> String.downcase()
    |> replace_umlauts()
    |> String.replace(~r/[^\w\s-]/u, "")
    |> String.replace(~r/[-\s]+/, "-")
    |> String.trim("-")
  end

  def slugify_downcase(_), do: ""

  defp replace_umlauts(string) do
    string
    |> String.replace("ä", "ae")
    |> String.replace("ö", "oe")
    |> String.replace("ü", "ue")
    |> String.replace("ß", "ss")
    |> String.replace("Ä", "ae")
    |> String.replace("Ö", "oe")
    |> String.replace("Ü", "ue")
  end
end
