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
    field_order = ["street", "zip_code", "city", "email_address", "phone_number", "homepage_url"]

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
end
