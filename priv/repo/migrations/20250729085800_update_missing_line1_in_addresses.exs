defmodule MehrSchulferien.Repo.Migrations.UpdateMissingLine1InAddresses do
  use Ecto.Migration
  import Ecto.Query
  alias MehrSchulferien.Repo

  def up do
    # Find all addresses with missing line1 that belong to schools
    query = from a in "addresses",
      join: l in "locations", on: l.id == a.school_location_id,
      where: is_nil(a.line1) or a.line1 == "",
      where: l.is_school == true,
      select: %{
        address_id: a.id,
        school_name: l.name
      }

    # Get all addresses that need updating
    addresses_to_update = Repo.all(query)
    
    IO.puts("Found #{length(addresses_to_update)} addresses with missing line1")
    
    # Update each address
    Enum.each(addresses_to_update, fn %{address_id: address_id, school_name: school_name} ->
      update_query = from a in "addresses",
        where: a.id == ^address_id,
        update: [set: [line1: ^school_name, updated_at: ^DateTime.utc_now()]]
      
      {count, _} = Repo.update_all(update_query, [])
      
      if count > 0 do
        IO.puts("✓ Updated address #{address_id} - line1 set to: #{school_name}")
      end
    end)
    
    IO.puts("\nMigration completed: #{length(addresses_to_update)} addresses updated")
  end

  def down do
    # This migration is not easily reversible
    # We could set line1 back to nil, but we wouldn't know which ones were originally nil
    IO.puts("Rollback not implemented - would need to track which line1 values were originally nil")
  end
end