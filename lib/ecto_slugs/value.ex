defmodule MehrSchulferien.ValueSlug do
  use EctoAutoslugField.Slug, to: :slug
  import Ecto.Changeset

  def get_sources(changeset, _opts) do
    value = get_field(changeset, :value)
    case value do
      nil -> []
      _ -> [Integer.to_string(value)]
    end
  end

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
