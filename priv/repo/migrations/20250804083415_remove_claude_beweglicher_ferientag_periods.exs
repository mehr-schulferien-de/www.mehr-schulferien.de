defmodule MehrSchulferien.Repo.Migrations.RemoveClaudeBeweglicherFerientagPeriods do
  use Ecto.Migration

  def up do
    execute """
    DELETE FROM periods 
    WHERE holiday_or_vacation_type_id = 7 
      AND created_by_email_address = 'claude@anthropic.com';
    """
  end

  def down do
    # This migration is not reversible as we're deleting data
    # If you need to restore these periods, they would need to be recreated from a backup
    :ok
  end
end
