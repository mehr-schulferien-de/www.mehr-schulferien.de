defmodule MehrSchulferien.ReleaseTasks do
  @app :mehr_schulferien

  def migrate do
    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def migrate_if_pending do
    for repo <- repos() do
      case Ecto.Migrator.with_repo(repo, &get_pending_migrations/1) do
        {:ok, [_ | _] = pending_migrations, _} ->
          IO.puts("Found #{length(pending_migrations)} pending migrations for #{repo}")
          {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
          IO.puts("Migrations completed for #{repo}")

        {:ok, [], _} ->
          IO.puts("No pending migrations found for #{repo}")

        error ->
          IO.puts("Error checking migrations for #{repo}: #{inspect(error)}")
      end
    end
  end

  def rollback(repo, version) do
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp get_pending_migrations(repo) do
    migrations_path = Path.join([Application.app_dir(@app, "priv"), "repo", "migrations"])

    Ecto.Migrator.migrations(repo, migrations_path)
    |> Enum.filter(fn {status, _version, _name} -> status == :down end)
  end

  defp repos do
    Application.load(@app)
    Application.fetch_env!(@app, :ecto_repos)
  end
end
