defmodule MehrSchulferien.Migrations.CorrectMvFerientermineTest do
  use MehrSchulferien.DataCase

  import MehrSchulferien.Factory
  import MehrSchulferien.MigrationHelpers

  alias MehrSchulferien.Periods.Period

  @migration require_migration!("correct_mv_ferientermine_after_afervo_amendment")

  @slugs ~w(herbst weihnachten winter ostern himmelfahrt pfingsten christi-himmelfahrt)

  setup do
    country = insert(:country)

    mv = insert(:federal_state, code: "MV", parent_location_id: country.id)

    %{country: country, types: insert_types(country, @slugs), mv: mv}
  end

  # The rows production holds for 2026/2027 and 2027/2028, taken from the
  # original AFerVO 2024/2030 M-V of 20 July 2022 and the KMK import.
  defp insert_production_rows(%{types: types, mv: mv}) do
    [
      {"herbst", ~D[2026-10-19], ~D[2026-10-24]},
      {"herbst", ~D[2026-11-26], ~D[2026-11-27]},
      {"weihnachten", ~D[2026-12-19], ~D[2027-01-02]},
      {"winter", ~D[2027-02-08], ~D[2027-02-19]},
      {"ostern", ~D[2027-03-22], ~D[2027-03-31]},
      {"himmelfahrt", ~D[2027-05-07], ~D[2027-05-07]},
      {"himmelfahrt", ~D[2027-05-14], ~D[2027-05-18]},
      {"herbst", ~D[2027-10-16], ~D[2027-10-23]},
      {"herbst", ~D[2027-11-25], ~D[2027-11-26]},
      {"weihnachten", ~D[2027-12-23], ~D[2028-01-04]},
      {"winter", ~D[2028-02-05], ~D[2028-02-17]},
      {"ostern", ~D[2028-04-10], ~D[2028-04-19]},
      {"himmelfahrt", ~D[2028-05-26], ~D[2028-05-26]},
      {"himmelfahrt", ~D[2028-06-02], ~D[2028-06-06]}
    ]
    |> Enum.each(fn {slug, starts_on, ends_on} ->
      insert_vacation(types[slug], mv, starts_on, ends_on)
    end)

    for {starts_on, ends_on} <- [
          {~D[2027-05-14], ~D[2027-05-18]},
          {~D[2028-06-02], ~D[2028-06-06]}
        ] do
      insert_vacation(types["pfingsten"], mv, starts_on, ends_on,
        display_priority: 3,
        is_listed_below_month: false
      )
    end

    for date <- [~D[2027-05-06], ~D[2027-05-07], ~D[2028-05-25], ~D[2028-05-26]] do
      insert_holiday(types["christi-himmelfahrt"], mv, date)
    end

    # The Brückentag after the Winterferien 2028, stored as a public holiday.
    insert_holiday(types["winter"], mv, ~D[2028-02-18])
  end

  defp periods_of(location) do
    Repo.all(
      from p in Period,
        join: t in assoc(p, :holiday_or_vacation_type),
        where: p.location_id == ^location.id,
        order_by: [p.starts_on, t.slug],
        select: {t.slug, p.starts_on, p.ends_on}
    )
  end

  @corrected [
    {"herbst", ~D[2026-10-15], ~D[2026-10-24]},
    {"weihnachten", ~D[2026-12-21], ~D[2027-01-02]},
    {"winter", ~D[2027-02-08], ~D[2027-02-19]},
    {"ostern", ~D[2027-03-24], ~D[2027-04-02]},
    {"christi-himmelfahrt", ~D[2027-05-06], ~D[2027-05-06]},
    {"himmelfahrt", ~D[2027-05-07], ~D[2027-05-07]},
    {"pfingsten", ~D[2027-05-14], ~D[2027-05-18]},
    {"herbst", ~D[2027-10-14], ~D[2027-10-23]},
    {"weihnachten", ~D[2027-12-22], ~D[2028-01-04]},
    {"winter", ~D[2028-02-05], ~D[2028-02-17]},
    {"winter", ~D[2028-02-18], ~D[2028-02-18]},
    {"ostern", ~D[2028-04-12], ~D[2028-04-21]},
    {"christi-himmelfahrt", ~D[2028-05-25], ~D[2028-05-25]},
    {"himmelfahrt", ~D[2028-05-26], ~D[2028-05-26]},
    {"pfingsten", ~D[2028-06-02], ~D[2028-06-06]}
  ]

  test "brings the stored periods in line with the amended AFerVO", context do
    insert_production_rows(context)

    run_migration(@migration)

    assert periods_of(context.mv) == @corrected
  end

  test "stores the Brückentag and Pfingstferien as listed school vacation", context do
    insert_production_rows(context)

    run_migration(@migration)

    for {starts_on, ends_on} <- [
          {~D[2028-02-18], ~D[2028-02-18]},
          {~D[2027-05-14], ~D[2027-05-18]},
          {~D[2028-06-02], ~D[2028-06-06]}
        ] do
      period = Repo.get_by!(Period, starts_on: starts_on, ends_on: ends_on)

      assert %{
               is_school_vacation: true,
               is_valid_for_students: true,
               is_public_holiday: false,
               is_valid_for_everybody: false,
               is_listed_below_month: true,
               display_priority: 5
             } = period
    end
  end

  test "is idempotent and tolerates rows somebody already fixed by hand", context do
    insert_production_rows(context)
    insert_vacation(context.types["ostern"], context.mv, ~D[2027-03-24], ~D[2027-04-02])

    run_migration(@migration)
    run_migration(@migration)

    assert periods_of(context.mv) == @corrected
  end

  test "inserts a corrected period that is missing entirely", %{mv: mv} do
    run_migration(@migration)

    periods = periods_of(mv)

    assert {"ostern", ~D[2027-03-24], ~D[2027-04-02]} in periods
    assert length(periods) == 9
  end

  test "leaves other federal states alone", %{country: country, types: types} do
    berlin = insert(:federal_state, parent_location_id: country.id)

    # The same dates the migration corrects for Mecklenburg-Vorpommern.
    insert_vacation(types["herbst"], berlin, ~D[2026-10-19], ~D[2026-10-24])
    insert_vacation(types["himmelfahrt"], berlin, ~D[2027-05-14], ~D[2027-05-18])

    run_migration(@migration)

    assert periods_of(berlin) == [
             {"herbst", ~D[2026-10-19], ~D[2026-10-24]},
             {"himmelfahrt", ~D[2027-05-14], ~D[2027-05-18]}
           ]
  end

  test "does nothing on a database without Mecklenburg-Vorpommern", %{mv: mv} do
    Repo.delete!(mv)

    run_migration(@migration)

    assert Repo.aggregate(Period, :count) == 0
  end
end
