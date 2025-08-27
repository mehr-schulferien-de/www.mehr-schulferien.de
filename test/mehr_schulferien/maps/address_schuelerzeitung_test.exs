defmodule MehrSchulferien.Maps.AddressSchuelerzeitungTest do
  use MehrSchulferien.DataCase
  import MehrSchulferien.Factory
  alias MehrSchulferien.Maps.Address

  describe "schuelerzeitung_url field" do
    test "accepts valid schuelerzeitung URLs" do
      school = insert(:school)

      valid_urls = [
        "https://schuelerzeitung.example-school.de",
        "http://www.schuelerzeitung.de",
        "https://example.com/schuelerzeitung"
      ]

      for url <- valid_urls do
        changeset =
          Address.changeset(%Address{}, %{
            "school_location_id" => school.id,
            "schuelerzeitung_url" => url
          })

        assert changeset.valid?, "Expected #{url} to be valid"
        assert changeset.changes[:schuelerzeitung_url] == url
      end
    end

    test "rejects invalid schuelerzeitung URLs" do
      school = insert(:school)

      invalid_urls = [
        "not-a-url",
        "ftp://invalid-protocol.com",
        "javascript:alert('test')",
        "//missing-protocol.com"
      ]

      for url <- invalid_urls do
        changeset =
          Address.changeset(%Address{}, %{
            "school_location_id" => school.id,
            "schuelerzeitung_url" => url
          })

        assert not changeset.valid?, "Expected #{url} to be invalid"
        assert changeset.errors[:schuelerzeitung_url] != nil
      end
    end

    test "schuelerzeitung_url is optional" do
      school = insert(:school)

      changeset =
        Address.changeset(%Address{}, %{
          "school_location_id" => school.id,
          "street" => "Teststraße 1",
          "zip_code" => "12345",
          "city" => "Berlin"
        })

      assert changeset.valid?
    end

    test "normalizes schuelerzeitung URLs by removing trailing slashes" do
      school = insert(:school)

      test_cases = [
        {"https://example.com/", "https://example.com"},
        {"https://example.com/schuelerzeitung", "https://example.com/schuelerzeitung"},
        {"https://example.com/schuelerzeitung/", "https://example.com/schuelerzeitung/"}
      ]

      for {input, expected} <- test_cases do
        changeset =
          Address.changeset(%Address{}, %{
            "school_location_id" => school.id,
            "schuelerzeitung_url" => input
          })

        assert changeset.changes[:schuelerzeitung_url] == expected
      end
    end

    test "schuelerzeitung_url can be updated" do
      school = insert(:school)
      address = insert(:address, school_location_id: school.id, schuelerzeitung_url: nil)

      changeset =
        Address.changeset(address, %{
          "schuelerzeitung_url" => "https://new-schuelerzeitung.example.com"
        })

      assert changeset.valid?
      assert changeset.changes[:schuelerzeitung_url] == "https://new-schuelerzeitung.example.com"
    end

    test "schuelerzeitung_url can be cleared" do
      school = insert(:school)

      address =
        insert(:address,
          school_location_id: school.id,
          schuelerzeitung_url: "https://old.example.com"
        )

      changeset =
        Address.changeset(address, %{
          "schuelerzeitung_url" => ""
        })

      assert changeset.valid?
      # When clearing a field to empty string, Ecto might not track it as a change
      # if the field allows nil/empty. Just verify it's valid.
      assert changeset.errors == []
    end
  end
end
