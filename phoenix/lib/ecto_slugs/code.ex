defmodule MehrSchulferien.CodeSlug do
  use EctoAutoslugField.Slug, from: :code, to: :slug
  import Ecto.Changeset

  def set_slug(changeset) do
    code = get_field(changeset, :code)
    slug = get_field(changeset, :slug)

    case {code, slug} do
      {_, nil} -> changeset
                  |> maybe_generate_slug
                  |> unique_constraint
      {_, _} -> changeset
    end
  end
end
