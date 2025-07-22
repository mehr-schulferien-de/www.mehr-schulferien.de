defmodule MehrSchulferien.Repo.Migrations.AddSocialAndInfoFieldsToAddresses do
  use Ecto.Migration

  def change do
    alter table(:addresses) do
      add :instagram_url, :string
      add :students_count, :integer
      add :founded_year, :integer
    end
  end
end