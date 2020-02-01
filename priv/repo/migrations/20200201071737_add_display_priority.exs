defmodule MehrSchulferien.Repo.Migrations.AddDisplayPriority do
  use Ecto.Migration

  def change do
    alter table(:holiday_or_vacation_types) do
      add :default_display_priority, :integer
    end

    alter table(:periods) do
      add :display_priority, :integer
    end
  end
end
