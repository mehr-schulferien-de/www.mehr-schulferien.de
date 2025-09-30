defmodule MehrSchulferien.DateQueryTest do
  use MehrSchulferien.DataCase

  import MehrSchulferien.Factory

  alias MehrSchulferien.DateQuery

  setup do
    # Create test data
    country = insert(:country, %{name: "Deutschland", slug: "deutschland"})

    federal_state =
      insert(:federal_state, %{name: "Bayern", slug: "bayern", parent_location_id: country.id})

    # Create a public holiday (e.g., New Year's Day - outside vacation period)
    new_year_type =
      insert(:holiday_or_vacation_type, %{
        name: "Neujahr",
        slug: "neujahr",
        default_is_public_holiday: true,
        default_is_school_vacation: false,
        country_location_id: country.id
      })

    new_year_day = Date.new!(2025, 1, 1)

    insert(:period, %{
      location_id: federal_state.id,
      holiday_or_vacation_type_id: new_year_type.id,
      starts_on: new_year_day,
      ends_on: new_year_day,
      is_public_holiday: true,
      is_school_vacation: false,
      is_valid_for_everybody: true,
      is_valid_for_students: false
    })

    # Create summer vacation
    summer_type =
      insert(:holiday_or_vacation_type, %{
        name: "Sommer",
        colloquial: "Sommerferien",
        slug: "sommerferien",
        default_is_public_holiday: false,
        default_is_school_vacation: true,
        country_location_id: country.id
      })

    insert(:period, %{
      location_id: federal_state.id,
      holiday_or_vacation_type_id: summer_type.id,
      starts_on: Date.new!(2025, 8, 1),
      ends_on: Date.new!(2025, 8, 31),
      is_public_holiday: false,
      is_school_vacation: true,
      is_valid_for_students: true,
      is_valid_for_everybody: false
    })

    %{
      country: country,
      federal_state: federal_state,
      new_year_day: new_year_day,
      vacation_day: Date.new!(2025, 8, 15),
      regular_day: Date.new!(2025, 9, 15),
      weekend: Date.new!(2025, 12, 27)
    }
  end

  describe "check_date_status/2" do
    test "identifies public holiday correctly", %{
      federal_state: federal_state,
      new_year_day: new_year_day
    } do
      result = DateQuery.check_date_status(federal_state, new_year_day)

      assert result.is_public_holiday == true
      assert result.is_school_day == false
      assert result.is_school_vacation == false
      assert result.is_weekend == false
      assert length(result.public_holiday_periods) == 1
      assert result.explanation =~ "Neujahr"
    end

    test "identifies school vacation correctly", %{
      federal_state: federal_state,
      vacation_day: vacation_day
    } do
      result = DateQuery.check_date_status(federal_state, vacation_day)

      assert result.is_public_holiday == false
      assert result.is_school_day == false
      assert result.is_school_vacation == true
      assert result.is_weekend == false
      assert length(result.school_vacation_periods) == 1
      assert result.explanation =~ "Sommerferien"
    end

    test "identifies regular school day correctly", %{
      federal_state: federal_state,
      regular_day: regular_day
    } do
      result = DateQuery.check_date_status(federal_state, regular_day)

      assert result.is_public_holiday == false
      assert result.is_school_day == true
      assert result.is_school_vacation == false
      assert result.is_weekend == false
      assert length(result.public_holiday_periods) == 0
      assert length(result.school_vacation_periods) == 0
      assert result.explanation == "Regulärer Schultag"
    end

    test "identifies weekend correctly", %{federal_state: federal_state, weekend: weekend} do
      result = DateQuery.check_date_status(federal_state, weekend)

      assert result.is_public_holiday == false
      assert result.is_school_day == false
      assert result.is_weekend == true
      assert result.explanation =~ "Samstag"
    end
  end

  describe "is_public_holiday?/2" do
    test "returns true for public holiday", %{
      federal_state: federal_state,
      new_year_day: new_year_day
    } do
      {is_holiday, periods} = DateQuery.is_public_holiday?(federal_state, new_year_day)

      assert is_holiday == true
      assert length(periods) == 1
    end

    test "returns false for regular day", %{
      federal_state: federal_state,
      regular_day: regular_day
    } do
      {is_holiday, periods} = DateQuery.is_public_holiday?(federal_state, regular_day)

      assert is_holiday == false
      assert length(periods) == 0
    end
  end

  describe "is_school_day?/2" do
    test "returns false for vacation", %{federal_state: federal_state, vacation_day: vacation_day} do
      {is_school_day, periods} = DateQuery.is_school_day?(federal_state, vacation_day)

      assert is_school_day == false
      assert length(periods) == 1
    end

    test "returns false for weekend", %{federal_state: federal_state, weekend: weekend} do
      {is_school_day, periods} = DateQuery.is_school_day?(federal_state, weekend)

      assert is_school_day == false
      assert length(periods) == 0
    end

    test "returns true for regular day", %{federal_state: federal_state, regular_day: regular_day} do
      {is_school_day, periods} = DateQuery.is_school_day?(federal_state, regular_day)

      assert is_school_day == true
      assert length(periods) == 0
    end
  end

  describe "is_school_vacation?/2" do
    test "returns true for vacation", %{federal_state: federal_state, vacation_day: vacation_day} do
      {is_vacation, periods} = DateQuery.is_school_vacation?(federal_state, vacation_day)

      assert is_vacation == true
      assert length(periods) == 1
    end

    test "returns false for regular day", %{
      federal_state: federal_state,
      regular_day: regular_day
    } do
      {is_vacation, periods} = DateQuery.is_school_vacation?(federal_state, regular_day)

      assert is_vacation == false
      assert length(periods) == 0
    end
  end
end
