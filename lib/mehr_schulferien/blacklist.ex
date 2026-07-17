defmodule MehrSchulferien.Blacklist do
  @moduledoc """
  The Blacklist context for managing contact data restrictions.

  This module provides functionality for:
  - Magic link verification flow
  - Blacklist entry creation and management
  - Pattern matching against existing and new data
  - Auto-removal of blacklisted data from schools
  """

  import Ecto.Query, warn: false
  require Logger

  alias MehrSchulferien.Blacklist.{Entry, PatternMatcher, RemovalLog, VerificationRequest}
  alias MehrSchulferien.{Email, Mailer}
  alias MehrSchulferien.Maps.Address
  alias MehrSchulferien.Repo

  @rate_limit_requests 3
  @rate_limit_hours 1

  # ============================================================================
  # Verification Requests
  # ============================================================================

  @doc """
  Creates a new verification request and returns the raw token.

  Returns `{:ok, verification_request, raw_token}` on success.
  Returns `{:error, :rate_limited}` if too many requests have been made.
  Returns `{:error, changeset}` on validation failure.
  """
  def create_verification_request(attrs, opts \\ []) do
    email = attrs["email"] || attrs[:email] || ""
    normalized_email = String.downcase(String.trim(email))

    if rate_limited?(normalized_email) do
      {:error, :rate_limited}
    else
      {raw_token, token_hash} = VerificationRequest.generate_token()

      attrs_with_token =
        attrs
        |> Map.put(:token_hash, token_hash)
        |> maybe_add_metadata(opts)

      changeset = VerificationRequest.create_changeset(attrs_with_token)

      case Repo.insert(changeset) do
        {:ok, verification_request} -> {:ok, verification_request, raw_token}
        {:error, changeset} -> {:error, changeset}
      end
    end
  end

  @doc """
  Verifies a token and marks the request as verified.

  Returns `{:ok, verification_request}` on success.
  Returns `{:error, :not_found}` if the token doesn't exist.
  Returns `{:error, :expired}` if the token has expired.
  Returns `{:error, :already_verified}` if already verified.
  """
  def verify_token(raw_token) do
    token_hash = VerificationRequest.hash_token(raw_token)

    case Repo.get_by(VerificationRequest, token_hash: token_hash) do
      nil ->
        {:error, :not_found}

      verification_request ->
        cond do
          VerificationRequest.expired?(verification_request) ->
            {:error, :expired}

          VerificationRequest.verified?(verification_request) ->
            {:error, :already_verified}

          true ->
            verification_request
            |> VerificationRequest.verify_changeset()
            |> Repo.update()
        end
    end
  end

  @doc """
  Gets a verification request by token.

  Returns the verification request or nil.
  """
  def get_verification_request_by_token(raw_token) do
    token_hash = VerificationRequest.hash_token(raw_token)
    Repo.get_by(VerificationRequest, token_hash: token_hash)
  end

  @doc """
  Checks if a verification request is valid for creating entries.

  Returns `true` if the request is verified and not expired.
  """
  def valid_for_entry_creation?(%VerificationRequest{} = request) do
    VerificationRequest.verified?(request) and not VerificationRequest.expired?(request)
  end

  def valid_for_entry_creation?(_), do: false

  # ============================================================================
  # Blacklist Entries
  # ============================================================================

  @doc """
  Creates a new blacklist entry and triggers auto-removal of matching data.

  Returns `{:ok, entry, removal_logs}` on success.
  Returns `{:error, changeset}` on validation failure.
  """
  def create_entry(attrs, verification_request) do
    attrs_with_requester =
      attrs
      |> Map.put(:requester_name, verification_request.full_name)
      |> Map.put(:requester_email, verification_request.email)
      |> Map.put(:verification_request_id, verification_request.id)

    changeset = Entry.create_changeset(attrs_with_requester)

    Repo.transaction(fn ->
      case Repo.insert(changeset) do
        {:ok, entry} ->
          removal_logs = remove_matching_data(entry)
          {entry, removal_logs}

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Creates a new blacklist entry for an authenticated wiki user.

  This is used when a user is already logged in via wiki authentication,
  bypassing the separate verification request flow.

  Returns `{:ok, {entry, removal_logs}}` on success.
  Returns `{:error, changeset}` on validation failure.
  """
  def create_entry_for_user(attrs, user) do
    attrs_with_requester =
      attrs
      |> Map.put(:requester_name, user.full_name || user.email)
      |> Map.put(:requester_email, user.email)

    changeset = Entry.create_changeset(attrs_with_requester)

    Repo.transaction(fn ->
      case Repo.insert(changeset) do
        {:ok, entry} ->
          # Send admin notification
          Email.blacklist_entry_created_notification(entry, 0)
          |> Mailer.deliver()

          removal_logs = remove_matching_data(entry)
          {entry, removal_logs}

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Lists all active blacklist entries.
  """
  def list_active_entries do
    Entry
    |> where([e], e.is_active == true)
    |> order_by([e], desc: e.inserted_at)
    |> Repo.all()
  end

  @doc """
  Lists active entries for a specific field type.
  """
  def list_active_entries_for_field(field_type) do
    Entry
    |> where([e], e.is_active == true and e.field_type == ^to_string(field_type))
    |> Repo.all()
  end

  @doc """
  Gets a blacklist entry by ID.
  """
  def get_entry(id), do: Repo.get(Entry, id)

  @doc """
  Deactivates a blacklist entry.
  """
  def deactivate_entry(%Entry{} = entry) do
    entry
    |> Entry.deactivate_changeset()
    |> Repo.update()
  end

  # ============================================================================
  # Blacklist Checking
  # ============================================================================

  @doc """
  Checks if a value is blacklisted for the given field type.

  Returns `true` if the value matches any active blacklist pattern.
  """
  def is_blacklisted?(value, field_type) do
    find_blocking_entry(value, field_type) != nil
  end

  @blacklistable_fields [
    :phone_number,
    :fax_number,
    :email_address,
    :homepage_url,
    :instagram_url,
    :wikipedia_url,
    :schuelerzeitung_url,
    :street,
    :city,
    :zip_code
  ]

  @doc """
  Checks address params for blacklisted values.

  Returns `:ok` if no values are blacklisted.
  Returns `{:error, blocked_fields}` if any values are blacklisted,
  where `blocked_fields` is a list of `{field_name, value, pattern}` tuples.

  ## Examples

      iex> check_params_for_blacklisted_values(%{"phone_number" => "+49 30 1234567"})
      :ok

      iex> check_params_for_blacklisted_values(%{"phone_number" => "+49 30 blocked"})
      {:error, [{"phone_number", "+49 30 blocked", "+49 30 blocked*"}]}
  """
  def check_params_for_blacklisted_values(params) when is_map(params) do
    alias MehrSchulferien.Helpers.PhoneFormatter

    # One query for all fields instead of one query per field
    entries_by_field = active_entries_by_field()

    blocked_fields =
      @blacklistable_fields
      |> Enum.flat_map(fn field ->
        field_string = to_string(field)
        value = Map.get(params, field_string) || Map.get(params, field)

        if value && value != "" do
          # For phone/fax numbers, also check the international format
          values_to_check =
            if field_string in ["phone_number", "fax_number"] do
              formatted = PhoneFormatter.format_international(value)
              # Check both raw and formatted values
              if formatted != value, do: [value, formatted], else: [value]
            else
              [value]
            end

          # Find if any of the values match a blacklist entry
          Enum.find_value(values_to_check, [], fn val ->
            case blocking_entry(entries_by_field, val, field_string) do
              nil -> nil
              entry -> [{field_string, value, entry.pattern}]
            end
          end)
        else
          []
        end
      end)

    if Enum.empty?(blocked_fields) do
      :ok
    else
      {:error, blocked_fields}
    end
  end

  @doc """
  Finds the blacklist entry that blocks a given value for a field type.

  Returns the entry or nil if not blocked.
  """
  def find_blocking_entry(nil, _field_type), do: nil
  def find_blocking_entry("", _field_type), do: nil

  def find_blocking_entry(value, field_type) when is_binary(value) do
    field_type_string = to_string(field_type)

    list_active_entries_for_field(field_type_string)
    |> Enum.find(fn entry ->
      PatternMatcher.matches?(value, entry.pattern_regex)
    end)
  end

  # All active entries grouped by field type - loads the whole blacklist in
  # ONE query so multi-field checks don't hit the DB once per field.
  defp active_entries_by_field do
    Enum.group_by(list_active_entries(), & &1.field_type)
  end

  defp blocking_entry(entries_by_field, value, field_type)
       when is_binary(value) and value != "" do
    entries_by_field
    |> Map.get(to_string(field_type), [])
    |> Enum.find(fn entry -> PatternMatcher.matches?(value, entry.pattern_regex) end)
  end

  defp blocking_entry(_entries_by_field, _value, _field_type), do: nil

  @doc """
  Formats blocked fields into a user-friendly error message.

  Returns a German error message listing all blocked fields.
  """
  def format_blocked_fields_error(blocked_fields) do
    field_descriptions =
      blocked_fields
      |> Enum.map_join(", ", fn {field, _value, pattern} ->
        "#{field_type_to_german_label(field)} (gesperrtes Muster: #{pattern})"
      end)

    "Die folgenden Daten sind gesperrt und können nicht verwendet werden: #{field_descriptions}"
  end

  @doc """
  Filters blacklisted fields from an address struct.

  For each blacklistable field, if the value matches any active blacklist pattern,
  the field is set to nil. Returns the filtered address.

  Returns nil if the input is nil.
  """
  def filter_address(nil), do: nil

  def filter_address(%Address{} = address) do
    # Runs on every school page render: fetch the blacklist once instead of
    # querying per field.
    entries_by_field = active_entries_by_field()

    Enum.reduce(@blacklistable_fields, address, fn field, acc ->
      value = Map.get(acc, field)

      if blocking_entry(entries_by_field, value, field) do
        Map.put(acc, field, nil)
      else
        acc
      end
    end)
  end

  @doc """
  Counts addresses that would match a pattern for a given field type.

  Useful for previewing the impact of a new blacklist entry.
  """
  def count_matching_addresses(pattern, field_type) do
    regex_pattern = PatternMatcher.to_regex_pattern(pattern)
    field_atom = String.to_existing_atom(field_type)

    query =
      from a in Address,
        where: fragment("? ~* ?", field(a, ^field_atom), ^regex_pattern),
        select: count(a.id)

    Repo.one(query)
  end

  @doc """
  Gets sample addresses that would match a pattern for a given field type.

  Returns up to `limit` addresses (default 5).
  """
  def sample_matching_addresses(pattern, field_type, limit \\ 5) do
    regex_pattern = PatternMatcher.to_regex_pattern(pattern)
    field_atom = String.to_existing_atom(field_type)

    query =
      from a in Address,
        where: fragment("? ~* ?", field(a, ^field_atom), ^regex_pattern),
        limit: ^limit,
        preload: [:school_location]

    Repo.all(query)
  end

  # ============================================================================
  # Auto-Removal
  # ============================================================================

  @doc """
  Removes matching data from all addresses and creates removal logs.

  Sends email notifications using the standard wiki edit workflow for each affected school.

  Returns a list of removal logs.
  """
  def remove_matching_data(%Entry{} = entry) do
    field_atom = String.to_existing_atom(entry.field_type)

    matching_addresses =
      from(a in Address,
        where: fragment("? ~* ?", field(a, ^field_atom), ^entry.pattern_regex),
        preload: [:school_location]
      )
      |> Repo.all()

    Enum.map(matching_addresses, fn address ->
      original_value = Map.get(address, field_atom)

      # Clear the field
      changeset = Ecto.Changeset.change(address, %{field_atom => nil})

      case PaperTrail.update(changeset, meta: %{blacklist_entry_id: entry.id, auto_removal: true}) do
        {:ok, %{model: updated_address}} ->
          # Create removal log
          {:ok, log} =
            RemovalLog.create_changeset(%{
              blacklist_entry_id: entry.id,
              address_id: address.id,
              school_location_id: address.school_location_id,
              field_name: entry.field_type,
              original_value: original_value,
              removed_at: DateTime.utc_now() |> DateTime.truncate(:second)
            })
            |> Repo.insert()

          # Send email notification using the standard wiki edit workflow
          send_removal_notification(
            address.school_location,
            updated_address,
            entry,
            original_value
          )

          log

        {:error, _changeset} ->
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  # Sends email notification for a blacklist removal using the standard wiki workflow
  defp send_removal_notification(school, address, entry, original_value) do
    if school do
      # Build changes map in the format expected by school_updated_notification
      field_label = field_type_to_german_label(entry.field_type)
      changes = %{field_label => {original_value, nil}}

      # Send notification using the standard wiki edit email
      Email.school_updated_notification(school, address, changes)
      |> Mailer.deliver()

      Logger.info(
        "Blacklist removal notification sent for school #{school.name} (#{entry.field_type}: #{original_value})"
      )
    end
  end

  # Maps field types to German labels (same as used in wiki edit emails)
  defp field_type_to_german_label("phone_number"), do: "Telefon"
  defp field_type_to_german_label("fax_number"), do: "Fax"
  defp field_type_to_german_label("email_address"), do: "E-Mail"
  defp field_type_to_german_label("homepage_url"), do: "Homepage"
  defp field_type_to_german_label("instagram_url"), do: "Instagram"
  defp field_type_to_german_label("wikipedia_url"), do: "Wikipedia"
  defp field_type_to_german_label("schuelerzeitung_url"), do: "Schülerzeitung"
  defp field_type_to_german_label("street"), do: "Straße"
  defp field_type_to_german_label("city"), do: "Stadt"
  defp field_type_to_german_label("zip_code"), do: "PLZ"
  defp field_type_to_german_label(other), do: other

  @doc """
  Gets removal logs for a blacklist entry.
  """
  def get_removal_logs_for_entry(entry_id) do
    RemovalLog
    |> where([r], r.blacklist_entry_id == ^entry_id)
    |> preload([:address, :school_location])
    |> Repo.all()
  end

  # ============================================================================
  # Private Functions
  # ============================================================================

  defp rate_limited?(email) do
    cutoff = DateTime.utc_now() |> DateTime.add(-@rate_limit_hours * 60 * 60, :second)

    count =
      VerificationRequest
      |> where([v], v.email == ^email and v.inserted_at > ^cutoff)
      |> Repo.aggregate(:count)

    count >= @rate_limit_requests
  end

  defp maybe_add_metadata(attrs, opts) do
    attrs
    |> maybe_put(:ip_address, Keyword.get(opts, :ip_address))
    |> maybe_put(:user_agent, Keyword.get(opts, :user_agent))
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
