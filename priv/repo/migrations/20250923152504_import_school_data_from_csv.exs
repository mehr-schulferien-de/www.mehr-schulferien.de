defmodule MehrSchulferien.Repo.Migrations.ImportSchoolDataFromCsv do
  use Ecto.Migration
  import Ecto.Query
  alias MehrSchulferien.Repo
  alias MehrSchulferien.Locations.Location
  alias MehrSchulferien.Maps.Address
  require Logger

  def up do
    # Suppress SQL debug logging during migration
    original_level = Logger.level()
    Logger.configure(level: :info)

    # Read and parse CSV file
    csv_path = "/tmp/jedeschule-data.csv"

    if File.exists?(csv_path) do
      IO.puts("Starting school data import from #{csv_path}")

      updated_count = csv_path
      |> File.stream!()
      |> CSV.decode!(headers: true)
      |> Stream.with_index(1)
      |> Enum.reduce(0, &process_csv_row/2)

      IO.puts("\nSchool data import completed. Updated #{updated_count} schools.")
    else
      IO.puts("CSV file not found at #{csv_path}")
    end

    # Restore original log level
    Logger.configure(level: original_level)
  end

  def down do
    # This migration only updates existing data, so we don't need to revert
    Logger.info("This migration cannot be automatically reverted as it updates existing data")
  end

  defp process_csv_row({row, index}, updated_count) do
    phone = row["phone"]

    # Skip rows without phone numbers
    if phone && phone != "" do
      normalized_phone = normalize_phone_number(phone)

      if normalized_phone do
        # Search for schools with this phone number that have NULL street, zip_code and city
        query = from a in Address,
          where: a.phone_number == ^normalized_phone,
          where: is_nil(a.street) and is_nil(a.zip_code) and is_nil(a.city),
          preload: [:school_location]

        # Use Repo.all to handle multiple results
        addresses = Repo.all(query)

        case addresses do
          [] ->
            updated_count

          addresses when is_list(addresses) ->
            # Update all schools with this phone number
            count = Enum.reduce(addresses, 0, fn address, acc ->
              if update_school_if_needed(address, row, index) do
                acc + 1
              else
                acc
              end
            end)
            updated_count + count
        end
      else
        updated_count
      end
    else
      updated_count
    end
  rescue
    error ->
      IO.puts("Error processing row #{index}: #{inspect(error)}")
      updated_count
  end

  defp update_school_if_needed(address, row, _index) do
    street_from_csv = row["address"]
    city_from_csv = row["city"]
    zip_from_csv = row["zip"]

    # Since we already filtered for NULL values in the query, we can update all three fields
    # Prepare update attributes - use string keys consistently
    update_attrs = %{}

    update_attrs = if street_from_csv && street_from_csv != "" do
      Map.put(update_attrs, "street", street_from_csv)
    else
      update_attrs
    end

    update_attrs = if city_from_csv && city_from_csv != "" do
      Map.put(update_attrs, "city", city_from_csv)
    else
      update_attrs
    end

    update_attrs = if zip_from_csv && zip_from_csv != "" do
      Map.put(update_attrs, "zip_code", zip_from_csv)
    else
      update_attrs
    end

    # Only update if we have something to update
    if map_size(update_attrs) > 0 do
      # Create changeset
      changeset = Address.changeset(address, update_attrs)

      # Use PaperTrail to track the change
      case PaperTrail.update(changeset) do
        {:ok, %{model: updated_address}} ->
          school_name = if address.school_location do
            address.school_location.name
          else
            "Unknown School"
          end

          # Print the updated school information
          IO.puts("Updated: #{school_name}")
          IO.puts("  Address: #{updated_address.street || "(no street)"}, #{updated_address.zip_code || "(no zip)"} #{updated_address.city || "(no city)"}")
          IO.puts("")

          true

        {:error, error} ->
          IO.puts("Failed to update school: #{inspect(error)}")
          false
      end
    else
      false
    end
  end

  defp normalize_phone_number(phone) when is_binary(phone) and phone != "" do
    # Clean the input
    cleaned = String.replace(phone, ~r/[-\/\(\)\s]/, "")

    # Skip if already international or too short
    if String.starts_with?(cleaned, "+") do
      phone
    else
      # Try to parse as German number
      case ExPhoneNumber.parse(cleaned, "DE") do
        {:ok, parsed_number} ->
          ExPhoneNumber.format(parsed_number, :international)

        _ ->
          # Try with leading zero if it doesn't have one
          with_zero = if String.starts_with?(cleaned, "0") do
            cleaned
          else
            "0" <> cleaned
          end

          case ExPhoneNumber.parse(with_zero, "DE") do
            {:ok, parsed_number} ->
              ExPhoneNumber.format(parsed_number, :international)

            _ ->
              nil
          end
      end
    end
  end

  defp normalize_phone_number(_), do: nil
end