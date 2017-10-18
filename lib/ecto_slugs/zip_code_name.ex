defmodule MehrSchulferien.Locations.ZipCodeNameSlug do
  use EctoAutoslugField.Slug, from: [:zip_code, :name], to: :slug
  import Ecto.Changeset

  def set_slug(changeset) do
    slug = get_field(changeset, :slug)

    case slug do
      nil -> changeset
             |> maybe_generate_slug
             |> unique_constraint
      _ -> changeset
    end
  end
end
