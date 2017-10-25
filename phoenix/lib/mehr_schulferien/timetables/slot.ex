defmodule MehrSchulferien.Timetables.Slot do
  use Ecto.Schema
  import Ecto.Changeset
  alias MehrSchulferien.Timetables.Slot
  alias MehrSchulferien.Timetables


  schema "slots" do
    belongs_to :day, Timetables.Day
    belongs_to :period, Timetables.Period

    timestamps()
  end

  @doc false
  def changeset(%Slot{} = slot, attrs) do
    slot
    |> cast(attrs, [:day_id, :period_id])
    |> validate_required([:day_id, :period_id])
    |> unique_constraint(:day, name: :slots_day_id_period_id_index)
    |> assoc_constraint(:day)
    |> assoc_constraint(:period)
  end
end
