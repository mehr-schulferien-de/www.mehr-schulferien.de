defmodule MehrSchulferien.Repo.Migrations.UpdateSchoolsFromJedeschuleCsv do
  use Ecto.Migration
  import Ecto.Query
  require Logger

  def up do
    # Suppress SQL debug output but keep info level
    previous_log_level = Logger.level()
    Logger.configure(level: :warning)

    csv_path = "/tmp/jedeschule-data.csv"

    if File.exists?(csv_path) do
      IO.puts("\n=== Starting Jedeschule CSV import ===")
      IO.puts("Processing file: #{csv_path}\n")

      # Ensure PaperTrail and ExPhoneNumber are started
      Application.ensure_all_started(:paper_trail)
      Application.ensure_all_started(:ex_phone_number)

      process_csv_file(csv_path)
    else
      IO.puts("CSV file not found at #{csv_path}, skipping migration")
    end

    # Restore previous log level
    Logger.configure(level: previous_log_level)
  end

  def down do
    # This migration only updates data, no structural changes to reverse
    :ok
  end

  defp process_csv_file(csv_path) do
    csv_path
    |> File.stream!()
    |> CSV.decode!(headers: true)
    |> Enum.each(fn row ->
      process_school_row(row)
    end)
  end

  defp process_school_row(row) do
    alias MehrSchulferien.{Repo, Locations.Location, Maps.Address}

    # Map to actual CSV column names
    csv_zip = row["zip"] || row["zip_code"] || row["postal_code"] || row["plz"]
    csv_phone = row["phone"] || row["phone_number"] || row["telefon"]
    csv_homepage = row["website"] || row["homepage_url"] || row["homepage"]
    csv_name = row["name"]

    if csv_zip && csv_phone do
      # Convert phone number to international format with spaces
      case ExPhoneNumber.parse(csv_phone, "DE") do
        {:ok, parsed_phone} ->
          # Get international format which includes proper spacing for German numbers
          formatted_phone = ExPhoneNumber.format(parsed_phone, :international)

          # Find schools with truncated versions of this phone number
          find_and_update_schools(csv_zip, formatted_phone, csv_homepage, csv_name)

        {:error, _reason} ->
          # Skip if phone number can't be parsed
          nil
      end
    end
  end

  defp prepare_url(url) when is_nil(url) or url == "", do: nil

  defp prepare_url(url) do
    url = String.trim(url)

    # Add https:// if no protocol is specified
    if not String.match?(url, ~r/^https?:\/\//i) do
      "https://" <> url
    else
      url
    end
  end

  defp find_and_update_schools(csv_zip, e164_phone, csv_homepage, csv_name) do
    alias MehrSchulferien.{Repo, Locations.Location, Maps.Address}

    # Prepare the homepage URL (add protocol if missing)
    prepared_homepage = prepare_url(csv_homepage)

    # Remove the leading +, spaces and dashes for comparison
    phone_without_formatting =
      e164_phone
      |> String.replace("+", "")
      |> String.replace(" ", "")
      |> String.replace("-", "")

    # Query for schools with addresses that have matching zip code and a phone number
    query =
      from(a in Address,
        join: l in Location,
        on: a.school_location_id == l.id,
        where: a.zip_code == ^csv_zip,
        where: not is_nil(a.phone_number),
        where: l.is_school == true,
        select: {l, a}
      )

    schools_with_addresses = Repo.all(query)

    Enum.each(schools_with_addresses, fn {school, address} ->
      # Remove + and spaces for comparison
      address_phone =
        (address.phone_number || "")
        |> String.replace("+", "")
        |> String.replace(" ", "")
        |> String.replace("-", "")

      # Check if the address's phone is a truncated version of the CSV phone
      if address_phone != "" &&
           String.length(address_phone) < String.length(phone_without_formatting) &&
           String.starts_with?(phone_without_formatting, address_phone) do
        # Prepare updates with string keys to match Address.changeset expectations
        updates = %{"phone_number" => e164_phone}

        # Update homepage if address doesn't have one but CSV has a URL
        updates =
          if is_nil(address.homepage_url) && prepared_homepage do
            Map.put(updates, "homepage_url", prepared_homepage)
          else
            updates
          end

        if map_size(updates) > 0 do
          # Print before state
          IO.puts("\n📍 DB School: #{school.name}")
          IO.puts("   CSV School: #{csv_name}")
          IO.puts("   ZIP: #{address.zip_code}")
          IO.puts("   Before:")
          IO.puts("     Phone: #{address.phone_number || "(none)"}")
          IO.puts("     Homepage: #{address.homepage_url || "(none)"}")

          # Use the Address.changeset to get proper validation and normalization
          changeset = Address.changeset(address, updates)

          if changeset.valid? do
            # Apply update with PaperTrail tracking
            # Note: We're not using daily limit bypass here since PaperTrail doesn't have that concept
            # The daily limit is managed by the Wiki module for frontend interactions
            case PaperTrail.update(changeset,
                   meta: %{ip_address: nil, source: "jedeschule_csv_import"}
                 ) do
              {:ok, %{model: updated_address}} ->
                IO.puts("   After:")
                IO.puts("     Phone: #{updated_address.phone_number}")
                IO.puts("     Homepage: #{updated_address.homepage_url || "(none)"}")
                IO.puts("   ✅ Updated successfully")

              {:error, reason} ->
                IO.puts("   ❌ Update failed: #{inspect(reason)}")
            end
          else
            IO.puts("   ⚠️  Skipped - invalid data: #{inspect(changeset.errors)}")
          end
        end
      end
    end)
  end
end
