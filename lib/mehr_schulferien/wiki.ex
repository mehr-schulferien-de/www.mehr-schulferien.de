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
  Rolls back a school or address to a specific version.
  """
  def rollback_to_version(model, version_id, ip_address) do
    with {version_id_int, ""} <- Integer.parse(version_id),
         version when not is_nil(version) <- Repo.get(PaperTrail.Version, version_id_int),
         true <- version_matches_model?(version, model) do
      # Get all versions for this model
      all_versions = PaperTrail.get_versions(model) |> Enum.sort_by(& &1.id)

      # Get the state before the target version
      state_before_target = get_state_before_version(version, all_versions)

      # Create changeset with the reconstructed state
      changeset = Ecto.Changeset.change(model, state_before_target)
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

  defp version_matches_model?(version, %{__struct__: MehrSchulferien.Maps.Address, id: id}) do
    version.item_type == "Address" and version.item_id == id
  end

  defp version_matches_model?(version, %{__struct__: MehrSchulferien.Locations.Location, id: id}) do
    version.item_type == "Location" and version.item_id == id
  end

  defp version_matches_model?(_, _), do: false
end
