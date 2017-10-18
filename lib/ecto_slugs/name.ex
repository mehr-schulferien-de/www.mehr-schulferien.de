defmodule MehrSchulferien.NameSlug do
  use EctoAutoslugField.Slug, from: :name, to: :slug
  import Ecto.Changeset

  def set_slug(changeset) do
    name = get_field(changeset, :name)
    slug = get_field(changeset, :slug)

    case {name, slug} do
      {_, nil} -> changeset
                  |> maybe_generate_slug
                  |> unique_constraint
      {_, _} -> changeset
    end
  end
end
