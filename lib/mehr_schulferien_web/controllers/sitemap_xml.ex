defmodule MehrSchulferienWeb.SitemapXML do
  use Phoenix.View,
    root: "lib/mehr_schulferien_web/templates",
    path: "sitemap"

  @doc """
  Finds the most recent period for an entity.
  """
  def find_most_recent_period(entity) do
    MehrSchulferien.Periods.find_most_recent_period(entity.periods)
  end
end
