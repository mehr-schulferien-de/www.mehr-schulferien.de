defmodule MehrSchulferien.Repo.Migrations.FixVacationPeriods20262027V3 do
  use Ecto.Migration

  def up do
    # This migration fixes vacation periods for 2026/2027 school year
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
      
      -- Add missing single day 31.10. for Herbst (only if not exists)
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 2 
          AND holiday_or_vacation_type_id = herbst_id 
          AND starts_on = '2026-10-31'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2026-10-31', '2026-10-31', 'claude@anthropic.com', 2, herbst_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
      -- Add missing single day 25.03. for Ostern (only if not exists)
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 2 
          AND holiday_or_vacation_type_id = ostern_id 
          AND starts_on = '2027-03-25'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2027-03-25', '2027-03-25', 'claude@anthropic.com', 2, ostern_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
      -- Add missing period 08.02.-12.02. for Ostern (Faschingsferien) (only if not exists)
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 2 
          AND holiday_or_vacation_type_id = ostern_id 
          AND starts_on = '2027-02-08'
          AND ends_on = '2027-02-12'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2027-02-08', '2027-02-12', 'claude@anthropic.com', 2, ostern_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
      -- Add missing Himmelfahrt/Pfingsten vacation 18.05.-29.05. (only if not exists)
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 2 
          AND holiday_or_vacation_type_id = himmelfahrt_pfingsten_id 
          AND starts_on = '2027-05-18'
          AND ends_on = '2027-05-29'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2027-05-18', '2027-05-29', 'claude@anthropic.com', 2, himmelfahrt_pfingsten_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
      -- ===========================================
      -- BAYERN (ID: 3)
      -- ===========================================
      
      -- Remove incorrect Winter vacation (Bayern has no Winter vacation)
      DELETE FROM periods 
      WHERE location_id = 3 
        AND holiday_or_vacation_type_id = winter_id 
        AND starts_on = '2027-02-08'
        AND ends_on = '2027-02-12'
        AND created_by_email_address = 'claude@anthropic.com';
      
      -- Bayern already has Himmelfahrt/Pfingsten, skip
      
      -- ===========================================
      -- BERLIN (ID: 4)
      -- ===========================================
      
      -- Add missing single day 07.05. for Himmelfahrt (only if not exists)
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 4 
          AND holiday_or_vacation_type_id = himmelfahrt_id 
          AND starts_on = '2027-05-07'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2027-05-07', '2027-05-07', 'claude@anthropic.com', 4, himmelfahrt_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
      -- Add missing period 18.05.-19.05. for Himmelfahrt/Pfingsten (only if not exists)
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 4 
          AND holiday_or_vacation_type_id = himmelfahrt_pfingsten_id 
          AND starts_on = '2027-05-18'
          AND ends_on = '2027-05-19'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2027-05-18', '2027-05-19', 'claude@anthropic.com', 4, himmelfahrt_pfingsten_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
      -- ===========================================
      -- BRANDENBURG (ID: 5)
      -- ===========================================
      
      -- Remove duplicate Herbst entry
      DELETE FROM periods WHERE id = 4861;
      
      -- Add missing single day 18.05. for Himmelfahrt (only if not exists)
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 5 
          AND holiday_or_vacation_type_id = himmelfahrt_id 
          AND starts_on = '2027-05-18'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2027-05-18', '2027-05-18', 'claude@anthropic.com', 5, himmelfahrt_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
      -- ===========================================
      -- BREMEN (ID: 6)
      -- ===========================================
      
      -- Add missing single day 07.05. for Himmelfahrt (only if not exists)
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 6 
          AND holiday_or_vacation_type_id = himmelfahrt_id 
          AND starts_on = '2027-05-07'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2027-05-07', '2027-05-07', 'claude@anthropic.com', 6, himmelfahrt_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
      -- Add missing single day 18.05. for Himmelfahrt (only if not exists)
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 6 
          AND holiday_or_vacation_type_id = himmelfahrt_id 
          AND starts_on = '2027-05-18'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2027-05-18', '2027-05-18', 'claude@anthropic.com', 6, himmelfahrt_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
      -- ===========================================
      -- HAMBURG (ID: 7)
      -- ===========================================
      
      -- Hamburg already has Winter vacation on 2027-01-29, skip
      -- Hamburg has Frühjahr instead of Ostern from 01.03.-12.03., skip
      
      -- ===========================================
      -- MECKLENBURG-VORPOMMERN (ID: 9)
      -- ===========================================
      
      -- Add missing Herbst period 26.11.-27.11. (only if not exists)
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 9 
          AND holiday_or_vacation_type_id = herbst_id 
          AND starts_on = '2026-11-26'
          AND ends_on = '2026-11-27'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2026-11-26', '2026-11-27', 'claude@anthropic.com', 9, herbst_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
      -- Add missing single day 07.05. for Himmelfahrt (only if not exists)
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 9 
          AND holiday_or_vacation_type_id = himmelfahrt_id 
          AND starts_on = '2027-05-07'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2027-05-07', '2027-05-07', 'claude@anthropic.com', 9, himmelfahrt_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
      -- ===========================================
      -- NIEDERSACHSEN (ID: 10)
      -- ===========================================
      
      -- Add missing single day 07.05. for Himmelfahrt (only if not exists)
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 10 
          AND holiday_or_vacation_type_id = himmelfahrt_id 
          AND starts_on = '2027-05-07'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2027-05-07', '2027-05-07', 'claude@anthropic.com', 10, himmelfahrt_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
      -- Add missing single day 18.05. for Himmelfahrt (only if not exists)
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 10 
          AND holiday_or_vacation_type_id = himmelfahrt_id 
          AND starts_on = '2027-05-18'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2027-05-18', '2027-05-18', 'claude@anthropic.com', 10, himmelfahrt_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
      -- ===========================================
      -- NORDRHEIN-WESTFALEN (ID: 11)
      -- ===========================================
      
      -- Add missing single day 18.05. for Himmelfahrt (only if not exists)
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 11 
          AND holiday_or_vacation_type_id = himmelfahrt_id 
          AND starts_on = '2027-05-18'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2027-05-18', '2027-05-18', 'claude@anthropic.com', 11, himmelfahrt_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
      -- ===========================================
      -- SACHSEN (ID: 14)
      -- ===========================================
      
      -- Add missing single day 07.05. for Himmelfahrt (only if not exists)
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 14 
          AND holiday_or_vacation_type_id = himmelfahrt_id 
          AND starts_on = '2027-05-07'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2027-05-07', '2027-05-07', 'claude@anthropic.com', 14, himmelfahrt_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
      -- ===========================================
      -- SCHLESWIG-HOLSTEIN (ID: 16)
      -- ===========================================
      
      -- Add missing single day 07.05. for Himmelfahrt (only if not exists)
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 16 
          AND holiday_or_vacation_type_id = himmelfahrt_id 
          AND starts_on = '2027-05-07'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2027-05-07', '2027-05-07', 'claude@anthropic.com', 16, himmelfahrt_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
      -- ===========================================
      -- THÜRINGEN (ID: 17)
      -- ===========================================
      
      -- Check and add all periods for Thüringen (which was completely missing)
      
      -- Herbst vacation 12.10.-24.10.
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 17 
          AND holiday_or_vacation_type_id = herbst_id 
          AND starts_on = '2026-10-12'
          AND ends_on = '2026-10-24'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2026-10-12', '2026-10-24', 'claude@anthropic.com', 17, herbst_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
      -- Weihnachten vacation 23.12.-02.01.
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 17 
          AND holiday_or_vacation_type_id = weihnachten_id 
          AND starts_on = '2026-12-23'
          AND ends_on = '2027-01-02'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2026-12-23', '2027-01-02', 'claude@anthropic.com', 17, weihnachten_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
      -- Winter vacation 01.02.-06.02.
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 17 
          AND holiday_or_vacation_type_id = winter_id 
          AND starts_on = '2027-02-01'
          AND ends_on = '2027-02-06'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2027-02-01', '2027-02-06', 'claude@anthropic.com', 17, winter_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
      -- Ostern vacation 22.03.-03.04.
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 17 
          AND holiday_or_vacation_type_id = ostern_id 
          AND starts_on = '2027-03-22'
          AND ends_on = '2027-04-03'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2027-03-22', '2027-04-03', 'claude@anthropic.com', 17, ostern_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
      -- Single day 07.05. for Himmelfahrt
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 17 
          AND holiday_or_vacation_type_id = himmelfahrt_id 
          AND starts_on = '2027-05-07'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2027-05-07', '2027-05-07', 'claude@anthropic.com', 17, himmelfahrt_id, 
                true, true, false, false, NOW(), NOW());
      END IF;
      
      -- Sommer vacation 10.07.-20.08.
      SELECT EXISTS(
        SELECT 1 FROM periods 
        WHERE location_id = 17 
          AND holiday_or_vacation_type_id = sommer_id 
          AND starts_on = '2027-07-10'
          AND ends_on = '2027-08-20'
      ) INTO record_exists;
      
      IF NOT record_exists THEN
        INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, holiday_or_vacation_type_id, 
                            is_school_vacation, is_valid_for_students, is_public_holiday, is_valid_for_everybody,
                            inserted_at, updated_at)
        VALUES ('2027-07-10', '2027-08-20', 'claude@anthropic.com', 17, sommer_id, 
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
      AND starts_on >= '2026-10-01' 
      AND starts_on <= '2027-09-30';
    """
  end
end