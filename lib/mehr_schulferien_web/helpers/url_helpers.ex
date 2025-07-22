defmodule MehrSchulferienWeb.Helpers.UrlHelpers do
  @moduledoc """
  Web layer wrapper for URL construction helpers.
  Delegates to core UrlBuilder to avoid duplication.
  """

  alias MehrSchulferien.UrlBuilder

  defdelegate base_url(), to: UrlBuilder
  defdelegate school_url(country_slug, school), to: UrlBuilder
  defdelegate federal_state_url(country_slug, federal_state, year), to: UrlBuilder
  defdelegate city_url(country_slug, city, year), to: UrlBuilder
  defdelegate google_maps_url(query), to: UrlBuilder
  defdelegate openstreetmap_url(query), to: UrlBuilder
  defdelegate apple_maps_url(query), to: UrlBuilder

  @doc """
  Formats a URL for display by removing trailing slashes from domain-only URLs.

  ## Examples

      iex> display_url("https://www.example.com/")
      "https://www.example.com"
      
      iex> display_url("https://www.example.com/path/")
      "https://www.example.com/path/"
      
      iex> display_url("https://www.example.com/path")
      "https://www.example.com/path"
  """
  def display_url(url) when is_binary(url) do
    case URI.parse(url) do
      %URI{scheme: scheme, host: host, path: path}
      when scheme in ["http", "https"] and is_binary(host) ->
        # If path is nil, "/" or empty, it's a domain-only URL
        if path in [nil, "/", ""] do
          # Remove trailing slash for domain-only URLs
          "#{scheme}://#{host}"
        else
          # Keep the URL as-is if it has a real path
          url
        end

      _ ->
        # Return unchanged if parsing fails or it's not a valid HTTP(S) URL
        url
    end
  end

  def display_url(nil), do: nil
  def display_url(url), do: url
end
