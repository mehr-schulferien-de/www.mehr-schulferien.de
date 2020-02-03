defmodule MehrSchulferien.LocationNameSlug do
  use EctoAutoslugField.Slug, from: :name, to: :slug

  import Ecto.Changeset
  import Ecto.Query

  alias MehrSchulferien.Maps.Location
  alias MehrSchulferien.Repo

  def build_slug(sources, changeset) do
    slug =
      case get_field(changeset, :slug) do
        nil -> super(sources, changeset)
        slug -> slug
      end

    new_slug(slug, changeset)
  end

  defp new_slug(slug, changeset) do
    case already_taken?(slug, changeset) do
      nil ->
        slug

      location ->
        slug = get_slug_base(slug, get_federal_state_code(location))
        alternative_slug(slug, changeset, 0)
    end
  end

  defp alternative_slug(base_slug, changeset, counter) do
    slug = format_slug(base_slug, counter)

    case already_taken?(slug, changeset) do
      nil -> slug
      _ -> alternative_slug(base_slug, changeset, counter + 1)
    end
  end

  defp get_slug_base(slug, federal_state_code) do
    slug <> "-" <> Slugger.slugify_downcase(federal_state_code)
  end

  defp format_slug(slug, 0), do: slug
  defp format_slug(slug, counter), do: slug <> "-" <> Integer.to_string(counter)

  defp already_taken?(slug, changeset) do
    is_country = get_field(changeset, :is_country)
    is_federal_state = get_field(changeset, :is_federal_state)
    is_county = get_field(changeset, :is_county)
    is_city = get_field(changeset, :is_city)
    is_school = get_field(changeset, :is_school)

    query =
      from l in Location,
        where: l.slug == ^slug,
        where: l.is_country == ^is_country,
        where: l.is_federal_state == ^is_federal_state,
        where: l.is_county == ^is_county,
        where: l.is_city == ^is_city,
        where: l.is_school == ^is_school,
        limit: 1

    Repo.one(query)
  end

  defp get_federal_state_code(%Location{parent_location_id: nil}), do: "unknown"

  defp get_federal_state_code(%Location{is_federal_state: true, code: code}) do
    code
  end

  defp get_federal_state_code(%Location{parent_location_id: parent_location_id}) do
    case get_parent(parent_location_id) do
      nil -> "unknown"
      location -> get_federal_state_code(location)
    end
  end

  defp get_parent(parent_location_id) do
    query =
      from l in Location,
        where: l.id == ^parent_location_id,
        limit: 1

    Repo.one(query)
  end
end
