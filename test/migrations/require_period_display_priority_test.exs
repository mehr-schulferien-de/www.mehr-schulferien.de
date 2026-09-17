defmodule MehrSchulferien.Migrations.RequirePeriodDisplayPriorityTest do
  use MehrSchulferien.DataCase

  import MehrSchulferien.Factory
  import MehrSchulferien.MigrationHelpers

  alias MehrSchulferien.Periods.Period

  @migration require_migration!("require_period_display_priority")

  setup do
    # The test database already carries the constraint; drop it inside the
    # sandbox transaction to recreate the rows production still has.
    Repo.query!("ALTER TABLE periods ALTER COLUMN display_priority DROP NOT NULL")

    country = insert(:country)
    state = insert(:federal_state, parent_location_id: country.id)
    types = insert_types(country, ~w(herbst beweglicher-ferientag))

    %{state: state, types: types}
  end

  defp insert_without_priority(type, state, date) do
    period = insert_vacation(type, state, date, date)
    Repo.query!("UPDATE periods SET display_priority = NULL WHERE id = $1", [period.id])
    period
  end

  test "fills a missing priority from the type's default, else 5", %{state: state, types: types} do
    Repo.update_all(
      where(MehrSchulferien.Calendars.HolidayOrVacationType, slug: "beweglicher-ferientag"),
      set: [default_display_priority: 7]
    )

    Repo.update_all(
      where(MehrSchulferien.Calendars.HolidayOrVacationType, slug: "herbst"),
      set: [default_display_priority: nil]
    )

    bewegliche = insert_without_priority(types["beweglicher-ferientag"], state, ~D[2027-06-01])
    herbst = insert_without_priority(types["herbst"], state, ~D[2027-10-14])
    set = insert_vacation(types["herbst"], state, ~D[2027-10-15], ~D[2027-10-15])

    run_migration(@migration)

    assert Repo.get!(Period, bewegliche.id).display_priority == 7
    assert Repo.get!(Period, herbst.id).display_priority == 5
    assert Repo.get!(Period, set.id).display_priority == set.display_priority
  end

  test "refuses a period without a priority afterwards", %{state: state, types: types} do
    run_migration(@migration)

    assert_raise Postgrex.Error, ~r/not_null_violation/, fn ->
      insert_without_priority(types["herbst"], state, ~D[2027-10-14])
    end
  end
end
