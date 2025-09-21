defmodule MehrSchulferien.Repo.Migrations.CleanIncompleteGermanPhoneNumbers do
  use Ecto.Migration

  import Ecto.Query

  def up do
    # Clean up incomplete phone numbers that match "+49 XXX XXX" pattern
    # These are incomplete German phone numbers that should be NULL

    from(a in "addresses",
      where: fragment("? ~ ?", a.phone_number, "^\\+49 \\d{3} \\d{3}$"),
      update: [set: [phone_number: nil]]
    )
    |> MehrSchulferien.Repo.update_all([])

    from(a in "addresses",
      where: fragment("? ~ ?", a.fax_number, "^\\+49 \\d{3} \\d{3}$"),
      update: [set: [fax_number: nil]]
    )
    |> MehrSchulferien.Repo.update_all([])
  end

  def down do
    # This migration is not reversible as we don't store the original incomplete numbers
    :ok
  end
end
