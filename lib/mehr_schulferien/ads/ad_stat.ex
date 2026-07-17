defmodule MehrSchulferien.Ads.AdStat do
  @moduledoc """
  One day of counters for one ad variant (unique on day + variant_id).
  Rows are only ever written by `MehrSchulferien.Ads.Recorder` via
  upsert-increment; there is no changeset because no user input reaches
  this table.
  """

  use Ecto.Schema

  schema "ad_stats" do
    field :day, :date
    field :variant_id, :integer
    field :impressions, :integer, default: 0
    field :clicks, :integer, default: 0

    timestamps()
  end
end
