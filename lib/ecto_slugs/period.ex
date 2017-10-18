defmodule MehrSchulferien.Timetables.PeriodSlug do
  use EctoAutoslugField.Slug, from: :starts_on, to: :slug
  import Ecto.Changeset
  alias MehrSchulferien.Locations
  alias MehrSchulferien.Timetables.Period
  alias MehrSchulferien.Repo
  import Ecto.Query


  def set_slug(changeset) do
    slug = get_field(changeset, :slug)

    case slug do
      nil -> changeset
             |> maybe_generate_slug
             |> unique_constraint
      _ -> changeset
    end
  end

  # slug: start with a minimal one and add stuff
  # if needed. Not 100% unique secure but good enough.
  #
  defp build_slug(_sources, changeset) do
    starts_on = get_field(changeset, :starts_on)
    ends_on = get_field(changeset, :ends_on)
    name = get_field(changeset, :name)
    school_id = get_field(changeset, :school_id)
    city_id = get_field(changeset, :city_id)
    federal_state_id = get_field(changeset, :federal_state_id)
    country_id = get_field(changeset, :country_id)

    location = case {school_id, city_id, federal_state_id, country_id} do
      {nil, nil, nil, id} when is_integer(id) ->
        Locations.get_country!(id)
      {nil, nil, id, nil} when is_integer(id) ->
        Locations.get_federal_state!(id)
      {nil, id, nil, nil} when is_integer(id) ->
        Locations.get_city!(id)
      {id, nil, nil, nil} when is_integer(id) ->
        Locations.get_school!(id)
      {_, _, _, _} ->
        nil
    end

    location = case location do
      nil -> ""
      _ -> location.slug
    end

    # Start with a minimal slug
    #
    base_slug = Slugger.slugify(String.downcase(name)) <>
                "-" <>
                Integer.to_string(starts_on.year) <>
                "-" <>
                location

    # Check if this slug is taken add date if it is
    #
    query = from p in Period, where: p.slug == ^base_slug
    new_slug = case {Repo.one(query), starts_on, ends_on} do
      {nil, _, _} -> base_slug
      {_, x, x} -> base_slug <> "-" <>
                   Integer.to_string(starts_on.day) <> "." <> Integer.to_string(starts_on.month) <> "."
      {_, _, _} -> base_slug <> "-" <>
                   Integer.to_string(starts_on.day) <> "." <> Integer.to_string(starts_on.month) <> ".-" <>
                   Integer.to_string(ends_on.day) <> "." <> Integer.to_string(ends_on.month) <> "."
    end

    # Check again and add UUID if it is
    #
    query = from p in Period, where: p.slug == ^new_slug

    case Repo.one(query) do
      nil -> new_slug
      _ -> new_slug <> "-" <> UUID.uuid1()
    end
  end

end
