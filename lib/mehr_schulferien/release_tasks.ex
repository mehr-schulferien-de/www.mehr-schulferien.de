defmodule MehrSchulferien.ReleaseTasks do
  @app :mehr_schulferien

  def migrate do
    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def migrate_if_pending do
    for repo <- repos() do
      {:ok, _, _} =
        Ecto.Migrator.with_repo(repo, fn repo ->
          migrations = Ecto.Migrator.migrations(repo)
          pending_migrations = Enum.filter(migrations, fn {status, _, _} -> status == :down end)

          if length(pending_migrations) > 0 do
            IO.puts("Running #{length(pending_migrations)} pending migrations...")
            Ecto.Migrator.run(repo, :up, all: true)
          else
            IO.puts("No pending migrations.")
            []
          end
        end)
    end
  end

  def rollback(repo, version) do
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.load(@app)
    Application.fetch_env!(@app, :ecto_repos)
  end
end
