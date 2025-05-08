defmodule MehrSchulferienWeb.Old.ViewHelpers do
  @moduledoc """
  View helpers for the old templates.
  """

  @doc """
  Generates a path to the old city show route.
  """
  def old_city_path(_conn, country_slug, city_slug) do
    "/old/ferien/#{country_slug}/stadt/#{city_slug}"
  end
end
