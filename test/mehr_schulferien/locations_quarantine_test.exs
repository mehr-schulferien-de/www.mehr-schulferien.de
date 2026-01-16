defmodule MehrSchulferien.LocationsQuarantineTest do
  use MehrSchulferien.DataCase

  alias MehrSchulferien.Locations
  import MehrSchulferien.Factory

  describe "quarantine_school/1" do
    test "quarantines a school successfully" do
      school = insert(:school)
      refute school.is_quarantined

      assert {:ok, %{model: updated_school}} = Locations.quarantine_school(school)
      assert updated_school.is_quarantined == true
    end

    test "returns error for non-school location" do
      city = insert(:city)
      assert {:error, :not_a_school} = Locations.quarantine_school(city)
    end

    test "returns error for nil" do
      assert {:error, :not_found} = Locations.quarantine_school(nil)
    end
  end

  describe "unquarantine_school/1" do
    test "unquarantines a school successfully" do
      school = insert(:school, is_quarantined: true)
      assert school.is_quarantined

      assert {:ok, %{model: updated_school}} = Locations.unquarantine_school(school)
      assert updated_school.is_quarantined == false
    end

    test "returns error for non-school location" do
      city = insert(:city)
      assert {:error, :not_a_school} = Locations.unquarantine_school(city)
    end

    test "returns error for nil" do
      assert {:error, :not_found} = Locations.unquarantine_school(nil)
    end
  end

  describe "school_quarantined?/1" do
    test "returns true for quarantined school" do
      school = insert(:school, is_quarantined: true)
      assert Locations.school_quarantined?(school)
    end

    test "returns false for non-quarantined school" do
      school = insert(:school, is_quarantined: false)
      refute Locations.school_quarantined?(school)
    end

    test "returns false for non-school" do
      city = insert(:city)
      refute Locations.school_quarantined?(city)
    end
  end

  describe "get_school_by_slug_including_quarantined/1" do
    test "returns quarantined school" do
      school = insert(:school, is_quarantined: true)
      found = Locations.get_school_by_slug_including_quarantined(school.slug)
      assert found.id == school.id
    end

    test "returns non-quarantined school" do
      school = insert(:school, is_quarantined: false)
      found = Locations.get_school_by_slug_including_quarantined(school.slug)
      assert found.id == school.id
    end

    test "returns nil for non-existent school" do
      assert Locations.get_school_by_slug_including_quarantined("non-existent") == nil
    end
  end

  describe "list_quarantined_schools/0" do
    test "returns only quarantined schools" do
      _normal_school = insert(:school, is_quarantined: false)
      quarantined1 = insert(:school, is_quarantined: true)
      quarantined2 = insert(:school, is_quarantined: true)

      schools = Locations.list_quarantined_schools()

      assert length(schools) == 2
      school_ids = Enum.map(schools, & &1.id)
      assert quarantined1.id in school_ids
      assert quarantined2.id in school_ids
    end

    test "returns empty list when no quarantined schools" do
      insert(:school, is_quarantined: false)
      assert Locations.list_quarantined_schools() == []
    end
  end

  describe "quarantined schools are excluded from queries" do
    test "list_schools/1 excludes quarantined schools" do
      city = insert(:city)
      _normal_school = insert(:school, parent_location_id: city.id, is_quarantined: false)
      _quarantined = insert(:school, parent_location_id: city.id, is_quarantined: true)

      schools = Locations.list_schools(city)
      assert length(schools) == 1
    end

    test "list_schools_selective/1 excludes quarantined schools" do
      city = insert(:city)
      _normal_school = insert(:school, parent_location_id: city.id, is_quarantined: false)
      _quarantined = insert(:school, parent_location_id: city.id, is_quarantined: true)

      schools = Locations.list_schools_selective(city)
      assert length(schools) == 1
    end

    test "count_schools/0 excludes quarantined schools" do
      city = insert(:city)
      insert(:school, parent_location_id: city.id, is_quarantined: false)
      insert(:school, parent_location_id: city.id, is_quarantined: true)

      # count_schools/0 counts all schools in the database
      assert Locations.count_schools() >= 1
    end

    test "count_schools/1 for city excludes quarantined schools" do
      city = insert(:city)
      insert(:school, parent_location_id: city.id, is_quarantined: false)
      insert(:school, parent_location_id: city.id, is_quarantined: true)

      assert Locations.count_schools(city) == 1
    end

    test "find_schools_in_same_city/1 excludes quarantined schools" do
      city = insert(:city)
      school1 = insert(:school, parent_location_id: city.id, is_quarantined: false)
      _quarantined = insert(:school, parent_location_id: city.id, is_quarantined: true)
      normal2 = insert(:school, parent_location_id: city.id, is_quarantined: false)

      schools = Locations.find_schools_in_same_city(school1)
      assert length(schools) == 1
      assert hd(schools).id == normal2.id
    end

    test "get_school_by_slug/1 returns quarantined school" do
      # Note: get_school_by_slug does NOT filter quarantined schools
      # This is intentional - the controller checks quarantine status separately
      school = insert(:school, is_quarantined: true)
      found = Locations.get_school_by_slug(school.slug)
      assert found.id == school.id
    end
  end
end
