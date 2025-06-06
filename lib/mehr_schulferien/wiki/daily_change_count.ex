defmodule MehrSchulferien.Wiki.DailyChangeCount do
  @moduledoc """
  Schema for tracking daily change counts in the wiki system.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "daily_change_counts" do
    field :date, :date
    field :count, :integer, default: 0

    timestamps()
  end

  @doc false
  def changeset(daily_change_count, attrs) do
    daily_change_count
    |> cast(attrs, [:date, :count])
    |> validate_required([:date, :count])
    |> validate_number(:count, greater_than_or_equal_to: 0)
    |> unique_constraint(:date)
  end
end
