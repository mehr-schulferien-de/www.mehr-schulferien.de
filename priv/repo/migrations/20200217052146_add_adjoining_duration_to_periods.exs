defmodule MehrSchulferien.Repo.Migrations.AddAdjoiningDurationToPeriods do
  use Ecto.Migration

  def change do
    alter table(:periods) do
      add :adjoining_duration, :integer
      add :array_agg, {:array, :integer}
    end
  end
end
