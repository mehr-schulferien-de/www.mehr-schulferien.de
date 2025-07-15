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
end
