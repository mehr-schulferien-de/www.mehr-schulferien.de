defmodule MehrSchulferien.NameSlug do
  use EctoAutoslugField.Slug, from: :name, to: :slug

  import Ecto.Changeset

  # Use the given :slug when possible.
  #
  def build_slug(sources, changeset) do
    case get_field(changeset, :slug) do
      nil -> 
        sources
        |> super(sources)
      slug ->
        slug
    end    
  end   
end
