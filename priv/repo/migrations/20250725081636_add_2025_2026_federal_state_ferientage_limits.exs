defmodule MehrSchulferien.Repo.Migrations.Add20252026FederalStateFerientageLimits do
  use Ecto.Migration

  def up do
    # Define the limits for each federal state (same for all years)
    federal_state_limits = [
      {"Baden-Württemberg", 4},
      {"Bayern", 0},
      {"Berlin", 0},
      {"Brandenburg", 1},
      {"Bremen", 1},
      {"Hamburg", 0},
      {"Hessen", 4},
      {"Mecklenburg-Vorpommern", 0},
      {"Niedersachsen", 0},
      {"Nordrhein-Westfalen", 3},
      {"Rheinland-Pfalz", 6},
      {"Saarland", 2},
      {"Sachsen", 1},
      {"Sachsen-Anhalt", 2},
      {"Schleswig-Holstein", 2},
      {"Thüringen", 2}
    ]

    # Add limits for 2025/2026 school year
    school_years = ["2025/2026"]

    Enum.each(school_years, fn school_year ->
      Enum.each(federal_state_limits, fn {state_name, limit} ->
        execute """
        INSERT INTO federal_state_ferientage_limits (federal_state_id, school_year, max_bewegliche_ferientage, inserted_at, updated_at)
        SELECT l.id, '#{school_year}', #{limit}, NOW(), NOW()
        FROM locations l
        WHERE l.name = '#{state_name}'
          AND l.is_federal_state = true
          AND l.parent_location_id = (SELECT id FROM locations WHERE slug = 'd' AND is_country = true)
          AND NOT EXISTS (
            SELECT 1 FROM federal_state_ferientage_limits fsl
            WHERE fsl.federal_state_id = l.id
            AND fsl.school_year = '#{school_year}'
          )
        """
      end)
    end)
  end

  def down do
    execute """
    DELETE FROM federal_state_ferientage_limits
    WHERE school_year = '2025/2026'
    """
  end
end
