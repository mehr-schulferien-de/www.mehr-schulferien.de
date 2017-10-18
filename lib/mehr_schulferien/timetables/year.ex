defmodule MehrSchulferien.Timetables.Year do
  use Ecto.Schema
  import Ecto.Changeset
  alias MehrSchulferien.Timetables.Year
  alias MehrSchulferien.ValueSlug

  @derive {Phoenix.Param, key: :slug}
  schema "years" do
    field :value, :integer
    field :slug, ValueSlug.Type

    timestamps()
  end

  @doc false
  def changeset(%Year{} = year, attrs) do
    year
    |> cast(attrs, [:value, :slug])
    |> ValueSlug.set_slug
    |> validate_required([:value, :slug])
    |> unique_constraint(:value)
    |> unique_constraint(:slug)
  end
end
