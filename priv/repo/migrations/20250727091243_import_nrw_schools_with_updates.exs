defmodule MehrSchulferien.Repo.Migrations.ImportNrwSchoolsWithUpdates do
  use Ecto.Migration
  require Logger
  import Ecto.Query
  alias MehrSchulferien.Locations.Location
  alias MehrSchulferien.Maps.Address
  alias MehrSchulferien.Repo
  
  @disable_ddl_transaction true
  @disable_migration_lock true

  def up do
    # Check if we're in dev mode
    dev_mode = Mix.env() == :dev
    
    # Get NRW federal state
    nrw = Repo.one(
      from l in Location,
      where: l.name == "Nordrhein-Westfalen" and l.is_federal_state == true,
      select: l
    )
    
    unless nrw do
      raise "Could not find Nordrhein-Westfalen federal state"
    end
    
    Logger.info("Found NRW with ID: #{nrw.id}")
    
    # Load schools from JSON file
    json_path = Path.join(:code.priv_dir(:mehr_schulferien), "repo/data/nrw-schulen.json")
    
    # Check if file exists
    if File.exists?(json_path) do
      case File.read(json_path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, schools} ->
            Logger.info("Loaded #{length(schools)} schools from JSON file")
            
            # Track statistics
            stats = %{
              total: length(schools),
              imported: 0,
              updated: 0,
              skipped_no_city: 0,
              skipped_no_code: 0,
              errors: 0
            }
            
            # Schools without cities (to be logged)
            schools_without_cities = []
            
            # Process schools in smaller batches
            {final_stats, final_schools_without_cities} = schools
            |> Enum.chunk_every(50)
            |> Enum.with_index()
            |> Enum.reduce({stats, schools_without_cities}, fn {batch, index}, {acc_stats, acc_no_cities} ->
              if rem(index, 20) == 0 do
                Logger.info("Processing batch #{index + 1}/#{div(length(schools), 50) + 1} (#{acc_stats.imported} imported, #{acc_stats.updated} updated so far)...")
              end
              
              # Process each batch in its own transaction
              batch_result = Repo.transaction(fn ->
                Enum.reduce(batch, {%{imported: 0, updated: 0, skipped_no_city: 0, skipped_no_code: 0, errors: 0}, []}, 
                  fn school_data, {batch_stats, batch_no_cities} ->
                    result = process_school(school_data, nrw, dev_mode)
                    
                    case result do
                      {:ok, :imported} -> 
                        {%{batch_stats | imported: batch_stats.imported + 1}, batch_no_cities}
                      {:ok, :updated} -> 
                        {%{batch_stats | updated: batch_stats.updated + 1}, batch_no_cities}
                      {:skip, :no_city, school_info} -> 
                        {%{batch_stats | skipped_no_city: batch_stats.skipped_no_city + 1}, 
                         [school_info | batch_no_cities]}
                      {:skip, :no_code} -> 
                        {%{batch_stats | skipped_no_code: batch_stats.skipped_no_code + 1}, batch_no_cities}
                      {:error, _reason} -> 
                        {%{batch_stats | errors: batch_stats.errors + 1}, batch_no_cities}
                    end
                  end)
              end, timeout: 60_000)
              
              case batch_result do
                {:ok, {batch_stats, batch_no_cities}} ->
                  {%{
                    acc_stats | 
                    imported: acc_stats.imported + batch_stats.imported,
                    updated: acc_stats.updated + batch_stats.updated,
                    skipped_no_city: acc_stats.skipped_no_city + batch_stats.skipped_no_city,
                    skipped_no_code: acc_stats.skipped_no_code + batch_stats.skipped_no_code,
                    errors: acc_stats.errors + batch_stats.errors
                  }, acc_no_cities ++ batch_no_cities}
                {:error, reason} ->
                  Logger.error("Batch #{index + 1} failed: #{inspect(reason)}")
                  {%{acc_stats | errors: acc_stats.errors + length(batch)}, acc_no_cities}
              end
            end)
            
            # Write schools without cities to file
            if length(final_schools_without_cities) > 0 do
              no_city_file = Path.join(File.cwd!(), "schools_without_cities.json")
              File.write!(no_city_file, Jason.encode!(final_schools_without_cities, pretty: true))
              Logger.info("Wrote #{length(final_schools_without_cities)} schools without cities to: #{no_city_file}")
            end
            
            Logger.info("""
            Import completed:
            - Total schools: #{final_stats.total}
            - Imported: #{final_stats.imported}
            - Updated: #{final_stats.updated}
            - Skipped (no city): #{final_stats.skipped_no_city}
            - Skipped (no code): #{final_stats.skipped_no_code}
            - Errors: #{final_stats.errors}
            """)
            
          {:error, error} ->
            raise "Failed to parse JSON: #{inspect(error)}"
        end
      {:error, reason} ->
        raise "Failed to read JSON file at #{json_path}: #{inspect(reason)}"
      end
    else
      Logger.info("NRW schools data file not found at #{json_path}, skipping import")
    end
  end

  def down do
    Logger.info("This migration does not support rollback as it updates existing data")
  end

  defp process_school(school_data, _nrw, dev_mode) do
    school_name = school_data["name"]
    school_code = school_data["nummer"]
    city_name = school_data["ort"]
    
    # Skip if no code
    if school_code == nil or school_code == "" do
      if dev_mode, do: Logger.info("  SKIP: #{school_name} - No school code")
      {:skip, :no_code}
    else
      # Check if city exists
      city = if city_name do
        Repo.one(
          from l in Location,
          where: l.name == ^city_name and l.is_city == true,
          limit: 1
        )
      end
      
      if city do
        # Check if school exists by official_id in address table
        existing_school = Repo.one(
          from l in Location,
          join: a in Address, on: a.school_location_id == l.id,
          where: a.official_id == ^school_code and l.is_school == true,
          limit: 1
        )
        
        if existing_school do
          # Update existing school
          update_school(existing_school, school_data, dev_mode)
        else
          # Create new school
          create_school(school_data, city, dev_mode)
        end
      else
        # City doesn't exist - skip and log
        if dev_mode, do: Logger.info("  SKIP: #{school_name} - City '#{city_name}' not found")
        school_info = %{
          name: school_name,
          code: school_code,
          city: city_name,
          address: school_data["anschrift"],
          plz: school_data["plz"],
          website: school_data["website"],
          form: school_data["form"]
        }
        {:skip, :no_city, school_info}
      end
    end
  end

  defp create_school(school_data, city, dev_mode) do
    try do
      # Create slug using Ecto functionality
      changeset = Location.changeset(%Location{}, %{
        name: school_data["name"],
        is_school: true,
        parent_location_id: city.id
      })
      
      case Repo.insert(changeset) do
        {:ok, school} ->
          # Create address with school code and other details
          address_attrs = %{
            "school_location_id" => school.id,
            "official_id" => school_data["nummer"],
            "street" => school_data["anschrift"],
            "zip_code" => school_data["plz"],
            "city" => school_data["ort"],
            "homepage_url" => school_data["website"],
            "students_count" => school_data["schuelerzahl"]
          }
          
          address_changeset = Address.changeset(%Address{}, address_attrs)
          
          case Repo.insert(address_changeset) do
            {:ok, _address} ->
              if dev_mode do
                Logger.info("  NEW: #{school.name} (#{school_data["nummer"]}) in #{city.name}")
              end
              {:ok, :imported}
            {:error, addr_changeset} ->
              # Delete the school if address creation fails
              Repo.delete(school)
              if dev_mode do
                Logger.error("  ERROR creating address for: #{school_data["name"]} - #{inspect(addr_changeset.errors)}")
              end
              {:error, addr_changeset}
          end
        {:error, changeset} ->
          if dev_mode do
            Logger.error("  ERROR creating: #{school_data["name"]} - #{inspect(changeset.errors)}")
          end
          {:error, changeset}
      end
    rescue
      e ->
        if dev_mode do
          Logger.error("  ERROR: #{school_data["name"]} - #{inspect(e)}")
        end
        {:error, e}
    end
  end

  defp update_school(existing_school, school_data, dev_mode) do
    try do
      # Get or create address for the school
      address = Repo.one(
        from a in Address,
        where: a.school_location_id == ^existing_school.id
      )
      
      # Prepare address updates
      address_updates = %{}
      updates_made = []
      
      # Update official_id if different
      new_official_id = school_data["nummer"]
      {address_updates, updates_made} = if new_official_id && new_official_id != "" do
        if !address || address.official_id != new_official_id do
          {Map.put(address_updates, "official_id", new_official_id), ["official_id" | updates_made]}
        else
          {address_updates, updates_made}
        end
      else
        {address_updates, updates_made}
      end
      
      # Update website if different
      new_website = school_data["website"]
      {address_updates, updates_made} = if new_website && new_website != "" do
        if !address || address.homepage_url != new_website do
          {Map.put(address_updates, "homepage_url", new_website), ["homepage_url" | updates_made]}
        else
          {address_updates, updates_made}
        end
      else
        {address_updates, updates_made}
      end
      
      # Update student count if available and different
      new_student_count = school_data["schuelerzahl"]
      {address_updates, updates_made} = if new_student_count do
        if !address || address.students_count != new_student_count do
          {Map.put(address_updates, "students_count", new_student_count), ["students_count" | updates_made]}
        else
          {address_updates, updates_made}
        end
      else
        {address_updates, updates_made}
      end
      
      # Update other address fields if available
      {address_updates, updates_made} = if school_data["anschrift"] && (!address || address.street != school_data["anschrift"]) do
        {Map.put(address_updates, "street", school_data["anschrift"]), ["street" | updates_made]}
      else
        {address_updates, updates_made}
      end
      
      {address_updates, updates_made} = if school_data["plz"] && (!address || address.zip_code != school_data["plz"]) do
        {Map.put(address_updates, "zip_code", school_data["plz"]), ["zip_code" | updates_made]}
      else
        {address_updates, updates_made}
      end
      
      {address_updates, updates_made} = if school_data["ort"] && (!address || address.city != school_data["ort"]) do
        {Map.put(address_updates, "city", school_data["ort"]), ["city" | updates_made]}
      else
        {address_updates, updates_made}
      end
      
      if map_size(address_updates) > 0 do
        if address do
          # Update existing address
          changeset = Address.changeset(address, address_updates)
          
          case Repo.update(changeset) do
            {:ok, _updated_address} ->
              if dev_mode do
                Logger.info("  UPDATE: #{existing_school.name} (#{school_data["nummer"]}) - Updated: #{Enum.join(updates_made, ", ")}")
              end
              {:ok, :updated}
            {:error, changeset} ->
              if dev_mode do
                Logger.error("  ERROR updating address: #{existing_school.name} - #{inspect(changeset.errors)}")
              end
              {:error, changeset}
          end
        else
          # Create new address
          address_attrs = Map.put(address_updates, "school_location_id", existing_school.id)
          changeset = Address.changeset(%Address{}, address_attrs)
          
          case Repo.insert(changeset) do
            {:ok, _new_address} ->
              if dev_mode do
                Logger.info("  UPDATE: #{existing_school.name} (#{school_data["nummer"]}) - Created address with: #{Enum.join(updates_made, ", ")}")
              end
              {:ok, :updated}
            {:error, changeset} ->
              if dev_mode do
                Logger.error("  ERROR creating address: #{existing_school.name} - #{inspect(changeset.errors)}")
              end
              {:error, changeset}
          end
        end
      else
        if dev_mode do
          Logger.info("  SKIP: #{existing_school.name} (#{school_data["nummer"]}) - No changes needed")
        end
        {:ok, :updated} # Count as updated even if no changes
      end
    rescue
      e ->
        if dev_mode do
          Logger.error("  ERROR: #{existing_school.name} - #{inspect(e)}")
        end
        {:error, e}
    end
  end
end