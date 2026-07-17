defmodule MehrSchulferien.Wiki.PendingChanges do
  @moduledoc """
  Context module for managing pending wiki changes.

  This module provides functions to create, approve, and reject pending changes
  that require admin approval before being applied to the live database.
  """

  import Ecto.Query
  require Logger

  alias MehrSchulferien.Email
  alias MehrSchulferien.Geocoding.Nominatim
  alias MehrSchulferien.Locations
  alias MehrSchulferien.Locations.Location
  alias MehrSchulferien.Mailer
  alias MehrSchulferien.Maps.Address
  alias MehrSchulferien.Periods
  alias MehrSchulferien.Periods.Period
  alias MehrSchulferien.Repo
  alias MehrSchulferien.Wiki.PendingChange

  @doc """
  Creates a new pending change record.

  Automatically generates unique approval and rejection tokens.
  Sends an email notification to the admin.

  ## Parameters

    - `attrs` - Map containing:
      - `:change_type` - One of the valid change types
      - `:payload` - Map containing all change data
      - `:original_record_id` - (optional) ID of existing record for updates/deletes
      - `:submitted_by_ip` - (optional) IP address of submitter

  ## Returns

    - `{:ok, pending_change}` on success
    - `{:error, changeset}` on validation failure
  """
  def create_pending_change(attrs) do
    # Generate unique tokens
    approval_token = generate_token()
    rejection_token = generate_token()

    attrs =
      attrs
      |> Map.put(:approval_token, approval_token)
      |> Map.put(:rejection_token, rejection_token)
      |> Map.put(:status, "pending")

    changeset = PendingChange.changeset(%PendingChange{}, attrs)

    case Repo.insert(changeset) do
      {:ok, pending_change} ->
        # Send email notification asynchronously
        send_notification_email(pending_change)
        {:ok, pending_change}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Gets a pending change by its approval token.

  Returns `nil` if not found.
  """
  def get_by_approval_token(token) when is_binary(token) do
    Repo.get_by(PendingChange, approval_token: token)
  end

  def get_by_approval_token(_), do: nil

  @doc """
  Gets a pending change by its rejection token.

  Returns `nil` if not found.
  """
  def get_by_rejection_token(token) when is_binary(token) do
    Repo.get_by(PendingChange, rejection_token: token)
  end

  def get_by_rejection_token(_), do: nil

  @doc """
  Approves a pending change and applies it to the live database.

  ## Parameters

    - `pending_change` - The pending change record to approve
    - `opts` - (optional) Options:
      - `:reviewer_note` - Optional note from the reviewer

  ## Returns

    - `{:ok, result}` on success, where result includes the applied record(s)
    - `{:error, reason}` on failure
  """
  def approve_change!(pending_change, opts \\ [])

  def approve_change!(%PendingChange{status: "pending"} = pending_change, opts) do
    Repo.transaction(fn ->
      # Apply the change based on type
      result = apply_change(pending_change)

      case result do
        {:ok, applied_result} ->
          # Mark as approved
          {:ok, _updated} =
            pending_change
            |> PendingChange.changeset(%{
              status: "approved",
              reviewed_at: DateTime.utc_now(),
              reviewer_note: Keyword.get(opts, :reviewer_note)
            })
            |> Repo.update()

          applied_result

        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
  end

  def approve_change!(%PendingChange{status: _status}, _opts) do
    {:error, :already_processed}
  end

  @doc """
  Rejects a pending change without applying it.

  ## Parameters

    - `pending_change` - The pending change record to reject
    - `opts` - (optional) Options:
      - `:reviewer_note` - Optional note from the reviewer

  ## Returns

    - `{:ok, pending_change}` on success
    - `{:error, reason}` on failure
  """
  def reject_change!(pending_change, opts \\ [])

  def reject_change!(%PendingChange{status: "pending"} = pending_change, opts) do
    pending_change
    |> PendingChange.changeset(%{
      status: "rejected",
      reviewed_at: DateTime.utc_now(),
      reviewer_note: Keyword.get(opts, :reviewer_note)
    })
    |> Repo.update()
  end

  def reject_change!(%PendingChange{status: _status}, _opts) do
    {:error, :already_processed}
  end

  @doc """
  Lists all pending changes with optional filters.

  ## Parameters

    - `opts` - Options:
      - `:status` - Filter by status ("pending", "approved", "rejected")
      - `:change_type` - Filter by change type
      - `:limit` - Limit number of results

  ## Returns

    - List of pending changes
  """
  def list_pending(opts \\ []) do
    query = from(pc in PendingChange, order_by: [desc: pc.inserted_at])

    # Default to filtering by "pending" status if not specified
    query =
      case Keyword.get(opts, :status, "pending") do
        nil -> query
        status -> where(query, [pc], pc.status == ^status)
      end

    query =
      case Keyword.get(opts, :change_type) do
        nil -> query
        type -> where(query, [pc], pc.change_type == ^type)
      end

    query =
      case Keyword.get(opts, :limit) do
        nil -> query
        limit -> limit(query, ^limit)
      end

    Repo.all(query)
  end

  @doc """
  Gets a pending change by ID.
  """
  def get_pending_change(id), do: Repo.get(PendingChange, id)

  # Private functions

  defp generate_token do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
  end

  defp send_notification_email(pending_change) do
    # Send email asynchronously to avoid blocking
    if Application.get_env(:mehr_schulferien, :env) == :test do
      # In test environment, run synchronously
      do_send_notification_email(pending_change)
    else
      Task.start(fn ->
        do_send_notification_email(pending_change)
      end)
    end
  end

  defp do_send_notification_email(pending_change) do
    Email.pending_change_notification(pending_change)
    |> Mailer.deliver()
  rescue
    error ->
      Logger.error("Failed to send pending change notification: #{inspect(error)}")
  end

  # Apply change based on type
  defp apply_change(%PendingChange{change_type: "create_school", payload: payload}) do
    apply_create_school(payload)
  end

  defp apply_change(%PendingChange{
         change_type: "update_school",
         payload: payload,
         original_record_id: school_id
       }) do
    apply_update_school(school_id, payload)
  end

  defp apply_change(%PendingChange{
         change_type: "delete_school",
         original_record_id: school_id,
         payload: payload
       }) do
    apply_delete_school(school_id, payload)
  end

  defp apply_change(%PendingChange{change_type: "create_period", payload: payload}) do
    apply_create_period(payload)
  end

  defp apply_change(%PendingChange{
         change_type: "update_period",
         payload: payload,
         original_record_id: period_id
       }) do
    apply_update_period(period_id, payload)
  end

  defp apply_change(%PendingChange{
         change_type: "delete_period",
         original_record_id: period_id
       }) do
    apply_delete_period(period_id)
  end

  defp apply_change(%PendingChange{
         change_type: "create_beweglicher_ferientag",
         payload: payload
       }) do
    apply_create_beweglicher_ferientag(payload)
  end

  defp apply_change(%PendingChange{
         change_type: "update_beweglicher_ferientag",
         payload: payload,
         original_record_id: period_id
       }) do
    apply_update_beweglicher_ferientag(period_id, payload)
  end

  defp apply_change(%PendingChange{
         change_type: "delete_beweglicher_ferientag",
         original_record_id: period_id
       }) do
    apply_delete_beweglicher_ferientag(period_id)
  end

  defp apply_change(%PendingChange{change_type: type}) do
    {:error, "Unknown change type: #{type}"}
  end

  # School operations

  defp apply_create_school(payload) do
    school_name = payload["school_name"]
    address_params = payload["address_params"]
    city_id = payload["city_id"]
    zip_code = payload["zip_code"]

    # Generate unique slug
    {:ok, school_slug} = Locations.generate_unique_school_slug(school_name, zip_code)

    # Create school location
    school_attrs = %{
      name: school_name,
      slug: school_slug,
      is_school: true,
      parent_location_id: city_id
    }

    school_changeset = Location.changeset(%Location{}, school_attrs)

    case PaperTrail.insert(school_changeset, meta: %{approved_via: "pending_changes"}) do
      {:ok, %{model: school}} ->
        # Get coordinates
        coords = get_coordinates_for_school(school_name, address_params, zip_code)

        # Create address
        address_attrs =
          address_params
          |> Map.put("school_location_id", school.id)
          |> Map.put("line1", school_name)
          |> maybe_add_coordinates(coords)

        address_changeset = Address.changeset(%Address{}, address_attrs)

        case PaperTrail.insert(address_changeset, meta: %{approved_via: "pending_changes"}) do
          {:ok, %{model: address}} ->
            school = Repo.preload(school, [:address, :parent_location])
            send_school_created_email(school, address)
            {:ok, %{school: school, address: address}}

          {:error, changeset} ->
            # Rollback school creation
            PaperTrail.delete(school)
            {:error, changeset}
        end

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp apply_update_school(school_id, payload) do
    school = Locations.get_location!(school_id) |> Repo.preload(:address)
    new_name = payload["school_name"]
    address_params = payload["address_params"]

    # Capture current state for email
    current_state = capture_school_state(school)

    # Update school name if changed
    school_result =
      if new_name && new_name != school.name do
        changeset = Location.changeset(school, %{name: new_name})
        PaperTrail.update(changeset, meta: %{approved_via: "pending_changes"})
      else
        {:ok, %{model: school, version: nil}}
      end

    case school_result do
      {:ok, %{model: updated_school}} ->
        # Update address
        address_result =
          if school.address do
            changeset = Address.changeset(school.address, address_params)
            PaperTrail.update(changeset, meta: %{approved_via: "pending_changes"})
          else
            # Create new address if none exists
            address_attrs =
              address_params
              |> Map.put("school_location_id", school.id)
              |> Map.put("line1", new_name || school.name)

            changeset = Address.changeset(%Address{}, address_attrs)
            PaperTrail.insert(changeset, meta: %{approved_via: "pending_changes"})
          end

        case address_result do
          {:ok, %{model: address}} ->
            updated_school =
              Repo.preload(updated_school, [:address, :parent_location], force: true)

            # Build changes for email
            changes = build_school_changes(current_state, payload)
            send_school_updated_email(updated_school, address, changes)

            {:ok, %{school: updated_school, address: address}}

          {:error, changeset} ->
            {:error, changeset}
        end

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp apply_delete_school(school_id, payload) do
    school = Locations.get_location!(school_id) |> Repo.preload(:address)
    deletion_reason = payload["deletion_reason"]

    case Locations.delete_school(school, deletion_reason: deletion_reason) do
      {:ok, result} ->
        send_school_deleted_email(school, school.address, deletion_reason)
        {:ok, result}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Period operations

  defp apply_create_period(payload) do
    period_params = %{
      "location_id" => payload["location_id"],
      "holiday_or_vacation_type_id" => payload["holiday_or_vacation_type_id"],
      "starts_on" => payload["starts_on"],
      "ends_on" => payload["ends_on"],
      "memo" => payload["memo"],
      "created_by_email_address" => "wiki@mehr-schulferien.de",
      "display_priority" => "5",
      "is_school_vacation" => "true",
      "is_listed_below_month" => "false",
      "is_public_holiday" => "false",
      "is_valid_for_everybody" => "false",
      "is_valid_for_students" => "true"
    }

    case Periods.create_period(period_params) do
      {:ok, period} ->
        send_period_created_email(period)
        {:ok, %{period: period}}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp apply_update_period(period_id, payload) do
    period = Periods.get_period!(period_id)

    # Capture current state for email
    current_state = %{
      starts_on: period.starts_on,
      ends_on: period.ends_on,
      memo: period.memo,
      location_id: period.location_id,
      holiday_or_vacation_type_id: period.holiday_or_vacation_type_id
    }

    period_params = %{
      "starts_on" => payload["starts_on"],
      "ends_on" => payload["ends_on"],
      "memo" => payload["memo"],
      "location_id" => payload["location_id"],
      "holiday_or_vacation_type_id" => payload["holiday_or_vacation_type_id"]
    }

    changeset = Period.changeset(period, period_params)

    case PaperTrail.update(changeset, meta: %{approved_via: "pending_changes"}) do
      {:ok, %{model: updated_period}} ->
        changes = build_period_changes(current_state, payload)
        send_period_updated_email(updated_period, changes)
        {:ok, %{period: updated_period}}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp apply_delete_period(period_id) do
    period =
      Periods.get_period!(period_id) |> Repo.preload([:location, :holiday_or_vacation_type])

    case Periods.delete_period(period) do
      {:ok, deleted_period} ->
        send_period_deleted_email(period)
        {:ok, %{period: deleted_period}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Beweglicher Ferientag operations

  defp apply_create_beweglicher_ferientag(payload) do
    school_id = payload["school_id"]
    date = payload["date"]
    memo = payload["memo"]

    school = Locations.get_location!(school_id)

    case Periods.create_beweglicher_ferientag_for_school(school_id, date, memo) do
      {:ok, period} ->
        send_beweglicher_ferientag_created_email(period, school)
        {:ok, %{period: period}}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp apply_update_beweglicher_ferientag(period_id, payload) do
    period = Periods.get_period!(period_id)
    period_params = payload["period_params"]

    changeset = Period.changeset(period, period_params)

    case PaperTrail.update(changeset, meta: %{approved_via: "pending_changes"}) do
      {:ok, %{model: updated_period}} ->
        school = Locations.get_location!(period.location_id)
        changes = build_beweglicher_ferientag_changes(period, payload)
        send_beweglicher_ferientag_updated_email(updated_period, school, changes)
        {:ok, %{period: updated_period}}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp apply_delete_beweglicher_ferientag(period_id) do
    period = Periods.get_period!(period_id)
    school = Locations.get_location!(period.location_id)

    case Periods.delete_period(period) do
      {:ok, deleted_period} ->
        send_beweglicher_ferientag_deleted_email(period, school)
        {:ok, %{period: deleted_period}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Helper functions

  defp get_coordinates_for_school(_name, address_params, zip_code) do
    street = address_params["street"]
    city = address_params["city"]

    case Nominatim.geocode_address(street, zip_code, city) do
      {:ok, {lon, lat}} ->
        {lon, lat}

      {:error, _} ->
        # Try fallback to zip code mappings
        get_coordinates_from_zip_mappings(zip_code)
    end
  end

  defp get_coordinates_from_zip_mappings(zip_code) when is_binary(zip_code) and zip_code != "" do
    query =
      from zm in MehrSchulferien.Maps.ZipCodeMapping,
        join: z in MehrSchulferien.Maps.ZipCode,
        on: zm.zip_code_id == z.id,
        where: z.value == ^zip_code,
        select: {zm.lon, zm.lat},
        limit: 1

    case Repo.one(query) do
      {lon, lat} when not is_nil(lon) and not is_nil(lat) -> {lon, lat}
      _ -> nil
    end
  end

  defp get_coordinates_from_zip_mappings(_), do: nil

  defp maybe_add_coordinates(attrs, nil), do: attrs

  defp maybe_add_coordinates(attrs, {lon, lat}) do
    attrs
    |> Map.put("lon", lon)
    |> Map.put("lat", lat)
  end

  defp capture_school_state(school) do
    %{
      name: school.name,
      address:
        if school.address do
          %{
            street: school.address.street,
            zip_code: school.address.zip_code,
            city: school.address.city,
            email_address: school.address.email_address,
            phone_number: school.address.phone_number,
            homepage_url: school.address.homepage_url,
            wikipedia_url: school.address.wikipedia_url,
            instagram_url: school.address.instagram_url,
            students_count: school.address.students_count,
            founded_year: school.address.founded_year,
            description: school.address.description
          }
        else
          nil
        end
    }
  end

  defp build_school_changes(current_state, payload) do
    changes = %{}

    # Check name change
    changes =
      if payload["school_name"] && payload["school_name"] != current_state.name do
        Map.put(changes, "Schulname", {current_state.name, payload["school_name"]})
      else
        changes
      end

    # Check address changes
    address_params = payload["address_params"] || %{}

    if current_state.address do
      field_mappings = [
        {"street", :street, "Straße"},
        {"zip_code", :zip_code, "PLZ"},
        {"city", :city, "Stadt"},
        {"email_address", :email_address, "E-Mail"},
        {"phone_number", :phone_number, "Telefon"},
        {"homepage_url", :homepage_url, "Homepage"},
        {"wikipedia_url", :wikipedia_url, "Wikipedia"},
        {"instagram_url", :instagram_url, "Instagram"},
        {"students_count", :students_count, "Schülerzahl"},
        {"founded_year", :founded_year, "Gründungsjahr"},
        {"description", :description, "Beschreibung"}
      ]

      Enum.reduce(field_mappings, changes, fn {param_key, state_key, label}, acc ->
        new_value = address_params[param_key]
        old_value = Map.get(current_state.address, state_key)

        if new_value != nil && to_string(new_value) != to_string(old_value) do
          Map.put(acc, label, {old_value, new_value})
        else
          acc
        end
      end)
    else
      changes
    end
  end

  defp build_period_changes(current_state, payload) do
    field_mappings = [
      {"starts_on", :starts_on, "Beginn"},
      {"ends_on", :ends_on, "Ende"},
      {"memo", :memo, "Notiz"}
    ]

    Enum.reduce(field_mappings, %{}, fn {param_key, state_key, label}, acc ->
      new_value = payload[param_key]
      old_value = Map.get(current_state, state_key)

      if new_value != nil && to_string(new_value) != to_string(old_value) do
        Map.put(acc, label, {format_value(old_value), format_value(new_value)})
      else
        acc
      end
    end)
  end

  defp build_beweglicher_ferientag_changes(period, payload) do
    period_params = payload["period_params"] || %{}

    changes = %{}

    if period_params["starts_on"] &&
         Date.to_string(period.starts_on) != period_params["starts_on"] do
      Map.put(changes, "Datum", {Date.to_string(period.starts_on), period_params["starts_on"]})
    else
      changes
    end
  end

  defp format_value(%Date{} = date), do: Date.to_string(date)
  defp format_value(value), do: value

  # Email notification helpers. Delivery happens async in a fire-and-forget
  # task and is suppressed in the test environment.
  defp deliver_async(build_email) do
    if Application.get_env(:mehr_schulferien, :env) != :test do
      Task.start(fn -> build_email.() |> Mailer.deliver() end)
    end
  end

  defp send_school_created_email(school, address) do
    deliver_async(fn ->
      country_slug = Locations.get_country_slug_from_location(school)
      Email.school_created_notification(school, address, country_slug)
    end)
  end

  defp send_school_updated_email(school, address, changes) do
    deliver_async(fn ->
      country_slug = Locations.get_country_slug_from_location(school)
      Email.school_updated_notification(school, address, changes, country_slug)
    end)
  end

  defp send_school_deleted_email(school, address, reason) do
    deliver_async(fn ->
      country_slug = Locations.get_country_slug_from_location(school)
      Email.school_deleted_notification(school, address, country_slug, reason)
    end)
  end

  defp send_period_created_email(period) do
    deliver_async(fn -> Email.period_created_notification(period) end)
  end

  defp send_period_updated_email(period, changes) do
    deliver_async(fn -> Email.period_updated_notification(period, changes) end)
  end

  defp send_period_deleted_email(period) do
    deliver_async(fn -> Email.period_deleted_notification(period) end)
  end

  defp send_beweglicher_ferientag_created_email(period, school) do
    deliver_async(fn -> Email.beweglicher_ferientag_created_notification(period, school) end)
  end

  defp send_beweglicher_ferientag_updated_email(period, school, changes) do
    deliver_async(fn ->
      Email.beweglicher_ferientag_updated_notification(period, school, changes)
    end)
  end

  defp send_beweglicher_ferientag_deleted_email(period, school) do
    deliver_async(fn -> Email.beweglicher_ferientag_deleted_notification(period, school) end)
  end
end
