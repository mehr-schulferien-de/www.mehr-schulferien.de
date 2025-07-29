defmodule MehrSchulferien.Repo.Migrations.FixSchoolSlugsWithZipCodes do
  use Ecto.Migration
  import Ecto.Query
  alias MehrSchulferien.Repo
  alias MehrSchulferien.Locations
  alias MehrSchulferien.Locations.Location
  alias MehrSchulferien.Maps.Address

  def up do
    # Get all schools whose slugs don't start with a 5-digit number
    schools_to_fix = 
      from(l in Location,
        where: l.is_school == true,
        where: not fragment("? ~ '^\\d{5}'", l.slug),
        left_join: a in Address, on: a.school_location_id == l.id,
        select: %{
          id: l.id,
          name: l.name,
          slug: l.slug,
          zip_code: a.zip_code
        }
      )
      |> Repo.all()

    IO.puts("Found #{length(schools_to_fix)} schools to fix")

    # Fix each school's slug
    Enum.each(schools_to_fix, fn school ->
      case school.zip_code do
        nil ->
          IO.puts("Skipping #{school.name} (#{school.slug}) - no zip code")
        
        zip_code ->
          # Use centralized function to generate unique slug
          case Locations.generate_unique_school_slug(school.name, zip_code, school.id) do
            {:ok, new_slug} ->
              update_school_slug(school.id, new_slug)
              IO.puts("Fixed: #{school.name} (#{school.slug} -> #{new_slug})")
            
            error ->
              IO.puts("Error fixing #{school.name}: #{inspect(error)}")
          end
      end
    end)

    IO.puts("Migration completed successfully!")
  end

  def down do
    # This migration is not easily reversible as we don't store the old slugs
    # If needed, you could create a backup table first in the up migration
    IO.puts("This migration cannot be automatically reversed")
  end

  defp update_school_slug(school_id, new_slug) do
    from(l in Location,
      where: l.id == ^school_id
    )
    |> Repo.update_all(set: [slug: new_slug, updated_at: DateTime.utc_now()])
  end
end