defmodule MehrSchulferien.Repo.Migrations.AddMemoToPeriods do
  use Ecto.Migration

  def change do
    alter table(:periods) do
      add :memo, :text
    end
  end
end
