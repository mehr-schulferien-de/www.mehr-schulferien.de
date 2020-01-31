defmodule MehrSchulferien.Calendars.Religion do
  use Ecto.Schema

  import Ecto.Changeset

  alias MehrSchulferien.NameSlug

  schema "religions" do
    field :name, :string
    field :slug, NameSlug.Type
    field :wikipedia_url, :string

    timestamps()
  end

  @doc false
  def changeset(religion, attrs) do
    religion
    |> cast(attrs, [:name, :slug, :wikipedia_url])
    |> validate_required([:name])
    |> NameSlug.maybe_generate_slug()
    |> NameSlug.unique_constraint()
  end
end
