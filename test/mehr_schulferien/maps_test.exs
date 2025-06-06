defmodule MehrSchulferien.MapsTest do
  use MehrSchulferien.DataCase

  import MehrSchulferien.Factory
  import Ecto.Changeset, only: [get_change: 2]

  alias MehrSchulferien.Maps
  alias MehrSchulferien.Maps.{Address, ZipCode, ZipCodeMapping}

  describe "addresses" do
    @valid_attrs %{
      "address_line1" => "Schubart-Gymnasium Partnerschule für Europa",
      "address_street" => "Rombacher Straße 30",
      "address_zip_code" => "73430",
      "address_city" => "Aalen",
      "email_address" => nil,
      "phone_number" => "+49 7361 9561",
      "fax_number" => "+49 7361 9561",
      "homepage_url" => nil,
      "school_type_entity" => "Gymnasium",
      "school_type" => "Gymnasium",
      "official_id" => "75774",
      "lon" => 10.08184,
      "lat" => 48.838598
    }
    @update_attrs %{"homepage_url" => "www.example.com"}
    @invalid_attrs %{"school_location_id" => nil}

    test "list_addresses/0 returns all addresses" do
      address = insert(:address)
      assert Maps.list_addresses() == [address]
    end

    test "get_address!/1 returns the address with given id" do
      address = insert(:address)
      assert Maps.get_address!(address.id) == address
    end

    test "create_address/1 with valid data creates a address" do
      school = insert(:school)
      valid_attrs = Map.put(@valid_attrs, "school_location_id", school.id)
      assert {:ok, %Address{} = _address} = Maps.create_address(valid_attrs)
    end

    test "create_address/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Maps.create_address(@invalid_attrs)
    end

    test "update_address/2 with valid data updates the address" do
      address = insert(:address)
      assert {:ok, %Address{} = _address} = Maps.update_address(address, @update_attrs)
    end

    test "update_address/2 with invalid data returns error changeset" do
      address = insert(:address)
      assert {:error, %Ecto.Changeset{}} = Maps.update_address(address, @invalid_attrs)
      assert address == Maps.get_address!(address.id)
    end

    test "delete_address/1 deletes the address" do
      address = insert(:address)
      assert {:ok, %Address{}} = Maps.delete_address(address)
      assert_raise Ecto.NoResultsError, fn -> Maps.get_address!(address.id) end
    end

    test "change_address/1 returns a address changeset" do
      address = insert(:address)
      assert %Ecto.Changeset{} = Maps.change_address(address)
    end

    test "normalizes German phone numbers to international format" do
      school = insert(:school)

      # Test various German phone number formats
      test_cases = [
        # German landline with area code
        {"030 12345678", "+49 30 12345678"},
        {"0711 123456", "+49 711 123456"},
        {"089 12345678", "+49 89 12345678"},

        # German mobile numbers (format varies by prefix)
        # 017x keeps space
        {"0171 1234567", "+49 171 1234567"},
        # 016x keeps space
        {"0160 1234567", "+49 160 1234567"},
        # 015x removes space
        {"0151 1234567", "+49 1511234567"},

        # With different separators
        {"030-12345678", "+49 30 12345678"},
        {"030/12345678", "+49 30 12345678"},
        {"030 (12345678)", "+49 30 12345678"},
        {"(030) 12345678", "+49 30 12345678"},

        # Already international format (should remain unchanged)
        {"+49 30 12345678", "+49 30 12345678"},
        {"+49 171 1234567", "+49 171 1234567"},

        # Invalid numbers (should remain unchanged) - using truly invalid formats
        {"invalid-phone", "invalid-phone"},
        {"not a number", "not a number"},
        {"xyz", "xyz"}
      ]

      for {input, expected} <- test_cases do
        attrs =
          Map.merge(@valid_attrs, %{
            "school_location_id" => school.id,
            "phone_number" => input
          })

        assert {:ok, %Address{} = address} = Maps.create_address(attrs)

        assert address.phone_number == expected,
               "Expected '#{input}' to normalize to '#{expected}', but got '#{address.phone_number}'"
      end
    end

    test "handles empty phone numbers correctly" do
      school = insert(:school)

      # Test empty string - Ecto will filter this out, so result should be nil
      attrs_empty =
        Map.merge(@valid_attrs, %{
          "school_location_id" => school.id,
          "phone_number" => ""
        })

      assert {:ok, %Address{} = address} = Maps.create_address(attrs_empty)
      # Empty string gets filtered by Ecto, so phone_number should be nil
      assert is_nil(address.phone_number),
             "Expected empty string to result in nil, but got '#{address.phone_number}'"

      # Test with explicit nil
      attrs_nil =
        Map.merge(@valid_attrs, %{
          "school_location_id" => school.id,
          "phone_number" => nil
        })

      assert {:ok, %Address{} = address_nil} = Maps.create_address(attrs_nil)

      assert is_nil(address_nil.phone_number),
             "Expected nil to remain nil, but got '#{address_nil.phone_number}'"
    end

    test "phone number normalization works with update_address/2" do
      school = insert(:school)

      # Create address with international number
      attrs =
        Map.merge(@valid_attrs, %{
          "school_location_id" => school.id,
          "phone_number" => "+49 30 12345678"
        })

      {:ok, address} = Maps.create_address(attrs)

      # Update with German format number
      update_attrs = %{"phone_number" => "0711 987654"}
      {:ok, updated_address} = Maps.update_address(address, update_attrs)

      assert updated_address.phone_number == "+49 711 987654"
    end

    test "phone number normalization in changeset works correctly" do
      school = insert(:school)

      # Test the changeset directly
      changeset =
        Address.changeset(%Address{}, %{
          "school_location_id" => school.id,
          "phone_number" => "030 12345678"
        })

      assert changeset.valid?
      assert get_change(changeset, :phone_number) == "+49 30 12345678"
    end
  end

  describe "zip_codes" do
    @valid_attrs %{value: "17890"}
    @update_attrs %{value: "17891"}
    @invalid_attrs %{value: nil}

    test "list_zip_codes/0 returns all zip_codes" do
      zip_code = insert(:zip_code)
      assert Maps.list_zip_codes() == [zip_code]
    end

    test "get_zip_code!/1 returns the zip_code with given id" do
      zip_code = insert(:zip_code)
      assert Maps.get_zip_code!(zip_code.id) == zip_code
    end

    test "create_zip_code/1 with valid data creates a zip_code" do
      country = insert(:country)
      valid_attrs = Map.put(@valid_attrs, :country_location_id, country.id)
      assert {:ok, %ZipCode{} = zip_code} = Maps.create_zip_code(valid_attrs)
      assert zip_code.slug == "17890"
      assert zip_code.value == "17890"
    end

    test "create_zip_code/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Maps.create_zip_code(@invalid_attrs)
    end

    test "update_zip_code/2 with valid data updates the zip_code" do
      zip_code = insert(:zip_code)
      assert {:ok, %ZipCode{} = zip_code} = Maps.update_zip_code(zip_code, @update_attrs)
      assert zip_code.value == "17891"
    end

    test "update_zip_code/2 with invalid data returns error changeset" do
      zip_code = insert(:zip_code)
      assert {:error, %Ecto.Changeset{}} = Maps.update_zip_code(zip_code, @invalid_attrs)
      assert zip_code == Maps.get_zip_code!(zip_code.id)
    end

    test "delete_zip_code/1 deletes the zip_code" do
      zip_code = insert(:zip_code)
      assert {:ok, %ZipCode{}} = Maps.delete_zip_code(zip_code)
      assert_raise Ecto.NoResultsError, fn -> Maps.get_zip_code!(zip_code.id) end
    end

    test "change_zip_code/1 returns a zip_code changeset" do
      zip_code = insert(:zip_code)
      assert %Ecto.Changeset{} = Maps.change_zip_code(zip_code)
    end
  end

  describe "zip_code_mappings" do
    @valid_attrs %{lat: 5.2, lon: 10.5}
    @update_attrs %{lon: 10.4}
    @invalid_attrs %{location_id: nil}

    test "list_zip_code_mappings/0 returns all zip_code_mappings" do
      zip_code_mapping = insert(:zip_code_mapping)
      assert Maps.list_zip_code_mappings() == [zip_code_mapping]
    end

    test "get_zip_code_mapping!/1 returns the zip_code_mapping with given id" do
      zip_code_mapping = insert(:zip_code_mapping)
      assert Maps.get_zip_code_mapping!(zip_code_mapping.id) == zip_code_mapping
    end

    test "create_zip_code_mapping/1 with valid data creates a zip_code_mapping" do
      location = insert(:city)
      zip_code = insert(:zip_code)
      valid_attrs = Map.merge(@valid_attrs, %{location_id: location.id, zip_code_id: zip_code.id})

      assert {:ok, %ZipCodeMapping{} = zip_code_mapping} =
               Maps.create_zip_code_mapping(valid_attrs)

      assert zip_code_mapping.lat == 5.2
      assert zip_code_mapping.lon == 10.5
    end

    test "create_zip_code_mapping/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Maps.create_zip_code_mapping(@invalid_attrs)
    end

    test "update_zip_code_mapping/2 with valid data updates the zip_code_mapping" do
      zip_code_mapping = insert(:zip_code_mapping)

      assert {:ok, %ZipCodeMapping{} = zip_code_mapping} =
               Maps.update_zip_code_mapping(zip_code_mapping, @update_attrs)

      assert zip_code_mapping.lon == 10.4
    end

    test "delete_zip_code_mapping/1 deletes the zip_code_mapping" do
      zip_code_mapping = insert(:zip_code_mapping)
      assert {:ok, %ZipCodeMapping{}} = Maps.delete_zip_code_mapping(zip_code_mapping)
      assert_raise Ecto.NoResultsError, fn -> Maps.get_zip_code_mapping!(zip_code_mapping.id) end
    end

    test "change_zip_code_mapping/1 returns a zip_code_mapping changeset" do
      zip_code_mapping = insert(:zip_code_mapping)
      assert %Ecto.Changeset{} = Maps.change_zip_code_mapping(zip_code_mapping)
    end
  end
end
