defmodule MehrSchulferien.Timetables.Category do
  use Ecto.Schema
  import Ecto.Changeset
  alias MehrSchulferien.Timetables.Category
  alias MehrSchulferien.NameSlug

  @derive {Phoenix.Param, key: :slug}
  schema "categories" do
    field :for_anybody, :boolean, default: false
    field :for_students, :boolean, default: false
    field :is_a_religion, :boolean, default: false
    field :name, :string
    field :name_plural, :string
    field :needs_exeat, :boolean, default: false
    field :slug, NameSlug.Type

    timestamps()
  end

  @doc false
  def changeset(%Category{} = category, attrs) do
    category
    |> cast(attrs, [:name, :name_plural, :slug, :needs_exeat, :for_students, :for_anybody, :is_a_religion])
    |> NameSlug.set_slug
    |> validate_required([:name, :name_plural, :slug, :needs_exeat, :for_students, :for_anybody, :is_a_religion])
    |> unique_constraint(:name)
    |> unique_constraint(:slug)
  end
end
