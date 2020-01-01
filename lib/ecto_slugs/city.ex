defmodule MehrSchulferien.CitySlug do
  use EctoAutoslugField.Slug, from: :name, to: :slug

  import Ecto.Changeset
  alias MehrSchulferien.Locations.City
  alias MehrSchulferien.Locations.ZipCode
  alias MehrSchulferien.Repo
  import Ecto.Query, only: [from: 2]

  def build_slug(_sources, changeset) do
    name = get_field(changeset, :name)
    [%ZipCode{value: zip_code_value}] = get_field(changeset, :zip_codes)

    # Check if this slug is taken add zip_code if it is.
    # If that is taken too add a UUID.
    #
    base_slug = Slugger.slugify(String.downcase(name))
    query = from s in City, where: s.slug == ^base_slug

    if Repo.one(query) != nil do
      new_base_slug = base_slug <> "-" <> zip_code_value
      query = from s in City, where: s.slug == ^new_base_slug

      if Repo.one(query) != nil do
        base_slug <> "-" <> UUID.uuid1()
      else
        new_base_slug
      end
    else
      base_slug
    end
  end
end
