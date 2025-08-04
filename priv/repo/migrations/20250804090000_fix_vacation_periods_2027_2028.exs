defmodule MehrSchulferien.Repo.Migrations.FixVacationPeriods20272028 do
  use Ecto.Migration

  def up do
    # This migration fixes vacation periods for 2027/2028 school year
    # It carefully checks for existing records before inserting
    
    execute """
    DO $$
    DECLARE
      herbst_id INTEGER;
      weihnachten_id INTEGER;
      winter_id INTEGER;
      ostern_id INTEGER;
      himmelfahrt_id INTEGER;
      himmelfahrt_pfingsten_id INTEGER;
      sommer_id INTEGER;
      record_exists BOOLEAN;
    BEGIN
      -- Get vacation type IDs
      SELECT id INTO herbst_id FROM holiday_or_vacation_types WHERE name = 'Herbst';
      SELECT id INTO weihnachten_id FROM holiday_or_vacation_types WHERE name = 'Weihnachten';
      SELECT id INTO winter_id FROM holiday_or_vacation_types WHERE name = 'Winter';
      SELECT id INTO ostern_id FROM holiday_or_vacation_types WHERE name = 'Ostern';
      SELECT id INTO himmelfahrt_id FROM holiday_or_vacation_types WHERE name = 'Himmelfahrt';
      SELECT id INTO himmelfahrt_pfingsten_id FROM holiday_or_vacation_types WHERE name = 'Himmelfahrt/Pfingsten';
      SELECT id INTO sommer_id FROM holiday_or_vacation_types WHERE name = 'Sommer';
      
      -- ===========================================
      -- BADEN-WÜRTTEMBERG (ID: 2)
      -- ===========================================
      
      -- Add missing single day 13.04. for Ostern
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 2 
          AND holiday_or_vacation_type_id = ostern_id 
          AND starts_on = '2028-04-13'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2028-04-13', '2028-04-13', 'claude@anthropic.com', 2, ostern_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
      -- Add missing period 28.02.-03.03. for Ostern (Faschingsferien)
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 2 
          AND holiday_or_vacation_type_id = ostern_id 
          AND starts_on = '2028-02-28'
          AND ends_on = '2028-03-03'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2028-02-28', '2028-03-03', 'claude@anthropic.com', 2, ostern_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
      -- ===========================================
      -- BAYERN (ID: 3)
      -- ===========================================
      
      -- Remove incorrect Winter vacation (Bayern has no Winter vacation)
      DELETE FROM periods 
      WHERE location_id = 3 
        AND holiday_or_vacation_type_id = winter_id 
        AND starts_on = '2028-02-28'
        AND ends_on = '2028-03-03'
        AND created_by_email_address = 'claude@anthropic.com';
      
      -- ===========================================
      -- BERLIN (ID: 4)
      -- ===========================================
      
      -- Add missing single day 26.05. for Himmelfahrt
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 4 
          AND holiday_or_vacation_type_id = himmelfahrt_id 
          AND starts_on = '2028-05-26'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2028-05-26', '2028-05-26', 'claude@anthropic.com', 4, himmelfahrt_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
      -- Add missing period 01.06.-02.06. for Himmelfahrt
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 4 
          AND holiday_or_vacation_type_id = himmelfahrt_id 
          AND starts_on = '2028-06-01'
          AND ends_on = '2028-06-02'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2028-06-01', '2028-06-02', 'claude@anthropic.com', 4, himmelfahrt_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
      -- ===========================================
      -- BREMEN (ID: 6)
      -- ===========================================
      
      -- Add missing single day 26.05. for Himmelfahrt
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 6 
          AND holiday_or_vacation_type_id = himmelfahrt_id 
          AND starts_on = '2028-05-26'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2028-05-26', '2028-05-26', 'claude@anthropic.com', 6, himmelfahrt_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
      -- Add missing single day 06.06. for Himmelfahrt
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 6 
          AND holiday_or_vacation_type_id = himmelfahrt_id 
          AND starts_on = '2028-06-06'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2028-06-06', '2028-06-06', 'claude@anthropic.com', 6, himmelfahrt_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
      -- ===========================================
      -- HAMBURG (ID: 7)
      -- ===========================================
      
      -- Add missing single day 28.01. for Winter
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 7 
          AND holiday_or_vacation_type_id = winter_id 
          AND starts_on = '2028-01-28'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2028-01-28', '2028-01-28', 'claude@anthropic.com', 7, winter_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
      -- ===========================================
      -- MECKLENBURG-VORPOMMERN (ID: 9)
      -- ===========================================
      
      -- Add missing single day 18.02. for Winter
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 9 
          AND holiday_or_vacation_type_id = winter_id 
          AND starts_on = '2028-02-18'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2028-02-18', '2028-02-18', 'claude@anthropic.com', 9, winter_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
      -- Add missing single day 26.05. for Himmelfahrt
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 9 
          AND holiday_or_vacation_type_id = himmelfahrt_id 
          AND starts_on = '2028-05-26'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2028-05-26', '2028-05-26', 'claude@anthropic.com', 9, himmelfahrt_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
      -- ===========================================
      -- NIEDERSACHSEN (ID: 10)
      -- ===========================================
      
      -- Add missing single day 26.05. for Himmelfahrt
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 10 
          AND holiday_or_vacation_type_id = himmelfahrt_id 
          AND starts_on = '2028-05-26'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2028-05-26', '2028-05-26', 'claude@anthropic.com', 10, himmelfahrt_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
      -- Add missing single day 06.06. for Himmelfahrt
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 10 
          AND holiday_or_vacation_type_id = himmelfahrt_id 
          AND starts_on = '2028-06-06'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2028-06-06', '2028-06-06', 'claude@anthropic.com', 10, himmelfahrt_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
      -- ===========================================
      -- SACHSEN (ID: 14)
      -- ===========================================
      
      -- Add missing single day 26.05. for Himmelfahrt
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 14 
          AND holiday_or_vacation_type_id = himmelfahrt_id 
          AND starts_on = '2028-05-26'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2028-05-26', '2028-05-26', 'claude@anthropic.com', 14, himmelfahrt_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
      -- ===========================================
      -- SACHSEN-ANHALT (ID: 15)
      -- ===========================================
      
      -- Update Himmelfahrt period to be Himmelfahrt/Pfingsten type
      UPDATE periods
      SET holiday_or_vacation_type_id = himmelfahrt_pfingsten_id
      WHERE id = 5306
        AND location_id = 15
        AND starts_on = '2028-06-03'
        AND ends_on = '2028-06-10';
      
      -- ===========================================
      -- SCHLESWIG-HOLSTEIN (ID: 16)
      -- ===========================================
      
      -- Add missing single day 26.05. for Himmelfahrt
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 16 
          AND holiday_or_vacation_type_id = himmelfahrt_id 
          AND starts_on = '2028-05-26'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2028-05-26', '2028-05-26', 'claude@anthropic.com', 16, himmelfahrt_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
      -- ===========================================
      -- THÜRINGEN (ID: 17)
      -- ===========================================
      
      -- Add missing single day 26.05. for Himmelfahrt
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 17 
          AND holiday_or_vacation_type_id = himmelfahrt_id 
          AND starts_on = '2028-05-26'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2028-05-26', '2028-05-26', 'claude@anthropic.com', 17, himmelfahrt_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
    END $$;
    """
  end

  def down do
    # Remove all periods created by this migration
    execute """
    DELETE FROM periods 
    WHERE created_by_email_address = 'claude@anthropic.com'
      AND starts_on >= '2027-10-01' 
      AND starts_on <= '2028-09-30';
    
    -- Revert Sachsen-Anhalt type change
    UPDATE periods
    SET holiday_or_vacation_type_id = (SELECT id FROM holiday_or_vacation_types WHERE name = 'Himmelfahrt')
    WHERE id = 5306
      AND location_id = 15
      AND starts_on = '2028-06-03'
      AND ends_on = '2028-06-10';
    
    -- Re-add Bayern's incorrect Winter vacation (that we deleted)
    INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                        is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                        inserted_at, updated_at)
    VALUES ('2028-02-28', '2028-03-03', 'claude@anthropic.com', 3, 
            (SELECT id FROM holiday_or_vacation_types WHERE name = 'Winter'), 
            true, true, false, false, NOW(), NOW())
    ON CONFLICT (starts_on, ends_on, location_id, holiday_or_vacation_type_id) DO NOTHING;
    """
  end
end