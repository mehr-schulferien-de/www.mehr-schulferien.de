defmodule MehrSchulferien.Wiki do
  @moduledoc """
  The Wiki context for managing collaborative editing of school address data.

  This module provides functionality for:
  - Daily change limits
  - Email notifications for changes
  - Version rollback functionality
  """

  import Ecto.Query, warn: false
  alias MehrSchulferien.Repo
  alias MehrSchulferien.Wiki.DailyChangeCount

  @doc """
  Gets the daily change count for a given date.
  """
  def get_daily_change_count(date) do
    case Repo.get_by(DailyChangeCount, date: date) do
      nil -> 0
      record -> record.count
    end
  end

  @doc """
  Increments the daily change count for a given date.
  """
  def increment_daily_change_count(date) do
    case Repo.get_by(DailyChangeCount, date: date) do
      nil ->
        %DailyChangeCount{date: date, count: 1}
        |> Repo.insert()

      record ->
        record
        |> Ecto.Changeset.change(count: record.count + 1)
        |> Repo.update()
    end
  end

  @doc """
  Rolls back an address to a specific version.
  """
  def rollback_to_version(address, version_id, ip_address) do
    with {version_id_int, ""} <- Integer.parse(version_id),
         version when not is_nil(version) <- Repo.get(PaperTrail.Version, version_id_int),
         true <- version.item_type == "Address" and version.item_id == address.id do
      # Get all versions for this address
      all_versions = PaperTrail.get_versions(address) |> Enum.sort_by(& &1.id)

      # Get the state before the target version
      state_before_target = get_state_before_version(version, all_versions)

      # Create changeset with the reconstructed state
      changeset = Ecto.Changeset.change(address, state_before_target)
      PaperTrail.update(changeset, meta: %{ip_address: ip_address})
    else
      :error -> {:error, :invalid_version_id}
      nil -> {:error, :version_not_found}
      false -> {:error, :version_mismatch}
    end
  end

  defp get_state_before_version(target_version, all_versions) do
    # Find the target version index and get all versions before it
    target_index = Enum.find_index(all_versions, fn v -> v.id == target_version.id end)

    cond do
      target_index == nil ->
        # Target version not found, return empty state
        %{}

      target_index == 0 ->
        # This is the first version (insert), so use its changes as the rollback state
        # Convert the target version's changes to atom keys and filter timestamps
        changes = target_version.item_changes || %{}

        changes
        |> Enum.filter(fn {key, _value} ->
          key not in ["inserted_at", "updated_at"]
        end)
        |> Enum.into(%{}, fn {key, value} ->
          key_atom = if is_atom(key), do: key, else: String.to_atom(key)
          {key_atom, value}
        end)

      true ->
        # Get all previous versions (before the target one) and reconstruct state
        previous_versions = Enum.take(all_versions, target_index)
        reconstruct_state_from_versions(previous_versions)
    end
  end

  defp reconstruct_state_from_versions(versions) do
    # Start with empty state and apply each version's changes chronologically
    final_state =
      versions
      |> Enum.reduce(%{}, fn version, current_state ->
        changes = version.item_changes || %{}

        # Convert string keys to atoms and filter out timestamp fields
        clean_changes =
          changes
          |> Enum.filter(fn {key, _value} ->
            key not in ["inserted_at", "updated_at"]
          end)
          |> Enum.into(%{}, fn {key, value} ->
            {String.to_atom(key), value}
          end)

        # Apply the changes to current state
        Map.merge(current_state, clean_changes)
      end)

    final_state
  end

  @doc """
  Sends an email notification when address data is changed.
  """
  def send_change_notification(school, old_address, new_address, ip_address) do
    # Build email content
    subject = "Schuladresse geändert: #{school.name}"

    body = """
    Eine Schuladresse wurde im Wiki geändert:

    Schule: #{school.name}
    Slug: #{school.slug}
    IP-Adresse: #{ip_address}
    Zeitpunkt: #{DateTime.utc_now() |> DateTime.to_string()}

    === ALTE DATEN ===
    Straße: #{old_address.street || ""}
    PLZ: #{old_address.zip_code || ""}
    Stadt: #{old_address.city || ""}
    E-Mail: #{old_address.email_address || ""}
    Telefon: #{old_address.phone_number || ""}
    Homepage: #{old_address.homepage_url || ""}
    Wikipedia: #{old_address.wikipedia_url || ""}

    === NEUE DATEN ===
    Straße: #{new_address.street || ""}
    PLZ: #{new_address.zip_code || ""}
    Stadt: #{new_address.city || ""}
    E-Mail: #{new_address.email_address || ""}
    Telefon: #{new_address.phone_number || ""}
    Homepage: #{new_address.homepage_url || ""}
    Wikipedia: #{new_address.wikipedia_url || ""}

    Link zur Schule: https://www.mehr-schulferien.de/wiki/schools/#{school.slug}
    """

    send_notification_email(subject, body)
  end

  @doc """
  Sends an email notification when a rollback is performed.
  """
  def send_rollback_notification(school, address, version_id, ip_address) do
    subject = "Schuladresse zurückgesetzt: #{school.name}"

    body = """
    Eine Schuladresse wurde im Wiki zurückgesetzt:

    Schule: #{school.name}
    Slug: #{school.slug}
    Zurückgesetzt zu Version: #{version_id}
    IP-Adresse: #{ip_address}
    Zeitpunkt: #{DateTime.utc_now() |> DateTime.to_string()}

    === AKTUELLE DATEN NACH ROLLBACK ===
    Straße: #{address.street || ""}
    PLZ: #{address.zip_code || ""}
    Stadt: #{address.city || ""}
    E-Mail: #{address.email_address || ""}
    Telefon: #{address.phone_number || ""}
    Homepage: #{address.homepage_url || ""}
    Wikipedia: #{address.wikipedia_url || ""}

    Link zur Schule: https://www.mehr-schulferien.de/wiki/schools/#{school.slug}
    """

    send_notification_email(subject, body)
  end

  defp send_notification_email(subject, body) do
    try do
      alias Swoosh.Email
      alias MehrSchulferien.Mailer

      email =
        Email.new()
        |> Email.to("sw@wintermeyer-consulting.de")
        |> Email.from({"Wiki System", "noreply@mehr-schulferien.de"})
        |> Email.subject(subject)
        |> Email.text_body(body)

      Mailer.deliver(email)
    rescue
      e ->
        # Log the error but don't fail the operation
        require Logger
        Logger.error("Failed to send wiki notification email: #{inspect(e)}")
        {:error, e}
    end
  end
end
