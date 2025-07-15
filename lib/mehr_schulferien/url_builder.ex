defmodule MehrSchulferien.UrlBuilder do
  @moduledoc """
  URL construction logic for the application.
  Core business logic for building URLs - used by both Email and Web layers.
  """

  @base_url "https://www.mehr-schulferien.de"

  @doc """
  Returns the base URL for the application.
  """
  def base_url, do: @base_url

  @doc """
  Constructs the full URL for a school page.

  ## Examples
      
      iex> school_url("d", %{slug: "example-school"})
      "https://www.mehr-schulferien.de/ferien/d/schule/example-school"
  """
  def school_url(country_slug, school) when is_binary(country_slug) do
    "#{@base_url}/ferien/#{country_slug}/schule/#{school.slug}"
  end

  @doc """
  Constructs the full URL for a federal state page.

  ## Examples
      
      iex> federal_state_url("d", %{slug: "bayern"}, 2024)
      "https://www.mehr-schulferien.de/ferien/d/bundesland/bayern/2024"
  """
  def federal_state_url(country_slug, federal_state, year)
      when is_binary(country_slug) and is_integer(year) do
    "#{@base_url}/ferien/#{country_slug}/bundesland/#{federal_state.slug}/#{year}"
  end

  @doc """
  Constructs the full URL for a city page.

  ## Examples
      
      iex> city_url("d", %{slug: "muenchen"}, 2024)
      "https://www.mehr-schulferien.de/ferien/d/stadt/muenchen/2024"
  """
  def city_url(country_slug, city, year) when is_binary(country_slug) and is_integer(year) do
    "#{@base_url}/ferien/#{country_slug}/stadt/#{city.slug}/#{year}"
  end

  @doc """
  Constructs a Google Maps search URL.
  """
  def google_maps_url(query) when is_binary(query) do
    "https://www.google.com/maps?q=#{URI.encode(query)}"
  end

  @doc """
  Constructs an OpenStreetMap search URL.
  """
  def openstreetmap_url(query) when is_binary(query) do
    "https://www.openstreetmap.org/search?query=#{URI.encode(query)}"
  end

  @doc """
  Constructs an Apple Maps search URL.
  """
  def apple_maps_url(query) when is_binary(query) do
    "https://maps.apple.com/?q=#{URI.encode(query)}"
  end
end
