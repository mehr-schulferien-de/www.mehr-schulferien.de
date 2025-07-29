defmodule MehrSchulferien.Repo.Migrations.NullifyShortPhoneNumbers do
  use Ecto.Migration

  def up do
    # Set all phone numbers with 10 or fewer characters to NULL
    # These are likely incomplete or incorrectly formatted phone numbers
    execute("
      UPDATE addresses 
      SET phone_number = NULL,
          updated_at = NOW()
      WHERE phone_number IS NOT NULL 
        AND phone_number != ''
        AND LENGTH(phone_number) <= 10
    ")
  end

  def down do
    # This migration is not reversible
    # Phone numbers have been deleted and cannot be restored
    IO.puts("This migration cannot be reversed - deleted phone numbers cannot be restored")
  end
end