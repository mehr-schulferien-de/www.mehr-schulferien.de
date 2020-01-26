defmodule MehrSchulferien.LocationNameSlug do
  use EctoAutoslugField.Slug, from: :name, to: :slug

  import Ecto.Changeset
  import Ecto.Query
  alias MehrSchulferien.Repo
  alias MehrSchulferien.Maps.Location

  # Use the given :slug when possible.
  #
  def build_slug(sources, changeset) do
    slug = case get_field(changeset, :slug) do
      nil -> 
        sources
        |> super(sources)
      slug ->
        slug
    end

    new_slug(slug, nil, nil, changeset)    
  end

  def new_slug(slug, federal_state_code, counter, changeset) do
    is_country = get_field(changeset, :is_country)
    is_federal_state = get_field(changeset, :is_federal_state)
    is_county = get_field(changeset, :is_county)
    is_city = get_field(changeset, :is_city)
    is_school = get_field(changeset, :is_school)
    parent_location_id = get_field(changeset, :parent_location_id)

    potential_new_slug = case [federal_state_code, counter] do
      [nil, nil] ->
        slug
      [federal_state_code, nil] ->
        slug <> "-" <> Slugger.slugify_downcase(federal_state_code)
      _ ->
        slug <> "-" <> Slugger.slugify_downcase(federal_state_code) <> "-" <> Integer.to_string(counter)
    end

    # Check if slug is already take.
    #
    query =
      from l in Location,
        where: l.slug == ^potential_new_slug,
        where: l.is_country == ^is_country,
        where: l.is_federal_state == ^is_federal_state,
        where: l.is_county == ^is_county,
        where: l.is_city == ^is_city,
        where: l.is_school == ^is_school,
        limit: 1    

    case Repo.one(query) do
      nil -> 
        potential_new_slug
      _ ->
        case [federal_state_code, counter] do
          [nil, counter] ->
            query =
              from l in Location,
                where: l.id == ^parent_location_id,
                limit: 1
            county = Repo.one(query)
            county_parent_location_id = county.parent_location_id

            query =
              from l in Location,
                where: l.id == ^county_parent_location_id,
                limit: 1
            federal_state = Repo.one(query)

            new_slug(slug, federal_state.code, counter, changeset)
          [federal_state_code, counter] -> 
            case counter do
              counter when is_integer(counter) ->
                new_slug(slug, federal_state_code, counter + 1, changeset)
              _ -> 
                new_slug(slug, federal_state_code, 2, changeset)
            end
          _ -> 
            new_slug(slug, "unkown", 1, changeset)
        end    
    end
  end
  
end
