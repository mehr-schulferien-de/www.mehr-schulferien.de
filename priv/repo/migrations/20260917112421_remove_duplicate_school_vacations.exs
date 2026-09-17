defmodule MehrSchulferien.Repo.Migrations.RemoveDuplicateSchoolVacations do
  use Ecto.Migration

  import Ecto.Query

  # The August 2025 data fix added a second school vacation for days that
  # already had one, so the Bundesland pages list them twice, often under the
  # wrong name (Himmelfahrtsferien for the Tuesday after Pfingsten). Of each
  # group the most specific name stays; among equals, the oldest row.

  @rank %{"pfingsten" => 3, "himmelfahrt-pfingsten" => 2, "unterrichtsfrei" => 1}

  def up do
    doomed =
      from(p in "periods",
        join: l in "locations",
        on: l.id == p.location_id,
        join: t in "holiday_or_vacation_types",
        on: t.id == p.holiday_or_vacation_type_id,
        where: l.is_federal_state and p.is_school_vacation,
        select: %{id: p.id, slug: t.slug, days: {p.location_id, p.starts_on, p.ends_on}}
      )
      |> repo().all()
      |> Enum.group_by(& &1.days)
      |> Enum.flat_map(fn {_days, periods} ->
        [_kept | rest] = Enum.sort_by(periods, &{-Map.get(@rank, &1.slug, 0), &1.id})
        Enum.map(rest, & &1.id)
      end)

    repo().delete_all(from(p in "periods", where: p.id in type(^doomed, {:array, :id})))
  end

  # Restoring the duplicates would only bring the double listings back.
  def down, do: :ok
end
