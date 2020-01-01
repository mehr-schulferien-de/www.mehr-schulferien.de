defmodule MehrSchulferien.NameSlug do
  use EctoAutoslugField.Slug, from: :name, to: :slug
end
