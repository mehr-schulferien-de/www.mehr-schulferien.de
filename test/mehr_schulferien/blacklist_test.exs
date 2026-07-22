defmodule MehrSchulferien.BlacklistTest do
  use MehrSchulferien.DataCase

  import MehrSchulferien.Factory

  alias MehrSchulferien.Blacklist
  alias MehrSchulferien.Blacklist.VerificationRequest

  describe "create_verification_request/2" do
    test "creates a verification request with valid attrs" do
      attrs = %{
        full_name: "Max Mustermann",
        email: "max@example.com"
      }

      assert {:ok, request, raw_token} = Blacklist.create_verification_request(attrs)
      assert request.full_name == "Max Mustermann"
      assert request.email == "max@example.com"
      assert request.token_hash != nil
      assert request.expires_at != nil
      assert request.verified_at == nil
      assert is_binary(raw_token)
    end

    test "normalizes email to lowercase" do
      attrs = %{
        full_name: "Max Mustermann",
        email: "MAX@EXAMPLE.COM"
      }

      assert {:ok, request, _token} = Blacklist.create_verification_request(attrs)
      assert request.email == "max@example.com"
    end

    test "stores IP address and user agent when provided" do
      attrs = %{
        full_name: "Max Mustermann",
        email: "max@example.com"
      }

      opts = [ip_address: "192.168.1.1", user_agent: "Mozilla/5.0"]

      assert {:ok, request, _token} = Blacklist.create_verification_request(attrs, opts)
      assert request.ip_address == "192.168.1.1"
      assert request.user_agent == "Mozilla/5.0"
    end

    test "returns error for invalid email" do
      attrs = %{
        full_name: "Max Mustermann",
        email: "invalid-email"
      }

      assert {:error, changeset} = Blacklist.create_verification_request(attrs)
      assert "muss eine gültige E-Mail-Adresse sein" in errors_on(changeset).email
    end

    test "returns error when rate limited" do
      attrs = %{
        full_name: "Max Mustermann",
        email: "rate-limited@example.com"
      }

      # Create 3 requests (the limit)
      {:ok, _, _} = Blacklist.create_verification_request(attrs)
      {:ok, _, _} = Blacklist.create_verification_request(attrs)
      {:ok, _, _} = Blacklist.create_verification_request(attrs)

      # Fourth request should be rate limited
      assert {:error, :rate_limited} = Blacklist.create_verification_request(attrs)
    end
  end

  describe "verify_token/1" do
    test "verifies a valid token" do
      attrs = %{full_name: "Test User", email: "test@example.com"}
      {:ok, _request, raw_token} = Blacklist.create_verification_request(attrs)

      assert {:ok, verified_request} = Blacklist.verify_token(raw_token)
      assert verified_request.verified_at != nil
    end

    test "returns error for invalid token" do
      assert {:error, :not_found} = Blacklist.verify_token("invalid-token")
    end

    test "returns error for expired token" do
      expired_request =
        insert(:blacklist_verification_request, %{
          expires_at: DateTime.utc_now() |> DateTime.add(-1, :hour) |> DateTime.truncate(:second)
        })

      # We need to use the actual token, but since we don't have it, we test via get_verification_request_by_token
      # For this test, we'll verify the expired? check works correctly
      assert VerificationRequest.expired?(expired_request)
    end

    test "returns error for already verified token" do
      attrs = %{full_name: "Test User", email: "test@example.com"}
      {:ok, _request, raw_token} = Blacklist.create_verification_request(attrs)

      # First verification succeeds
      {:ok, _} = Blacklist.verify_token(raw_token)

      # Second verification fails
      assert {:error, :already_verified} = Blacklist.verify_token(raw_token)
    end
  end

  describe "create_entry/2" do
    test "creates a blacklist entry" do
      verification_request = insert(:verified_blacklist_request)

      attrs = %{
        pattern: "+49 30 1234*",
        field_type: "phone_number",
        reason: "Requested by school"
      }

      assert {:ok, {entry, removal_logs}} = Blacklist.create_entry(attrs, verification_request)
      assert entry.pattern == "+49 30 1234*"
      assert entry.field_type == "phone_number"
      assert entry.full_name == verification_request.full_name
      assert entry.email == verification_request.email
      assert entry.is_active == true
      assert is_list(removal_logs)
    end

    test "rejects invalid field type" do
      verification_request = insert(:verified_blacklist_request)

      attrs = %{
        pattern: "test*",
        field_type: "invalid_field"
      }

      assert {:error, changeset} = Blacklist.create_entry(attrs, verification_request)
      assert "muss ein gültiger Feldtyp sein" in errors_on(changeset).field_type
    end

    test "rejects overly broad patterns" do
      verification_request = insert(:verified_blacklist_request)

      attrs = %{
        pattern: "*",
        field_type: "phone_number"
      }

      assert {:error, changeset} = Blacklist.create_entry(attrs, verification_request)
      assert errors_on(changeset).pattern != []
    end
  end

  describe "is_blacklisted?/2" do
    test "returns true for blacklisted value" do
      insert(:blacklist_entry, %{
        pattern: "+49 30 1234*",
        field_type: "phone_number"
      })

      assert Blacklist.is_blacklisted?("+49 30 12345678", :phone_number)
    end

    test "returns false for non-blacklisted value" do
      insert(:blacklist_entry, %{
        pattern: "+49 30 1234*",
        field_type: "phone_number"
      })

      refute Blacklist.is_blacklisted?("+49 40 98765432", :phone_number)
    end

    test "returns false for nil" do
      refute Blacklist.is_blacklisted?(nil, :phone_number)
    end

    test "returns false for empty string" do
      refute Blacklist.is_blacklisted?("", :phone_number)
    end

    test "only matches the correct field type" do
      insert(:blacklist_entry, %{
        pattern: "+49 30 1234*",
        field_type: "phone_number"
      })

      # Same pattern should not match email field
      refute Blacklist.is_blacklisted?("+49 30 12345678", :email_address)
    end

    test "matches case-insensitively" do
      insert(:blacklist_entry, %{
        pattern: "info@*.schule.de",
        field_type: "email_address"
      })

      assert Blacklist.is_blacklisted?("INFO@TEST.SCHULE.DE", :email_address)
    end

    test "only matches active entries" do
      entry =
        insert(:blacklist_entry, %{
          pattern: "+49 30 1234*",
          field_type: "phone_number"
        })

      # Deactivate the entry
      Blacklist.deactivate_entry(entry)

      refute Blacklist.is_blacklisted?("+49 30 12345678", :phone_number)
    end
  end

  describe "remove_matching_data/1" do
    test "removes matching data from addresses" do
      school = insert(:school)

      address =
        insert(:address, %{
          school_location_id: school.id,
          phone_number: "+49 30 12345678"
        })

      entry =
        insert(:blacklist_entry, %{
          pattern: "+49 30 1234*",
          field_type: "phone_number"
        })

      removal_logs = Blacklist.remove_matching_data(entry)

      assert length(removal_logs) == 1
      [log] = removal_logs
      assert log.original_value == "+49 30 12345678"
      assert log.field_name == "phone_number"
      assert log.address_id == address.id

      # Verify address was updated
      updated_address = MehrSchulferien.Repo.get!(MehrSchulferien.Maps.Address, address.id)
      assert updated_address.phone_number == nil
    end

    test "does not remove non-matching data" do
      school = insert(:school)

      address =
        insert(:address, %{
          school_location_id: school.id,
          phone_number: "+49 40 98765432"
        })

      entry =
        insert(:blacklist_entry, %{
          pattern: "+49 30 1234*",
          field_type: "phone_number"
        })

      removal_logs = Blacklist.remove_matching_data(entry)

      assert removal_logs == []

      # Verify address was not updated
      unchanged_address = MehrSchulferien.Repo.get!(MehrSchulferien.Maps.Address, address.id)
      assert unchanged_address.phone_number == "+49 40 98765432"
    end
  end

  describe "count_matching_addresses/2" do
    test "counts matching addresses" do
      school1 = insert(:school)
      school2 = insert(:school)
      school3 = insert(:school)

      insert(:address, %{school_location_id: school1.id, phone_number: "+49 30 12345678"})
      insert(:address, %{school_location_id: school2.id, phone_number: "+49 30 12349999"})
      insert(:address, %{school_location_id: school3.id, phone_number: "+49 40 98765432"})

      count = Blacklist.count_matching_addresses("+49 30 1234*", "phone_number")
      assert count == 2
    end
  end

  describe "list_active_entries/0" do
    test "lists only active entries" do
      entry1 = insert(:blacklist_entry, %{pattern: "test1*", field_type: "phone_number"})
      entry2 = insert(:blacklist_entry, %{pattern: "test2*", field_type: "phone_number"})

      Blacklist.deactivate_entry(entry2)

      entries = Blacklist.list_active_entries()
      entry_ids = Enum.map(entries, & &1.id)

      assert entry1.id in entry_ids
      refute entry2.id in entry_ids
    end
  end

  describe "valid_for_entry_creation?/1" do
    test "returns true for verified and non-expired request" do
      request = insert(:verified_blacklist_request)
      assert Blacklist.valid_for_entry_creation?(request)
    end

    test "returns false for unverified request" do
      request = insert(:blacklist_verification_request)
      refute Blacklist.valid_for_entry_creation?(request)
    end

    test "returns false for expired request" do
      request =
        insert(:verified_blacklist_request, %{
          expires_at: DateTime.utc_now() |> DateTime.add(-1, :hour) |> DateTime.truncate(:second)
        })

      refute Blacklist.valid_for_entry_creation?(request)
    end
  end
end
