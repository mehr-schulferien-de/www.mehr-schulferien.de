defmodule MehrSchulferien.Display.FederalState do
  use Ecto.Schema
  import Ecto.Changeset

  schema "federal_states" do
    timestamps()
  end

  @doc false
  def changeset(federal_state, attrs) do
    federal_state
    |> cast(attrs, [])
    |> validate_required([])
  end
end
