defmodule MehrSchulferien.Migrations.CorrectPublicHolidays20272028Test do
  use MehrSchulferien.DataCase

  import MehrSchulferien.Factory
  import MehrSchulferien.MigrationHelpers

  alias MehrSchulferien.Periods.Period

  @migration require_migration!("correct_public_holidays_2027_2028")

  @holidays ~w(christi-himmelfahrt pfingstmontag reformationstag allerheiligen weltkindertag)
  @vacations ~w(winter himmelfahrt pfingsten)

  setup do
    country = insert(:country)

    states =
      Map.new(~w(BE HH NI NW TH), fn code ->
        {code, insert(:federal_state, code: code, parent_location_id: country.id)}
      end)

    %{types: insert_types(country, @holidays ++ @vacations, @vacations), states: states}
  end

  defp holidays_of(state) do
    Repo.all(
      from p in Period,
        join: t in assoc(p, :holiday_or_vacation_type),
        where: p.location_id == ^state.id and p.is_public_holiday,
        order_by: p.starts_on,
        select: {t.slug, p.starts_on}
    )
  end

  test "drops a holiday stored on the school-free day next to the real one", %{
    types: types,
    states: %{"NI" => ni}
  } do
    insert_holiday(types["christi-himmelfahrt"], ni, ~D[2027-05-06])
    insert_holiday(types["christi-himmelfahrt"], ni, ~D[2027-05-07])
    insert_vacation(types["himmelfahrt"], ni, ~D[2027-05-07], ~D[2027-05-07])
    insert_holiday(types["pfingstmontag"], ni, ~D[2028-06-05])
    insert_holiday(types["pfingstmontag"], ni, ~D[2028-06-06])
    insert_vacation(types["pfingsten"], ni, ~D[2028-06-06], ~D[2028-06-06])

    run_migration(@migration)

    assert holidays_of(ni) == [
             {"christi-himmelfahrt", ~D[2027-05-06]},
             {"reformationstag", ~D[2027-10-31]},
             {"pfingstmontag", ~D[2028-06-05]},
             {"reformationstag", ~D[2028-10-31]}
           ]

    assert Repo.aggregate(where(Period, is_school_vacation: true), :count) == 2
  end

  test "keeps a misdated holiday when no school vacation marks that day", %{
    types: types,
    states: %{"BE" => berlin}
  } do
    insert_holiday(types["pfingstmontag"], berlin, ~D[2028-06-01])

    run_migration(@migration)

    assert holidays_of(berlin) == [{"pfingstmontag", ~D[2028-06-01]}]
  end

  test "turns a vacation day stored as a public holiday into a school-free day", %{
    types: types,
    states: %{"HH" => hamburg}
  } do
    insert_holiday(types["winter"], hamburg, ~D[2027-01-29])

    run_migration(@migration)

    assert %{
             is_school_vacation: true,
             is_valid_for_students: true,
             is_public_holiday: false,
             is_valid_for_everybody: false,
             display_priority: 5
           } = Repo.get_by!(Period, location_id: hamburg.id, starts_on: ~D[2027-01-29])
  end

  test "adds the holidays after the summer for 2027 and 2028", %{states: states} = context do
    insert_holiday(context.types["reformationstag"], states["NI"], ~D[2027-10-31])

    run_migration(@migration)
    run_migration(@migration)

    assert holidays_of(states["NI"]) == [
             {"reformationstag", ~D[2027-10-31]},
             {"reformationstag", ~D[2028-10-31]}
           ]

    assert holidays_of(states["NW"]) == [
             {"allerheiligen", ~D[2027-11-01]},
             {"allerheiligen", ~D[2028-11-01]}
           ]

    assert holidays_of(states["TH"]) == [
             {"weltkindertag", ~D[2027-09-20]},
             {"reformationstag", ~D[2027-10-31]},
             {"weltkindertag", ~D[2028-09-20]},
             {"reformationstag", ~D[2028-10-31]}
           ]

    assert holidays_of(states["BE"]) == []

    assert %{is_valid_for_everybody: true, is_school_vacation: false, display_priority: 10} =
             Repo.get_by!(Period, location_id: states["NW"].id, starts_on: ~D[2027-11-01])
  end

  test "does nothing on a database without federal states", %{states: states} do
    Enum.each(states, fn {_code, state} -> Repo.delete!(state) end)

    run_migration(@migration)

    assert Repo.aggregate(Period, :count) == 0
  end
end
