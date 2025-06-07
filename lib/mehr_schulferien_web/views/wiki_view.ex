defmodule MehrSchulferienWeb.WikiView do
  use MehrSchulferienWeb, :view

  @doc """
  Formats a version timestamp for display
  """
  def format_version_date(version) do
    version.inserted_at
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.shift_zone!("Europe/Berlin")
    |> Calendar.strftime("%d.%m.%Y %H:%M:%S")
  end

  @doc """
  Gets a summary of changes for a version
  """
  def version_summary(version) do
    version_summary(version, [])
  end

  @doc """
  Gets a summary of changes for a version with access to all versions for old value lookup
  """
  def version_summary(version, all_versions) do
    changes = Map.get(version, :item_changes, %{})

    # Define order for consistent output
    field_order = [
      "street",
      "zip_code",
      "city",
      "email_address",
      "phone_number",
      "homepage_url",
      "wikipedia_url"
    ]

    case Map.get(version, :event) do
      "insert" ->
        # For insert events, show the initial values
        initial_values =
          field_order
          |> Enum.filter(fn key ->
            Map.has_key?(changes, key) and changes[key] not in [nil, ""]
          end)
          |> Enum.map(fn key ->
            field_name = field_label(key)
            new_value = format_display_value(changes[key])
            "#{field_name}: #{new_value}"
          end)
          |> Enum.join(", ")

        if initial_values == "" do
          "Initiale Erstellung"
        else
          "Erstellt mit: #{initial_values}"
        end

      "update" ->
        # For update events, reconstruct old values from version history
        change_descriptions =
          field_order
          |> Enum.filter(fn key -> Map.has_key?(changes, key) end)
          |> Enum.map(fn key ->
            new_value = changes[key]
            old_value = get_old_value(key, version, all_versions)

            field_name = field_label(key)
            old_display = format_display_value(old_value)
            new_display = format_display_value(new_value)

            "#{field_name}: #{old_display} → #{new_display}"
          end)
          |> Enum.join(", ")

        if change_descriptions == "" do
          "Keine relevanten Änderungen"
        else
          "Geändert: #{change_descriptions}"
        end

      nil ->
        # Legacy format without event field - assume it contains [old, new] pairs
        change_descriptions =
          field_order
          |> Enum.filter(fn key -> Map.has_key?(changes, key) end)
          |> Enum.map(fn key ->
            case Map.get(changes, key) do
              [old_value, new_value] ->
                field_name = field_label(key)
                old_display = format_display_value(old_value)
                new_display = format_display_value(new_value)
                "#{field_name}: #{old_display} → #{new_display}"

              other_value ->
                field_name = field_label(key)
                new_display = format_display_value(other_value)
                "#{field_name}: #{new_display}"
            end
          end)
          |> Enum.join(", ")

        if change_descriptions == "" do
          "Keine relevanten Änderungen"
        else
          "Geändert: #{change_descriptions}"
        end

      _ ->
        "Unbekannte Änderung"
    end
  end

  # Gets the old value for a field by reconstructing the state before the current version
  defp get_old_value(field, current_version, all_versions) do
    # Sort all versions by ID (more reliable than timestamp since they might be identical)
    sorted_versions = Enum.sort_by(all_versions, & &1.id)

    # Find the current version index and get all versions before it
    current_index = Enum.find_index(sorted_versions, fn v -> v.id == current_version.id end)

    if current_index && current_index > 0 do
      # Get all previous versions (before the current one)
      previous_versions = Enum.take(sorted_versions, current_index)
      reconstruct_field_value(field, previous_versions)
    else
      nil
    end
  end

  # Reconstructs the value of a field by applying version changes in order
  defp reconstruct_field_value(_field, []), do: nil

  defp reconstruct_field_value(field, versions) do
    versions
    |> Enum.reduce(nil, fn version, current_value ->
      changes = Map.get(version, :item_changes, %{})

      case Map.get(version, :event) do
        "insert" ->
          # For insert, use the initial value if this field was set, otherwise keep current
          if Map.has_key?(changes, field) do
            Map.get(changes, field)
          else
            current_value
          end

        "update" ->
          # For update, use the new value if this field was changed, otherwise keep current
          if Map.has_key?(changes, field) do
            Map.get(changes, field)
          else
            current_value
          end

        _ ->
          current_value
      end
    end)
  end

  @doc """
  Gets a human readable label for a field
  """
  def field_label("street"), do: "Straße"
  def field_label("zip_code"), do: "PLZ"
  def field_label("city"), do: "Stadt"
  def field_label("email_address"), do: "E-Mail"
  def field_label("phone_number"), do: "Telefon"
  def field_label("homepage_url"), do: "Homepage"
  def field_label("wikipedia_url"), do: "Wikipedia"
  def field_label(field), do: field

  # Formats values for display, handling nil and empty strings
  defp format_display_value(nil), do: "leer"
  defp format_display_value(""), do: "leer"
  defp format_display_value(value) when is_binary(value), do: "\"#{value}\""
  defp format_display_value(value), do: "#{value}"

  @doc """
  Formats the originator information for display
  """
  def format_originator(version) do
    case version.meta do
      %{"ip_address" => ip} -> "IP: #{obfuscate_ip(ip)}"
      _ -> "Unbekannt"
    end
  end

  # Obfuscates an IP address by showing only the second half
  defp obfuscate_ip(ip) when is_binary(ip) do
    parts = String.split(ip, ".")

    case length(parts) do
      4 ->
        # IPv4 address
        [_a, _b, c, d] = parts
        "*.*.#{c}.#{d}"

      _ ->
        # For other formats or if parsing fails, just show last part
        case String.split(ip, ".") do
          parts when length(parts) > 1 ->
            last_part = List.last(parts)
            "*." <> last_part

          _ ->
            # If no dots found, show partial (keep the last part)
            if String.length(ip) > 4 do
              last_part = String.slice(ip, -4, 4)
              "*" <> last_part
            else
              "*" <> ip
            end
        end
    end
  end

  defp obfuscate_ip(_), do: "*"

  @doc """
  Gets a specific field value from a version, taking into account the version structure
  """
  def get_version_field(version, field) do
    changes = Map.get(version, :item_changes, %{})

    case Map.get(version, :event) do
      "insert" ->
        # For insert events, get the initial value of the field
        Map.get(changes, field)

      "update" ->
        # For update events, get the new value of the field
        Map.get(changes, field)

      nil ->
        # Legacy format - might contain [old, new] pairs or direct values
        case Map.get(changes, field) do
          [_old_value, new_value] -> new_value
          other_value -> other_value
        end

      _ ->
        # For other event types, try to get the field value directly
        Map.get(changes, field)
    end
  end

  @doc """
  Reconstructs the complete data state that you would get if you rollback to this version.
  This shows the state BEFORE this version was applied, which is what "Wiederherstellen" will restore.
  Enhanced version that includes current state as fallback for missing historical data.
  """
  def get_version_data(version, all_versions, current_school \\ nil) do
    # Get base historical data
    base_data = get_version_data_historical(version, all_versions)

    # If no current school provided, return just historical data
    if is_nil(current_school) do
      base_data
    else
      # Determine which fields changed in this version
      changed_fields = Map.keys(Map.get(version, :item_changes, %{}))

      # Use current school/address data as fallback ONLY for fields that were NOT changed in this version
      fallback_data = %{
        "name" => current_school.name,
        "street" => current_school.address && current_school.address.street,
        "zip_code" => current_school.address && current_school.address.zip_code,
        "city" => current_school.address && current_school.address.city,
        "email_address" => current_school.address && current_school.address.email_address,
        "phone_number" => current_school.address && current_school.address.phone_number,
        "homepage_url" => current_school.address && current_school.address.homepage_url,
        "wikipedia_url" => current_school.address && current_school.address.wikipedia_url
      }

      # Merge with preference for historical data.
      # If historical value is nil/empty we only fallback when the field was NOT changed in this version.
      Map.merge(fallback_data, base_data, fn key, fallback, historical ->
        cond do
          historical not in [nil, ""] -> historical
          key in changed_fields -> nil
          true -> fallback
        end
      end)
    end
  end

  # Internal function that does the actual historical reconstruction
  defp get_version_data_historical(version, all_versions) do
    # Sort all versions by ID to ensure correct order  
    sorted_versions = Enum.sort_by(all_versions, & &1.id)

    # Find the current version index
    current_index = Enum.find_index(sorted_versions, fn v -> v.id == version.id end)

    if current_index && current_index > 0 do
      # Get all versions BEFORE the current one (this is what rollback restores to)
      versions_before_current = Enum.take(sorted_versions, current_index)

      # Separate school versions from address versions
      {school_versions, address_versions} =
        Enum.split_with(versions_before_current, fn v ->
          v.item_type == "Location"
        end)

      # Reconstruct school fields (name) from school versions
      school_data = reconstruct_school_fields(school_versions)

      # Reconstruct address fields from address versions  
      address_data = reconstruct_address_fields(address_versions)

      # Combine school and address data
      Map.merge(address_data, school_data)
    else
      # For the very first version, there's no previous state to rollback to
      # Return empty map so fields show as "—"
      %{}
    end
  end

  # Reconstruct school-specific fields (like name) from Location versions
  defp reconstruct_school_fields(school_versions) do
    school_versions
    |> Enum.sort_by(& &1.id)
    |> Enum.reduce(%{}, fn version, acc ->
      changes = Map.get(version, :item_changes, %{})

      # Handle school name changes
      if Map.has_key?(changes, "name") do
        Map.put(acc, "name", changes["name"])
      else
        acc
      end
    end)
  end

  # Reconstruct address fields from Address versions
  defp reconstruct_address_fields(address_versions) do
    address_field_names = [
      "street",
      "zip_code",
      "city",
      "email_address",
      "phone_number",
      "homepage_url",
      "wikipedia_url"
    ]

    # Build the state by applying all address versions chronologically
    address_field_names
    |> Enum.reduce(%{}, fn field, acc ->
      value = reconstruct_field_value_improved(field, address_versions)
      Map.put(acc, field, value)
    end)
  end

  # Improved field reconstruction that handles PaperTrail's structure better
  defp reconstruct_field_value_improved(field, versions) do
    # Apply versions in chronological order (by ID) to build up the field value
    versions
    |> Enum.sort_by(& &1.id)
    |> Enum.reduce(nil, fn version, current_value ->
      changes = Map.get(version, :item_changes, %{})

      # Check if this field was changed in this version
      if Map.has_key?(changes, field) do
        # Use the value from this version
        Map.get(changes, field)
      else
        # Keep the current value (carry forward from previous versions)
        current_value
      end
    end)
  end

  @doc """
  Gets the list of fields that were changed in a specific version
  """
  def get_changed_fields(version) do
    changes = Map.get(version, :item_changes, %{})
    Map.keys(changes)
  end
end
