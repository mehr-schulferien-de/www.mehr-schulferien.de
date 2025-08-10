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
  Rolls back a record to a specific version.
  This restores the complete state AT the selected version.
  """
  def rollback_to_version(model, version_id, ip_address) do
    with {version_id_int, ""} <- Integer.parse(version_id),
         version when not is_nil(version) <- Repo.get(PaperTrail.Version, version_id_int),
         true <- version_matches_model?(version, model) do
      # Get ALL versions for this model, sorted chronologically
      all_versions =
        PaperTrail.get_versions(model)
        |> Enum.sort_by(& &1.id)

      # Find the target version index
      target_index = Enum.find_index(all_versions, fn v -> v.id == version.id end)

      if target_index == nil do
        {:error, :version_not_found_in_history}
      else
        # Get all versions up to and including the target
        versions_up_to_target = Enum.take(all_versions, target_index + 1)

        # Build the complete state at the target version by accumulating ALL changes
        # This represents what the record should look like at that point in time
        accumulated_state =
          versions_up_to_target
          |> Enum.reduce(%{}, fn v, acc ->
            changes = v.item_changes || %{}

            # Convert all keys to atoms and filter out timestamps
            atomized_changes =
              changes
              |> Enum.filter(fn {key, _value} ->
                atom_key = to_atom_key(key)
                atom_key not in [:inserted_at, :updated_at, :id]
              end)
              |> Enum.into(%{}, fn {key, value} ->
                atom_key = to_atom_key(key)
                converted_value = convert_version_value(atom_key, value)
                {atom_key, converted_value}
              end)

            # Merge changes into accumulated state
            Map.merge(acc, atomized_changes)
          end)

        # Compare accumulated state with current state
        # We need to restore ALL fields that were ever changed
        changes_to_apply =
          accumulated_state
          |> Enum.filter(fn {field, target_value} ->
            current_value = Map.get(model, field)
            values_differ?(current_value, target_value)
          end)
          |> Enum.into(%{})

        if map_size(changes_to_apply) > 0 do
          # Apply the changes
          changeset = Ecto.Changeset.change(model, changes_to_apply)

          # Create a new version for the rollback
          result =
            PaperTrail.update(changeset,
              meta: %{
                ip_address: ip_address,
                rollback_to: version_id,
                rollback_from: List.last(all_versions).id
              }
            )

          case result do
            {:ok, _} = success -> success
            {:error, _} = error -> error
          end
        else
          # No changes needed - already at this version's state
          {:error, :already_at_version}
        end
      end
    else
      :error -> {:error, :invalid_version_id}
      nil -> {:error, :version_not_found}
      false -> {:error, :version_mismatch}
    end
  end

  # Helper to convert keys to atoms consistently
  defp to_atom_key(key) when is_atom(key), do: key
  defp to_atom_key(key) when is_binary(key), do: String.to_atom(key)

  # Helper to check if two values differ
  defp values_differ?(val1, val2) when is_nil(val1) and is_nil(val2), do: false
  defp values_differ?(%Date{} = d1, %Date{} = d2), do: Date.compare(d1, d2) != :eq
  defp values_differ?(val1, val2), do: val1 != val2

  # Convert stored version values to proper types
  defp convert_version_value(key, value) when key in [:starts_on, :ends_on] do
    case value do
      %Date{} = date ->
        date

      nil ->
        nil

      "" ->
        nil

      binary when is_binary(binary) ->
        case Date.from_iso8601(binary) do
          {:ok, date} -> date
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp convert_version_value(:location_id, value) when is_binary(value) do
    case Integer.parse(value) do
      {id, ""} -> id
      _ -> value
    end
  end

  defp convert_version_value(:holiday_or_vacation_type_id, value) when is_binary(value) do
    case Integer.parse(value) do
      {id, ""} -> id
      _ -> value
    end
  end

  defp convert_version_value(_key, value), do: value

  # Check if version matches the model type
  defp version_matches_model?(version, %{__struct__: MehrSchulferien.Maps.Address, id: id}) do
    version.item_type == "Address" and version.item_id == id
  end

  defp version_matches_model?(version, %{__struct__: MehrSchulferien.Locations.Location, id: id}) do
    version.item_type == "Location" and version.item_id == id
  end

  defp version_matches_model?(version, %{__struct__: MehrSchulferien.Periods.Period, id: id}) do
    version.item_type == "Period" and version.item_id == id
  end

  defp version_matches_model?(_, _), do: false
end
