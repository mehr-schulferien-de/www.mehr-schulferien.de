defmodule MehrSchulferien.Repo.Migrations.NormalizeAllPhoneNumbers do
  use Ecto.Migration
  import Ecto.Query
  alias MehrSchulferien.Repo

  def up do
    # Get all addresses with phone numbers
    query = from a in "addresses",
      where: not is_nil(a.phone_number) and a.phone_number != "",
      select: %{
        id: a.id,
        phone_number: a.phone_number
      }

    addresses = Repo.all(query)
    
    IO.puts("Processing #{length(addresses)} phone numbers...")
    
    updated_count = 0
    error_count = 0
    
    {updated_count, error_count} = Enum.reduce(addresses, {0, 0}, fn address, {updated, errors} ->
      normalized = normalize_german_phone(address.phone_number)
      
      if normalized != address.phone_number do
        IO.puts("Updating address #{address.id}:")
        IO.puts("  From: #{address.phone_number}")
        IO.puts("  To:   #{normalized}")
        
        update_query = from a in "addresses",
          where: a.id == ^address.id,
          update: [set: [phone_number: ^normalized, updated_at: ^DateTime.utc_now()]]
        
        case Repo.update_all(update_query, []) do
          {1, _} -> {updated + 1, errors}
          _ -> 
            IO.puts("  ERROR: Failed to update")
            {updated, errors + 1}
        end
      else
        {updated, errors}
      end
    end)
    
    IO.puts("\nMigration completed:")
    IO.puts("  Total addresses processed: #{length(addresses)}")
    IO.puts("  Phone numbers updated: #{updated_count}")
    IO.puts("  Errors: #{error_count}")
  end

  def down do
    IO.puts("Rollback not implemented - phone number normalization cannot be easily reversed")
  end
  
  # Same normalization logic as in Maps.Address module
  defp normalize_german_phone(phone_number) do
    # Import ExPhoneNumber at runtime since it's not available at compile time in migrations
    Code.ensure_loaded(ExPhoneNumber)
    
    # Clean the input by removing common separators but keep spaces for formatting
    cleaned = String.replace(phone_number, ~r/[-\/\(\)]/, "")
    
    cond do
      # Already in international format
      String.starts_with?(cleaned, "+") ->
        phone_number
      
      # Try to parse as German number
      true ->
        case ExPhoneNumber.parse(cleaned, "DE") do
          {:ok, parsed_number} ->
            ExPhoneNumber.format(parsed_number, :international)
          
          _ ->
            # If parsing fails, leave original unchanged to avoid data loss
            phone_number
        end
    end
  end
end