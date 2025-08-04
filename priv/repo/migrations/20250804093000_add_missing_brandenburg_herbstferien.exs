defmodule MehrSchulferien.Repo.Migrations.AddMissingBrandenburgHerbstferien do
  use Ecto.Migration

  def up do
    # This migration adds missing Herbstferien for Brandenburg
    
    execute """
    DO $$
    DECLARE
      herbst_id INTEGER;
      record_exists BOOLEAN;
    BEGIN
      -- Get Herbst vacation type ID
      SELECT id INTO herbst_id FROM holiday_or_vacation_types WHERE name = 'Herbst';
      
      -- ===========================================
      -- BRANDENBURG (ID: 5) - 2025/2026
      -- ===========================================
      
      -- Check if Herbstferien 2025 already exists
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 5 
          AND holiday_or_vacation_type_id = herbst_id 
          AND starts_on = '2025-10-20'
          AND ends_on = '2025-11-01'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (
          starts_on, ends_on, created_by_email_address, location_id, 
          holiday_or_vacation_type_id, is_school_vacation, is_valid_for_students, 
          is_public_holiday, is_valid_for_everybody, display_priority,
          is_listed_below_month, inserted_at, updated_at
        )
        VALUES (
          '2025-10-20', '2025-11-01', 'claude@anthropic.com', 5, 
          herbst_id, true, true, 
          false, false, 5,
          false, NOW(), NOW()
        );
        RAISE NOTICE 'Added Brandenburg Herbstferien 2025/2026: 20.10. - 01.11.';
      ELSE
        RAISE NOTICE 'Brandenburg Herbstferien 2025/2026 already exists';
      END IF;
      
      -- ===========================================
      -- BRANDENBURG (ID: 5) - 2026/2027
      -- ===========================================
      
      -- Check if Herbstferien 2026 already exists
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 5 
          AND holiday_or_vacation_type_id = herbst_id 
          AND starts_on = '2026-10-19'
          AND ends_on = '2026-10-30'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        -- First check if there's a duplicate entry we need to handle
        -- (The earlier migration had a duplicate issue)
        SELECT EXISTS(
          SELECT 1 FROM periods 
          WHERE location_id = 5 
            AND holiday_or_vacation_type_id = herbst_id 
            AND starts_on = '2026-10-20'
            AND ends_on = '2026-11-01'
        ) INTO record_exists;
        
        IF record_exists THEN
          -- Remove the incorrect entry
          DELETE FROM periods 
          WHERE location_id = 5 
            AND holiday_or_vacation_type_id = herbst_id 
            AND starts_on = '2026-10-20'
            AND ends_on = '2026-11-01';
          RAISE NOTICE 'Removed incorrect Brandenburg Herbstferien 2026 entry';
        END IF;
        
        -- Now insert the correct dates
        INSERT INTO periods (
          starts_on, ends_on, created_by_email_address, location_id, 
          holiday_or_vacation_type_id, is_school_vacation, is_valid_for_students, 
          is_public_holiday, is_valid_for_everybody, display_priority,
          is_listed_below_month, inserted_at, updated_at
        )
        VALUES (
          '2026-10-19', '2026-10-30', 'claude@anthropic.com', 5, 
          herbst_id, true, true, 
          false, false, 5,
          false, NOW(), NOW()
        );
        RAISE NOTICE 'Added Brandenburg Herbstferien 2026/2027: 19.10. - 30.10.';
      ELSE
        RAISE NOTICE 'Brandenburg Herbstferien 2026/2027 already exists';
      END IF;
      
    END $$;
    """
  end

  def down do
    # Remove the periods created by this migration
    execute """
    DELETE FROM periods 
    WHERE created_by_email_address = 'claude@anthropic.com'
      AND location_id = 5
      AND starts_on IN ('2025-10-20', '2026-10-19');
    """
  end
end