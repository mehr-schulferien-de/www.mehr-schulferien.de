defmodule MehrSchulferien.Repo.Migrations.CorrectMvFerientermineAfterAfervoAmendment do
  use Ecto.Migration

  import Ecto.Query

  # Mecklenburg-Vorpommern amended its AFerVO 2024/2030 M-V on 6 August 2025.
  # The periods for 2026/2027 and 2027/2028 were imported before that and still
  # carried the old dates, which a reader reported in September 2026.
  #
  # Dates checked against regierung-mv.de/.../Schulorganisation/Ferientermine/
  # (2026/2027) and the KMK Ferienkalender 2027/2028, Stand 09.10.2025. The
  # extra days in November now apply to berufliche Schulen only.

  # {type, stored dates, amended dates}
  @moved [
    {"herbst", {~D[2026-10-19], ~D[2026-10-24]}, {~D[2026-10-15], ~D[2026-10-24]}},
    {"weihnachten", {~D[2026-12-19], ~D[2027-01-02]}, {~D[2026-12-21], ~D[2027-01-02]}},
    {"ostern", {~D[2027-03-22], ~D[2027-03-31]}, {~D[2027-03-24], ~D[2027-04-02]}},
    {"herbst", {~D[2027-10-16], ~D[2027-10-23]}, {~D[2027-10-14], ~D[2027-10-23]}},
    {"weihnachten", {~D[2027-12-23], ~D[2028-01-04]}, {~D[2027-12-22], ~D[2028-01-04]}},
    {"ostern", {~D[2028-04-10], ~D[2028-04-19]}, {~D[2028-04-12], ~D[2028-04-21]}}
  ]

  # Right dates, but stored as a public holiday or unlisted. 18.02.2028 is
  # the schulfreier Brückentag after the Winterferien.
  @kept [
    {"pfingsten", {~D[2027-05-14], ~D[2027-05-18]}},
    {"pfingsten", {~D[2028-06-02], ~D[2028-06-06]}},
    {"winter", {~D[2028-02-18], ~D[2028-02-18]}}
  ]

  @removed [
    {"herbst", {~D[2026-11-26], ~D[2026-11-27]}},
    {"herbst", {~D[2027-11-25], ~D[2027-11-26]}},
    # Duplicates of the Pfingstferien under the wrong name.
    {"himmelfahrt", {~D[2027-05-14], ~D[2027-05-18]}},
    {"himmelfahrt", {~D[2028-06-02], ~D[2028-06-06]}},
    # Christi Himmelfahrt falls on 06.05.2027 and 25.05.2028, which are stored
    # as well. The Friday after it is already a Himmelfahrt school vacation.
    {"christi-himmelfahrt", {~D[2027-05-07], ~D[2027-05-07]}},
    {"christi-himmelfahrt", {~D[2028-05-26], ~D[2028-05-26]}}
  ]

  @school_vacation [
    is_school_vacation: true,
    is_valid_for_students: true,
    is_public_holiday: false,
    is_valid_for_everybody: false,
    is_listed_below_month: true,
    display_priority: 5
  ]

  def up do
    # nil on a fresh database without locations, e.g. the test repo.
    if mv_id = federal_state_id("MV") do
      for {type, dates} <- @removed do
        repo().delete_all(periods(mv_id, type, dates))
      end

      # Keeps the row and its id, unless somebody already entered the amended
      # dates by hand: the unique index would refuse a second row.
      for {type, stored, {starts_on, ends_on} = amended} <- @moved do
        if repo().exists?(periods(mv_id, type, amended)) do
          repo().delete_all(periods(mv_id, type, stored))
        else
          repo().update_all(periods(mv_id, type, stored),
            set: [starts_on: starts_on, ends_on: ends_on]
          )
        end
      end

      amended = for {type, _stored, dates} <- @moved, do: {type, dates}

      for {type, dates} <- amended ++ @kept do
        ensure_school_vacation(mv_id, type, dates)
      end
    end
  end

  # The corrected dates are the published ones; rolling back must not bring
  # the outdated ones back.
  def down, do: :ok

  defp ensure_school_vacation(location_id, type, {starts_on, ends_on} = dates) do
    set = [updated_at: now()] ++ @school_vacation

    case repo().update_all(periods(location_id, type, dates), set: set) do
      {0, _} ->
        repo().insert_all("periods", [
          Map.new(
            [
              starts_on: starts_on,
              ends_on: ends_on,
              location_id: location_id,
              holiday_or_vacation_type_id: type_id(type),
              created_by_email_address: "claude@anthropic.com",
              inserted_at: now()
            ] ++ set
          )
        ])

      _ ->
        :ok
    end
  end

  defp periods(location_id, type, {starts_on, ends_on}) do
    from(p in "periods",
      join: t in "holiday_or_vacation_types",
      on: t.id == p.holiday_or_vacation_type_id,
      where:
        p.location_id == ^location_id and t.slug == ^type and
          p.starts_on == ^starts_on and p.ends_on == ^ends_on
    )
  end

  defp federal_state_id(code) do
    repo().one(
      from(l in "locations",
        where: l.code == ^code and l.is_federal_state == true,
        select: l.id,
        limit: 1
      )
    )
  end

  defp type_id(slug) do
    repo().one!(from(t in "holiday_or_vacation_types", where: t.slug == ^slug, select: t.id))
  end

  defp now, do: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
end
