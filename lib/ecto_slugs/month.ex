defmodule MehrSchulferien.Timetables.MonthSlug do
  use EctoAutoslugField.Slug, from: :value, to: :slug
  import Ecto.Changeset

  alias MehrSchulferien.Timetables
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

  # slug: yyyy-mm
  #
  defp build_slug(_sources, changeset) do
    value = get_field(changeset, :value)
    year_id = get_field(changeset, :year_id)

    year = case year_id do
      x when is_integer(x) ->
        query = from y in Timetables.Year, where: y.id == ^year_id
        Repo.one(query)
      _ -> nil
    end

    case [year, value] do
      [nil, _] -> nil
      [_, x] when is_integer(x) and x < 10 -> year.slug <> "-0" <> Integer.to_string(x)
      [_, x] when is_integer(x) -> year.slug <> "-" <> Integer.to_string(x)
      [_, _] -> nil
    end
  end
end
