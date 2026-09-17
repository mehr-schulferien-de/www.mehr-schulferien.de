defmodule MehrSchulferien.Repo.Migrations.RequirePeriodDisplayPriority do
  use Ecto.Migration

  # Period.changeset requires display_priority, but the August 2025 data fix
  # wrote periods with raw SQL and left it empty. nil sorts above every number,
  # so those school vacations hid public holidays such as Fronleichnam in the
  # calendar colours. The constraint makes the next raw import fail loudly.
  def up do
    execute """
    UPDATE periods AS p
    SET display_priority = COALESCE(
      (SELECT t.default_display_priority
       FROM holiday_or_vacation_types AS t
       WHERE t.id = p.holiday_or_vacation_type_id),
      5
    )
    WHERE p.display_priority IS NULL
    """

    alter table(:periods) do
      modify :display_priority, :integer, null: false
    end
  end

  def down do
    alter table(:periods) do
      modify :display_priority, :integer, null: true
    end
  end
end
