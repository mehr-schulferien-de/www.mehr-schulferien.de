defmodule MehrSchulferien.Timetables.InsetDayQuantity do
  use Ecto.Schema
  import Ecto.Changeset
  alias MehrSchulferien.Timetables.InsetDayQuantity

  # Bewegliche Ferientage
  #
  schema "inset_day_quantities" do
    field :value, :integer
    belongs_to :federal_state, MehrSchulferien.Locations.FederalState
    belongs_to :year, MehrSchulferien.Timetables.Year

    timestamps()
  end

  @doc false
  def changeset(%InsetDayQuantity{} = inset_day_quantity, attrs) do
    inset_day_quantity
    |> cast(attrs, [:value, :federal_state_id, :year_id])
    |> validate_required([:value, :federal_state_id, :year_id])
    |> validate_number(:value, greater_than: 0)
    |> assoc_constraint(:year)
    |> assoc_constraint(:federal_state)
    |> unique_constraint(:federal_state_id, name: :state_id_year_id)
  end
end
