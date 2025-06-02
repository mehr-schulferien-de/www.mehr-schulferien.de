defmodule Mix.Tasks.GenerateSeeds do
  @moduledoc """
  Generates seed files from the current database.

  All tables except users and sessions are exported. The generated seed files
  preserve relationships and slugs while optimizing for fast bulk inserts.

  ## Usage

      mix generate_seeds

  This will create seed files in priv/repo/seeds/ directory.
  """

  use Mix.Task

  alias MehrSchulferien.Repo
  alias MehrSchulferien.Locations.Location
  alias MehrSchulferien.Calendars.{HolidayOrVacationType, Religion}
  alias MehrSchulferien.Periods.Period
  alias MehrSchulferien.Maps.{Address, ZipCode, ZipCodeMapping}

  import Ecto.Query

  @shortdoc "Generates seed files from current database"

  def run(_args) do
    Mix.Task.run("app.start")

    seeds_dir = "priv/repo/seeds"
    File.mkdir_p!(seeds_dir)

    IO.puts("Generating seed files...")

    # Export in dependency order to maintain relationships
    export_religions(seeds_dir)
    export_locations(seeds_dir)
    export_holiday_or_vacation_types(seeds_dir)
    export_zip_codes(seeds_dir)
    export_zip_code_mappings(seeds_dir)
    export_addresses(seeds_dir)
    export_periods(seeds_dir)

    IO.puts("Seed files generated successfully in #{seeds_dir}/")
    IO.puts("To use these seeds, run: mix run priv/repo/seeds.exs")
  end

  defp export_religions(seeds_dir) do
    IO.puts("Exporting religions...")

    religions = Repo.all(from r in Religion, order_by: r.id)

    data =
      religions
      |> Enum.map(fn religion ->
        %{
          name: religion.name,
          slug: religion.slug,
          wikipedia_url: religion.wikipedia_url,
          inserted_at: truncate_datetime(religion.inserted_at),
          updated_at: truncate_datetime(religion.updated_at)
        }
      end)

    create_seed_file(seeds_dir, "religions.exs", "religions", data, """
    # Create lookup map for religions by slug
    {_, religion_results} = MehrSchulferien.Repo.insert_all("religions", religions_data, returning: [:id, :slug])
    religion_lookup = Map.merge(religion_lookup, Map.new(religion_results, fn %{id: id, slug: slug} -> {slug, id} end))
    Process.put(:religion_lookup, religion_lookup)
    """)
  end

  defp export_locations(seeds_dir) do
    IO.puts("Exporting locations...")

    # Get all locations with their parent and cachable calendar location slugs in one query
    locations_with_relations =
      Repo.all(
        from l in Location,
          left_join: p in Location,
          on: l.parent_location_id == p.id,
          left_join: c in Location,
          on: l.cachable_calendar_location_id == c.id,
          select: {l, p.slug, c.slug},
          order_by: [l.parent_location_id, l.id]
      )

    data =
      locations_with_relations
      |> Enum.map(fn {location, parent_slug, cachable_slug} ->
        %{
          name: location.name,
          code: location.code,
          slug: location.slug,
          is_country: location.is_country,
          is_federal_state: location.is_federal_state,
          is_county: location.is_county,
          is_city: location.is_city,
          is_school: location.is_school,
          parent_location_slug: parent_slug,
          cachable_calendar_location_slug: cachable_slug,
          inserted_at: truncate_datetime(location.inserted_at),
          updated_at: truncate_datetime(location.updated_at)
        }
      end)

    # Locations need special handling due to parent relationships
    create_locations_seed_file(seeds_dir, data)
  end

  defp create_locations_seed_file(seeds_dir, data) do
    batch_size = 1000

    if length(data) > batch_size do
      create_batched_locations_seed_file(seeds_dir, data, batch_size)
    else
      content = """
      # Generated seed file for locations
      # This file was automatically generated from the database

      locations_data = #{inspect(data, pretty: true, limit: :infinity)}

      # Initialize location lookup map
      location_lookup = %{}

      # Insert locations in dependency order (parents before children)
      # First pass: insert locations without parent references
      locations_without_parents = Enum.filter(locations_data, fn loc -> is_nil(loc.parent_location_slug) end)

      if length(locations_without_parents) > 0 do
        locations_for_insert = Enum.map(locations_without_parents, fn location ->
          location
          |> Map.drop([:parent_location_slug, :cachable_calendar_location_slug])
          |> Map.put(:parent_location_id, nil)
          |> Map.put(:cachable_calendar_location_id, nil)
        end)

        {_, location_results} = MehrSchulferien.Repo.insert_all("locations", locations_for_insert, returning: [:id, :slug])
        location_lookup = Map.merge(location_lookup, Map.new(location_results, fn %{id: id, slug: slug} -> {slug, id} end))
      end

            # Subsequent passes: insert locations with parent references using Enum.reduce_while
      remaining_locations = Enum.filter(locations_data, fn loc -> not is_nil(loc.parent_location_slug) end)

      {_remaining, location_lookup} = Enum.reduce_while(1..100, {remaining_locations, location_lookup}, fn _iteration, {remaining, lookup} ->
        if length(remaining) == 0 do
          {:halt, {remaining, lookup}}
        else
          # Find locations whose parents are now available
          ready_locations = Enum.filter(remaining, fn loc -> 
            Map.has_key?(lookup, loc.parent_location_slug)
          end)
          
          if length(ready_locations) == 0 do
            # If no progress can be made, insert remaining with nil parent_id
            IO.puts("Warning: Some locations have missing parent references, inserting with nil parent_id")
            ready_locations = remaining
          end

          locations_for_insert = Enum.map(ready_locations, fn location ->
            parent_location_id = Map.get(lookup, location.parent_location_slug)
            cachable_calendar_location_id = Map.get(lookup, location.cachable_calendar_location_slug)

            location
            |> Map.drop([:parent_location_slug, :cachable_calendar_location_slug])
            |> Map.put(:parent_location_id, parent_location_id)
            |> Map.put(:cachable_calendar_location_id, cachable_calendar_location_id)
          end)

          {_, location_results} = MehrSchulferien.Repo.insert_all("locations", locations_for_insert, returning: [:id, :slug])
          updated_lookup = Map.merge(lookup, Map.new(location_results, fn %{id: id, slug: slug} -> {slug, id} end))
          
          new_remaining = remaining -- ready_locations
          {:cont, {new_remaining, updated_lookup}}
        end
      end)

      Process.put(:location_lookup, location_lookup)
      IO.puts("Inserted \#{length(locations_data)} locations")
      """

      File.write!(Path.join(seeds_dir, "locations.exs"), content)
      IO.puts("  ✓ locations.exs (#{length(data)} records)")
    end
  end

  defp create_batched_locations_seed_file(seeds_dir, data, batch_size) do
    # For locations, we need to maintain parent-child relationships across batches
    # So we'll process all data but in smaller insert operations

    content = """
    # Generated seed file for locations
    # This file was automatically generated from the database

    locations_data = #{inspect(data, pretty: true, limit: :infinity)}

    # Initialize location lookup map
    location_lookup = %{}

    # Insert locations in dependency order (parents before children)
    # First pass: insert locations without parent references
    locations_without_parents = Enum.filter(locations_data, fn loc -> is_nil(loc.parent_location_slug) end)

    if length(locations_without_parents) > 0 do
      # Process in batches
      locations_without_parents
      |> Enum.chunk_every(#{batch_size})
      |> Enum.with_index()
      |> Enum.each(fn {batch, index} ->
        IO.puts("Processing root locations batch \#{index + 1} (\#{length(batch)} records)")
        
        locations_for_insert = Enum.map(batch, fn location ->
          location
          |> Map.drop([:parent_location_slug, :cachable_calendar_location_slug])
          |> Map.put(:parent_location_id, nil)
          |> Map.put(:cachable_calendar_location_id, nil)
        end)

        {_, location_results} = MehrSchulferien.Repo.insert_all("locations", locations_for_insert, returning: [:id, :slug])
        location_lookup = Map.merge(location_lookup, Map.new(location_results, fn %{id: id, slug: slug} -> {slug, id} end))
      end)
    end

        # Subsequent passes: insert locations with parent references using Enum.reduce_while
    remaining_locations = Enum.filter(locations_data, fn loc -> not is_nil(loc.parent_location_slug) end)

    {_remaining, location_lookup} = Enum.reduce_while(1..100, {remaining_locations, location_lookup}, fn _iteration, {remaining, lookup} ->
      if length(remaining) == 0 do
        {:halt, {remaining, lookup}}
      else
        # Find locations whose parents are now available
        ready_locations = Enum.filter(remaining, fn loc -> 
          Map.has_key?(lookup, loc.parent_location_slug)
        end)
        
        if length(ready_locations) == 0 do
          # If no progress can be made, insert remaining with nil parent_id
          IO.puts("Warning: Some locations have missing parent references, inserting with nil parent_id")
          ready_locations = remaining
        end

        # Process ready locations in batches
        updated_lookup = ready_locations
        |> Enum.chunk_every(#{batch_size})
        |> Enum.with_index()
        |> Enum.reduce(lookup, fn {batch, index}, acc_lookup ->
          IO.puts("Processing child locations batch \#{index + 1} (\#{length(batch)} records)")
          
          locations_for_insert = Enum.map(batch, fn location ->
            parent_location_id = Map.get(acc_lookup, location.parent_location_slug)
            cachable_calendar_location_id = Map.get(acc_lookup, location.cachable_calendar_location_slug)

            location
            |> Map.drop([:parent_location_slug, :cachable_calendar_location_slug])
            |> Map.put(:parent_location_id, parent_location_id)
            |> Map.put(:cachable_calendar_location_id, cachable_calendar_location_id)
          end)

          {_, location_results} = MehrSchulferien.Repo.insert_all("locations", locations_for_insert, returning: [:id, :slug])
          Map.merge(acc_lookup, Map.new(location_results, fn %{id: id, slug: slug} -> {slug, id} end))
        end)
        
        new_remaining = remaining -- ready_locations
        {:cont, {new_remaining, updated_lookup}}
      end
    end)

    Process.put(:location_lookup, location_lookup)
    IO.puts("Inserted \#{length(locations_data)} locations")
    """

    batches_count =
      div(length(data), batch_size) + if rem(length(data), batch_size) > 0, do: 1, else: 0

    File.write!(Path.join(seeds_dir, "locations.exs"), content)
    IO.puts("  ✓ locations.exs (#{length(data)} records in ~#{batches_count} batches)")
  end

  defp export_holiday_or_vacation_types(seeds_dir) do
    IO.puts("Exporting holiday_or_vacation_types...")

    types =
      Repo.all(
        from h in HolidayOrVacationType,
          left_join: l in Location,
          on: h.country_location_id == l.id,
          left_join: r in Religion,
          on: h.default_religion_id == r.id,
          select: {h, l.slug, r.slug},
          order_by: h.id
      )

    data =
      types
      |> Enum.map(fn {type, country_slug, religion_slug} ->
        %{
          name: type.name,
          colloquial: type.colloquial,
          wikipedia_url: type.wikipedia_url,
          default_html_class: type.default_html_class,
          default_is_listed_below_month: type.default_is_listed_below_month,
          default_display_priority: type.default_display_priority,
          default_is_public_holiday: type.default_is_public_holiday,
          default_is_school_vacation: type.default_is_school_vacation,
          default_is_valid_for_everybody: type.default_is_valid_for_everybody,
          default_is_valid_for_students: type.default_is_valid_for_students,
          slug: type.slug,
          country_location_slug: country_slug,
          default_religion_slug: religion_slug,
          inserted_at: truncate_datetime(type.inserted_at),
          updated_at: truncate_datetime(type.updated_at)
        }
      end)

    create_seed_file(
      seeds_dir,
      "holiday_or_vacation_types.exs",
      "holiday_or_vacation_types",
      data,
      """
      # Map slugs to IDs and insert
      holiday_types_for_insert = Enum.map(holiday_or_vacation_types_data, fn type ->
        location_lookup = Process.get(:location_lookup, %{})
        religion_lookup = Process.get(:religion_lookup, %{})
        country_location_id = Map.get(location_lookup, type.country_location_slug)
        default_religion_id = if type.default_religion_slug, do: Map.get(religion_lookup, type.default_religion_slug)

        type
        |> Map.drop([:country_location_slug, :default_religion_slug])
        |> Map.put(:country_location_id, country_location_id)
        |> Map.put(:default_religion_id, default_religion_id)
      end)

          {_, holiday_type_results} = MehrSchulferien.Repo.insert_all("holiday_or_vacation_types", holiday_types_for_insert, returning: [:id, :slug])
      holiday_type_lookup = Map.merge(holiday_type_lookup, Map.new(holiday_type_results, fn %{id: id, slug: slug} -> {slug, id} end))
      Process.put(:holiday_type_lookup, holiday_type_lookup)
      """
    )
  end

  defp export_zip_codes(seeds_dir) do
    IO.puts("Exporting zip_codes...")

    zip_codes =
      Repo.all(
        from z in ZipCode,
          left_join: l in Location,
          on: z.country_location_id == l.id,
          select: {z, l.slug},
          order_by: z.id
      )

    data =
      zip_codes
      |> Enum.map(fn {zip_code, country_slug} ->
        %{
          value: zip_code.value,
          slug: zip_code.slug,
          country_location_slug: country_slug,
          inserted_at: truncate_datetime(zip_code.inserted_at),
          updated_at: truncate_datetime(zip_code.updated_at)
        }
      end)

    create_seed_file(seeds_dir, "zip_codes.exs", "zip_codes", data, """
    # Map slugs to IDs and insert
    zip_codes_for_insert = Enum.map(zip_codes_data, fn zip_code ->
      location_lookup = Process.get(:location_lookup, %{})
      country_location_id = Map.get(location_lookup, zip_code.country_location_slug)

      zip_code
      |> Map.drop([:country_location_slug])
      |> Map.put(:country_location_id, country_location_id)
    end)

    {_, zip_code_results} = MehrSchulferien.Repo.insert_all("zip_codes", zip_codes_for_insert, returning: [:id, :slug])
    zip_code_lookup = Map.merge(zip_code_lookup, Map.new(zip_code_results, fn %{id: id, slug: slug} -> {slug, id} end))
    Process.put(:zip_code_lookup, zip_code_lookup)
    """)
  end

  defp export_zip_code_mappings(seeds_dir) do
    IO.puts("Exporting zip_code_mappings...")

    mappings =
      Repo.all(
        from zcm in ZipCodeMapping,
          join: l in Location,
          on: zcm.location_id == l.id,
          join: z in ZipCode,
          on: zcm.zip_code_id == z.id,
          select: {zcm, l.slug, z.slug},
          order_by: zcm.id
      )

    data =
      mappings
      |> Enum.map(fn {mapping, location_slug, zip_code_slug} ->
        %{
          lat: mapping.lat,
          lon: mapping.lon,
          location_slug: location_slug,
          zip_code_slug: zip_code_slug,
          inserted_at: truncate_datetime(mapping.inserted_at),
          updated_at: truncate_datetime(mapping.updated_at)
        }
      end)

    create_seed_file(seeds_dir, "zip_code_mappings.exs", "zip_code_mappings", data, """
    # Map slugs to IDs and insert
    mappings_for_insert = Enum.map(zip_code_mappings_data, fn mapping ->
      location_lookup = Process.get(:location_lookup, %{})
      zip_code_lookup = Process.get(:zip_code_lookup, %{})
      location_id = Map.get(location_lookup, mapping.location_slug)
      zip_code_id = Map.get(zip_code_lookup, mapping.zip_code_slug)

      mapping
      |> Map.drop([:location_slug, :zip_code_slug])
      |> Map.put(:location_id, location_id)
      |> Map.put(:zip_code_id, zip_code_id)
    end)

    MehrSchulferien.Repo.insert_all("zip_code_mappings", mappings_for_insert)
    """)
  end

  defp export_addresses(seeds_dir) do
    IO.puts("Exporting addresses...")

    addresses =
      Repo.all(
        from a in Address,
          join: l in Location,
          on: a.school_location_id == l.id,
          select: {a, l.slug},
          order_by: a.id
      )

    data =
      addresses
      |> Enum.map(fn {address, school_slug} ->
        %{
          line1: address.line1,
          street: address.street,
          zip_code: address.zip_code,
          city: address.city,
          email_address: address.email_address,
          phone_number: address.phone_number,
          fax_number: address.fax_number,
          homepage_url: address.homepage_url,
          school_type: address.school_type,
          official_id: address.official_id,
          lon: address.lon,
          lat: address.lat,
          school_location_slug: school_slug,
          inserted_at: truncate_datetime(address.inserted_at),
          updated_at: truncate_datetime(address.updated_at)
        }
      end)

    create_seed_file(seeds_dir, "addresses.exs", "addresses", data, """
    # Map slugs to IDs and insert
    addresses_for_insert = Enum.map(addresses_data, fn address ->
      location_lookup = Process.get(:location_lookup, %{})
      school_location_id = Map.get(location_lookup, address.school_location_slug)

      address
      |> Map.drop([:school_location_slug])
      |> Map.put(:school_location_id, school_location_id)
    end)

    MehrSchulferien.Repo.insert_all("addresses", addresses_for_insert)
    """)
  end

  defp export_periods(seeds_dir) do
    IO.puts("Exporting periods...")

    periods =
      Repo.all(
        from p in Period,
          join: l in Location,
          on: p.location_id == l.id,
          join: h in HolidayOrVacationType,
          on: p.holiday_or_vacation_type_id == h.id,
          left_join: r in Religion,
          on: p.religion_id == r.id,
          select: {p, l.slug, h.slug, r.slug},
          order_by: p.id
      )

    data =
      periods
      |> Enum.map(fn {period, location_slug, holiday_type_slug, religion_slug} ->
        %{
          starts_on: period.starts_on,
          ends_on: period.ends_on,
          created_by_email_address: period.created_by_email_address,
          memo: period.memo,
          display_priority: period.display_priority,
          html_class: period.html_class,
          is_listed_below_month: period.is_listed_below_month,
          is_public_holiday: period.is_public_holiday,
          is_school_vacation: period.is_school_vacation,
          is_valid_for_everybody: period.is_valid_for_everybody,
          is_valid_for_students: period.is_valid_for_students,
          location_slug: location_slug,
          holiday_or_vacation_type_slug: holiday_type_slug,
          religion_slug: religion_slug,
          inserted_at: truncate_datetime(period.inserted_at),
          updated_at: truncate_datetime(period.updated_at)
        }
      end)

    create_seed_file(seeds_dir, "periods.exs", "periods", data, """
    # Map slugs to IDs and insert
    periods_for_insert = Enum.map(periods_data, fn period ->
      location_lookup = Process.get(:location_lookup, %{})
      holiday_type_lookup = Process.get(:holiday_type_lookup, %{})
      religion_lookup = Process.get(:religion_lookup, %{})
      location_id = Map.get(location_lookup, period.location_slug)
      holiday_or_vacation_type_id = Map.get(holiday_type_lookup, period.holiday_or_vacation_type_slug)
      religion_id = if period.religion_slug, do: Map.get(religion_lookup, period.religion_slug)

      period
      |> Map.drop([:location_slug, :holiday_or_vacation_type_slug, :religion_slug])
      |> Map.put(:location_id, location_id)
      |> Map.put(:holiday_or_vacation_type_id, holiday_or_vacation_type_id)
      |> Map.put(:religion_id, religion_id)
    end)

    MehrSchulferien.Repo.insert_all("periods", periods_for_insert)
    """)
  end

  defp create_seed_file(seeds_dir, filename, var_name, data, insertion_code) do
    # Split large datasets into smaller chunks to avoid PostgreSQL parameter limits
    batch_size = 1000

    if length(data) > batch_size do
      create_batched_seed_file(seeds_dir, filename, var_name, data, insertion_code, batch_size)
    else
      content = """
      # Generated seed file for #{var_name}
      # This file was automatically generated from the database

      #{var_name}_data = #{inspect(data, pretty: true, limit: :infinity)}

      # Initialize lookup maps
      #{get_lookup_initialization(var_name)}

      #{insertion_code}
      IO.puts("Inserted \#{length(#{var_name}_data)} #{var_name}")
      """

      File.write!(Path.join(seeds_dir, filename), content)
      IO.puts("  ✓ #{filename} (#{length(data)} records)")
    end
  end

  defp create_batched_seed_file(seeds_dir, filename, var_name, data, insertion_code, batch_size) do
    batches = Enum.chunk_every(data, batch_size)

    content = """
    # Generated seed file for #{var_name}
    # This file was automatically generated from the database

    # Process data in batches to avoid PostgreSQL parameter limits
    #{var_name}_batches = #{inspect(batches, pretty: true, limit: :infinity)}

    # Initialize lookup maps
    #{get_lookup_initialization(var_name)}

    # Process each batch
    for {batch, index} <- Enum.with_index(#{var_name}_batches) do
      IO.puts("Processing #{var_name} batch \#{index + 1}/\#{length(#{var_name}_batches)} (\#{length(batch)} records)")
      
      #{String.replace(insertion_code, "#{var_name}_data", "batch")}
    end

    total_count = #{var_name}_batches |> Enum.map(&length/1) |> Enum.sum()
    IO.puts("Inserted \#{total_count} #{var_name}")
    """

    File.write!(Path.join(seeds_dir, filename), content)
    IO.puts("  ✓ #{filename} (#{length(data)} records in #{length(batches)} batches)")
  end

  defp get_lookup_initialization(var_name) do
    case var_name do
      "religions" -> "religion_lookup = %{}"
      "locations" -> "location_lookup = %{}"
      "holiday_or_vacation_types" -> "holiday_type_lookup = %{}"
      "zip_codes" -> "zip_code_lookup = %{}"
      _ -> ""
    end
  end

  defp truncate_datetime(nil), do: nil

  defp truncate_datetime(%NaiveDateTime{} = dt) do
    %{dt | microsecond: {0, 0}}
  end
end
