defmodule MehrSchulferien.RateLimiter.Counter do
  @moduledoc """
  Schema for rate limit counters.

  Counters are keyed by a string that encodes the scope (user/global),
  time period (hourly/daily), and the relevant date/hour.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "rate_limit_counters" do
    field :key, :string
    field :count, :integer, default: 0
    field :expires_at, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(counter, attrs) do
    counter
    |> cast(attrs, [:key, :count, :expires_at])
    |> validate_required([:key, :expires_at])
    |> unique_constraint(:key)
  end
end
