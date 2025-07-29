defmodule MehrSchulferien.Repo.Migrations.MergeDuplicateSchools do
  use Ecto.Migration
  import Ecto.Query
  alias MehrSchulferien.Repo

  def up do
    # Find and merge duplicate schools
    # Note: Migrations run in a transaction by default
    merge_duplicate_schools()
  end

  def down do
    # This migration is not reversible as we're deleting data
    # and modifying existing records
    raise "This migration cannot be rolled back. The deleted school data cannot be recovered."
  end

  defp merge_duplicate_schools do
    # Get all duplicate groups
    duplicate_groups = find_duplicate_groups()

    IO.puts("================================================================================")
    IO.puts("DUPLICATE SCHOOLS MERGE MIGRATION")
    IO.puts("================================================================================")
    IO.puts("Found #{length(duplicate_groups)} groups of duplicate schools to merge")
    IO.puts("")

    merged_count = 0
    total_deleted = 0

    Enum.each(duplicate_groups, fn group ->
      {merged, deleted} = merge_group(group)
      merged_count = merged_count + merged
      total_deleted = total_deleted + deleted
    end)

    IO.puts("")
    IO.puts("================================================================================")
    IO.puts("SUMMARY:")
    IO.puts("- Processed #{length(duplicate_groups)} duplicate groups")
    IO.puts("- Merged #{merged_count} groups successfully")
    IO.puts("- Deleted #{total_deleted} duplicate schools")
    IO.puts("================================================================================")
  end

  defp find_duplicate_groups do
    # Query to find schools with the same name, zip code, and first 5 letters of street
    query = """
    SELECT l.name, a.zip_code, SUBSTRING(a.street, 1, 5) as street_prefix, COUNT(l.id) as count
    FROM locations l
    INNER JOIN addresses a ON l.id = a.school_location_id
    WHERE l.is_school = true 
      AND a.zip_code IS NOT NULL 
      AND a.street IS NOT NULL
    GROUP BY l.name, a.zip_code, SUBSTRING(a.street, 1, 5)
    HAVING COUNT(l.id) > 1
    """

    case Repo.query(query) do
      {:ok, %{rows: rows}} ->
        Enum.map(rows, fn [name, zip_code, street_prefix, _count] ->
          %{name: name, zip_code: zip_code, street_prefix: street_prefix}
        end)

      {:error, error} ->
        raise "Failed to find duplicate groups: #{inspect(error)}"
    end
  end

  defp merge_group(%{name: name, zip_code: zip_code, street_prefix: street_prefix}) do
    # Get all schools in this duplicate group
    schools_query = """
    SELECT l.id, l.inserted_at, a.id as address_id, a.street, a.phone_number, a.homepage_url
    FROM locations l
    INNER JOIN addresses a ON l.id = a.school_location_id
    WHERE l.is_school = true 
      AND l.name = $1 
      AND a.zip_code = $2 
      AND SUBSTRING(a.street, 1, 5) = $3
    ORDER BY l.inserted_at ASC
    """

    case Repo.query(schools_query, [name, zip_code, street_prefix]) do
      {:ok, %{rows: rows}} when length(rows) > 1 ->
        # First row is the oldest (to keep)
        [oldest | newer_schools] = rows

        [
          oldest_id,
          _oldest_inserted_at,
          oldest_address_id,
          oldest_street,
          oldest_phone,
          oldest_homepage
        ] = oldest

        # Get the most recent school's data
        [
          newest_id,
          _newest_inserted_at,
          newest_address_id,
          newest_street,
          newest_phone,
          newest_homepage
        ] = List.last(rows)

        # Update oldest school's address with data from newest if different
        update_oldest_address(
          oldest_address_id,
          oldest_street,
          oldest_phone,
          oldest_homepage,
          newest_street,
          newest_phone,
          newest_homepage
        )

        # Delete all newer duplicate schools
        Enum.each(newer_schools, fn [
                                      school_id,
                                      _inserted_at,
                                      address_id,
                                      _street,
                                      _phone,
                                      _homepage
                                    ] ->
          delete_school_and_address(school_id, address_id)
        end)

        IO.puts(
          "Merged #{length(newer_schools)} duplicates for: #{name} (#{zip_code}, #{street_prefix}...)"
        )

        {1, length(newer_schools)}

      {:ok, _} ->
        # No duplicates found or only one school
        {0, 0}

      {:error, error} ->
        raise "Failed to query schools: #{inspect(error)}"
    end
  end

  defp update_oldest_address(
         address_id,
         old_street,
         old_phone,
         old_homepage,
         new_street,
         new_phone,
         new_homepage
       ) do
    updates = []
    params = [address_id]
    param_count = 1

    # Build dynamic update query
    {updates, params, param_count} =
      if new_street != old_street and not is_nil(new_street) do
        param_count = param_count + 1
        {["street = $#{param_count}" | updates], params ++ [new_street], param_count}
      else
        {updates, params, param_count}
      end

    {updates, params, param_count} =
      if new_phone != old_phone and not is_nil(new_phone) do
        param_count = param_count + 1
        {["phone_number = $#{param_count}" | updates], params ++ [new_phone], param_count}
      else
        {updates, params, param_count}
      end

    {updates, params, _param_count} =
      if new_homepage != old_homepage and not is_nil(new_homepage) do
        param_count = param_count + 1
        {["homepage_url = $#{param_count}" | updates], params ++ [new_homepage], param_count}
      else
        {updates, params, param_count}
      end

    # Only update if there are changes
    if length(updates) > 0 do
      update_query = """
      UPDATE addresses 
      SET #{Enum.join(updates, ", ")}, updated_at = NOW()
      WHERE id = $1
      """

      case Repo.query(update_query, params) do
        {:ok, _} -> :ok
        {:error, error} -> raise "Failed to update address: #{inspect(error)}"
      end
    end
  end

  defp delete_school_and_address(school_id, address_id) do
    # First check if the school has any child locations
    check_children_query = "SELECT COUNT(*) FROM locations WHERE parent_location_id = $1"

    case Repo.query(check_children_query, [school_id]) do
      {:ok, %{rows: [[0]]}} ->
        # No children, safe to delete

        # Delete any periods associated with this location
        delete_periods_query = "DELETE FROM periods WHERE location_id = $1"

        case Repo.query(delete_periods_query, [school_id]) do
          {:ok, _} -> :ok
          {:error, error} -> raise "Failed to delete periods: #{inspect(error)}"
        end

        # Delete address
        delete_address_query = "DELETE FROM addresses WHERE id = $1"

        case Repo.query(delete_address_query, [address_id]) do
          {:ok, _} -> :ok
          {:error, error} -> raise "Failed to delete address: #{inspect(error)}"
        end

        # Delete location
        delete_location_query = "DELETE FROM locations WHERE id = $1"

        case Repo.query(delete_location_query, [school_id]) do
          {:ok, _} -> :ok
          {:error, error} -> raise "Failed to delete location: #{inspect(error)}"
        end

      {:ok, %{rows: [[count]]}} ->
        # Has children, cannot delete
        raise "Cannot delete school with ID #{school_id} because it has #{count} child locations"

      {:error, error} ->
        raise "Failed to check for child locations: #{inspect(error)}"
    end
  end
end
