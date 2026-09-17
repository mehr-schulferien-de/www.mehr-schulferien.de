defmodule MehrSchulferien.Migrations.RemoveDuplicateSchoolVacationsTest do
  use MehrSchulferien.DataCase

  import MehrSchulferien.Factory
  import MehrSchulferien.MigrationHelpers

  alias MehrSchulferien.Periods.Period

  @migration require_migration!("remove_duplicate_school_vacations")

  @slugs ~w(pfingsten himmelfahrt-pfingsten unterrichtsfrei himmelfahrt herbst)

  @pfingsten {~D[2027-05-18], ~D[2027-05-18]}
  @brueckentag {~D[2026-05-15], ~D[2026-05-15]}
  @pfingstferien {~D[2027-05-15], ~D[2027-05-22]}

  setup do
    country = insert(:country)
    state = insert(:federal_state, parent_location_id: country.id)

    %{country: country, types: insert_types(country, @slugs), state: state}
  end

  defp insert_on(type, location, {starts_on, ends_on}),
    do: insert_vacation(type, location, starts_on, ends_on)

  defp vacations_of(location) do
    Repo.all(
      from p in Period,
        join: t in assoc(p, :holiday_or_vacation_type),
        where: p.location_id == ^location.id,
        order_by: [p.starts_on, t.slug],
        select: {t.slug, p.starts_on}
    )
  end

  test "keeps one period per day range, preferring the Pfingsten name", %{
    types: types,
    state: state
  } do
    insert_on(types["himmelfahrt"], state, @pfingsten)
    insert_on(types["pfingsten"], state, @pfingsten)
    insert_on(types["himmelfahrt"], state, @brueckentag)
    insert_on(types["unterrichtsfrei"], state, @brueckentag)
    insert_on(types["himmelfahrt"], state, @pfingstferien)
    insert_on(types["himmelfahrt-pfingsten"], state, @pfingstferien)

    run_migration(@migration)
    run_migration(@migration)

    assert vacations_of(state) == [
             {"unterrichtsfrei", ~D[2026-05-15]},
             {"himmelfahrt-pfingsten", ~D[2027-05-15]},
             {"pfingsten", ~D[2027-05-18]}
           ]
  end

  test "keeps the older period when both carry the same kind of name", %{
    types: types,
    state: state
  } do
    older = insert_on(types["herbst"], state, @brueckentag)
    insert_on(types["himmelfahrt"], state, @brueckentag)

    run_migration(@migration)

    assert Repo.all(select(Period, [p], p.id)) == [older.id]
  end

  test "leaves different days, other states and schools alone", %{
    country: country,
    types: types,
    state: state
  } do
    other_state = insert(:federal_state, parent_location_id: country.id)
    school = insert(:school)

    insert_on(types["himmelfahrt"], state, @pfingsten)
    insert_on(types["pfingsten"], state, @pfingstferien)
    insert_on(types["pfingsten"], other_state, @pfingsten)
    insert_on(types["himmelfahrt"], school, @pfingsten)
    insert_on(types["pfingsten"], school, @pfingsten)

    run_migration(@migration)

    assert length(vacations_of(state)) == 2
    assert length(vacations_of(other_state)) == 1
    assert length(vacations_of(school)) == 2
  end
end
