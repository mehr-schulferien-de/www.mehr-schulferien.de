defmodule MehrSchulferien.Timetables.DaySlug do
  use EctoAutoslugField.Slug, from: :value, to: :slug
  import Ecto.Changeset

  alias MehrSchulferien.Timetables.Year
  alias MehrSchulferien.Timetables.Month
  alias MehrSchulferien.Repo
  import Ecto.Query

  # slug: yyyy-mm-dd
  #
  def build_slug(_sources, changeset) do
    value = get_field(changeset, :value)
    year_id = get_field(changeset, :year_id)
    month_id = get_field(changeset, :month_id)

    year = case year_id do
      x when is_integer(x) ->
        query = from y in Year, where: y.id == ^year_id
        Repo.one(query)
      _ -> nil
    end

    month = case month_id do
      x when is_integer(x) ->
        query = from m in Month, where: m.id == ^month_id
        Repo.one(query)
      _ -> nil
    end

    case [year, month, value.day] do
      [nil, _, _] -> nil
      [_, nil, _] -> nil
      [_, _, x] when is_integer(x) and x < 10 -> month.slug <> "-0" <> Integer.to_string(x)
      [_, _, x] when is_integer(x) -> month.slug <> "-" <> Integer.to_string(x)
      [_, _, _] -> nil
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
