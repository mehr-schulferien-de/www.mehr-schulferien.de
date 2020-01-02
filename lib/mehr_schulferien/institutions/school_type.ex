defmodule MehrSchulferien.Institutions.SchoolType do
  use Ecto.Schema
  import Ecto.Changeset
  alias MehrSchulferien.NameSlug

  schema "school_types" do
    field :name, :string
    field :slug, NameSlug.Type

    timestamps()
  end

  @doc false
  def changeset(school_type, attrs) do
    school_type
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
