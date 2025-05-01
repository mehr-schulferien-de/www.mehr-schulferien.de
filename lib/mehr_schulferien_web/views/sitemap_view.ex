defmodule MehrSchulferienWeb.SitemapView do
  use MehrSchulferienWeb, :view

  import MehrSchulferienWeb.SitemapHelpers

  @doc """
  Finds the most recent period for an entity.
  """
  def find_most_recent_period(entity) do
    MehrSchulferien.Periods.find_most_recent_period(entity.periods)
  end
end
