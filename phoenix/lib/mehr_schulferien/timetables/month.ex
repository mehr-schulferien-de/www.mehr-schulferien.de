defmodule MehrSchulferien.Timetables.Month do
  use Ecto.Schema
  import Ecto.Changeset
  alias MehrSchulferien.Timetables.Month
  alias MehrSchulferien.Timetables.MonthSlug


  @derive {Phoenix.Param, key: :slug}
  schema "months" do
    field :slug, MonthSlug.Type
    field :value, :integer
    belongs_to :year, MehrSchulferien.Timetables.Year

    timestamps()
  end

  @doc false
  def changeset(%Month{} = month, attrs) do
    month
    |> cast(attrs, [:value, :slug, :year_id])
    |> MonthSlug.set_slug
    |> validate_required([:value, :slug])
    |> unique_constraint(:slug)
    |> assoc_constraint(:year)
  end
end
