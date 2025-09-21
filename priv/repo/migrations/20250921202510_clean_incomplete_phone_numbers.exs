defmodule MehrSchulferien.Repo.Migrations.CleanIncompletePhoneNumbers do
  use Ecto.Migration
  import Ecto.Query

  def up do
    # Update all entries where phone_number is exactly "+49 711 216"
    # Set both phone_number and fax_number to NULL for those addresses
    from(a in "addresses",
      where: a.phone_number == "+49 711 216",
      update: [set: [phone_number: nil, fax_number: nil]]
    )
    |> repo().update_all([])

    # Update remaining entries where fax_number is exactly "+49 711 216"
    from(a in "addresses",
      where: a.fax_number == "+49 711 216",
      update: [set: [fax_number: nil]]
    )
    |> repo().update_all([])
  end

  def down do
    # This migration cannot be safely reversed as we don't know the original fax_number values
    # for addresses where phone_number was "+49 711 216"
    raise "This migration cannot be reversed"
  end
end
