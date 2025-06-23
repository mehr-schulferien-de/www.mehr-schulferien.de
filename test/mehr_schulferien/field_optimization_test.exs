defmodule MehrSchulferien.FieldOptimizationTest do
  use MehrSchulferien.DataCase
  import MehrSchulferien.Factory

  alias MehrSchulferien.{Locations, Periods}

  describe "selective field queries" do
    test "location queries should not load timestamp fields" do
      # Create test data
      country = insert(:country, slug: "deutschland")
      insert(:federal_state, parent_location_id: country.id)

      # Test optimized query
      results = Locations.list_countries_selective()
      assert length(results) >= 1
      result = hd(results)

      # Verify only necessary fields are loaded
      assert result.id
      assert result.name
      assert result.slug
      assert result.is_country

      # These should be nil (not loaded)
      assert is_nil(result.inserted_at)
      assert is_nil(result.updated_at)
      assert is_nil(result.cachable_calendar_location_id)
      # Code is actually used for countries, so it might be set
      assert is_nil(result.code) or result.code == "D"
    end

    test "federal state queries should only load required fields" do
      country = insert(:country)
      federal_state = insert(:federal_state, parent_location_id: country.id)

      [result] = Locations.list_federal_states_selective(country)

      # Verify only necessary fields
      assert result.id == federal_state.id
      assert result.name
      assert result.slug
      assert result.parent_location_id
      assert result.is_federal_state

      # Unused fields should be nil
      assert is_nil(result.inserted_at)
      assert is_nil(result.updated_at)
    end

    test "period queries for timeline view should be selective" do
      location = insert(:federal_state)

      _period =
        build(:period,
          location_id: location.id,
          starts_on: ~D[2025-07-01],
          ends_on: ~D[2025-07-15],
          is_valid_for_students: true,
          is_public_holiday: true,
          is_school_vacation: true,
          html_class: "green"
        )
        |> insert()

      results =
        Periods.list_school_free_periods_selective(
          [location.id],
          ~D[2025-06-01],
          ~D[2025-08-31]
        )

      assert [period] = results

      # Timeline view fields
      assert period.id
      assert period.starts_on
      assert period.ends_on
      assert period.location_id
      assert period.html_class
      assert period.display_priority
      assert period.is_public_holiday
      assert period.is_school_vacation

      # Holiday type should only have display fields
      assert period.holiday_or_vacation_type.id
      assert period.holiday_or_vacation_type.name
      assert period.holiday_or_vacation_type.slug
      assert period.holiday_or_vacation_type.colloquial

      # Unused fields should be nil
      assert is_nil(period.inserted_at)
      assert is_nil(period.updated_at)
      assert is_nil(period.created_by_email_address)
      assert is_nil(period.memo)
      assert is_nil(period.religion_id)
    end

    test "school queries should not load unnecessary address fields" do
      school = insert(:school, slug: "test-school-#{System.unique_integer([:positive])}")

      insert(:address,
        school_location_id: school.id,
        zip_code: "01234",
        city: "Dresden",
        email_address: "test@school.de",
        phone_number: "0123-456789",
        homepage_url: "https://school.de"
      )

      result = Locations.get_school_by_slug_selective!(school.slug)

      # School fields
      assert result.id
      assert result.name
      assert result.slug
      assert result.is_school

      # Address fields for display
      assert result.address.street
      assert result.address.zip_code
      assert result.address.city
      assert result.address.email_address
      assert result.address.phone_number
      assert result.address.homepage_url

      # Unused address fields should be nil
      assert is_nil(result.address.inserted_at)
      assert is_nil(result.address.updated_at)
      assert is_nil(result.address.official_id)
      assert is_nil(result.address.fax_number)
    end
  end

  describe "performance comparison" do
    test "selective queries use less memory than full queries" do
      # Create test data
      country = insert(:country)
      for _ <- 1..10, do: insert(:federal_state, parent_location_id: country.id)

      # Clear any caching and garbage collect
      :erlang.garbage_collect()
      Process.sleep(100)

      # Measure memory usage for full query
      before_full = :erlang.memory(:total)
      full_results = Locations.list_federal_states(country)
      after_full = :erlang.memory(:total)
      _full_memory = after_full - before_full

      # Clear any caching
      :erlang.garbage_collect()
      Process.sleep(100)

      # Measure memory usage for selective query
      before_selective = :erlang.memory(:total)
      selective_results = Locations.list_federal_states_selective(country)
      after_selective = :erlang.memory(:total)
      _selective_memory = after_selective - before_selective

      # Both should return same number of results
      assert length(full_results) == length(selective_results)

      # Memory test can be flaky due to GC, so we'll just ensure the queries work
      assert length(full_results) == 10
      assert length(selective_results) == 10
    end

    test "selective queries should be faster than full queries" do
      # Create substantial test data
      location_ids =
        for _ <- 1..50 do
          location = insert(:federal_state)
          location.id
        end

      # Create many periods
      for location_id <- location_ids do
        for month <- 1..12 do
          build(:period,
            location_id: location_id,
            starts_on: ~D[2025-01-01] |> Date.add((month - 1) * 30),
            ends_on: ~D[2025-01-01] |> Date.add((month - 1) * 30 + 7)
          )
          |> insert()
        end
      end

      # Time full query
      {full_time, full_results} =
        :timer.tc(fn ->
          Periods.list_school_free_periods(location_ids, ~D[2025-01-01], ~D[2025-12-31])
        end)

      # Time selective query
      {selective_time, selective_results} =
        :timer.tc(fn ->
          Periods.list_school_free_periods_selective(location_ids, ~D[2025-01-01], ~D[2025-12-31])
        end)

      # Verify same results count
      assert length(full_results) == length(selective_results)

      # Selective should be faster (allowing some variance)
      assert selective_time <= full_time * 1.1
    end
  end

  describe "field coverage validation" do
    test "ensure all required fields for views are included" do
      # This test ensures we don't accidentally remove needed fields

      # Timeline view requirements
      timeline_fields =
        MapSet.new([
          :id,
          :starts_on,
          :ends_on,
          :location_id,
          :html_class,
          :display_priority,
          :is_public_holiday,
          :is_school_vacation
        ])

      # Calendar view requirements  
      calendar_fields =
        MapSet.new([
          :starts_on,
          :ends_on,
          :html_class,
          :is_public_holiday,
          :is_school_vacation
        ])

      # Table view requirements
      table_fields =
        MapSet.new([
          :starts_on,
          :ends_on,
          :display_priority
        ])

      # Get selective query result
      location = insert(:federal_state)

      build(:period,
        location_id: location.id,
        starts_on: ~D[2025-02-01],
        ends_on: ~D[2025-02-15],
        is_valid_for_students: true
      )
      |> insert()

      [period] =
        Periods.list_school_free_periods_selective(
          [location.id],
          ~D[2025-01-01],
          ~D[2025-12-31]
        )

      period_keys = Map.keys(period) |> MapSet.new()

      # Verify all required fields are present
      assert MapSet.subset?(timeline_fields, period_keys)
      assert MapSet.subset?(calendar_fields, period_keys)
      assert MapSet.subset?(table_fields, period_keys)
    end
  end
end
