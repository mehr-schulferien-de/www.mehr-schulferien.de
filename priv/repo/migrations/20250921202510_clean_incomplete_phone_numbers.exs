defmodule MehrSchulferien.Repo.Migrations.CleanIncompletePhoneNumbers do
  use Ecto.Migration

  def up do
    # Update all entries where phone_number is exactly "+49 711 216"
    # Set both phone_number and fax_number to NULL for those addresses
    execute """
    UPDATE addresses
    SET phone_number = NULL, fax_number = NULL
    WHERE phone_number = '+49 711 216'
    """

    # Update remaining entries where fax_number is exactly "+49 711 216"
    execute """
    UPDATE addresses
    SET fax_number = NULL
    WHERE fax_number = '+49 711 216'
    """
  end

  def down do
    # This migration cannot be safely reversed as we don't know the original fax_number values
    # for addresses where phone_number was "+49 711 216"
    raise "This migration cannot be reversed"
  end
end
