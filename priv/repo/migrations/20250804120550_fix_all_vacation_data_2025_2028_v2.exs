defmodule MehrSchulferien.Repo.Migrations.FixAllVacationData20252028V2 do
  use Ecto.Migration

  def up do
    # This migration fixes all vacation data for school years 2025/2026, 2026/2027, and 2027/2028
    # Based on official KMK (Kultusministerkonferenz) vacation schedules
    
    execute """
    DO $$
    BEGIN
      -- Create temporary table with all vacation data to insert
      CREATE TEMP TABLE vacation_data_to_insert (
        starts_on DATE,
        ends_on DATE,
        location_id INTEGER,
        vacation_type VARCHAR,
        UNIQUE(starts_on, ends_on, location_id, vacation_type)
      );
      
      -- Insert all vacation data into temporary table
      -- SCHOOL YEAR 2025/2026
      
      -- Baden-Württemberg (ID: 2)
      INSERT INTO vacation_data_to_insert VALUES
      ('2025-10-27', '2025-10-30', 2, 'Herbst'),
      ('2025-10-31', '2025-10-31', 2, 'Herbst'),
      ('2025-12-22', '2026-01-05', 2, 'Weihnachten'),
      ('2026-03-30', '2026-04-11', 2, 'Ostern'),
      ('2026-05-26', '2026-06-05', 2, 'Himmelfahrt/Pfingsten'),
      ('2026-07-30', '2026-09-12', 2, 'Sommer');
    
      -- Bayern (ID: 3)
      INSERT INTO vacation_data_to_insert VALUES
      ('2025-11-03', '2025-11-07', 3, 'Herbst'),
      ('2025-12-22', '2026-01-05', 3, 'Weihnachten'),
      ('2026-02-16', '2026-02-20', 3, 'Frühjahr'),
      ('2026-03-30', '2026-04-10', 3, 'Ostern'),
      ('2026-05-26', '2026-06-05', 3, 'Himmelfahrt/Pfingsten'),
      ('2026-08-03', '2026-09-14', 3, 'Sommer');
    
      -- Berlin (ID: 4)
      INSERT INTO vacation_data_to_insert VALUES
      ('2025-10-20', '2025-11-01', 4, 'Herbst'),
      ('2025-12-22', '2026-01-02', 4, 'Weihnachten'),
      ('2026-02-02', '2026-02-07', 4, 'Winter'),
      ('2026-03-30', '2026-04-10', 4, 'Ostern'),
      ('2026-05-15', '2026-05-15', 4, 'Himmelfahrt'),
      ('2026-05-26', '2026-05-26', 4, 'Pfingsten'),
      ('2026-07-09', '2026-08-22', 4, 'Sommer');
    
      -- Brandenburg (ID: 5)
      INSERT INTO vacation_data_to_insert VALUES
      ('2025-10-20', '2025-11-01', 5, 'Herbst'),
      ('2025-12-22', '2026-01-02', 5, 'Weihnachten'),
      ('2026-02-02', '2026-02-07', 5, 'Winter'),
      ('2026-03-30', '2026-04-10', 5, 'Ostern'),
      ('2026-05-26', '2026-05-26', 5, 'Pfingsten'),
      ('2026-07-09', '2026-08-22', 5, 'Sommer');
    
      -- Bremen (ID: 6)
      INSERT INTO vacation_data_to_insert VALUES
      ('2025-10-13', '2025-10-25', 6, 'Herbst'),
      ('2025-12-22', '2026-01-05', 6, 'Weihnachten'),
      ('2026-02-02', '2026-02-03', 6, 'Winter'),
      ('2026-03-23', '2026-04-07', 6, 'Ostern'),
      ('2026-05-15', '2026-05-15', 6, 'Himmelfahrt'),
      ('2026-05-26', '2026-05-26', 6, 'Pfingsten'),
      ('2026-07-02', '2026-08-12', 6, 'Sommer');
    
      -- Hamburg (ID: 7)
      INSERT INTO vacation_data_to_insert VALUES
      ('2025-10-20', '2025-10-31', 7, 'Herbst'),
      ('2025-12-17', '2026-01-02', 7, 'Weihnachten'),
      ('2026-01-30', '2026-01-30', 7, 'Winter'),
      ('2026-03-02', '2026-03-13', 7, 'Frühjahr'),
      ('2026-05-11', '2026-05-15', 7, 'Himmelfahrt'),
      ('2026-07-09', '2026-08-19', 7, 'Sommer');
    
      -- Hessen (ID: 8)
      INSERT INTO vacation_data_to_insert VALUES
      ('2025-10-06', '2025-10-18', 8, 'Herbst'),
      ('2025-12-22', '2026-01-10', 8, 'Weihnachten'),
      ('2026-03-30', '2026-04-10', 8, 'Ostern'),
      ('2026-06-29', '2026-08-07', 8, 'Sommer');
    
      -- Mecklenburg-Vorpommern (ID: 9)
      INSERT INTO vacation_data_to_insert VALUES
      ('2025-10-02', '2025-10-02', 9, 'Herbst'),
      ('2025-10-20', '2025-10-25', 9, 'Herbst'),
      ('2025-11-03', '2025-11-03', 9, 'Herbst'),
      ('2025-12-22', '2026-01-05', 9, 'Weihnachten'),
      ('2026-02-09', '2026-02-20', 9, 'Winter'),
      ('2026-03-30', '2026-04-08', 9, 'Ostern'),
      ('2026-05-15', '2026-05-15', 9, 'Himmelfahrt'),
      ('2026-05-22', '2026-05-26', 9, 'Pfingsten'),
      ('2026-07-13', '2026-08-22', 9, 'Sommer');
    
      -- Niedersachsen (ID: 10)
      INSERT INTO vacation_data_to_insert VALUES
      ('2025-10-13', '2025-10-25', 10, 'Herbst'),
      ('2025-12-22', '2026-01-05', 10, 'Weihnachten'),
      ('2026-02-02', '2026-02-03', 10, 'Winter'),
      ('2026-03-23', '2026-04-07', 10, 'Ostern'),
      ('2026-05-15', '2026-05-15', 10, 'Himmelfahrt'),
      ('2026-05-26', '2026-05-26', 10, 'Pfingsten'),
      ('2026-07-02', '2026-08-12', 10, 'Sommer');
    
      -- Nordrhein-Westfalen (ID: 11)
      INSERT INTO vacation_data_to_insert VALUES
      ('2025-10-13', '2025-10-25', 11, 'Herbst'),
      ('2025-12-22', '2026-01-06', 11, 'Weihnachten'),
      ('2026-03-30', '2026-04-11', 11, 'Ostern'),
      ('2026-05-26', '2026-05-26', 11, 'Pfingsten'),
      ('2026-07-20', '2026-09-01', 11, 'Sommer');
    
      -- Rheinland-Pfalz (ID: 12)
      INSERT INTO vacation_data_to_insert VALUES
      ('2025-10-13', '2025-10-24', 12, 'Herbst'),
      ('2025-12-22', '2026-01-07', 12, 'Weihnachten'),
      ('2026-03-30', '2026-04-10', 12, 'Ostern'),
      ('2026-06-29', '2026-08-07', 12, 'Sommer');
    
      -- Saarland (ID: 13)
      INSERT INTO vacation_data_to_insert VALUES
      ('2025-10-13', '2025-10-24', 13, 'Herbst'),
      ('2025-12-22', '2026-01-02', 13, 'Weihnachten'),
      ('2026-02-16', '2026-02-20', 13, 'Winter'),
      ('2026-04-07', '2026-04-17', 13, 'Ostern'),
      ('2026-06-29', '2026-08-07', 13, 'Sommer');
    
      -- Sachsen (ID: 14)
      INSERT INTO vacation_data_to_insert VALUES
      ('2025-10-06', '2025-10-18', 14, 'Herbst'),
      ('2025-12-22', '2026-01-02', 14, 'Weihnachten'),
      ('2026-02-09', '2026-02-21', 14, 'Winter'),
      ('2026-04-03', '2026-04-10', 14, 'Ostern'),
      ('2026-05-15', '2026-05-15', 14, 'Himmelfahrt'),
      ('2026-07-04', '2026-08-14', 14, 'Sommer');
    
      -- Sachsen-Anhalt (ID: 15)
      INSERT INTO vacation_data_to_insert VALUES
      ('2025-10-13', '2025-10-25', 15, 'Herbst'),
      ('2025-12-22', '2026-01-05', 15, 'Weihnachten'),
      ('2026-01-31', '2026-02-06', 15, 'Winter'),
      ('2026-03-30', '2026-04-04', 15, 'Ostern'),
      ('2026-05-26', '2026-05-29', 15, 'Himmelfahrt/Pfingsten'),
      ('2026-07-04', '2026-08-14', 15, 'Sommer');
    
      -- Schleswig-Holstein (ID: 16)
      INSERT INTO vacation_data_to_insert VALUES
      ('2025-10-20', '2025-10-30', 16, 'Herbst'),
      ('2025-12-19', '2026-01-06', 16, 'Weihnachten'),
      ('2026-03-26', '2026-04-10', 16, 'Ostern'),
      ('2026-05-15', '2026-05-15', 16, 'Himmelfahrt'),
      ('2026-07-04', '2026-08-15', 16, 'Sommer');
    
      -- Thüringen (ID: 17)
      INSERT INTO vacation_data_to_insert VALUES
      ('2025-10-06', '2025-10-18', 17, 'Herbst'),
      ('2025-12-22', '2026-01-03', 17, 'Weihnachten'),
      ('2026-02-16', '2026-02-21', 17, 'Winter'),
      ('2026-04-07', '2026-04-17', 17, 'Ostern'),
      ('2026-05-15', '2026-05-15', 17, 'Himmelfahrt'),
      ('2026-07-04', '2026-08-14', 17, 'Sommer');
    
      -- SCHOOL YEAR 2026/2027
    
      -- Baden-Württemberg (ID: 2)
      INSERT INTO vacation_data_to_insert VALUES
      ('2026-10-26', '2026-10-30', 2, 'Herbst'),
      ('2026-10-31', '2026-10-31', 2, 'Herbst'),
      ('2026-12-23', '2027-01-09', 2, 'Weihnachten'),
      ('2027-03-25', '2027-03-25', 2, 'Ostern'),
      ('2027-03-30', '2027-04-03', 2, 'Ostern'),
      ('2027-05-18', '2027-05-29', 2, 'Himmelfahrt/Pfingsten'),
      ('2027-07-29', '2027-09-11', 2, 'Sommer');
    
      -- Bayern (ID: 3)
      INSERT INTO vacation_data_to_insert VALUES
      ('2026-11-02', '2026-11-06', 3, 'Herbst'),
      ('2026-12-24', '2027-01-08', 3, 'Weihnachten'),
      ('2027-02-08', '2027-02-12', 3, 'Frühjahr'),
      ('2027-03-22', '2027-04-02', 3, 'Ostern'),
      ('2027-05-18', '2027-05-28', 3, 'Himmelfahrt/Pfingsten'),
      ('2027-08-02', '2027-09-13', 3, 'Sommer');
    
      -- Berlin (ID: 4)
      INSERT INTO vacation_data_to_insert VALUES
      ('2026-10-19', '2026-10-31', 4, 'Herbst'),
      ('2026-12-23', '2027-01-02', 4, 'Weihnachten'),
      ('2027-02-01', '2027-02-06', 4, 'Winter'),
      ('2027-03-22', '2027-04-02', 4, 'Ostern'),
      ('2027-05-07', '2027-05-07', 4, 'Himmelfahrt'),
      ('2027-05-18', '2027-05-19', 4, 'Pfingsten'),
      ('2027-07-01', '2027-08-14', 4, 'Sommer');
    
      -- Brandenburg (ID: 5)
      INSERT INTO vacation_data_to_insert VALUES
      ('2026-10-19', '2026-10-30', 5, 'Herbst'),
      ('2026-12-23', '2027-01-02', 5, 'Weihnachten'),
      ('2027-02-01', '2027-02-06', 5, 'Winter'),
      ('2027-03-22', '2027-04-03', 5, 'Ostern'),
      ('2027-05-18', '2027-05-18', 5, 'Pfingsten'),
      ('2027-07-01', '2027-08-14', 5, 'Sommer');
    
      -- Bremen (ID: 6)
      INSERT INTO vacation_data_to_insert VALUES
      ('2026-10-12', '2026-10-24', 6, 'Herbst'),
      ('2026-12-23', '2027-01-09', 6, 'Weihnachten'),
      ('2027-02-01', '2027-02-02', 6, 'Winter'),
      ('2027-03-22', '2027-04-03', 6, 'Ostern'),
      ('2027-05-07', '2027-05-07', 6, 'Himmelfahrt'),
      ('2027-05-18', '2027-05-18', 6, 'Pfingsten'),
      ('2027-07-08', '2027-08-18', 6, 'Sommer');
    
      -- Hamburg (ID: 7)
      INSERT INTO vacation_data_to_insert VALUES
      ('2026-10-19', '2026-10-30', 7, 'Herbst'),
      ('2026-12-21', '2027-01-01', 7, 'Weihnachten'),
      ('2027-01-29', '2027-01-29', 7, 'Winter'),
      ('2027-03-01', '2027-03-12', 7, 'Frühjahr'),
      ('2027-05-07', '2027-05-14', 7, 'Himmelfahrt'),
      ('2027-07-01', '2027-08-11', 7, 'Sommer');
    
      -- Hessen (ID: 8)
      INSERT INTO vacation_data_to_insert VALUES
      ('2026-10-05', '2026-10-17', 8, 'Herbst'),
      ('2026-12-23', '2027-01-12', 8, 'Weihnachten'),
      ('2027-03-22', '2027-04-02', 8, 'Ostern'),
      ('2027-06-28', '2027-08-06', 8, 'Sommer');
    
      -- Mecklenburg-Vorpommern (ID: 9)
      INSERT INTO vacation_data_to_insert VALUES
      ('2026-10-19', '2026-10-24', 9, 'Herbst'),
      ('2026-11-26', '2026-11-27', 9, 'Herbst'),
      ('2026-12-19', '2027-01-02', 9, 'Weihnachten'),
      ('2027-02-08', '2027-02-19', 9, 'Winter'),
      ('2027-03-22', '2027-03-31', 9, 'Ostern'),
      ('2027-05-07', '2027-05-07', 9, 'Himmelfahrt'),
      ('2027-05-14', '2027-05-18', 9, 'Pfingsten'),
      ('2027-07-05', '2027-08-14', 9, 'Sommer');
    
      -- Niedersachsen (ID: 10)
      INSERT INTO vacation_data_to_insert VALUES
      ('2026-10-12', '2026-10-24', 10, 'Herbst'),
      ('2026-12-23', '2027-01-09', 10, 'Weihnachten'),
      ('2027-02-01', '2027-02-02', 10, 'Winter'),
      ('2027-03-22', '2027-04-03', 10, 'Ostern'),
      ('2027-05-07', '2027-05-07', 10, 'Himmelfahrt'),
      ('2027-05-18', '2027-05-18', 10, 'Pfingsten'),
      ('2027-07-08', '2027-08-18', 10, 'Sommer');
    
      -- Nordrhein-Westfalen (ID: 11)
      INSERT INTO vacation_data_to_insert VALUES
      ('2026-10-17', '2026-10-31', 11, 'Herbst'),
      ('2026-12-23', '2027-01-06', 11, 'Weihnachten'),
      ('2027-03-22', '2027-04-03', 11, 'Ostern'),
      ('2027-05-18', '2027-05-18', 11, 'Pfingsten'),
      ('2027-07-19', '2027-08-31', 11, 'Sommer');
    
      -- Rheinland-Pfalz (ID: 12)
      INSERT INTO vacation_data_to_insert VALUES
      ('2026-10-05', '2026-10-16', 12, 'Herbst'),
      ('2026-12-23', '2027-01-08', 12, 'Weihnachten'),
      ('2027-03-22', '2027-04-02', 12, 'Ostern'),
      ('2027-06-28', '2027-08-06', 12, 'Sommer');
    
      -- Saarland (ID: 13)
      INSERT INTO vacation_data_to_insert VALUES
      ('2026-10-05', '2026-10-16', 13, 'Herbst'),
      ('2026-12-21', '2026-12-31', 13, 'Weihnachten'),
      ('2027-02-08', '2027-02-12', 13, 'Winter'),
      ('2027-03-30', '2027-04-09', 13, 'Ostern'),
      ('2027-06-28', '2027-08-06', 13, 'Sommer');
    
      -- Sachsen (ID: 14)
      INSERT INTO vacation_data_to_insert VALUES
      ('2026-10-12', '2026-10-24', 14, 'Herbst'),
      ('2026-12-23', '2027-01-02', 14, 'Weihnachten'),
      ('2027-02-08', '2027-02-19', 14, 'Winter'),
      ('2027-03-26', '2027-04-02', 14, 'Ostern'),
      ('2027-05-07', '2027-05-07', 14, 'Himmelfahrt'),
      ('2027-05-15', '2027-05-18', 14, 'Pfingsten'),
      ('2027-07-10', '2027-08-20', 14, 'Sommer');
    
      -- Sachsen-Anhalt (ID: 15)
      INSERT INTO vacation_data_to_insert VALUES
      ('2026-10-19', '2026-10-30', 15, 'Herbst'),
      ('2026-12-21', '2027-01-02', 15, 'Weihnachten'),
      ('2027-02-01', '2027-02-06', 15, 'Winter'),
      ('2027-03-22', '2027-03-27', 15, 'Ostern'),
      ('2027-05-15', '2027-05-22', 15, 'Himmelfahrt/Pfingsten'),
      ('2027-07-10', '2027-08-20', 15, 'Sommer');
    
      -- Schleswig-Holstein (ID: 16)
      INSERT INTO vacation_data_to_insert VALUES
      ('2026-10-12', '2026-10-24', 16, 'Herbst'),
      ('2026-12-21', '2027-01-06', 16, 'Weihnachten'),
      ('2027-03-30', '2027-04-10', 16, 'Ostern'),
      ('2027-05-07', '2027-05-07', 16, 'Himmelfahrt'),
      ('2027-07-03', '2027-08-14', 16, 'Sommer');
    
      -- Thüringen (ID: 17)
      INSERT INTO vacation_data_to_insert VALUES
      ('2026-10-12', '2026-10-24', 17, 'Herbst'),
      ('2026-12-23', '2027-01-02', 17, 'Weihnachten'),
      ('2027-02-01', '2027-02-06', 17, 'Winter'),
      ('2027-03-22', '2027-04-03', 17, 'Ostern'),
      ('2027-05-07', '2027-05-07', 17, 'Himmelfahrt'),
      ('2027-07-10', '2027-08-20', 17, 'Sommer');
    
      -- SCHOOL YEAR 2027/2028
    
      -- Baden-Württemberg (ID: 2)
      INSERT INTO vacation_data_to_insert VALUES
      ('2027-11-02', '2027-11-06', 2, 'Herbst'),
      ('2027-12-23', '2028-01-08', 2, 'Weihnachten'),
      ('2028-04-13', '2028-04-13', 2, 'Ostern'),
      ('2028-04-18', '2028-04-22', 2, 'Ostern'),
      ('2028-06-06', '2028-06-17', 2, 'Himmelfahrt/Pfingsten'),
      ('2028-07-27', '2028-09-09', 2, 'Sommer');
    
      -- Bayern (ID: 3)
      INSERT INTO vacation_data_to_insert VALUES
      ('2027-11-02', '2027-11-05', 3, 'Herbst'),
      ('2027-12-24', '2028-01-07', 3, 'Weihnachten'),
      ('2028-02-28', '2028-03-03', 3, 'Frühjahr'),
      ('2028-04-10', '2028-04-21', 3, 'Ostern'),
      ('2028-06-06', '2028-06-16', 3, 'Himmelfahrt/Pfingsten'),
      ('2028-07-31', '2028-09-11', 3, 'Sommer');
    
      -- Berlin (ID: 4)
      INSERT INTO vacation_data_to_insert VALUES
      ('2027-10-11', '2027-10-23', 4, 'Herbst'),
      ('2027-12-22', '2027-12-31', 4, 'Weihnachten'),
      ('2028-01-31', '2028-02-05', 4, 'Winter'),
      ('2028-04-10', '2028-04-22', 4, 'Ostern'),
      ('2028-05-26', '2028-05-26', 4, 'Himmelfahrt'),
      ('2028-06-01', '2028-06-02', 4, 'Pfingsten'),
      ('2028-07-01', '2028-08-12', 4, 'Sommer');
    
      -- Brandenburg (ID: 5)
      INSERT INTO vacation_data_to_insert VALUES
      ('2027-10-11', '2027-10-23', 5, 'Herbst'),
      ('2027-12-23', '2027-12-31', 5, 'Weihnachten'),
      ('2028-01-31', '2028-02-05', 5, 'Winter'),
      ('2028-04-10', '2028-04-22', 5, 'Ostern'),
      ('2028-06-29', '2028-08-12', 5, 'Sommer');
    
      -- Bremen (ID: 6)
      INSERT INTO vacation_data_to_insert VALUES
      ('2027-10-18', '2027-10-30', 6, 'Herbst'),
      ('2027-12-23', '2028-01-08', 6, 'Weihnachten'),
      ('2028-01-31', '2028-02-01', 6, 'Winter'),
      ('2028-04-10', '2028-04-22', 6, 'Ostern'),
      ('2028-05-26', '2028-05-26', 6, 'Himmelfahrt'),
      ('2028-06-06', '2028-06-06', 6, 'Pfingsten'),
      ('2028-07-20', '2028-08-30', 6, 'Sommer');
    
      -- Hamburg (ID: 7)
      INSERT INTO vacation_data_to_insert VALUES
      ('2027-10-11', '2027-10-22', 7, 'Herbst'),
      ('2027-12-20', '2027-12-31', 7, 'Weihnachten'),
      ('2028-01-28', '2028-01-28', 7, 'Winter'),
      ('2028-03-06', '2028-03-17', 7, 'Frühjahr'),
      ('2028-05-22', '2028-05-26', 7, 'Himmelfahrt'),
      ('2028-07-03', '2028-08-11', 7, 'Sommer');
    
      -- Hessen (ID: 8)
      INSERT INTO vacation_data_to_insert VALUES
      ('2027-10-04', '2027-10-16', 8, 'Herbst'),
      ('2027-12-23', '2028-01-11', 8, 'Weihnachten'),
      ('2028-04-03', '2028-04-14', 8, 'Ostern'),
      ('2028-07-03', '2028-08-11', 8, 'Sommer');
    
      -- Mecklenburg-Vorpommern (ID: 9)
      INSERT INTO vacation_data_to_insert VALUES
      ('2027-10-16', '2027-10-23', 9, 'Herbst'),
      ('2027-11-25', '2027-11-26', 9, 'Herbst'),
      ('2027-12-23', '2028-01-04', 9, 'Weihnachten'),
      ('2028-02-05', '2028-02-17', 9, 'Winter'),
      ('2028-02-18', '2028-02-18', 9, 'Winter'),
      ('2028-04-10', '2028-04-19', 9, 'Ostern'),
      ('2028-05-26', '2028-05-26', 9, 'Himmelfahrt'),
      ('2028-06-02', '2028-06-06', 9, 'Pfingsten'),
      ('2028-06-26', '2028-08-05', 9, 'Sommer');
    
      -- Niedersachsen (ID: 10)
      INSERT INTO vacation_data_to_insert VALUES
      ('2027-10-16', '2027-10-30', 10, 'Herbst'),
      ('2027-12-23', '2028-01-08', 10, 'Weihnachten'),
      ('2028-01-31', '2028-02-01', 10, 'Winter'),
      ('2028-04-10', '2028-04-22', 10, 'Ostern'),
      ('2028-05-26', '2028-05-26', 10, 'Himmelfahrt'),
      ('2028-06-06', '2028-06-06', 10, 'Pfingsten'),
      ('2028-07-20', '2028-08-30', 10, 'Sommer');
    
      -- Nordrhein-Westfalen (ID: 11)
      INSERT INTO vacation_data_to_insert VALUES
      ('2027-10-23', '2027-11-06', 11, 'Herbst'),
      ('2027-12-24', '2028-01-08', 11, 'Weihnachten'),
      ('2028-04-10', '2028-04-22', 11, 'Ostern'),
      ('2028-07-10', '2028-08-22', 11, 'Sommer');
    
      -- Rheinland-Pfalz (ID: 12)
      INSERT INTO vacation_data_to_insert VALUES
      ('2027-10-04', '2027-10-15', 12, 'Herbst'),
      ('2027-12-23', '2028-01-07', 12, 'Weihnachten'),
      ('2028-04-10', '2028-04-21', 12, 'Ostern'),
      ('2028-07-03', '2028-08-11', 12, 'Sommer');
    
      -- Saarland (ID: 13)
      INSERT INTO vacation_data_to_insert VALUES
      ('2027-10-04', '2027-10-15', 13, 'Herbst'),
      ('2027-12-20', '2027-12-31', 13, 'Weihnachten'),
      ('2028-02-21', '2028-02-29', 13, 'Winter'),
      ('2028-04-12', '2028-04-21', 13, 'Ostern'),
      ('2028-07-03', '2028-08-11', 13, 'Sommer');
    
      -- Sachsen (ID: 14)
      INSERT INTO vacation_data_to_insert VALUES
      ('2027-10-11', '2027-10-23', 14, 'Herbst'),
      ('2027-12-23', '2028-01-01', 14, 'Weihnachten'),
      ('2028-02-14', '2028-02-26', 14, 'Winter'),
      ('2028-04-14', '2028-04-22', 14, 'Ostern'),
      ('2028-05-26', '2028-05-26', 14, 'Himmelfahrt'),
      ('2028-07-22', '2028-09-01', 14, 'Sommer');
    
      -- Sachsen-Anhalt (ID: 15)
      INSERT INTO vacation_data_to_insert VALUES
      ('2027-10-18', '2027-10-23', 15, 'Herbst'),
      ('2027-12-20', '2027-12-31', 15, 'Weihnachten'),
      ('2028-02-07', '2028-02-12', 15, 'Winter'),
      ('2028-04-10', '2028-04-22', 15, 'Ostern'),
      ('2028-06-03', '2028-06-10', 15, 'Himmelfahrt/Pfingsten'),
      ('2028-07-22', '2028-09-01', 15, 'Sommer');
    
      -- Schleswig-Holstein (ID: 16)
      INSERT INTO vacation_data_to_insert VALUES
      ('2027-10-11', '2027-10-23', 16, 'Herbst'),
      ('2027-12-23', '2028-01-08', 16, 'Weihnachten'),
      ('2028-04-03', '2028-04-15', 16, 'Ostern'),
      ('2028-05-26', '2028-05-26', 16, 'Himmelfahrt'),
      ('2028-06-24', '2028-08-04', 16, 'Sommer');
    
      -- Thüringen (ID: 17)
      INSERT INTO vacation_data_to_insert VALUES
      ('2027-10-09', '2027-10-23', 17, 'Herbst'),
      ('2027-12-23', '2027-12-31', 17, 'Weihnachten'),
      ('2028-02-07', '2028-02-12', 17, 'Winter'),
      ('2028-04-03', '2028-04-15', 17, 'Ostern'),
      ('2028-05-26', '2028-05-26', 17, 'Himmelfahrt'),
      ('2028-07-22', '2028-09-01', 17, 'Sommer');
    
      -- Now insert all data from temporary table into periods table
      INSERT INTO periods (starts_on, ends_on, created_by_email_address, location_id, 
                          holiday_or_vacation_type_id, is_school_vacation, is_valid_for_students, 
                          is_public_holiday, is_valid_for_everybody, inserted_at, updated_at)
      SELECT 
        v.starts_on, 
        v.ends_on, 
        'claude@anthropic.com',
        v.location_id,
        h.id,
        true,
        true,
        false,
        false,
        NOW(),
        NOW()
      FROM vacation_data_to_insert v
      JOIN holiday_or_vacation_types h ON h.name = v.vacation_type
      ON CONFLICT (starts_on, ends_on, location_id, holiday_or_vacation_type_id) DO NOTHING;
    
      -- Drop the temporary table
      DROP TABLE vacation_data_to_insert;
    END $$;
    """
  end

  def down do
    # Reverse migration: delete all vacation data for these school years
    execute """
    DELETE FROM periods 
    WHERE location_id IN (2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17) 
      AND is_school_vacation = true
      AND created_by_email_address = 'claude@anthropic.com'
      AND (
        (starts_on >= '2025-06-01' AND starts_on <= '2026-09-30') OR
        (starts_on >= '2026-06-01' AND starts_on <= '2027-09-30') OR
        (starts_on >= '2027-06-01' AND starts_on <= '2028-09-30')
      );
    """
  end
end