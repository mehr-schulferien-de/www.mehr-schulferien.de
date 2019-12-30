defmodule MehrSchulferien.Locations.ZipCodeNameSlug do
  use EctoAutoslugField.Slug, from: :name, to: :slug
  import Ecto.Changeset
  alias MehrSchulferien.Locations.City
  alias MehrSchulferien.Repo
  import Ecto.Query, only: [from: 2]

  def set_slug(changeset) do
    slug = get_field(changeset, :slug)

    case slug do
      nil -> changeset
             |> maybe_generate_slug
             |> unique_constraint
      _ -> changeset
    end
  end

  def build_slug(_sources, changeset) do
    name = get_field(changeset, :name)
    zip_code = get_field(changeset, :zip_code)

    if Enum.member?([name, zip_code], nil) do
      UUID.uuid1()
    else
      # Avoid super long slugs.
      #
      base_slug = Slugger.slugify(String.downcase(zip_code)) <>
                  "-" <>
                  Slugger.slugify(String.downcase(MehrSchulferienWeb.Formatter.truncate(name, max_length: 70)))

      # Check if this slug is taken add UUID if it is
      #
      query = from s in City, where: s.slug == ^base_slug

      if Repo.one(query) != nil do
        base_slug = base_slug <> "-" <> UUID.uuid1()
      else
        base_slug
      end
    end
  end

end
