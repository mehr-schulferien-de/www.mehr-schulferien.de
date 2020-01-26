defmodule MehrSchulferien.ZipCodeValueSlug do
  use EctoAutoslugField.Slug, from: :value, to: :slug
end
