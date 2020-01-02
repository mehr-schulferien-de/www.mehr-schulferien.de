defmodule MehrSchulferien.Institutions.SchoolType do
  use Ecto.Schema
  import Ecto.Changeset

  schema "school_types" do
    field :name, :string
    field :slug, :string

    timestamps()
  end

  @doc false
  def changeset(school_type, attrs) do
    school_type
    |> cast(attrs, [:name, :slug])
    |> validate_required([:name, :slug])
  end
end
