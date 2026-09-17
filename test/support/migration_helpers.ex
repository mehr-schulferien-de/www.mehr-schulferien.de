defmodule MehrSchulferien.MigrationHelpers do
  @moduledoc """
  Loads a data migration from `priv/repo/migrations`, runs it inside the SQL
  sandbox, and builds the periods it works on.
  """

  import MehrSchulferien.Factory

  alias MehrSchulferien.Repo

  # `mix test` runs ecto.migrate in the same VM first. When the migration was
  # pending it is already loaded, and compiling it again would warn.
  def require_migration!(name) do
    module = Module.concat(MehrSchulferien.Repo.Migrations, Macro.camelize(name))

    unless Code.ensure_loaded?(module) do
      [file] = Path.wildcard(Path.join(Ecto.Migrator.migrations_path(Repo), "*_#{name}.exs"))
      Code.compile_file(file)
    end

    module
  end

  # A fresh version per call, because Ecto skips a version it already ran.
  # The lock is off: it would hold the sandbox connection the migration needs.
  def run_migration(module) do
    :ok =
      Ecto.Migrator.up(Repo, System.unique_integer([:positive]), module,
        log: false,
        migration_lock: false
      )
  end

  @doc "One holiday_or_vacation_type per slug; those in `vacations` are school vacations."
  def insert_types(country, slugs, vacations \\ nil) do
    Map.new(slugs, fn slug ->
      {slug,
       insert(:holiday_or_vacation_type,
         name: slug,
         slug: slug,
         default_is_school_vacation: slug in (vacations || slugs),
         country_location_id: country.id
       )}
    end)
  end

  def insert_vacation(type, location, starts_on, ends_on, attrs \\ []) do
    insert(
      :school_vacation,
      Keyword.merge(
        [
          location_id: location.id,
          holiday_or_vacation_type: type,
          starts_on: starts_on,
          ends_on: ends_on,
          is_valid_for_students: true,
          is_listed_below_month: true,
          display_priority: 5
        ],
        attrs
      )
    )
  end

  def insert_holiday(type, location, date) do
    insert(:public_holiday,
      location_id: location.id,
      holiday_or_vacation_type: type,
      starts_on: date,
      ends_on: date,
      is_valid_for_everybody: true,
      is_valid_for_students: true,
      is_listed_below_month: true,
      display_priority: 10
    )
  end
end
