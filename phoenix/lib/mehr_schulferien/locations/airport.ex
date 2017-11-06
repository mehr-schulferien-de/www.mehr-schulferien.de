defmodule MehrSchulferien.Locations.Airport do
  use Ecto.Schema
  import Ecto.Changeset
  alias MehrSchulferien.Locations.Airport
  alias MehrSchulferien.Locations.FederalState
  alias MehrSchulferien.CodeSlug
  alias MehrSchulferien.Repo
  import Ecto.Query, only: [from: 2]

  @derive {Phoenix.Param, key: :slug}
  schema "airports" do
    field :code, :string
    field :homepage_url, :string
    field :name, :string
    field :slug, CodeSlug.Type
    field :federal_state_code, :string, virtual: true
    belongs_to :country, MehrSchulferien.Locations.Country
    belongs_to :federal_state, MehrSchulferien.Locations.FederalState

    timestamps()
  end

  @doc false
  def changeset(%Airport{} = airport, attrs) do
    airport
    |> cast(attrs, [:name, :slug, :code, :homepage_url, :federal_state_code, :federal_state_id, :country_id])
    |> CodeSlug.set_slug
    |> set_federal_state_id
    |> validate_length(:code, is: 3)
    |> validate_format(:code, ~r/[A-Z]{3}/)
    |> validate_required([:name, :slug, :code])
    |> unique_constraint(:slug)
  end

  def set_federal_state_id(changeset) do
    federal_state_code = get_field(changeset, :federal_state_code)

    if federal_state_code != nil do
      query = from fs in FederalState, where: fs.code == ^federal_state_code
      federal_state = Repo.one(query)
      case federal_state do
        nil -> changeset
        _ -> changeset = put_change(changeset, :federal_state_id, federal_state.id)
             changeset = put_change(changeset, :country_id, federal_state.country_id)
             changeset
      end
    else
      changeset
    end
  end
end
