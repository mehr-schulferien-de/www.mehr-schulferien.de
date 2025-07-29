defmodule MehrSchulferien.Repo.Migrations.RemoveDuplicateSchools do
  use Ecto.Migration
  import Ecto.Query
  alias MehrSchulferien.Repo
  
  def up do
    # Process each duplicate group
    # No updates needed for school slug: laborschule-des-landes-nordrhein-westfalen-an-der-universitat-bielefeld
# Delete duplicate school: Laborschule des Landes Nordrhein-Westfalen an der Universität Bielefeld (slug: laborschule-des-landes-nordrhein-westfalen-an-der-universitat-bielefeld-nw)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'laborschule-des-landes-nordrhein-westfalen-an-der-universitat-bielefeld-nw' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'laborschule-des-landes-nordrhein-westfalen-an-der-universitat-bielefeld-nw' 
  AND is_school = true
")


# No updates needed for school slug: 37079-geschwister-scholl-gesamtschule-kooperative-gesamtschule-goettingen
# Delete duplicate school: Geschwister-Scholl-Gesamtschule Kooperative Gesamtschule Göttingen (slug: 37079-geschwister-scholl-gesamtschule-kooperative-gesamtschule-goettingen-5b48dc12-b970-11e7-bce5-001ec9cdab18)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '37079-geschwister-scholl-gesamtschule-kooperative-gesamtschule-goettingen-5b48dc12-b970-11e7-bce5-001ec9cdab18' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = '37079-geschwister-scholl-gesamtschule-kooperative-gesamtschule-goettingen-5b48dc12-b970-11e7-bce5-001ec9cdab18' 
  AND is_school = true
")

# Delete duplicate school: Geschwister-Scholl-Gesamtschule Kooperative Gesamtschule Göttingen (slug: 37079-geschwister-scholl-gesamtschule-kooperative-gesamtschule-goettingen-5b49728a-b970-11e7-a391-001ec9cdab18)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '37079-geschwister-scholl-gesamtschule-kooperative-gesamtschule-goettingen-5b49728a-b970-11e7-a391-001ec9cdab18' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = '37079-geschwister-scholl-gesamtschule-kooperative-gesamtschule-goettingen-5b49728a-b970-11e7-a391-001ec9cdab18' 
  AND is_school = true
")

# Delete duplicate school: Geschwister-Scholl-Gesamtschule Kooperative Gesamtschule Göttingen (slug: 37079-geschwister-scholl-gesamtschule-kooperative-gesamtschule-goettingen-5b4a2aa4-b970-11e7-8c7f-001ec9cdab18)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '37079-geschwister-scholl-gesamtschule-kooperative-gesamtschule-goettingen-5b4a2aa4-b970-11e7-8c7f-001ec9cdab18' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = '37079-geschwister-scholl-gesamtschule-kooperative-gesamtschule-goettingen-5b4a2aa4-b970-11e7-8c7f-001ec9cdab18' 
  AND is_school = true
")


# Update oldest school (slug: 41238-franz-meyers-gymnasium) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'http://www.fmg-mg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '41238-franz-meyers-gymnasium' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Franz-Meyers-Gymnasium (slug: franz-meyers-gymnasium)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'franz-meyers-gymnasium' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'franz-meyers-gymnasium' 
  AND is_school = true
")


# Update oldest school (slug: grundschule-gotenring) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'http://kgs-gotenring.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'grundschule-gotenring' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Grundschule Gotenring (slug: grundschule-gotenring-nw)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'grundschule-gotenring-nw' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'grundschule-gotenring-nw' 
  AND is_school = true
")


# Update oldest school (slug: grundschule-erlenweg-nw) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'http://kgs-erlenweg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'grundschule-erlenweg-nw' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Grundschule Erlenweg (slug: grundschule-erlenweg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'grundschule-erlenweg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'grundschule-erlenweg' 
  AND is_school = true
")


# Update oldest school (slug: bischofliche-st-angela-schule) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://angela-dueren.de/realschule/',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'bischofliche-st-angela-schule' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Bischöfliche St. Angela-Schule (slug: bischofliche-st-angela-schule-nw)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'bischofliche-st-angela-schule-nw' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'bischofliche-st-angela-schule-nw' 
  AND is_school = true
")


# Update oldest school (slug: 63739-kronberg-gymnasium-aschaffenburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.kronberg-gymnasium.de',
              phone_number = '+49 6021 4477960',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '63739-kronberg-gymnasium-aschaffenburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Kronberg-Gymnasium Aschaffenburg (slug: kronberg-gymnasium-aschaffenburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'kronberg-gymnasium-aschaffenburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'kronberg-gymnasium-aschaffenburg' 
  AND is_school = true
")


# Update oldest school (slug: 63739-karl-theodor-von-dalberg-gymnasium-aschaffenburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.dalberg-gymnasium.de/',
              phone_number = '+49 6021 451850',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '63739-karl-theodor-von-dalberg-gymnasium-aschaffenburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Karl-Theodor-von-Dalberg-Gymnasium Aschaffenburg (slug: karl-theodor-von-dalberg-gymnasium-aschaffenburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'karl-theodor-von-dalberg-gymnasium-aschaffenburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'karl-theodor-von-dalberg-gymnasium-aschaffenburg' 
  AND is_school = true
")


# Update oldest school (slug: 63755-spessart-gymnasium-alzenau) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.spessart-gymnasium.de',
              phone_number = '+49 6023 320040',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '63755-spessart-gymnasium-alzenau' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Spessart-Gymnasium Alzenau (slug: spessart-gymnasium-alzenau)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'spessart-gymnasium-alzenau' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'spessart-gymnasium-alzenau' 
  AND is_school = true
")


# Update oldest school (slug: 63768-hanns-seidel-gymnasium-hoesbach) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.hanns-seidel-gymnasium.de',
              phone_number = '+49 6021 449890',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '63768-hanns-seidel-gymnasium-hoesbach' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Hanns-Seidel-Gymnasium Hösbach (slug: hanns-seidel-gymnasium-hosbach)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'hanns-seidel-gymnasium-hosbach' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'hanns-seidel-gymnasium-hosbach' 
  AND is_school = true
")


# Update oldest school (slug: 63785-main-limes-realschule-staatliche-realschule-obernburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://https://www.main-limes-realschule-obernburg.de/',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '63785-main-limes-realschule-staatliche-realschule-obernburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Main-Limes-Realschule Staatliche Realschule Obernburg (slug: main-limes-realschule-staatliche-realschule-obernburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'main-limes-realschule-staatliche-realschule-obernburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'main-limes-realschule-staatliche-realschule-obernburg' 
  AND is_school = true
")


# Update oldest school (slug: 63820-julius-echter-gymnasium-elsenfeld) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.julius-echter-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '63820-julius-echter-gymnasium-elsenfeld' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Julius-Echter-Gymnasium Elsenfeld (slug: julius-echter-gymnasium-elsenfeld)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'julius-echter-gymnasium-elsenfeld' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'julius-echter-gymnasium-elsenfeld' 
  AND is_school = true
")


# Update oldest school (slug: 63820-staatliche-realschule-elsenfeld) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://https://www.rse-online.de/',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '63820-staatliche-realschule-elsenfeld' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Elsenfeld (slug: staatliche-realschule-elsenfeld)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-elsenfeld' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-elsenfeld' 
  AND is_school = true
")


# Update oldest school (slug: 63897-johannes-hartung-realschule-staatliche-realschule-miltenberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-miltenberg.de',
              phone_number = '+49 9371 95190',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '63897-johannes-hartung-realschule-staatliche-realschule-miltenberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Johannes-Hartung-Realschule Staatliche Realschule Miltenberg (slug: johannes-hartung-realschule-staatliche-realschule-miltenberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'johannes-hartung-realschule-staatliche-realschule-miltenberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'johannes-hartung-realschule-staatliche-realschule-miltenberg' 
  AND is_school = true
")


# Update oldest school (slug: 63897-johannes-butzbach-gymnasium-miltenberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.jbg-miltenberg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '63897-johannes-butzbach-gymnasium-miltenberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Johannes-Butzbach-Gymnasium Miltenberg (slug: johannes-butzbach-gymnasium-miltenberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'johannes-butzbach-gymnasium-miltenberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'johannes-butzbach-gymnasium-miltenberg' 
  AND is_school = true
")


# Update oldest school (slug: 63916-karl-ernst-gymnasium-amorbach) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.amorgym.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '63916-karl-ernst-gymnasium-amorbach' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Karl-Ernst-Gymnasium Amorbach (slug: karl-ernst-gymnasium-amorbach)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'karl-ernst-gymnasium-amorbach' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'karl-ernst-gymnasium-amorbach' 
  AND is_school = true
")


# Update oldest school (slug: 67065-ernst-reuter-schule) with newest data
execute("
  UPDATE addresses 
  SET phone_number = '+49 621 504421320',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '67065-ernst-reuter-schule' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Ernst-Reuter-Schule (slug: 67065-ernst-reuter-schule-6e7b48d8-b970-11e7-82ee-001ec9cdab18)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '67065-ernst-reuter-schule-6e7b48d8-b970-11e7-82ee-001ec9cdab18' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = '67065-ernst-reuter-schule-6e7b48d8-b970-11e7-82ee-001ec9cdab18' 
  AND is_school = true
")


# Update oldest school (slug: 80331-staedtische-salvator-realschule-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.sar.musin.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '80331-staedtische-salvator-realschule-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtische Salvator-Realschule München (slug: stadtische-salvator-realschule-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtische-salvator-realschule-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtische-salvator-realschule-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 80331-theresia-gerhardinger-gymnasium-am-anger-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.tggaa.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '80331-theresia-gerhardinger-gymnasium-am-anger-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Theresia-Gerhardinger-Gymnasium am Anger München (slug: theresia-gerhardinger-gymnasium-am-anger-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'theresia-gerhardinger-gymnasium-am-anger-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'theresia-gerhardinger-gymnasium-am-anger-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 80333-staedtisches-luisengymnasium-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.staedtisches-luisengymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '80333-staedtisches-luisengymnasium-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtisches Luisengymnasium München (slug: stadtisches-luisengymnasium-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtisches-luisengymnasium-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtisches-luisengymnasium-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 80335-wittelsbacher-gymnasium-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.wittelsbacher-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '80335-wittelsbacher-gymnasium-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Wittelsbacher-Gymnasium München (slug: wittelsbacher-gymnasium-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'wittelsbacher-gymnasium-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'wittelsbacher-gymnasium-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 80336-theresien-gymnasium-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.thg.musin.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '80336-theresien-gymnasium-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Theresien-Gymnasium München (slug: theresien-gymnasium-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'theresien-gymnasium-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'theresien-gymnasium-munchen' 
  AND is_school = true
")


# No updates needed for school slug: 80339-staedtische-carl-von-linde-realschule-muenchen
# Delete duplicate school: Städtische Carl-von-Linde-Realschule München (slug: stadtische-carl-von-linde-realschule-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtische-carl-von-linde-realschule-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtische-carl-von-linde-realschule-munchen' 
  AND is_school = true
")


# No updates needed for school slug: 80469-private-isar-realschule-muenchen
# Delete duplicate school: Private Isar-Realschule München (slug: private-isar-realschule-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'private-isar-realschule-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'private-isar-realschule-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 80538-wilhelmsgymnasium-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.wilhelmsgymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '80538-wilhelmsgymnasium-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Wilhelmsgymnasium München (slug: wilhelmsgymnasium-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'wilhelmsgymnasium-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'wilhelmsgymnasium-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 80538-staedtisches-st-anna-gymnasium-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.sag.musin.de',
              phone_number = '+49 89 2129910',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '80538-staedtisches-st-anna-gymnasium-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtisches St.-Anna-Gymnasium München (slug: stadtisches-st-anna-gymnasium-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtisches-st-anna-gymnasium-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtisches-st-anna-gymnasium-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 80538-luitpold-gymnasium-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.luitpold-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '80538-luitpold-gymnasium-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Luitpold-Gymnasium München (slug: luitpold-gymnasium-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'luitpold-gymnasium-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'luitpold-gymnasium-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 80634-staedtische-rudolf-diesel-realschule-muenchen) with newest data
execute("
  UPDATE addresses 
  SET 
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '80634-staedtische-rudolf-diesel-realschule-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtische Rudolf-Diesel-Realschule München (slug: stadtische-rudolf-diesel-realschule-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtische-rudolf-diesel-realschule-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtische-rudolf-diesel-realschule-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 80636-rupprecht-gymnasium-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rupprecht-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '80636-rupprecht-gymnasium-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Rupprecht-Gymnasium München (slug: rupprecht-gymnasium-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'rupprecht-gymnasium-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'rupprecht-gymnasium-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 80636-staedtisches-adolf-weber-gymnasium-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.awg.musin.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '80636-staedtisches-adolf-weber-gymnasium-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtisches Adolf-Weber-Gymnasium München (slug: stadtisches-adolf-weber-gymnasium-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtisches-adolf-weber-gymnasium-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtisches-adolf-weber-gymnasium-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 80638-nymphenburger-gymnasium-muenchen-des-schulvereins-ernst-adam-e-v) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.nymphenburger-schulen.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '80638-nymphenburger-gymnasium-muenchen-des-schulvereins-ernst-adam-e-v' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Nymphenburger Gymnasium München des Schulvereins Ernst Adam e.V. (slug: nymphenburger-gymnasium-munchen-des-schulvereins-ernst-adam-e-v)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'nymphenburger-gymnasium-munchen-des-schulvereins-ernst-adam-e-v' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'nymphenburger-gymnasium-munchen-des-schulvereins-ernst-adam-e-v' 
  AND is_school = true
")


# Update oldest school (slug: 80638-nymphenburger-realschule-muenchen-des-schulvereins-ernst-adam-e-v) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.nymphenburger-schulen.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '80638-nymphenburger-realschule-muenchen-des-schulvereins-ernst-adam-e-v' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Nymphenburger Realschule München des Schulvereins Ernst Adam e.V. (slug: nymphenburger-realschule-munchen-des-schulvereins-ernst-adam-e-v)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'nymphenburger-realschule-munchen-des-schulvereins-ernst-adam-e-v' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'nymphenburger-realschule-munchen-des-schulvereins-ernst-adam-e-v' 
  AND is_school = true
")


# Update oldest school (slug: 80796-staedtische-hermann-frieb-realschule-muenchen) with newest data
execute("
  UPDATE addresses 
  SET phone_number = '+49 89 3079370',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '80796-staedtische-hermann-frieb-realschule-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtische Hermann-Frieb-Realschule München (slug: stadtische-hermann-frieb-realschule-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtische-hermann-frieb-realschule-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtische-hermann-frieb-realschule-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 80796-staedtisches-sophie-scholl-gymnasium-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.ssg.musin.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '80796-staedtisches-sophie-scholl-gymnasium-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtisches Sophie-Scholl-Gymnasium München (slug: stadtisches-sophie-scholl-gymnasium-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtisches-sophie-scholl-gymnasium-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtisches-sophie-scholl-gymnasium-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 80801-staedtische-ricarda-huch-realschule-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rica.musin.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '80801-staedtische-ricarda-huch-realschule-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtische Ricarda-Huch-Realschule München (slug: stadtische-ricarda-huch-realschule-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtische-ricarda-huch-realschule-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtische-ricarda-huch-realschule-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 80801-gisela-gymnasium-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gisela-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '80801-gisela-gymnasium-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gisela-Gymnasium München (slug: gisela-gymnasium-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gisela-gymnasium-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gisela-gymnasium-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 80803-maximiliansgymnasium-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.maxgym.musin.de',
              phone_number = '+49 89 23365400',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '80803-maximiliansgymnasium-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Maximiliansgymnasium München (slug: maximiliansgymnasium-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'maximiliansgymnasium-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'maximiliansgymnasium-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 80803-oskar-von-miller-gymnasium-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.ovmg.de',
              phone_number = '+49 89 23365430',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '80803-oskar-von-miller-gymnasium-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Oskar-von-Miller-Gymnasium München (slug: oskar-von-miller-gymnasium-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'oskar-von-miller-gymnasium-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'oskar-von-miller-gymnasium-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 80804-staedtisches-willi-graf-gymnasium-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.wgg.musin.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '80804-staedtisches-willi-graf-gymnasium-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtisches Willi-Graf-Gymnasium München (slug: stadtisches-willi-graf-gymnasium-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtisches-willi-graf-gymnasium-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtisches-willi-graf-gymnasium-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 80807-staedtisches-lion-feuchtwanger-gymnasium-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.lfg.musin.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '80807-staedtisches-lion-feuchtwanger-gymnasium-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtisches Lion-Feuchtwanger-Gymnasium München (slug: stadtisches-lion-feuchtwanger-gymnasium-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtisches-lion-feuchtwanger-gymnasium-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtisches-lion-feuchtwanger-gymnasium-munchen' 
  AND is_school = true
")


# No updates needed for school slug: 80937-staedtische-balthasar-neumann-realschule-muenchen
# Delete duplicate school: Städtische Balthasar-Neumann-Realschule München (slug: stadtische-balthasar-neumann-realschule-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtische-balthasar-neumann-realschule-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtische-balthasar-neumann-realschule-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 80993-staedtische-artur-kutscher-realschule-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.akr.musin.de',
              phone_number = '+49 89 23383200',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '80993-staedtische-artur-kutscher-realschule-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtische Artur-Kutscher-Realschule München (slug: stadtische-artur-kutscher-realschule-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtische-artur-kutscher-realschule-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtische-artur-kutscher-realschule-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 80999-staedtische-carl-spitzweg-realschule-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.csr.musin.de',
              phone_number = '+49 89 23364260',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '80999-staedtische-carl-spitzweg-realschule-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtische Carl-Spitzweg-Realschule München (slug: stadtische-carl-spitzweg-realschule-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtische-carl-spitzweg-realschule-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtische-carl-spitzweg-realschule-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 81241-max-planck-gymnasium-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.mpg-muenchen.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '81241-max-planck-gymnasium-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Max-Planck-Gymnasium München (slug: max-planck-gymnasium-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'max-planck-gymnasium-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'max-planck-gymnasium-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 81241-staedtische-anne-frank-realschule-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.afr.musin.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '81241-staedtische-anne-frank-realschule-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtische Anne-Frank-Realschule München (slug: stadtische-anne-frank-realschule-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtische-anne-frank-realschule-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtische-anne-frank-realschule-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 81241-staedtisches-elsa-braendstroem-gymnasium-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.elsa.musin.de',
              phone_number = '+49 89 23385700',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '81241-staedtisches-elsa-braendstroem-gymnasium-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtisches Elsa-Brändström-Gymnasium München (slug: stadtisches-elsa-brandstrom-gymnasium-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtisches-elsa-brandstrom-gymnasium-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtisches-elsa-brandstrom-gymnasium-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 81243-staedtisches-bertolt-brecht-gymnasium-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.bbg.musin.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '81243-staedtisches-bertolt-brecht-gymnasium-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtisches Bertolt-Brecht-Gymnasium München (slug: stadtisches-bertolt-brecht-gymnasium-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtisches-bertolt-brecht-gymnasium-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtisches-bertolt-brecht-gymnasium-munchen' 
  AND is_school = true
")


# No updates needed for school slug: 81243-karlsgymnasium-muenchen-pasing
# Delete duplicate school: Karlsgymnasium München-Pasing (slug: karlsgymnasium-munchen-pasing)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'karlsgymnasium-munchen-pasing' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'karlsgymnasium-munchen-pasing' 
  AND is_school = true
")


# Update oldest school (slug: 81247-staedtische-realschule-an-der-blutenburg-muenchen) with newest data
execute("
  UPDATE addresses 
  SET 
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '81247-staedtische-realschule-an-der-blutenburg-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtische Realschule an der Blutenburg München (slug: stadtische-realschule-an-der-blutenburg-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtische-realschule-an-der-blutenburg-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtische-realschule-an-der-blutenburg-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 81371-dante-gymnasium-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.dante-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '81371-dante-gymnasium-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Dante-Gymnasium München (slug: dante-gymnasium-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'dante-gymnasium-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'dante-gymnasium-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 81371-klenze-gymnasium-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.klenze-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '81371-klenze-gymnasium-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Klenze-Gymnasium München (slug: klenze-gymnasium-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'klenze-gymnasium-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'klenze-gymnasium-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 81377-erasmus-grasser-gymnasium-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.dasegg.musin.de',
              phone_number = '+49 89 724694870',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '81377-erasmus-grasser-gymnasium-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Erasmus-Grasser-Gymnasium München (slug: erasmus-grasser-gymnasium-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'erasmus-grasser-gymnasium-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'erasmus-grasser-gymnasium-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 81475-joseph-von-fraunhofer-schule-staatl-realschule-muenchen-ii) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://https://www.fraunhofer.schule',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '81475-joseph-von-fraunhofer-schule-staatl-realschule-muenchen-ii' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Joseph-von-Fraunhofer-Schule Staatl. Realschule München II (slug: joseph-von-fraunhofer-schule-staatl-realschule-munchen-ii)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'joseph-von-fraunhofer-schule-staatl-realschule-munchen-ii' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'joseph-von-fraunhofer-schule-staatl-realschule-munchen-ii' 
  AND is_school = true
")


# Update oldest school (slug: 81539-staedtisches-abendgymnasium-fuer-berufstaetige-im-anton-fingerle-bildu) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.ag.musin.de',
              phone_number = '+49 89 23343735',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '81539-staedtisches-abendgymnasium-fuer-berufstaetige-im-anton-fingerle-bildu' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtisches Abendgymnasium für Berufstätige im Anton-Fingerle-Bildungszentrum München (slug: stadtisches-abendgymnasium-fur-berufstatige-im-anton-fingerle-bildungszentrum-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtisches-abendgymnasium-fur-berufstatige-im-anton-fingerle-bildungszentrum-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtisches-abendgymnasium-fur-berufstatige-im-anton-fingerle-bildungszentrum-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 81539-asam-gymnasium-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.asam-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '81539-asam-gymnasium-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Asam-Gymnasium München (slug: asam-gymnasium-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'asam-gymnasium-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'asam-gymnasium-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 81541-pestalozzi-gymnasium-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.pestalozzimuenchen.de',
              phone_number = '+49 89 624474880',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '81541-pestalozzi-gymnasium-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Pestalozzi-Gymnasium München (slug: pestalozzi-gymnasium-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'pestalozzi-gymnasium-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'pestalozzi-gymnasium-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 81541-maria-theresia-gymnasium-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.mtg.musin.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '81541-maria-theresia-gymnasium-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Maria-Theresia-Gymnasium München (slug: maria-theresia-gymnasium-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'maria-theresia-gymnasium-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'maria-theresia-gymnasium-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 81547-staedtisches-theodolinden-gymnasium-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.tlg.musin.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '81547-staedtisches-theodolinden-gymnasium-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtisches Theodolinden-Gymnasium München (slug: stadtisches-theodolinden-gymnasium-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtisches-theodolinden-gymnasium-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtisches-theodolinden-gymnasium-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 81667-staatliche-berufsoberschule-fuer-technik-muenchen) with newest data
execute("
  UPDATE addresses 
  SET phone_number = '+49 89 23348271',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '81667-staatliche-berufsoberschule-fuer-technik-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Berufsoberschule für Technik München (slug: staatliche-berufsoberschule-fur-technik-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-berufsoberschule-fur-technik-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-berufsoberschule-fur-technik-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 81667-staatliche-fachoberschule-fuer-technik-muenchen) with newest data
execute("
  UPDATE addresses 
  SET phone_number = '+49 89 23348271',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '81667-staatliche-fachoberschule-fuer-technik-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Fachoberschule für Technik München (slug: staatliche-fachoberschule-fur-technik-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-fachoberschule-fur-technik-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-fachoberschule-fur-technik-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 81667-privatgymnasium-dr-florian-ueberreiter-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.ueberreiter.de',
              phone_number = '+49 89 45244560',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '81667-privatgymnasium-dr-florian-ueberreiter-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Privatgymnasium Dr. Florian Überreiter München (slug: privatgymnasium-dr-florian-uberreiter-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'privatgymnasium-dr-florian-uberreiter-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'privatgymnasium-dr-florian-uberreiter-munchen' 
  AND is_school = true
")


# No updates needed for school slug: 81671-michaeli-gymnasium-muenchen
# Delete duplicate school: Michaeli-Gymnasium München (slug: michaeli-gymnasium-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'michaeli-gymnasium-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'michaeli-gymnasium-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 81675-staedtische-adalbert-stifter-realschule-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.asr.musin.de',
              phone_number = '+49 89 12009970',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '81675-staedtische-adalbert-stifter-realschule-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtische Adalbert-Stifter-Realschule München (slug: stadtische-adalbert-stifter-realschule-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtische-adalbert-stifter-realschule-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtische-adalbert-stifter-realschule-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 81675-staedtische-fridtjof-nansen-realschule-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fnr.musin.de',
              phone_number = '+49 89 4576980',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '81675-staedtische-fridtjof-nansen-realschule-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtische Fridtjof-Nansen-Realschule München (slug: stadtische-fridtjof-nansen-realschule-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtische-fridtjof-nansen-realschule-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtische-fridtjof-nansen-realschule-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 81677-max-josef-stift-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.maxjosefstift.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '81677-max-josef-stift-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Max-Josef-Stift München (slug: max-josef-stift-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'max-josef-stift-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'max-josef-stift-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 81735-staedtisches-werner-von-siemens-gymnasium-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.wsg.musin.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '81735-staedtisches-werner-von-siemens-gymnasium-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtisches Werner-von-Siemens-Gymnasium München (slug: stadtisches-werner-von-siemens-gymnasium-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtisches-werner-von-siemens-gymnasium-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtisches-werner-von-siemens-gymnasium-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 81737-staedtische-wilhelm-busch-realschule-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://htto://www.wbr.musin.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '81737-staedtische-wilhelm-busch-realschule-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtische Wilhelm-Busch-Realschule München (slug: stadtische-wilhelm-busch-realschule-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtische-wilhelm-busch-realschule-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtische-wilhelm-busch-realschule-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 81737-staedtische-wilhelm-roentgen-realschule-muenchen) with newest data
execute("
  UPDATE addresses 
  SET 
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '81737-staedtische-wilhelm-roentgen-realschule-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtische Wilhelm-Röntgen-Realschule München (slug: stadtische-wilhelm-rontgen-realschule-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtische-wilhelm-rontgen-realschule-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtische-wilhelm-rontgen-realschule-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 81739-staedtisches-heinrich-heine-gymnasium-muenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.hhg-muenchen.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '81739-staedtisches-heinrich-heine-gymnasium-muenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtisches Heinrich-Heine-Gymnasium München (slug: stadtisches-heinrich-heine-gymnasium-munchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtisches-heinrich-heine-gymnasium-munchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtisches-heinrich-heine-gymnasium-munchen' 
  AND is_school = true
")


# Update oldest school (slug: 82008-lise-meitner-gymnasium-unterhaching) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.lmgu.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '82008-lise-meitner-gymnasium-unterhaching' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Lise-Meitner-Gymnasium Unterhaching (slug: lise-meitner-gymnasium-unterhaching)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'lise-meitner-gymnasium-unterhaching' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'lise-meitner-gymnasium-unterhaching' 
  AND is_school = true
")


# Update oldest school (slug: 82041-gymnasium-oberhaching) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-oberhaching.de',
              phone_number = '+49 89 6386680',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '82041-gymnasium-oberhaching' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Oberhaching (slug: gymnasium-oberhaching)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-oberhaching' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-oberhaching' 
  AND is_school = true
")


# Update oldest school (slug: 82110-max-born-gymnasium-germering) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.mbg-germering.de',
              phone_number = '+49 89 14332290',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '82110-max-born-gymnasium-germering' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Max-Born-Gymnasium Germering (slug: max-born-gymnasium-germering)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'max-born-gymnasium-germering' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'max-born-gymnasium-germering' 
  AND is_school = true
")


# Update oldest school (slug: 82131-otto-von-taube-gymnasium-gauting) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.ovtg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '82131-otto-von-taube-gymnasium-gauting' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Otto-von-Taube-Gymnasium Gauting (slug: otto-von-taube-gymnasium-gauting)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'otto-von-taube-gymnasium-gauting' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'otto-von-taube-gymnasium-gauting' 
  AND is_school = true
")


# Update oldest school (slug: 82140-gymnasium-olching) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymolching.de',
              phone_number = '+49 8142 4484780',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '82140-gymnasium-olching' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Olching (slug: gymnasium-olching)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-olching' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-olching' 
  AND is_school = true
")


# Update oldest school (slug: 82152-feodor-lynen-gymnasium-planegg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.flg-online.de',
              phone_number = '+49 89 86306520',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '82152-feodor-lynen-gymnasium-planegg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Feodor-Lynen-Gymnasium Planegg (slug: feodor-lynen-gymnasium-planegg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'feodor-lynen-gymnasium-planegg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'feodor-lynen-gymnasium-planegg' 
  AND is_school = true
")


# Update oldest school (slug: 82166-kurt-huber-gymnasium-graefelfing) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.khg.net/',
              phone_number = '+49 89 8980340',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '82166-kurt-huber-gymnasium-graefelfing' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Kurt-Huber-Gymnasium Gräfelfing (slug: kurt-huber-gymnasium-grafelfing)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'kurt-huber-gymnasium-grafelfing' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'kurt-huber-gymnasium-grafelfing' 
  AND is_school = true
")


# Update oldest school (slug: 82178-staatliche-realschule-puchheim) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rs-puchheim.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '82178-staatliche-realschule-puchheim' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Puchheim (slug: staatliche-realschule-puchheim)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-puchheim' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-puchheim' 
  AND is_school = true
")


# Update oldest school (slug: 82178-gymnasium-puchheim) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-puchheim.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '82178-gymnasium-puchheim' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Puchheim (slug: gymnasium-puchheim)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-puchheim' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-puchheim' 
  AND is_school = true
")


# Update oldest school (slug: 82194-gymnasium-groebenzell) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasiumgroebenzell.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '82194-gymnasium-groebenzell' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Gröbenzell (slug: gymnasium-grobenzell)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-grobenzell' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-grobenzell' 
  AND is_school = true
")


# Update oldest school (slug: 82205-christoph-probst-gymnasium-gilching) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.christoph-probst-gymnasium.de/',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '82205-christoph-probst-gymnasium-gilching' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Christoph-Probst-Gymnasium Gilching (slug: christoph-probst-gymnasium-gilching)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'christoph-probst-gymnasium-gilching' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'christoph-probst-gymnasium-gilching' 
  AND is_school = true
")


# Update oldest school (slug: 82216-orlando-di-lasso-realschule-staatl-realschule-maisach) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rs-maisach.eu',
              phone_number = '+49 8141 227080',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '82216-orlando-di-lasso-realschule-staatl-realschule-maisach' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Orlando-di-Lasso-Realschule Staatl. Realschule Maisach (slug: orlando-di-lasso-realschule-staatl-realschule-maisach)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'orlando-di-lasso-realschule-staatl-realschule-maisach' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'orlando-di-lasso-realschule-staatl-realschule-maisach' 
  AND is_school = true
")


# Update oldest school (slug: 82256-viscardi-gymnasium-fuerstenfeldbruck) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.viscardi-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '82256-viscardi-gymnasium-fuerstenfeldbruck' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Viscardi-Gymnasium Fürstenfeldbruck (slug: viscardi-gymnasium-furstenfeldbruck)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'viscardi-gymnasium-furstenfeldbruck' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'viscardi-gymnasium-furstenfeldbruck' 
  AND is_school = true
")


# Update oldest school (slug: 82256-ferdinand-von-miller-schule-staatliche-realschule-fuerstenfeldbruck) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-ffb.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '82256-ferdinand-von-miller-schule-staatliche-realschule-fuerstenfeldbruck' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Ferdinand-von-Miller-Schule Staatliche Realschule Fürstenfeldbruck (slug: ferdinand-von-miller-schule-staatliche-realschule-furstenfeldbruck)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'ferdinand-von-miller-schule-staatliche-realschule-furstenfeldbruck' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'ferdinand-von-miller-schule-staatliche-realschule-furstenfeldbruck' 
  AND is_school = true
")


# Update oldest school (slug: 82319-gymnasium-starnberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymasium-starnberg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '82319-gymnasium-starnberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Starnberg (slug: gymnasium-starnberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-starnberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-starnberg' 
  AND is_school = true
")


# Update oldest school (slug: 82362-staatliche-berufsoberschule-weilheim-i-ob) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fos-bos-weilheim.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '82362-staatliche-berufsoberschule-weilheim-i-ob' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Berufsoberschule Weilheim i.OB (slug: staatliche-berufsoberschule-weilheim-i-ob)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-berufsoberschule-weilheim-i-ob' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-berufsoberschule-weilheim-i-ob' 
  AND is_school = true
")


# Update oldest school (slug: 82362-staatliche-realschule-weilheim) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rswm.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '82362-staatliche-realschule-weilheim' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Weilheim (slug: staatliche-realschule-weilheim)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-weilheim' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-weilheim' 
  AND is_school = true
")


# Update oldest school (slug: 82362-staatliche-fachoberschule-weilheim-i-ob) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fos-bos-weilheim.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '82362-staatliche-fachoberschule-weilheim-i-ob' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Fachoberschule Weilheim i.OB (slug: staatliche-fachoberschule-weilheim-i-ob)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-fachoberschule-weilheim-i-ob' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-fachoberschule-weilheim-i-ob' 
  AND is_school = true
")


# Update oldest school (slug: 82377-heinrich-campendonk-realschule-staatliche-realschule-penzberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-penzberg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '82377-heinrich-campendonk-realschule-staatliche-realschule-penzberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Heinrich-Campendonk-Realschule Staatliche Realschule Penzberg (slug: heinrich-campendonk-realschule-staatliche-realschule-penzberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'heinrich-campendonk-realschule-staatliche-realschule-penzberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'heinrich-campendonk-realschule-staatliche-realschule-penzberg' 
  AND is_school = true
")


# Update oldest school (slug: 82380-staatliche-realschule-peissenberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-peissenberg.de',
              phone_number = '+49 8803 489250',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '82380-staatliche-realschule-peissenberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Peißenberg (slug: staatliche-realschule-peissenberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-peissenberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-peissenberg' 
  AND is_school = true
")


# Update oldest school (slug: 82418-staffelsee-gymnasium-murnau) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.staffelsee-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '82418-staffelsee-gymnasium-murnau' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staffelsee-Gymnasium Murnau (slug: staffelsee-gymnasium-murnau)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staffelsee-gymnasium-murnau' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staffelsee-gymnasium-murnau' 
  AND is_school = true
")


# Update oldest school (slug: 82467-werdenfels-gymnasium-garmisch-partenkirchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.werdenfels-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '82467-werdenfels-gymnasium-garmisch-partenkirchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Werdenfels-Gymnasium Garmisch-Partenkirchen (slug: werdenfels-gymnasium-garmisch-partenkirchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'werdenfels-gymnasium-garmisch-partenkirchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'werdenfels-gymnasium-garmisch-partenkirchen' 
  AND is_school = true
")


# Update oldest school (slug: 82488-benediktinergymnasium-ettal) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.ettal-gymnasium.de',
              phone_number = '+49 8822 746510',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '82488-benediktinergymnasium-ettal' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Benediktinergymnasium Ettal (slug: benediktinergymnasium-ettal)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'benediktinergymnasium-ettal' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'benediktinergymnasium-ettal' 
  AND is_school = true
")


# Update oldest school (slug: 82538-gymnasium-geretsried) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymger.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '82538-gymnasium-geretsried' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Geretsried (slug: gymnasium-geretsried)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-geretsried' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-geretsried' 
  AND is_school = true
")


# Update oldest school (slug: 82538-staatl-realschule-geretsried) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rsger.de',
              phone_number = '+49 8171 91996',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '82538-staatl-realschule-geretsried' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatl. Realschule Geretsried (slug: staatl-realschule-geretsried)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatl-realschule-geretsried' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatl-realschule-geretsried' 
  AND is_school = true
")


# Update oldest school (slug: 83022-johann-rieder-realschule-staatliche-realschule-rosenheim) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://https://www.johann-rieder-realschule.de',
              phone_number = '+49 8031 3651851',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '83022-johann-rieder-realschule-staatliche-realschule-rosenheim' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Johann-Rieder-Realschule Staatliche Realschule Rosenheim (slug: johann-rieder-realschule-staatliche-realschule-rosenheim)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'johann-rieder-realschule-staatliche-realschule-rosenheim' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'johann-rieder-realschule-staatliche-realschule-rosenheim' 
  AND is_school = true
")


# Update oldest school (slug: 83022-ignaz-guenther-gymnasium-rosenheim) with newest data
execute("
  UPDATE addresses 
  SET phone_number = '+49 8031 3658652',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '83022-ignaz-guenther-gymnasium-rosenheim' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Ignaz-Günther-Gymnasium Rosenheim (slug: ignaz-gunther-gymnasium-rosenheim)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'ignaz-gunther-gymnasium-rosenheim' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'ignaz-gunther-gymnasium-rosenheim' 
  AND is_school = true
")


# Update oldest school (slug: 83022-karolinen-gymnasium-rosenheim) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.karolinen-gymnasium-rosenheim.de',
              phone_number = '+49 8031 3651901',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '83022-karolinen-gymnasium-rosenheim' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Karolinen-Gymnasium Rosenheim (slug: karolinen-gymnasium-rosenheim)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'karolinen-gymnasium-rosenheim' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'karolinen-gymnasium-rosenheim' 
  AND is_school = true
")


# Update oldest school (slug: 83024-staatliche-berufsoberschule-rosenheim) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fosbos-rosenheim.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '83024-staatliche-berufsoberschule-rosenheim' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Berufsoberschule Rosenheim (slug: staatliche-berufsoberschule-rosenheim)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-berufsoberschule-rosenheim' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-berufsoberschule-rosenheim' 
  AND is_school = true
")


# Update oldest school (slug: 83052-staatl-realschule-bruckmuehl) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rs-bruckmuehl.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '83052-staatl-realschule-bruckmuehl' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatl. Realschule Bruckmühl (slug: staatl-realschule-bruckmuhl)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatl-realschule-bruckmuhl' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatl-realschule-bruckmuhl' 
  AND is_school = true
")


# Update oldest school (slug: 83052-gymnasium-bruckmuehl) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-bruckmuehl.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '83052-gymnasium-bruckmuehl' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Bruckmühl (slug: gymnasium-bruckmuhl)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-bruckmuhl' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-bruckmuhl' 
  AND is_school = true
")


# Update oldest school (slug: 83098-dientzenhofer-schule-staatliche-realschule-brannenburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rs-brannenburg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '83098-dientzenhofer-schule-staatliche-realschule-brannenburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Dientzenhofer-Schule Staatliche Realschule Brannenburg (slug: dientzenhofer-schule-staatliche-realschule-brannenburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'dientzenhofer-schule-staatliche-realschule-brannenburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'dientzenhofer-schule-staatliche-realschule-brannenburg' 
  AND is_school = true
")


# Update oldest school (slug: 83250-achental-realschule-staatl-realschule-marquartstein) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.achental-realschule.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '83250-achental-realschule-staatl-realschule-marquartstein' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Achental-Realschule Staatl. Realschule Marquartstein (slug: achental-realschule-staatl-realschule-marquartstein)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'achental-realschule-staatl-realschule-marquartstein' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'achental-realschule-staatl-realschule-marquartstein' 
  AND is_school = true
")


# Update oldest school (slug: 83278-chiemgau-gymnasium-traunstein) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.chgts.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '83278-chiemgau-gymnasium-traunstein' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Chiemgau-Gymnasium Traunstein (slug: chiemgau-gymnasium-traunstein)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'chiemgau-gymnasium-traunstein' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'chiemgau-gymnasium-traunstein' 
  AND is_school = true
")


# Update oldest school (slug: 83278-staatliche-fachoberschule-traunstein) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fos-bos-traunstein.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '83278-staatliche-fachoberschule-traunstein' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Fachoberschule Traunstein (slug: staatliche-fachoberschule-traunstein)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-fachoberschule-traunstein' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-fachoberschule-traunstein' 
  AND is_school = true
")


# Update oldest school (slug: 83278-staatliche-berufsoberschule-traunstein) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fos-bos-traunstein.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '83278-staatliche-berufsoberschule-traunstein' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Berufsoberschule Traunstein (slug: staatliche-berufsoberschule-traunstein)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-berufsoberschule-traunstein' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-berufsoberschule-traunstein' 
  AND is_school = true
")


# Update oldest school (slug: 83301-johannes-heidenhain-gymnasium-traunreut) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.jhg-traunreut.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '83301-johannes-heidenhain-gymnasium-traunreut' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Johannes-Heidenhain-Gymnasium Traunreut (slug: johannes-heidenhain-gymnasium-traunreut)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'johannes-heidenhain-gymnasium-traunreut' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'johannes-heidenhain-gymnasium-traunreut' 
  AND is_school = true
")


# Update oldest school (slug: 83308-hertzhaimer-gymnasium-trostberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.hertzhaimer-gymnasium.schule',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '83308-hertzhaimer-gymnasium-trostberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Hertzhaimer-Gymnasium Trostberg (slug: hertzhaimer-gymnasium-trostberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'hertzhaimer-gymnasium-trostberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'hertzhaimer-gymnasium-trostberg' 
  AND is_school = true
")


# Update oldest school (slug: 83410-rottmayr-gymnasium-laufen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rottmayr-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '83410-rottmayr-gymnasium-laufen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Rottmayr-Gymnasium Laufen (slug: rottmayr-gymnasium-laufen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'rottmayr-gymnasium-laufen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'rottmayr-gymnasium-laufen' 
  AND is_school = true
")


# Update oldest school (slug: 83435-karlsgymnasium-bad-reichenhall) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.karlsgymnasium-bgl.de',
              phone_number = '+49 8651 71670',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '83435-karlsgymnasium-bad-reichenhall' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Karlsgymnasium Bad Reichenhall (slug: karlsgymnasium-bad-reichenhall)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'karlsgymnasium-bad-reichenhall' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'karlsgymnasium-bad-reichenhall' 
  AND is_school = true
")


# Update oldest school (slug: 83471-gymnasium-berchtesgaden) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymbgd.de',
              phone_number = '+49 8652 976490',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '83471-gymnasium-berchtesgaden' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Berchtesgaden (slug: gymnasium-berchtesgaden)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-berchtesgaden' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-berchtesgaden' 
  AND is_school = true
")


# Update oldest school (slug: 83512-luitpold-gymnasium-wasserburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-wasserburg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '83512-luitpold-gymnasium-wasserburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Luitpold-Gymnasium Wasserburg (slug: luitpold-gymnasium-wasserburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'luitpold-gymnasium-wasserburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'luitpold-gymnasium-wasserburg' 
  AND is_school = true
")


# Update oldest school (slug: 83512-anton-heilingbrunner-schule-staatliche-realschule-wasserburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rs-wasserburg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '83512-anton-heilingbrunner-schule-staatliche-realschule-wasserburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Anton-Heilingbrunner-Schule Staatliche Realschule Wasserburg (slug: anton-heilingbrunner-schule-staatliche-realschule-wasserburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'anton-heilingbrunner-schule-staatliche-realschule-wasserburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'anton-heilingbrunner-schule-staatliche-realschule-wasserburg' 
  AND is_school = true
")


# Update oldest school (slug: 83512-staatliche-berufsoberschule-wasserburg-a-inn) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fosbos-wasserburg.de',
              phone_number = '+49 8071 10400',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '83512-staatliche-berufsoberschule-wasserburg-a-inn' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Berufsoberschule Wasserburg a.Inn (slug: staatliche-berufsoberschule-wasserburg-a-inn)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-berufsoberschule-wasserburg-a-inn' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-berufsoberschule-wasserburg-a-inn' 
  AND is_school = true
")


# Update oldest school (slug: 83512-staatliche-fachoberschule-wasserburg-a-inn) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fosbos-wasserburg.de',
              phone_number = '+49 8071 10400',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '83512-staatliche-fachoberschule-wasserburg-a-inn' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Fachoberschule Wasserburg a.Inn (slug: staatliche-fachoberschule-wasserburg-a-inn)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-fachoberschule-wasserburg-a-inn' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-fachoberschule-wasserburg-a-inn' 
  AND is_school = true
")


# Update oldest school (slug: 83527-staatl-realschule-haag-i-ob) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rs-haag.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '83527-staatl-realschule-haag-i-ob' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatl. Realschule Haag i.OB (slug: staatl-realschule-haag-i-ob)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatl-realschule-haag-i-ob' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatl-realschule-haag-i-ob' 
  AND is_school = true
")


# Update oldest school (slug: 83536-gymnasium-gars-a-inn) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasiumgars.de',
              phone_number = '+49 8073 91930',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '83536-gymnasium-gars-a-inn' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Gars a.Inn (slug: gymnasium-gars-a-inn)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-gars-a-inn' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-gars-a-inn' 
  AND is_school = true
")


# Update oldest school (slug: 83607-privatgymnasium-holzkirchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.ganztagsschule.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '83607-privatgymnasium-holzkirchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Privatgymnasium Holzkirchen (slug: privatgymnasium-holzkirchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'privatgymnasium-holzkirchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'privatgymnasium-holzkirchen' 
  AND is_school = true
")


# Update oldest school (slug: 83646-staatliche-fachoberschule-bad-toelz) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fosbos-badtoelz.de',
              phone_number = '+49 8041 76480',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '83646-staatliche-fachoberschule-bad-toelz' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Fachoberschule Bad Tölz (slug: staatliche-fachoberschule-bad-tolz)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-fachoberschule-bad-tolz' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-fachoberschule-bad-tolz' 
  AND is_school = true
")


# Update oldest school (slug: 83646-gabriel-von-seidl-gymnasium-bad-toelz) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymtoelz.de',
              phone_number = '+49 8041 7994880',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '83646-gabriel-von-seidl-gymnasium-bad-toelz' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gabriel-von-Seidl-Gymnasium Bad Tölz (slug: gabriel-von-seidl-gymnasium-bad-tolz)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gabriel-von-seidl-gymnasium-bad-tolz' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gabriel-von-seidl-gymnasium-bad-tolz' 
  AND is_school = true
")


# Update oldest school (slug: 83646-staatliche-berufsoberschule-bad-toelz) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fosbos-badtoelz.de',
              phone_number = '+49 8041 76480',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '83646-staatliche-berufsoberschule-bad-toelz' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Berufsoberschule Bad Tölz (slug: staatliche-berufsoberschule-bad-tolz)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-berufsoberschule-bad-tolz' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-berufsoberschule-bad-tolz' 
  AND is_school = true
")


# Update oldest school (slug: 83684-gymnasium-tegernsee) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-tegernsee.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '83684-gymnasium-tegernsee' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Tegernsee (slug: gymnasium-tegernsee)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-tegernsee' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-tegernsee' 
  AND is_school = true
")


# Update oldest school (slug: 83714-gymnasium-miesbach) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymb.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '83714-gymnasium-miesbach' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Miesbach (slug: gymnasium-miesbach)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-miesbach' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-miesbach' 
  AND is_school = true
")


# Update oldest school (slug: 83714-staatliche-berufsoberschule-miesbach) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.bsz-miesbach.de',
              phone_number = '+49 8025 99730',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '83714-staatliche-berufsoberschule-miesbach' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Berufsoberschule Miesbach (slug: staatliche-berufsoberschule-miesbach)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-berufsoberschule-miesbach' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-berufsoberschule-miesbach' 
  AND is_school = true
")


# Update oldest school (slug: 84028-staatliche-fachoberschule-landshut) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fos-landshut.de',
              phone_number = '+49 871 966760',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '84028-staatliche-fachoberschule-landshut' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Fachoberschule Landshut (slug: staatliche-fachoberschule-landshut)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-fachoberschule-landshut' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-fachoberschule-landshut' 
  AND is_school = true
")


# No updates needed for school slug: 84028-staatliche-realschule-landshut
# Delete duplicate school: Staatliche Realschule Landshut (slug: staatliche-realschule-landshut)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-landshut' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-landshut' 
  AND is_school = true
")


# Update oldest school (slug: 84030-staatliche-realschule-ergolding) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://https://www.rsergolding.de',
              phone_number = '+49 871 974828811',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '84030-staatliche-realschule-ergolding' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Ergolding (slug: staatliche-realschule-ergolding)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-ergolding' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-ergolding' 
  AND is_school = true
")


# Update oldest school (slug: 84034-hans-leinberger-gymnasium-landshut) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.h-l-g.de',
              phone_number = '+49 871 962600',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '84034-hans-leinberger-gymnasium-landshut' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Hans-Leinberger-Gymnasium Landshut (slug: hans-leinberger-gymnasium-landshut)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'hans-leinberger-gymnasium-landshut' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'hans-leinberger-gymnasium-landshut' 
  AND is_school = true
")


# Update oldest school (slug: 84048-gabelsberger-gymnasium-mainburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gabelsberger-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '84048-gabelsberger-gymnasium-mainburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gabelsberger-Gymnasium Mainburg (slug: gabelsberger-gymnasium-mainburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gabelsberger-gymnasium-mainburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gabelsberger-gymnasium-mainburg' 
  AND is_school = true
")


# Update oldest school (slug: 84056-staatliche-realschule-rottenburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rs-rottenburg.de',
              phone_number = '+49 8781 201300',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '84056-staatliche-realschule-rottenburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Rottenburg (slug: staatliche-realschule-rottenburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-rottenburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-rottenburg' 
  AND is_school = true
")


# Update oldest school (slug: 84066-burkhart-gymnasium-mallersdorf-pfaffenberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-mallersdorf.de',
              phone_number = '+49 8772 96030',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '84066-burkhart-gymnasium-mallersdorf-pfaffenberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Burkhart-Gymnasium Mallersdorf-Pfaffenberg (slug: burkhart-gymnasium-mallersdorf-pfaffenberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'burkhart-gymnasium-mallersdorf-pfaffenberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'burkhart-gymnasium-mallersdorf-pfaffenberg' 
  AND is_school = true
")


# Update oldest school (slug: 84088-staatliche-realschule-neufahrn-i-nb) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-neufahrn.de',
              phone_number = '+49 8773 968570',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '84088-staatliche-realschule-neufahrn-i-nb' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Neufahrn i.NB (slug: staatliche-realschule-neufahrn-i-nb)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-neufahrn-i-nb' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-neufahrn-i-nb' 
  AND is_school = true
")


# Update oldest school (slug: 84095-maristen-gymnasium-furth) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.maristen-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '84095-maristen-gymnasium-furth' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Maristen-Gymnasium Furth (slug: maristen-gymnasium-furth)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'maristen-gymnasium-furth' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'maristen-gymnasium-furth' 
  AND is_school = true
")


# Update oldest school (slug: 84130-herzog-tassilo-realschule-staatliche-realschule-dingolfing) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-dingolfing.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '84130-herzog-tassilo-realschule-staatliche-realschule-dingolfing' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Herzog-Tassilo-Realschule Staatliche Realschule Dingolfing (slug: herzog-tassilo-realschule-staatliche-realschule-dingolfing)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'herzog-tassilo-realschule-staatliche-realschule-dingolfing' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'herzog-tassilo-realschule-staatliche-realschule-dingolfing' 
  AND is_school = true
")


# Update oldest school (slug: 84130-gymnasium-dingolfing) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymdgf.de/',
              phone_number = '+49 8731 31960',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '84130-gymnasium-dingolfing' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Dingolfing (slug: gymnasium-dingolfing)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-dingolfing' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-dingolfing' 
  AND is_school = true
")


# Update oldest school (slug: 84137-staatliche-realschule-vilsbiburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-vilsbiburg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '84137-staatliche-realschule-vilsbiburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Vilsbiburg (slug: staatliche-realschule-vilsbiburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-vilsbiburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-vilsbiburg' 
  AND is_school = true
")


# Update oldest school (slug: 84137-maximilian-von-montgelas-gymnasium-vilsbiburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.montgelas-gymnasium.de',
              phone_number = '+49 8741 96520',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '84137-maximilian-von-montgelas-gymnasium-vilsbiburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Maximilian-von-Montgelas-Gymnasium Vilsbiburg (slug: maximilian-von-montgelas-gymnasium-vilsbiburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'maximilian-von-montgelas-gymnasium-vilsbiburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'maximilian-von-montgelas-gymnasium-vilsbiburg' 
  AND is_school = true
")


# No updates needed for school slug: 84307-karl-von-closen-gymnasium-eggenfelden
# Delete duplicate school: Karl-von-Closen-Gymnasium Eggenfelden (slug: karl-von-closen-gymnasium-eggenfelden)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'karl-von-closen-gymnasium-eggenfelden' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'karl-von-closen-gymnasium-eggenfelden' 
  AND is_school = true
")


# Update oldest school (slug: 84347-staatliche-realschule-pfarrkirchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rs-pan.de',
              phone_number = '+49 8561 929550',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '84347-staatliche-realschule-pfarrkirchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Pfarrkirchen (slug: staatliche-realschule-pfarrkirchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-pfarrkirchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-pfarrkirchen' 
  AND is_school = true
")


# Update oldest school (slug: 84347-staatliche-berufsoberschule-pfarrkirchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fosbospan.de',
              phone_number = '+49 8561 483310',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '84347-staatliche-berufsoberschule-pfarrkirchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Berufsoberschule Pfarrkirchen (slug: staatliche-berufsoberschule-pfarrkirchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-berufsoberschule-pfarrkirchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-berufsoberschule-pfarrkirchen' 
  AND is_school = true
")


# Update oldest school (slug: 84347-staatliche-fachoberschule-pfarrkirchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fosbospan.de',
              phone_number = '+49 8561 483310',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '84347-staatliche-fachoberschule-pfarrkirchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Fachoberschule Pfarrkirchen (slug: staatliche-fachoberschule-pfarrkirchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-fachoberschule-pfarrkirchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-fachoberschule-pfarrkirchen' 
  AND is_school = true
")


# Update oldest school (slug: 84347-gymnasium-pfarrkirchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gympan.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '84347-gymnasium-pfarrkirchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Pfarrkirchen (slug: gymnasium-pfarrkirchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-pfarrkirchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-pfarrkirchen' 
  AND is_school = true
")


# Update oldest school (slug: 84359-staatliche-realschule-simbach-a-inn) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://https://www.rs-simbach.de/',
              phone_number = '+49 8571 983440',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '84359-staatliche-realschule-simbach-a-inn' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Simbach a.Inn (slug: staatliche-realschule-simbach-a-inn)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-simbach-a-inn' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-simbach-a-inn' 
  AND is_school = true
")


# Update oldest school (slug: 84405-gymnasium-dorfen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasiumdorfen.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '84405-gymnasium-dorfen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Dorfen (slug: gymnasium-dorfen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-dorfen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-dorfen' 
  AND is_school = true
")


# Update oldest school (slug: 84416-staatliche-realschule-taufkirchen-vils) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rstaufkirchen.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '84416-staatliche-realschule-taufkirchen-vils' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Taufkirchen (Vils) (slug: staatliche-realschule-taufkirchen-vils)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-taufkirchen-vils' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-taufkirchen-vils' 
  AND is_school = true
")


# Update oldest school (slug: 84478-gymnasium-waldkraiburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasiumwaldkraiburg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '84478-gymnasium-waldkraiburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Waldkraiburg (slug: gymnasium-waldkraiburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-waldkraiburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-waldkraiburg' 
  AND is_school = true
")


# Update oldest school (slug: 84489-aventinus-gymnasium-burghausen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.aventinus-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '84489-aventinus-gymnasium-burghausen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Aventinus-Gymnasium Burghausen (slug: aventinus-gymnasium-burghausen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'aventinus-gymnasium-burghausen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'aventinus-gymnasium-burghausen' 
  AND is_school = true
")


# Update oldest school (slug: 84489-kurfuerst-maximilian-gymnasium-burghausen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.kumax.de',
              phone_number = '+49 8677 97430',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '84489-kurfuerst-maximilian-gymnasium-burghausen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Kurfürst-Maximilian-Gymnasium Burghausen (slug: kurfurst-maximilian-gymnasium-burghausen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'kurfurst-maximilian-gymnasium-burghausen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'kurfurst-maximilian-gymnasium-burghausen' 
  AND is_school = true
")


# Update oldest school (slug: 84503-koenig-karlmann-gymnasium-altoetting) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.koenig-karlmann-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '84503-koenig-karlmann-gymnasium-altoetting' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: König-Karlmann-Gymnasium Altötting (slug: konig-karlmann-gymnasium-altotting)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'konig-karlmann-gymnasium-altotting' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'konig-karlmann-gymnasium-altotting' 
  AND is_school = true
")


# Update oldest school (slug: 84503-herzog-ludwig-realschule-staatliche-realschule-altoetting) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.herzog-ludwig-rs.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '84503-herzog-ludwig-realschule-staatliche-realschule-altoetting' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Herzog-Ludwig-Realschule Staatliche Realschule Altötting (slug: herzog-ludwig-realschule-staatliche-realschule-altotting)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'herzog-ludwig-realschule-staatliche-realschule-altotting' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'herzog-ludwig-realschule-staatliche-realschule-altotting' 
  AND is_school = true
")


# Update oldest school (slug: 85049-gnadenthal-maedchenrealschule-ingolstadt-der-dioezese-eichstaett) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gnadenthal-realschule.de',
              phone_number = '+49 841 93870500',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85049-gnadenthal-maedchenrealschule-ingolstadt-der-dioezese-eichstaett' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gnadenthal-Mädchenrealschule Ingolstadt der Diözese Eichstätt (slug: gnadenthal-madchenrealschule-ingolstadt-der-diozese-eichstatt)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gnadenthal-madchenrealschule-ingolstadt-der-diozese-eichstatt' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gnadenthal-madchenrealschule-ingolstadt-der-diozese-eichstatt' 
  AND is_school = true
")


# Update oldest school (slug: 85049-staatliche-berufsoberschule-ingolstadt) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fos-bos.de',
              phone_number = '+49 841 30542100',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85049-staatliche-berufsoberschule-ingolstadt' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Berufsoberschule Ingolstadt (slug: staatliche-berufsoberschule-ingolstadt)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-berufsoberschule-ingolstadt' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-berufsoberschule-ingolstadt' 
  AND is_school = true
")


# Update oldest school (slug: 85049-christoph-scheiner-gymnasium-ingolstadt) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.christoph-scheiner-gymnasium.de',
              phone_number = '+49 841 30540300',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85049-christoph-scheiner-gymnasium-ingolstadt' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Christoph-Scheiner-Gymnasium Ingolstadt (slug: christoph-scheiner-gymnasium-ingolstadt)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'christoph-scheiner-gymnasium-ingolstadt' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'christoph-scheiner-gymnasium-ingolstadt' 
  AND is_school = true
")


# Update oldest school (slug: 85049-katharinen-gymnasium-ingolstadt) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.katharinengymnasium.de',
              phone_number = '+49 841 30541300',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85049-katharinen-gymnasium-ingolstadt' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Katharinen-Gymnasium Ingolstadt (slug: katharinen-gymnasium-ingolstadt)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'katharinen-gymnasium-ingolstadt' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'katharinen-gymnasium-ingolstadt' 
  AND is_school = true
")


# Update oldest school (slug: 85049-freiherr-von-ickstatt-schule-staatliche-realschule-ingolstadt-i) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://https://www.ickstatt.de',
              phone_number = '+49 841 30540400',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85049-freiherr-von-ickstatt-schule-staatliche-realschule-ingolstadt-i' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Freiherr-von-Ickstatt-Schule Staatliche Realschule Ingolstadt I (slug: freiherr-von-ickstatt-schule-staatliche-realschule-ingolstadt-i)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'freiherr-von-ickstatt-schule-staatliche-realschule-ingolstadt-i' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'freiherr-von-ickstatt-schule-staatliche-realschule-ingolstadt-i' 
  AND is_school = true
")


# Update oldest school (slug: 85049-reuchlin-gymnasium-ingolstadt) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.reuchlingymnasium.de',
              phone_number = '+49 841 30543300',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85049-reuchlin-gymnasium-ingolstadt' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Reuchlin-Gymnasium Ingolstadt (slug: reuchlin-gymnasium-ingolstadt)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'reuchlin-gymnasium-ingolstadt' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'reuchlin-gymnasium-ingolstadt' 
  AND is_school = true
")


# Update oldest school (slug: 85049-gnadenthal-gymnasium-ingolstadt-der-dioezese-eichstaett) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gnadenthal-gymnasium.de',
              phone_number = '+49 841 93870300',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85049-gnadenthal-gymnasium-ingolstadt-der-dioezese-eichstaett' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gnadenthal-Gymnasium Ingolstadt der Diözese Eichstätt (slug: gnadenthal-gymnasium-ingolstadt-der-diozese-eichstatt)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gnadenthal-gymnasium-ingolstadt-der-diozese-eichstatt' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gnadenthal-gymnasium-ingolstadt-der-diozese-eichstatt' 
  AND is_school = true
")


# Update oldest school (slug: 85049-staatliche-fachoberschule-ingolstadt) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fos-bos.de',
              phone_number = '+49 841 30542100',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85049-staatliche-fachoberschule-ingolstadt' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Fachoberschule Ingolstadt (slug: staatliche-fachoberschule-ingolstadt)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-fachoberschule-ingolstadt' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-fachoberschule-ingolstadt' 
  AND is_school = true
")


# Update oldest school (slug: 85051-apian-gymnasium-ingolstadt) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.apian.de',
              phone_number = '+49 841 30542300',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85051-apian-gymnasium-ingolstadt' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Apian-Gymnasium Ingolstadt (slug: apian-gymnasium-ingolstadt)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'apian-gymnasium-ingolstadt' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'apian-gymnasium-ingolstadt' 
  AND is_school = true
")


# Update oldest school (slug: 85072-willibald-gymnasium-eichstaett) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.willibald-gymnasium.de',
              phone_number = '+49 8421 9344990',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85072-willibald-gymnasium-eichstaett' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Willibald-Gymnasium Eichstätt (slug: willibald-gymnasium-eichstatt)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'willibald-gymnasium-eichstatt' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'willibald-gymnasium-eichstatt' 
  AND is_school = true
")


# Update oldest school (slug: 85072-gabrieli-gymnasium-eichstaett) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gabrieli-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85072-gabrieli-gymnasium-eichstaett' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gabrieli-Gymnasium Eichstätt (slug: gabrieli-gymnasium-eichstatt)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gabrieli-gymnasium-eichstatt' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gabrieli-gymnasium-eichstatt' 
  AND is_school = true
")


# Update oldest school (slug: 85072-knabenrealschule-rebdorf-der-dioezese-eichstaett) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.krs-rebdorf.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85072-knabenrealschule-rebdorf-der-dioezese-eichstaett' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Knabenrealschule Rebdorf der Diözese Eichstätt (slug: knabenrealschule-rebdorf-der-diozese-eichstatt)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'knabenrealschule-rebdorf-der-diozese-eichstatt' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'knabenrealschule-rebdorf-der-diozese-eichstatt' 
  AND is_school = true
")


# No updates needed for school slug: 85077-volksschule-manching-im-lindenkreuz
# Delete duplicate school: Volksschule Manching im Lindenkreuz (slug: 85077-volksschule-manching-im-lindenkreuz-4a76d4c0-b970-11e7-9a41-001ec9cdab18)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85077-volksschule-manching-im-lindenkreuz-4a76d4c0-b970-11e7-9a41-001ec9cdab18' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = '85077-volksschule-manching-im-lindenkreuz-4a76d4c0-b970-11e7-9a41-001ec9cdab18' 
  AND is_school = true
")


# Update oldest school (slug: 85077-realschule-am-keltenwall-staatliche-realschule-manching) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rs-manching.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85077-realschule-am-keltenwall-staatliche-realschule-manching' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Realschule am Keltenwall Staatliche Realschule Manching (slug: realschule-am-keltenwall-staatliche-realschule-manching)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'realschule-am-keltenwall-staatliche-realschule-manching' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'realschule-am-keltenwall-staatliche-realschule-manching' 
  AND is_school = true
")


# Update oldest school (slug: 85092-staatl-realschule-koesching) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-koesching.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85092-staatl-realschule-koesching' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatl. Realschule Kösching (slug: staatl-realschule-kosching)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatl-realschule-kosching' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatl-realschule-kosching' 
  AND is_school = true
")


# Update oldest school (slug: 85221-josef-effner-gymnasium-dachau) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.effner.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85221-josef-effner-gymnasium-dachau' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Josef-Effner-Gymnasium Dachau (slug: josef-effner-gymnasium-dachau)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'josef-effner-gymnasium-dachau' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'josef-effner-gymnasium-dachau' 
  AND is_school = true
")


# Update oldest school (slug: 85221-ignaz-taschner-gymnasium-dachau) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.ignaz-taschner-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85221-ignaz-taschner-gymnasium-dachau' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Ignaz-Taschner-Gymnasium Dachau (slug: ignaz-taschner-gymnasium-dachau)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'ignaz-taschner-gymnasium-dachau' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'ignaz-taschner-gymnasium-dachau' 
  AND is_school = true
")


# Update oldest school (slug: 85229-gymnasium-markt-indersdorf) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gym-indersdorf.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85229-gymnasium-markt-indersdorf' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Markt Indersdorf (slug: gymnasium-markt-indersdorf)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-markt-indersdorf' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-markt-indersdorf' 
  AND is_school = true
")


# Update oldest school (slug: 85276-schyren-gymnasium-pfaffenhofen-a-d-ilm) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.schyren-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85276-schyren-gymnasium-pfaffenhofen-a-d-ilm' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Schyren-Gymnasium Pfaffenhofen a.d.Ilm (slug: schyren-gymnasium-pfaffenhofen-a-d-ilm)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'schyren-gymnasium-pfaffenhofen-a-d-ilm' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'schyren-gymnasium-pfaffenhofen-a-d-ilm' 
  AND is_school = true
")


# Update oldest school (slug: 85290-staatl-realschule-geisenfeld) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rs-geisenfeld.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85290-staatl-realschule-geisenfeld' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatl. Realschule Geisenfeld (slug: staatl-realschule-geisenfeld)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatl-realschule-geisenfeld' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatl-realschule-geisenfeld' 
  AND is_school = true
")


# Update oldest school (slug: 85298-staatliche-berufsoberschule-scheyern) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.bos-scheyern.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85298-staatliche-berufsoberschule-scheyern' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Berufsoberschule Scheyern (slug: staatliche-berufsoberschule-scheyern)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-berufsoberschule-scheyern' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-berufsoberschule-scheyern' 
  AND is_school = true
")


# Update oldest school (slug: 85354-staatliche-berufsoberschule-freising) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fosbosfreising.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85354-staatliche-berufsoberschule-freising' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Berufsoberschule Freising (slug: staatliche-berufsoberschule-freising)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-berufsoberschule-freising' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-berufsoberschule-freising' 
  AND is_school = true
")


# Update oldest school (slug: 85354-camerloher-gymnasium-freising) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.camerloher-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85354-camerloher-gymnasium-freising' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Camerloher-Gymnasium Freising (slug: camerloher-gymnasium-freising)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'camerloher-gymnasium-freising' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'camerloher-gymnasium-freising' 
  AND is_school = true
")


# Update oldest school (slug: 85354-dom-gymnasium-freising) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.dom-gymnasium.de',
              phone_number = '+49 8161 60082200',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85354-dom-gymnasium-freising' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Dom-Gymnasium Freising (slug: dom-gymnasium-freising)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'dom-gymnasium-freising' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'dom-gymnasium-freising' 
  AND is_school = true
")


# Update oldest school (slug: 85354-josef-hofmiller-gymnasium-freising) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.johogym-freising.de',
              phone_number = '+49 8161 60082700',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85354-josef-hofmiller-gymnasium-freising' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Josef-Hofmiller-Gymnasium Freising (slug: josef-hofmiller-gymnasium-freising)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'josef-hofmiller-gymnasium-freising' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'josef-hofmiller-gymnasium-freising' 
  AND is_school = true
")


# Update oldest school (slug: 85354-karl-meichelbeck-realschule-staatl-realschule-freising) with newest data
execute("
  UPDATE addresses 
  SET phone_number = '+49 8161 60082000',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85354-karl-meichelbeck-realschule-staatl-realschule-freising' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Karl-Meichelbeck-Realschule Staatl. Realschule Freising (slug: karl-meichelbeck-realschule-staatl-realschule-freising)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'karl-meichelbeck-realschule-staatl-realschule-freising' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'karl-meichelbeck-realschule-staatl-realschule-freising' 
  AND is_school = true
")


# Update oldest school (slug: 85354-staatliche-fachoberschule-freising) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fosbosfreising.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85354-staatliche-fachoberschule-freising' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Fachoberschule Freising (slug: staatliche-fachoberschule-freising)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-fachoberschule-freising' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-fachoberschule-freising' 
  AND is_school = true
")


# Update oldest school (slug: 85368-kastulus-realschule-staatliche-realschule-moosburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschulemoosburg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85368-kastulus-realschule-staatliche-realschule-moosburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Kastulus-Realschule Staatliche Realschule Moosburg (slug: kastulus-realschule-staatliche-realschule-moosburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'kastulus-realschule-staatliche-realschule-moosburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'kastulus-realschule-staatliche-realschule-moosburg' 
  AND is_school = true
")


# Update oldest school (slug: 85368-karl-ritter-von-frisch-gymnasium-moosburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-moosburg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85368-karl-ritter-von-frisch-gymnasium-moosburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Karl-Ritter-von-Frisch-Gymnasium Moosburg (slug: karl-ritter-von-frisch-gymnasium-moosburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'karl-ritter-von-frisch-gymnasium-moosburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'karl-ritter-von-frisch-gymnasium-moosburg' 
  AND is_school = true
")


# Update oldest school (slug: 85386-imma-mack-realschule-staatl-realschule-eching) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-eching.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85386-imma-mack-realschule-staatl-realschule-eching' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Imma-Mack-Realschule Staatl. Realschule Eching (slug: imma-mack-realschule-staatl-realschule-eching)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'imma-mack-realschule-staatl-realschule-eching' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'imma-mack-realschule-staatl-realschule-eching' 
  AND is_school = true
")


# Update oldest school (slug: 85435-anne-frank-gymnasium-erding) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.afg-erding.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85435-anne-frank-gymnasium-erding' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Anne-Frank-Gymnasium Erding (slug: anne-frank-gymnasium-erding)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'anne-frank-gymnasium-erding' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'anne-frank-gymnasium-erding' 
  AND is_school = true
")


# Update oldest school (slug: 85435-herzog-tassilo-realschule-staatliche-realschule-erding) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-erding.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85435-herzog-tassilo-realschule-staatliche-realschule-erding' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Herzog-Tassilo-Realschule Staatliche Realschule Erding (slug: herzog-tassilo-realschule-staatliche-realschule-erding)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'herzog-tassilo-realschule-staatliche-realschule-erding' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'herzog-tassilo-realschule-staatliche-realschule-erding' 
  AND is_school = true
")


# Update oldest school (slug: 85435-korbinian-aigner-gymnasium-erding) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.kag-erding.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85435-korbinian-aigner-gymnasium-erding' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Korbinian-Aigner-Gymnasium Erding (slug: korbinian-aigner-gymnasium-erding)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'korbinian-aigner-gymnasium-erding' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'korbinian-aigner-gymnasium-erding' 
  AND is_school = true
")


# Update oldest school (slug: 85521-gymnasium-ottobrunn) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-ottobrunn.de',
              phone_number = '+49 89 6066650',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85521-gymnasium-ottobrunn' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Ottobrunn (slug: gymnasium-ottobrunn)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-ottobrunn' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-ottobrunn' 
  AND is_school = true
")


# Update oldest school (slug: 85540-ernst-mach-gymnasium-haar) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.emg-haar.de',
              phone_number = '+49 89 43707770',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85540-ernst-mach-gymnasium-haar' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Ernst-Mach-Gymnasium Haar (slug: ernst-mach-gymnasium-haar)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'ernst-mach-gymnasium-haar' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'ernst-mach-gymnasium-haar' 
  AND is_school = true
")


# Update oldest school (slug: 85560-dr-wintrich-schule-staatliche-realschule-ebersberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rsebe.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85560-dr-wintrich-schule-staatliche-realschule-ebersberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Dr.-Wintrich-Schule Staatliche Realschule Ebersberg (slug: dr-wintrich-schule-staatliche-realschule-ebersberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'dr-wintrich-schule-staatliche-realschule-ebersberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'dr-wintrich-schule-staatliche-realschule-ebersberg' 
  AND is_school = true
")


# Update oldest school (slug: 85570-franz-marc-gymnasium-markt-schwaben) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.franz-marc-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85570-franz-marc-gymnasium-markt-schwaben' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Franz-Marc-Gymnasium Markt Schwaben (slug: franz-marc-gymnasium-markt-schwaben)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'franz-marc-gymnasium-markt-schwaben' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'franz-marc-gymnasium-markt-schwaben' 
  AND is_school = true
")


# Update oldest school (slug: 85570-lena-christ-realschule-staatl-realschule-markt-schwaben) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.lena-christ-realschule.net',
              phone_number = '+49 8121 22356',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85570-lena-christ-realschule-staatl-realschule-markt-schwaben' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Lena-Christ-Realschule Staatl. Realschule Markt Schwaben (slug: lena-christ-realschule-staatl-realschule-markt-schwaben)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'lena-christ-realschule-staatl-realschule-markt-schwaben' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'lena-christ-realschule-staatl-realschule-markt-schwaben' 
  AND is_school = true
")


# Update oldest school (slug: 85579-gymnasium-neubiberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-neubiberg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85579-gymnasium-neubiberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Neubiberg (slug: gymnasium-neubiberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-neubiberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-neubiberg' 
  AND is_school = true
")


# Update oldest school (slug: 85579-staatliche-realschule-neubiberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-neubiberg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85579-staatliche-realschule-neubiberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Neubiberg (slug: staatliche-realschule-neubiberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-neubiberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-neubiberg' 
  AND is_school = true
")


# Update oldest school (slug: 85609-st-emmeram-realschule-staatl-realschule-aschheim) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://https://www.realschule-aschheim.de/',
              phone_number = '+49 89 90108260',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85609-st-emmeram-realschule-staatl-realschule-aschheim' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: St.-Emmeram-Realschule Staatl. Realschule Aschheim (slug: st-emmeram-realschule-staatl-realschule-aschheim)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'st-emmeram-realschule-staatl-realschule-aschheim' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'st-emmeram-realschule-staatl-realschule-aschheim' 
  AND is_school = true
")


# Update oldest school (slug: 85737-johann-andreas-schmeller-realschule-staatliche-realschule-ismaning) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rs-ismaning.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85737-johann-andreas-schmeller-realschule-staatliche-realschule-ismaning' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Johann-Andreas-Schmeller-Realschule Staatliche Realschule Ismaning (slug: johann-andreas-schmeller-realschule-staatliche-realschule-ismaning)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'johann-andreas-schmeller-realschule-staatliche-realschule-ismaning' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'johann-andreas-schmeller-realschule-staatliche-realschule-ismaning' 
  AND is_school = true
")


# Update oldest school (slug: 85748-werner-heisenberg-gymnasium-garching) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.whg-garching.de/',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '85748-werner-heisenberg-gymnasium-garching' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Werner-Heisenberg-Gymnasium Garching (slug: werner-heisenberg-gymnasium-garching)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'werner-heisenberg-gymnasium-garching' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'werner-heisenberg-gymnasium-garching' 
  AND is_school = true
")


# Update oldest school (slug: 86150-holbein-gymnasium-augsburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.holbein-gymnasium.de',
              phone_number = '+49 821 3241611',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86150-holbein-gymnasium-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Holbein-Gymnasium Augsburg (slug: holbein-gymnasium-augsburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'holbein-gymnasium-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'holbein-gymnasium-augsburg' 
  AND is_school = true
")


# Update oldest school (slug: 86150-bertolt-brecht-realschule-staatl-realschule-augsburg-i) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://https://www.bbrs.de/',
              phone_number = '+49 821 3241527',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86150-bertolt-brecht-realschule-staatl-realschule-augsburg-i' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Bertolt-Brecht-Realschule Staatl. Realschule Augsburg I (slug: bertolt-brecht-realschule-staatl-realschule-augsburg-i)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'bertolt-brecht-realschule-staatl-realschule-augsburg-i' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'bertolt-brecht-realschule-staatl-realschule-augsburg-i' 
  AND is_school = true
")


# Update oldest school (slug: 86150-staedtisches-maria-theresia-gymnasium-augsburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.mtg-augsburg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86150-staedtisches-maria-theresia-gymnasium-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtisches Maria-Theresia-Gymnasium Augsburg (slug: stadtisches-maria-theresia-gymnasium-augsburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtisches-maria-theresia-gymnasium-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtisches-maria-theresia-gymnasium-augsburg' 
  AND is_school = true
")


# Update oldest school (slug: 86152-gymnasium-bei-st-stephan-augsburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.st-stephan.de',
              phone_number = '+49 821 32418500',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86152-gymnasium-bei-st-stephan-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium bei St.Stephan Augsburg (slug: gymnasium-bei-st-stephan-augsburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-bei-st-stephan-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-bei-st-stephan-augsburg' 
  AND is_school = true
")


# Update oldest school (slug: 86152-staedtisches-jakob-fugger-gymnasium-augsburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.jakob-fugger-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86152-staedtisches-jakob-fugger-gymnasium-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtisches Jakob-Fugger-Gymnasium Augsburg (slug: stadtisches-jakob-fugger-gymnasium-augsburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtisches-jakob-fugger-gymnasium-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtisches-jakob-fugger-gymnasium-augsburg' 
  AND is_school = true
")


# Update oldest school (slug: 86152-abendrealschule-fuer-berufstaetige-der-stadt-augsburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.abendrealschule-augsburg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86152-abendrealschule-fuer-berufstaetige-der-stadt-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Abendrealschule für Berufstätige der Stadt Augsburg (slug: abendrealschule-fur-berufstatige-der-stadt-augsburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'abendrealschule-fur-berufstatige-der-stadt-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'abendrealschule-fur-berufstatige-der-stadt-augsburg' 
  AND is_school = true
")


# Update oldest school (slug: 86152-peutinger-gymnasium-augsburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.peutinger-gymnasium-augsburg.de',
              phone_number = '+49 821 32418475',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86152-peutinger-gymnasium-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Peutinger-Gymnasium Augsburg (slug: peutinger-gymnasium-augsburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'peutinger-gymnasium-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'peutinger-gymnasium-augsburg' 
  AND is_school = true
")


# Update oldest school (slug: 86154-heinrich-von-buz-realschule-staatliche-realschule-augsburg-ii) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.Heinrichvonbuz-realschule.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86154-heinrich-von-buz-realschule-staatliche-realschule-augsburg-ii' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Heinrich-von-Buz-Realschule Staatliche Realschule Augsburg II (slug: heinrich-von-buz-realschule-staatliche-realschule-augsburg-ii)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'heinrich-von-buz-realschule-staatliche-realschule-augsburg-ii' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'heinrich-von-buz-realschule-staatliche-realschule-augsburg-ii' 
  AND is_school = true
")


# Update oldest school (slug: 86159-gymnasium-bei-st-anna-augsburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gym-anna.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86159-gymnasium-bei-st-anna-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium bei St.Anna Augsburg (slug: gymnasium-bei-st-anna-augsburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-bei-st-anna-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-bei-st-anna-augsburg' 
  AND is_school = true
")


# Update oldest school (slug: 86161-staedtische-berufsoberschule-augsburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.bos-augsburg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86161-staedtische-berufsoberschule-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtische Berufsoberschule Augsburg (slug: stadtische-berufsoberschule-augsburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtische-berufsoberschule-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtische-berufsoberschule-augsburg' 
  AND is_school = true
")


# Update oldest school (slug: 86163-rudolf-diesel-gymnasium-augsburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rdg-online.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86163-rudolf-diesel-gymnasium-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Rudolf-Diesel-Gymnasium Augsburg (slug: rudolf-diesel-gymnasium-augsburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'rudolf-diesel-gymnasium-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'rudolf-diesel-gymnasium-augsburg' 
  AND is_school = true
")


# Update oldest school (slug: 86199-realschule-maria-stern-augsburg-des-schulwerks-der-dioezese-augsburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rs-mariastern.de',
              phone_number = '+49 821 455813200',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86199-realschule-maria-stern-augsburg-des-schulwerks-der-dioezese-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Realschule Maria Stern Augsburg des Schulwerks der Diözese Augsburg (slug: realschule-maria-stern-augsburg-des-schulwerks-der-diozese-augsburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'realschule-maria-stern-augsburg-des-schulwerks-der-diozese-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'realschule-maria-stern-augsburg-des-schulwerks-der-diozese-augsburg' 
  AND is_school = true
")


# Update oldest school (slug: 86199-gymnasium-maria-stern-augsburg-des-schulwerks-der-dioezese-augsburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-mariastern.de',
              phone_number = '+49 821 455811100',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86199-gymnasium-maria-stern-augsburg-des-schulwerks-der-dioezese-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Maria Stern Augsburg des Schulwerks der Diözese Augsburg (slug: gymnasium-maria-stern-augsburg-des-schulwerks-der-diozese-augsburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-maria-stern-augsburg-des-schulwerks-der-diozese-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-maria-stern-augsburg-des-schulwerks-der-diozese-augsburg' 
  AND is_school = true
")


# Update oldest school (slug: 86316-staatl-fachoberschule-friedberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fosbosfriedberg.de/',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86316-staatl-fachoberschule-friedberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatl. Fachoberschule Friedberg (slug: staatl-fachoberschule-friedberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatl-fachoberschule-friedberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatl-fachoberschule-friedberg' 
  AND is_school = true
")


# Update oldest school (slug: 86343-gymnasium-koenigsbrunn) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasiumkoenigsbrunn.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86343-gymnasium-koenigsbrunn' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Königsbrunn (slug: gymnasium-konigsbrunn)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-konigsbrunn' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-konigsbrunn' 
  AND is_school = true
")


# Update oldest school (slug: 86343-via-claudia-realschule-staatliche-realschule-koenigsbrunn) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rskoenigsbrunn.de',
              phone_number = '+49 821 31025151',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86343-via-claudia-realschule-staatliche-realschule-koenigsbrunn' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Via-Claudia-Realschule Staatliche Realschule Königsbrunn (slug: via-claudia-realschule-staatliche-realschule-konigsbrunn)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'via-claudia-realschule-staatliche-realschule-konigsbrunn' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'via-claudia-realschule-staatliche-realschule-konigsbrunn' 
  AND is_school = true
")


# Update oldest school (slug: 86356-staatliche-realschule-neusaess) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-neusaess.de',
              phone_number = '+49 821 31025454',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86356-staatliche-realschule-neusaess' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Neusäß (slug: staatliche-realschule-neusass)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-neusass' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-neusass' 
  AND is_school = true
")


# Update oldest school (slug: 86381-staatliche-realschule-krumbach) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-krumbach.de',
              phone_number = '+49 8282 800350',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86381-staatliche-realschule-krumbach' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Krumbach (slug: staatliche-realschule-krumbach)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-krumbach' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-krumbach' 
  AND is_school = true
")


# Update oldest school (slug: 86381-simpert-kraemer-gymnasium-krumbach) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.skg-krumbach.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86381-simpert-kraemer-gymnasium-krumbach' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Simpert-Kraemer-Gymnasium Krumbach (slug: simpert-kraemer-gymnasium-krumbach)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'simpert-kraemer-gymnasium-krumbach' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'simpert-kraemer-gymnasium-krumbach' 
  AND is_school = true
")


# Update oldest school (slug: 86405-dr-max-josef-metzger-schule-staatl-realschule-meitingen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://https://www.rsmeitingen.org',
              phone_number = '+49 821 31025301',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86405-dr-max-josef-metzger-schule-staatl-realschule-meitingen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Dr.-Max-Josef-Metzger-Schule Staatl. Realschule Meitingen (slug: dr-max-josef-metzger-schule-staatl-realschule-meitingen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'dr-max-josef-metzger-schule-staatl-realschule-meitingen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'dr-max-josef-metzger-schule-staatl-realschule-meitingen' 
  AND is_school = true
")


# Update oldest school (slug: 86438-volksschule-kissing) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.mskissing.de',
              phone_number = '+49 8233 7907451',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86438-volksschule-kissing' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Volksschule Kissing (slug: 86438-volksschule-kissing-4a4b963e-b970-11e7-aa93-001ec9cdab18)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86438-volksschule-kissing-4a4b963e-b970-11e7-aa93-001ec9cdab18' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = '86438-volksschule-kissing-4a4b963e-b970-11e7-aa93-001ec9cdab18' 
  AND is_school = true
")


# Update oldest school (slug: 86441-staatl-realschule-zusmarshausen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rs-zusmarshausen.de',
              phone_number = '+49 821 31025751',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86441-staatl-realschule-zusmarshausen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatl. Realschule Zusmarshausen (slug: staatl-realschule-zusmarshausen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatl-realschule-zusmarshausen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatl-realschule-zusmarshausen' 
  AND is_school = true
")


# Update oldest school (slug: 86470-christoph-von-schmid-schule-staatliche-realschule-thannhausen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rs-thannhausen.de',
              phone_number = '+49 8281 999320',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86470-christoph-von-schmid-schule-staatliche-realschule-thannhausen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Christoph-von-Schmid-Schule Staatliche Realschule Thannhausen (slug: christoph-von-schmid-schule-staatliche-realschule-thannhausen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'christoph-von-schmid-schule-staatliche-realschule-thannhausen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'christoph-von-schmid-schule-staatliche-realschule-thannhausen' 
  AND is_school = true
")


# Update oldest school (slug: 86513-ringeisen-gymnasium-der-st-josefskongregation-ursberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.ringeisen-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86513-ringeisen-gymnasium-der-st-josefskongregation-ursberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Ringeisen-Gymnasium der St. Josefskongregation Ursberg (slug: ringeisen-gymnasium-der-st-josefskongregation-ursberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'ringeisen-gymnasium-der-st-josefskongregation-ursberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'ringeisen-gymnasium-der-st-josefskongregation-ursberg' 
  AND is_school = true
")


# Update oldest school (slug: 86529-gymnasium-schrobenhausen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymsob.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86529-gymnasium-schrobenhausen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Schrobenhausen (slug: gymnasium-schrobenhausen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-schrobenhausen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-schrobenhausen' 
  AND is_school = true
")


# Update oldest school (slug: 86529-franz-von-lenbach-schule-staatliche-realschule-fuer-knaben-schrobenh) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://https://www.fvls.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86529-franz-von-lenbach-schule-staatliche-realschule-fuer-knaben-schrobenh' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Franz-von-Lenbach-Schule Staatliche Realschule für Knaben Schrobenhausen (slug: franz-von-lenbach-schule-staatliche-realschule-fur-knaben-schrobenhausen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'franz-von-lenbach-schule-staatliche-realschule-fur-knaben-schrobenhausen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'franz-von-lenbach-schule-staatliche-realschule-fur-knaben-schrobenhausen' 
  AND is_school = true
")


# Update oldest school (slug: 86551-wittelsbacher-realschule-staatliche-realschule-aichach) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.wir-aichach.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86551-wittelsbacher-realschule-staatliche-realschule-aichach' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Wittelsbacher-Realschule Staatliche Realschule Aichach (slug: wittelsbacher-realschule-staatliche-realschule-aichach)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'wittelsbacher-realschule-staatliche-realschule-aichach' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'wittelsbacher-realschule-staatliche-realschule-aichach' 
  AND is_school = true
")


# Update oldest school (slug: 86551-deutschherren-gymnasium-aichach) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.dhgaic.de',
              phone_number = '+49 8251 93310',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86551-deutschherren-gymnasium-aichach' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Deutschherren-Gymnasium Aichach (slug: deutschherren-gymnasium-aichach)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'deutschherren-gymnasium-aichach' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'deutschherren-gymnasium-aichach' 
  AND is_school = true
")


# Update oldest school (slug: 86609-gymnasium-donauwoerth) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gym-don.de',
              phone_number = '+49 906 706560',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86609-gymnasium-donauwoerth' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Donauwörth (slug: gymnasium-donauworth)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-donauworth' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-donauworth' 
  AND is_school = true
")


# Update oldest school (slug: 86609-hans-leipelt-schule-staatliche-fachoberschule-donauwoerth) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fosbos-donauwoerth.de',
              phone_number = '+49 906 7050810',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86609-hans-leipelt-schule-staatliche-fachoberschule-donauwoerth' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Hans-Leipelt-Schule Staatliche Fachoberschule Donauwörth (slug: hans-leipelt-schule-staatliche-fachoberschule-donauworth)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'hans-leipelt-schule-staatliche-fachoberschule-donauworth' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'hans-leipelt-schule-staatliche-fachoberschule-donauworth' 
  AND is_school = true
")


# Update oldest school (slug: 86609-hans-leipelt-schule-staatliche-berufsoberschule-donauwoerth) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fosbos-donauwoerth.de',
              phone_number = '+49 906 7050810',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86609-hans-leipelt-schule-staatliche-berufsoberschule-donauwoerth' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Hans-Leipelt-Schule Staatliche Berufsoberschule Donauwörth (slug: hans-leipelt-schule-staatliche-berufsoberschule-donauworth)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'hans-leipelt-schule-staatliche-berufsoberschule-donauworth' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'hans-leipelt-schule-staatliche-berufsoberschule-donauworth' 
  AND is_school = true
")


# Update oldest school (slug: 86633-descartes-gymnasium-neuburg-a-d-donau) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.descartes-gym.de',
              phone_number = '+49 8431 67860',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86633-descartes-gymnasium-neuburg-a-d-donau' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Descartes-Gymnasium Neuburg a.d.Donau (slug: descartes-gymnasium-neuburg-a-d-donau)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'descartes-gymnasium-neuburg-a-d-donau' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'descartes-gymnasium-neuburg-a-d-donau' 
  AND is_school = true
")


# Update oldest school (slug: 86637-gymnasium-wertingen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-wertingen.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86637-gymnasium-wertingen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Wertingen (slug: gymnasium-wertingen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-wertingen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-wertingen' 
  AND is_school = true
")


# Update oldest school (slug: 86650-anton-jaumann-realschule-staatliche-realschule-wemding) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rs-wemding.de',
              phone_number = '+49 9092 965190',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86650-anton-jaumann-realschule-staatliche-realschule-wemding' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Anton-Jaumann-Realschule Staatliche Realschule Wemding (slug: anton-jaumann-realschule-staatliche-realschule-wemding)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'anton-jaumann-realschule-staatliche-realschule-wemding' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'anton-jaumann-realschule-staatliche-realschule-wemding' 
  AND is_school = true
")


# Update oldest school (slug: 86720-realschule-maria-stern-noerdlingen-des-schulwerks-der-dioezese-augsburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.mariastern.de',
              phone_number = '+49 821 455814800',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86720-realschule-maria-stern-noerdlingen-des-schulwerks-der-dioezese-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Realschule Maria Stern Nördlingen des Schulwerks der Diözese Augsburg (slug: realschule-maria-stern-nordlingen-des-schulwerks-der-diozese-augsburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'realschule-maria-stern-nordlingen-des-schulwerks-der-diozese-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'realschule-maria-stern-nordlingen-des-schulwerks-der-diozese-augsburg' 
  AND is_school = true
")


# Update oldest school (slug: 86720-theodor-heuss-gymnasium-noerdlingen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.thg-noe.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86720-theodor-heuss-gymnasium-noerdlingen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Theodor-Heuss-Gymnasium Nördlingen (slug: theodor-heuss-gymnasium-nordlingen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'theodor-heuss-gymnasium-nordlingen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'theodor-heuss-gymnasium-nordlingen' 
  AND is_school = true
")


# Update oldest school (slug: 86732-albrecht-ernst-gymnasium-oettingen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasiumoettingen.de',
              phone_number = '+49 9082 96900',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86732-albrecht-ernst-gymnasium-oettingen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Albrecht-Ernst-Gymnasium Oettingen (slug: albrecht-ernst-gymnasium-oettingen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'albrecht-ernst-gymnasium-oettingen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'albrecht-ernst-gymnasium-oettingen' 
  AND is_school = true
")


# Update oldest school (slug: 86757-maria-ward-realschule-wallerstein-des-schulwerks-der-dioezese-augsburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.maria-ward-wallerstein.de',
              phone_number = '+49 821 455815100',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86757-maria-ward-realschule-wallerstein-des-schulwerks-der-dioezese-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Maria-Ward-Realschule Wallerstein des Schulwerks der Diözese Augsburg (slug: maria-ward-realschule-wallerstein-des-schulwerks-der-diozese-augsburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'maria-ward-realschule-wallerstein-des-schulwerks-der-diozese-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'maria-ward-realschule-wallerstein-des-schulwerks-der-diozese-augsburg' 
  AND is_school = true
")


# Update oldest school (slug: 86807-staatliche-realschule-buchloe) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-buchloe.de',
              phone_number = '+49 8241 5078630',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86807-staatliche-realschule-buchloe' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Buchloe (slug: staatliche-realschule-buchloe)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-buchloe' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-buchloe' 
  AND is_school = true
")


# Update oldest school (slug: 86825-fachoberschule-bad-woerishofen-des-zweckverbandes-beruflicher-schule) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fosbos-bw.de',
              phone_number = '+49 8247 96720',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86825-fachoberschule-bad-woerishofen-des-zweckverbandes-beruflicher-schule' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Fachoberschule Bad Wörishofen des Zweckverbandes Beruflicher Schulen Bad Wörishofen (slug: fachoberschule-bad-worishofen-des-zweckverbandes-beruflicher-schulen-bad-worishofen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'fachoberschule-bad-worishofen-des-zweckverbandes-beruflicher-schulen-bad-worishofen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'fachoberschule-bad-worishofen-des-zweckverbandes-beruflicher-schulen-bad-worishofen' 
  AND is_school = true
")


# Update oldest school (slug: 86830-leonhard-wagner-gymnasium-schwabmuenchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.lwg-smue.de',
              phone_number = '+49 821 31027801',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86830-leonhard-wagner-gymnasium-schwabmuenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Leonhard-Wagner-Gymnasium Schwabmünchen (slug: leonhard-wagner-gymnasium-schwabmunchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'leonhard-wagner-gymnasium-schwabmunchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'leonhard-wagner-gymnasium-schwabmunchen' 
  AND is_school = true
")


# Update oldest school (slug: 86830-leonhard-wagner-realschule-staatl-realschule-schwabmuenchen) with newest data
execute("
  UPDATE addresses 
  SET phone_number = '+49 821 31025601',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86830-leonhard-wagner-realschule-staatl-realschule-schwabmuenchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Leonhard-Wagner-Realschule Staatl. Realschule Schwabmünchen (slug: leonhard-wagner-realschule-staatl-realschule-schwabmunchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'leonhard-wagner-realschule-staatl-realschule-schwabmunchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'leonhard-wagner-realschule-staatl-realschule-schwabmunchen' 
  AND is_school = true
")


# Update oldest school (slug: 86842-joseph-bernhart-gymnasium-tuerkheim) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-tuerkheim.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86842-joseph-bernhart-gymnasium-tuerkheim' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Joseph-Bernhart-Gymnasium Türkheim (slug: joseph-bernhart-gymnasium-turkheim)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'joseph-bernhart-gymnasium-turkheim' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'joseph-bernhart-gymnasium-turkheim' 
  AND is_school = true
")


# Update oldest school (slug: 86899-staatl-fachoberschule-landsberg-a-lech) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.bs-landsberg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86899-staatl-fachoberschule-landsberg-a-lech' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatl. Fachoberschule Landsberg a.Lech (slug: staatl-fachoberschule-landsberg-a-lech)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatl-fachoberschule-landsberg-a-lech' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatl-fachoberschule-landsberg-a-lech' 
  AND is_school = true
")


# Update oldest school (slug: 86899-dominikus-zimmermann-gymnasium-landsberg-am-lech) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.dzg-landsberg.de',
              phone_number = '+49 8191 92700',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86899-dominikus-zimmermann-gymnasium-landsberg-am-lech' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Dominikus-Zimmermann-Gymnasium Landsberg am Lech (slug: dominikus-zimmermann-gymnasium-landsberg-am-lech)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'dominikus-zimmermann-gymnasium-landsberg-am-lech' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'dominikus-zimmermann-gymnasium-landsberg-am-lech' 
  AND is_school = true
")


# Update oldest school (slug: 86899-ignaz-koegler-gymnasium-landsberg-am-lech) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.ikg-landsberg.de',
              phone_number = '+49 8191 6571080',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86899-ignaz-koegler-gymnasium-landsberg-am-lech' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Ignaz-Kögler-Gymnasium Landsberg am Lech (slug: ignaz-kogler-gymnasium-landsberg-am-lech)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'ignaz-kogler-gymnasium-landsberg-am-lech' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'ignaz-kogler-gymnasium-landsberg-am-lech' 
  AND is_school = true
")


# Update oldest school (slug: 86899-johann-winklhofer-realschule-staatliche-realschule-landsberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.jwr-landsberg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86899-johann-winklhofer-realschule-staatliche-realschule-landsberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Johann-Winklhofer-Realschule Staatliche Realschule Landsberg (slug: johann-winklhofer-realschule-staatliche-realschule-landsberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'johann-winklhofer-realschule-staatliche-realschule-landsberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'johann-winklhofer-realschule-staatliche-realschule-landsberg' 
  AND is_school = true
")


# Update oldest school (slug: 86911-ammersee-gymnasium-diessen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.amseegym.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86911-ammersee-gymnasium-diessen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Ammersee-Gymnasium Dießen (slug: ammersee-gymnasium-diessen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'ammersee-gymnasium-diessen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'ammersee-gymnasium-diessen' 
  AND is_school = true
")


# Update oldest school (slug: 86956-welfen-gymnasium-schongau) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.welfen-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '86956-welfen-gymnasium-schongau' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Welfen-Gymnasium Schongau (slug: welfen-gymnasium-schongau)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'welfen-gymnasium-schongau' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'welfen-gymnasium-schongau' 
  AND is_school = true
")


# Update oldest school (slug: 87435-allgaeu-gymnasium-kempten) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.allgaeu-gymnasium.de',
              phone_number = '+49 831 74582200',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '87435-allgaeu-gymnasium-kempten' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Allgäu-Gymnasium Kempten (slug: allgau-gymnasium-kempten)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'allgau-gymnasium-kempten' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'allgau-gymnasium-kempten' 
  AND is_school = true
")


# Update oldest school (slug: 87435-realschule-an-der-salzstrasse-staatliche-realschule-kempten) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.staatliche-realschule-kempten.de',
              phone_number = '+49 831 74582100',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '87435-realschule-an-der-salzstrasse-staatliche-realschule-kempten' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Realschule an der Salzstraße Staatliche Realschule Kempten (slug: realschule-an-der-salzstrasse-staatliche-realschule-kempten)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'realschule-an-der-salzstrasse-staatliche-realschule-kempten' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'realschule-an-der-salzstrasse-staatliche-realschule-kempten' 
  AND is_school = true
")


# Update oldest school (slug: 87435-staatliche-fachoberschule-kempten-allgaeu) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fosbos-kempten.de',
              phone_number = '+49 831 25385410',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '87435-staatliche-fachoberschule-kempten-allgaeu' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Fachoberschule Kempten (Allgäu) (slug: staatliche-fachoberschule-kempten-allgau)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-fachoberschule-kempten-allgau' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-fachoberschule-kempten-allgau' 
  AND is_school = true
")


# Update oldest school (slug: 87439-hildegardis-gymnasium-kempten) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.hildegardis-gymnasium.de',
              phone_number = '+49 831 74582400',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '87439-hildegardis-gymnasium-kempten' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Hildegardis-Gymnasium Kempten (slug: hildegardis-gymnasium-kempten)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'hildegardis-gymnasium-kempten' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'hildegardis-gymnasium-kempten' 
  AND is_school = true
")


# Update oldest school (slug: 87439-carl-von-linde-gymnasium-kempten) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.cvl-kempten.de',
              phone_number = '+49 831 74582500',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '87439-carl-von-linde-gymnasium-kempten' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Carl-von-Linde-Gymnasium Kempten (slug: carl-von-linde-gymnasium-kempten)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'carl-von-linde-gymnasium-kempten' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'carl-von-linde-gymnasium-kempten' 
  AND is_school = true
")


# Update oldest school (slug: 87439-staedtische-realschule-kempten) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.die-staedtische.de',
              phone_number = '+49 831 74582300',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '87439-staedtische-realschule-kempten' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtische Realschule Kempten (slug: stadtische-realschule-kempten)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtische-realschule-kempten' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtische-realschule-kempten' 
  AND is_school = true
")


# Update oldest school (slug: 87439-maria-ward-schule-kempten-maedchenrealschule-d-schulwerks-d-dioezese) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.mw-kempten.de',
              phone_number = '+49 821 455814000',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '87439-maria-ward-schule-kempten-maedchenrealschule-d-schulwerks-d-dioezese' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Maria-Ward-Schule Kempten Mädchenrealschule d. Schulwerks d.Diözese Augsburg (slug: maria-ward-schule-kempten-madchenrealschule-d-schulwerks-d-diozese-augsburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'maria-ward-schule-kempten-madchenrealschule-d-schulwerks-d-diozese-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'maria-ward-schule-kempten-madchenrealschule-d-schulwerks-d-diozese-augsburg' 
  AND is_school = true
")


# Update oldest school (slug: 87509-maedchenrealschule-maria-stern-immenstadt-des-schulwerks-der-dioezese) with newest data
execute("
  UPDATE addresses 
  SET phone_number = '+49 821 455813800',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '87509-maedchenrealschule-maria-stern-immenstadt-des-schulwerks-der-dioezese' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Mädchenrealschule Maria Stern Immenstadt des Schulwerks der Diözese Augsburg (slug: madchenrealschule-maria-stern-immenstadt-des-schulwerks-der-diozese-augsburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'madchenrealschule-maria-stern-immenstadt-des-schulwerks-der-diozese-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'madchenrealschule-maria-stern-immenstadt-des-schulwerks-der-diozese-augsburg' 
  AND is_school = true
")


# Update oldest school (slug: 87509-staatliche-realschule-fuer-knaben-immenstadt) with newest data
execute("
  UPDATE addresses 
  SET phone_number = '+49 8323 99859100',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '87509-staatliche-realschule-fuer-knaben-immenstadt' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule für Knaben Immenstadt (slug: staatliche-realschule-fur-knaben-immenstadt)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-fur-knaben-immenstadt' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-fur-knaben-immenstadt' 
  AND is_school = true
")


# Update oldest school (slug: 87509-gymnasium-immenstadt) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-immenstadt.de',
              phone_number = '+49 8323 99859200',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '87509-gymnasium-immenstadt' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Immenstadt (slug: gymnasium-immenstadt)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-immenstadt' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-immenstadt' 
  AND is_school = true
")


# Update oldest school (slug: 87527-staatliche-realschule-sonthofen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.stareso.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '87527-staatliche-realschule-sonthofen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Sonthofen (slug: staatliche-realschule-sonthofen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-sonthofen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-sonthofen' 
  AND is_school = true
")


# Update oldest school (slug: 87527-gymnasium-sonthofen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-sonthofen.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '87527-gymnasium-sonthofen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Sonthofen (slug: gymnasium-sonthofen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-sonthofen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-sonthofen' 
  AND is_school = true
")


# Update oldest school (slug: 87600-marien-gymnasium-kaufbeuren-d-schulwerks-d-dioezese-augsburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.marien-gymnasium.de',
              phone_number = '+49 821 455811600',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '87600-marien-gymnasium-kaufbeuren-d-schulwerks-d-dioezese-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Marien-Gymnasium Kaufbeuren d. Schulwerks d. Diözese Augsburg (slug: marien-gymnasium-kaufbeuren-d-schulwerks-d-diozese-augsburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'marien-gymnasium-kaufbeuren-d-schulwerks-d-diozese-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'marien-gymnasium-kaufbeuren-d-schulwerks-d-diozese-augsburg' 
  AND is_school = true
")


# Update oldest school (slug: 87600-sophie-la-roche-realschule-staatl-realschule-kaufbeuren) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-kaufbeuren.de',
              phone_number = '+49 8341 993070',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '87600-sophie-la-roche-realschule-staatl-realschule-kaufbeuren' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Sophie-La-Roche-Realschule Staatl. Realschule Kaufbeuren (slug: sophie-la-roche-realschule-staatl-realschule-kaufbeuren)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'sophie-la-roche-realschule-staatl-realschule-kaufbeuren' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'sophie-la-roche-realschule-staatl-realschule-kaufbeuren' 
  AND is_school = true
")


# Update oldest school (slug: 87600-jakob-brucker-gymnasium-kaufbeuren) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.jakob-brucker-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '87600-jakob-brucker-gymnasium-kaufbeuren' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Jakob-Brucker-Gymnasium Kaufbeuren (slug: jakob-brucker-gymnasium-kaufbeuren)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'jakob-brucker-gymnasium-kaufbeuren' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'jakob-brucker-gymnasium-kaufbeuren' 
  AND is_school = true
")


# Update oldest school (slug: 87600-marien-realschule-kaufbeuren-d-schulwerks-d-dioezese-augsburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.marien-realschule-kaufbeuren.de',
              phone_number = '+49 821 455813900',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '87600-marien-realschule-kaufbeuren-d-schulwerks-d-dioezese-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Marien-Realschule Kaufbeuren d. Schulwerks d. Diözese Augsburg (slug: marien-realschule-kaufbeuren-d-schulwerks-d-diozese-augsburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'marien-realschule-kaufbeuren-d-schulwerks-d-diozese-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'marien-realschule-kaufbeuren-d-schulwerks-d-diozese-augsburg' 
  AND is_school = true
")


# Update oldest school (slug: 87616-gymnasium-marktoberdorf) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-marktoberdorf.de',
              phone_number = '+49 8342 96640',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '87616-gymnasium-marktoberdorf' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Marktoberdorf (slug: gymnasium-marktoberdorf)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-marktoberdorf' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-marktoberdorf' 
  AND is_school = true
")


# Update oldest school (slug: 87616-staatl-realschule-marktoberdorf) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.real-mod.de',
              phone_number = '+49 8342 895780',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '87616-staatl-realschule-marktoberdorf' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatl. Realschule Marktoberdorf (slug: staatl-realschule-marktoberdorf)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatl-realschule-marktoberdorf' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatl-realschule-marktoberdorf' 
  AND is_school = true
")


# Update oldest school (slug: 87629-johann-jakob-herkomer-schule-staatliche-realschule-fuessen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rsfuessen.de',
              phone_number = '+49 8362 925040',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '87629-johann-jakob-herkomer-schule-staatliche-realschule-fuessen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Johann-Jakob-Herkomer-Schule Staatliche Realschule Füssen (slug: johann-jakob-herkomer-schule-staatliche-realschule-fussen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'johann-jakob-herkomer-schule-staatliche-realschule-fussen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'johann-jakob-herkomer-schule-staatliche-realschule-fussen' 
  AND is_school = true
")


# Update oldest school (slug: 87629-gymnasium-fuessen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-fuessen.de',
              phone_number = '+49 8362 925200',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '87629-gymnasium-fuessen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Füssen (slug: gymnasium-fussen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-fussen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-fussen' 
  AND is_school = true
")


# Update oldest school (slug: 87634-staatliche-realschule-oberguenzburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rsobg.de',
              phone_number = '+49 8372 922330',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '87634-staatliche-realschule-oberguenzburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Obergünzburg (slug: staatliche-realschule-obergunzburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-obergunzburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-obergunzburg' 
  AND is_school = true
")


# Update oldest school (slug: 87645-gymnasium-hohenschwangau) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-hohenschwangau.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '87645-gymnasium-hohenschwangau' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Hohenschwangau (slug: gymnasium-hohenschwangau)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-hohenschwangau' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-hohenschwangau' 
  AND is_school = true
")


# Update oldest school (slug: 87700-staatliche-berufsoberschule-memmingen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fosbos-mm.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '87700-staatliche-berufsoberschule-memmingen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Berufsoberschule Memmingen (slug: staatliche-berufsoberschule-memmingen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-berufsoberschule-memmingen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-berufsoberschule-memmingen' 
  AND is_school = true
")


# Update oldest school (slug: 87700-bernhard-strigel-gymnasium-memmingen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.bsg-mm.de',
              phone_number = '+49 8331 7850530',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '87700-bernhard-strigel-gymnasium-memmingen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Bernhard-Strigel-Gymnasium Memmingen (slug: bernhard-strigel-gymnasium-memmingen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'bernhard-strigel-gymnasium-memmingen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'bernhard-strigel-gymnasium-memmingen' 
  AND is_school = true
")


# Update oldest school (slug: 87700-voehlin-gymnasium-memmingen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.voehlin.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '87700-voehlin-gymnasium-memmingen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Vöhlin-Gymnasium Memmingen (slug: vohlin-gymnasium-memmingen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'vohlin-gymnasium-memmingen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'vohlin-gymnasium-memmingen' 
  AND is_school = true
")


# Update oldest school (slug: 87719-maria-ward-realschule-mindelheim-des-schulwerks-der-dioezese-augsburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.maria-ward-realschule-mindelheim.de',
              phone_number = '+49 821 455814500',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '87719-maria-ward-realschule-mindelheim-des-schulwerks-der-dioezese-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Maria-Ward-Realschule Mindelheim des Schulwerks der Diözese Augsburg (slug: maria-ward-realschule-mindelheim-des-schulwerks-der-diozese-augsburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'maria-ward-realschule-mindelheim-des-schulwerks-der-diozese-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'maria-ward-realschule-mindelheim-des-schulwerks-der-diozese-augsburg' 
  AND is_school = true
")


# Update oldest school (slug: 87724-rupert-ness-gymnasium-ottobeuren) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gym-rs-ottobeuren.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '87724-rupert-ness-gymnasium-ottobeuren' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Rupert-Ness-Gymnasium Ottobeuren (slug: rupert-ness-gymnasium-ottobeuren)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'rupert-ness-gymnasium-ottobeuren' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'rupert-ness-gymnasium-ottobeuren' 
  AND is_school = true
")


# Update oldest school (slug: 87740-marianum-buxheim-gymnasium-des-schulwerks-der-dioezese-augsburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.marianum.info',
              phone_number = '+49 821 455811200',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '87740-marianum-buxheim-gymnasium-des-schulwerks-der-dioezese-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Marianum Buxheim Gymnasium des Schulwerks der Diözese Augsburg (slug: marianum-buxheim-gymnasium-des-schulwerks-der-diozese-augsburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'marianum-buxheim-gymnasium-des-schulwerks-der-diozese-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'marianum-buxheim-gymnasium-des-schulwerks-der-diozese-augsburg' 
  AND is_school = true
")


# Update oldest school (slug: 88131-bodensee-gymnasium-lindau) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.bodensee-gymnasium.de',
              phone_number = '+49 8382 93600',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '88131-bodensee-gymnasium-lindau' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Bodensee-Gymnasium Lindau (slug: bodensee-gymnasium-lindau)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'bodensee-gymnasium-lindau' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'bodensee-gymnasium-lindau' 
  AND is_school = true
")


# Update oldest school (slug: 88131-staatliche-fachoberschule-lindau-bodensee) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.bsz-lindau.de',
              phone_number = '+49 8382 9479471',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '88131-staatliche-fachoberschule-lindau-bodensee' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Fachoberschule Lindau (Bodensee) (slug: staatliche-fachoberschule-lindau-bodensee)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-fachoberschule-lindau-bodensee' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-fachoberschule-lindau-bodensee' 
  AND is_school = true
")


# Update oldest school (slug: 88131-volksschule-lindau-43b77450-b970-11e7-944e-001ec9cdab18) with newest data
execute("
  UPDATE addresses 
  SET phone_number = '+49 8382 975264',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '88131-volksschule-lindau-43b77450-b970-11e7-944e-001ec9cdab18' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Volksschule Lindau (slug: 88131-volksschule-lindau-4a1e9670-b970-11e7-8ed0-001ec9cdab18)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '88131-volksschule-lindau-4a1e9670-b970-11e7-8ed0-001ec9cdab18' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = '88131-volksschule-lindau-4a1e9670-b970-11e7-8ed0-001ec9cdab18' 
  AND is_school = true
")


# Update oldest school (slug: 88131-valentin-heider-gymnasium-lindau) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.vhg-lindau.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '88131-valentin-heider-gymnasium-lindau' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Valentin-Heider-Gymnasium Lindau (slug: valentin-heider-gymnasium-lindau)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'valentin-heider-gymnasium-lindau' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'valentin-heider-gymnasium-lindau' 
  AND is_school = true
")


# Update oldest school (slug: 88161-staatliche-realschule-lindenberg-i-allgaeu) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rslin.de',
              phone_number = '+49 8381 890990',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '88161-staatliche-realschule-lindenberg-i-allgaeu' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Lindenberg i.Allgäu (slug: staatliche-realschule-lindenberg-i-allgau)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-lindenberg-i-allgau' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-lindenberg-i-allgau' 
  AND is_school = true
")


# Update oldest school (slug: 88161-gymnasium-lindenberg-i-allgaeu) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymlindenberg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '88161-gymnasium-lindenberg-i-allgaeu' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Lindenberg i.Allgäu (slug: gymnasium-lindenberg-i-allgau)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-lindenberg-i-allgau' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-lindenberg-i-allgau' 
  AND is_school = true
")


# No updates needed for school slug: 88400-sonderpaedagogisches-bildungs-und-beratungszentrum-mit-dem-faerdersc-40d052e8-b970-11e7-9ce3-001ec9cdab18
# Delete duplicate school: Sonderpädagogisches Bildungs- und Beratungszentrum mit dem Färderschwerpunkt Kärperliche und motorische Entwicklung (slug: 88400-sonderpaedagogisches-bildungs-und-beratungszentrum-mit-dem-faerdersc-40d0e9a6-b970-11e7-83ec-001ec9cdab18)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '88400-sonderpaedagogisches-bildungs-und-beratungszentrum-mit-dem-faerdersc-40d0e9a6-b970-11e7-83ec-001ec9cdab18' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = '88400-sonderpaedagogisches-bildungs-und-beratungszentrum-mit-dem-faerdersc-40d0e9a6-b970-11e7-83ec-001ec9cdab18' 
  AND is_school = true
")


# Update oldest school (slug: 89231-lessing-gymnasium-neu-ulm) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.lessing.schule.neu-ulm.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '89231-lessing-gymnasium-neu-ulm' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Lessing-Gymnasium Neu-Ulm (slug: lessing-gymnasium-neu-ulm)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'lessing-gymnasium-neu-ulm' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'lessing-gymnasium-neu-ulm' 
  AND is_school = true
")


# Update oldest school (slug: 89231-staatliche-fachoberschule-neu-ulm) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fosbos.neu-ulm.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '89231-staatliche-fachoberschule-neu-ulm' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Fachoberschule Neu-Ulm (slug: staatliche-fachoberschule-neu-ulm)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-fachoberschule-neu-ulm' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-fachoberschule-neu-ulm' 
  AND is_school = true
")


# Update oldest school (slug: 89231-staatliche-berufsoberschule-neu-ulm) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fosbos.neu-ulm.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '89231-staatliche-berufsoberschule-neu-ulm' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Berufsoberschule Neu-Ulm (slug: staatliche-berufsoberschule-neu-ulm)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-berufsoberschule-neu-ulm' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-berufsoberschule-neu-ulm' 
  AND is_school = true
")


# Update oldest school (slug: 89231-christoph-probst-realschule-staatliche-realschule-neu-ulm) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rsnu.de',
              phone_number = '+49 731 1763930',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '89231-christoph-probst-realschule-staatliche-realschule-neu-ulm' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Christoph-Probst-Realschule Staatliche Realschule Neu-Ulm (slug: christoph-probst-realschule-staatliche-realschule-neu-ulm)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'christoph-probst-realschule-staatliche-realschule-neu-ulm' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'christoph-probst-realschule-staatliche-realschule-neu-ulm' 
  AND is_school = true
")


# Update oldest school (slug: 89233-bertha-von-suttner-gymnasium-neu-ulm) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.bvsg-nu.info',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '89233-bertha-von-suttner-gymnasium-neu-ulm' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Bertha-von-Suttner-Gymnasium Neu-Ulm (slug: bertha-von-suttner-gymnasium-neu-ulm)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'bertha-von-suttner-gymnasium-neu-ulm' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'bertha-von-suttner-gymnasium-neu-ulm' 
  AND is_school = true
")


# Update oldest school (slug: 89264-staedtische-realschule-weissenhorn) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-weissenhorn.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '89264-staedtische-realschule-weissenhorn' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtische Realschule Weißenhorn (slug: stadtische-realschule-weissenhorn)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtische-realschule-weissenhorn' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtische-realschule-weissenhorn' 
  AND is_school = true
")


# Update oldest school (slug: 89264-nikolaus-kopernikus-gymnasium-weissenhorn) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-weissenhorn.de',
              phone_number = '+49 7309 96460',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '89264-nikolaus-kopernikus-gymnasium-weissenhorn' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Nikolaus-Kopernikus-Gymnasium Weißenhorn (slug: nikolaus-kopernikus-gymnasium-weissenhorn)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'nikolaus-kopernikus-gymnasium-weissenhorn' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'nikolaus-kopernikus-gymnasium-weissenhorn' 
  AND is_school = true
")


# Update oldest school (slug: 89269-illertal-gymnasium-voehringen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.illertal-gymnasium.de',
              phone_number = '+49 7307 921440',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '89269-illertal-gymnasium-voehringen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Illertal-Gymnasium Vöhringen (slug: illertal-gymnasium-vohringen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'illertal-gymnasium-vohringen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'illertal-gymnasium-vohringen' 
  AND is_school = true
")


# Update oldest school (slug: 89312-maria-ward-gymnasium-guenzburg-d-schulwerks-d-dioezese-augsburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.mwg-gz.de',
              phone_number = '+49 821 455811400',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '89312-maria-ward-gymnasium-guenzburg-d-schulwerks-d-dioezese-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Maria-Ward-Gymnasium Günzburg d. Schulwerks d. Diözese Augsburg (slug: maria-ward-gymnasium-gunzburg-d-schulwerks-d-diozese-augsburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'maria-ward-gymnasium-gunzburg-d-schulwerks-d-diozese-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'maria-ward-gymnasium-gunzburg-d-schulwerks-d-diozese-augsburg' 
  AND is_school = true
")


# Update oldest school (slug: 89312-maria-ward-realschule-guenzburg-des-schulwerks-der-dioezese-augsburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.mwrs-gz.de',
              phone_number = '+49 821 455813700',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '89312-maria-ward-realschule-guenzburg-des-schulwerks-der-dioezese-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Maria-Ward-Realschule Günzburg des Schulwerks der Diözese Augsburg (slug: maria-ward-realschule-gunzburg-des-schulwerks-der-diozese-augsburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'maria-ward-realschule-gunzburg-des-schulwerks-der-diozese-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'maria-ward-realschule-gunzburg-des-schulwerks-der-diozese-augsburg' 
  AND is_school = true
")


# Update oldest school (slug: 89312-dossenberger-gymnasium-guenzburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.dossenberger.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '89312-dossenberger-gymnasium-guenzburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Dossenberger-Gymnasium Günzburg (slug: dossenberger-gymnasium-gunzburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'dossenberger-gymnasium-gunzburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'dossenberger-gymnasium-gunzburg' 
  AND is_school = true
")


# No updates needed for school slug: 89331-markgrafen-realschule-staatliche-realschule-burgau
# Delete duplicate school: Markgrafen-Realschule Staatliche Realschule Burgau (slug: markgrafen-realschule-staatliche-realschule-burgau)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'markgrafen-realschule-staatliche-realschule-burgau' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'markgrafen-realschule-staatliche-realschule-burgau' 
  AND is_school = true
")


# Update oldest school (slug: 89358-st-thomas-gymnasium-wettenhausen-d-schulwerks-d-dioezese-augsburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.thomas-gymnasium.de',
              phone_number = '+49 821 455812100',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '89358-st-thomas-gymnasium-wettenhausen-d-schulwerks-d-dioezese-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: St.-Thomas-Gymnasium Wettenhausen d. Schulwerks d. Diözese Augsburg (slug: st-thomas-gymnasium-wettenhausen-d-schulwerks-d-diozese-augsburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'st-thomas-gymnasium-wettenhausen-d-schulwerks-d-diozese-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'st-thomas-gymnasium-wettenhausen-d-schulwerks-d-diozese-augsburg' 
  AND is_school = true
")


# Update oldest school (slug: 89407-johann-michael-sailer-gymnasium-dillingen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.sailer-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '89407-johann-michael-sailer-gymnasium-dillingen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Johann-Michael-Sailer-Gymnasium Dillingen (slug: johann-michael-sailer-gymnasium-dillingen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'johann-michael-sailer-gymnasium-dillingen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'johann-michael-sailer-gymnasium-dillingen' 
  AND is_school = true
")


# Update oldest school (slug: 89407-st-bonaventura-realschule-dillingen-des-schulwerks-der-dioezese-aug) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.bonareal.de',
              phone_number = '+49 821 455813400',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '89407-st-bonaventura-realschule-dillingen-des-schulwerks-der-dioezese-aug' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: St. Bonaventura-Realschule Dillingen des Schulwerks der Diözese Augsburg (slug: st-bonaventura-realschule-dillingen-des-schulwerks-der-diozese-augsburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'st-bonaventura-realschule-dillingen-des-schulwerks-der-diozese-augsburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'st-bonaventura-realschule-dillingen-des-schulwerks-der-diozese-augsburg' 
  AND is_school = true
")


# Update oldest school (slug: 89415-albertus-gymnasium-lauingen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.albertus-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '89415-albertus-gymnasium-lauingen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Albertus-Gymnasium Lauingen (slug: albertus-gymnasium-lauingen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'albertus-gymnasium-lauingen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'albertus-gymnasium-lauingen' 
  AND is_school = true
")


# Update oldest school (slug: 90403-willstaetter-gymnasium-nuernberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.willstaetter-gymnasium.de',
              phone_number = '+49 911 2312311',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '90403-willstaetter-gymnasium-nuernberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Willstätter-Gymnasium Nürnberg (slug: willstatter-gymnasium-nurnberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'willstatter-gymnasium-nurnberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'willstatter-gymnasium-nurnberg' 
  AND is_school = true
")


# Update oldest school (slug: 90408-staedtische-fachoberschule-nuernberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.bon.nuernberg.de/',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '90408-staedtische-fachoberschule-nuernberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtische Fachoberschule Nürnberg (slug: stadtische-fachoberschule-nurnberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtische-fachoberschule-nurnberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtische-fachoberschule-nurnberg' 
  AND is_school = true
")


# Update oldest school (slug: 90409-hans-sachs-gymnasium-nuernberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.hans-sachs-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '90409-hans-sachs-gymnasium-nuernberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Hans-Sachs-Gymnasium Nürnberg (slug: hans-sachs-gymnasium-nurnberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'hans-sachs-gymnasium-nurnberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'hans-sachs-gymnasium-nurnberg' 
  AND is_school = true
")


# Update oldest school (slug: 90409-staedtisches-labenwolf-gymnasium-nuernberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.labenwolf.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '90409-staedtisches-labenwolf-gymnasium-nuernberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtisches Labenwolf-Gymnasium Nürnberg (slug: stadtisches-labenwolf-gymnasium-nurnberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtisches-labenwolf-gymnasium-nurnberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtisches-labenwolf-gymnasium-nurnberg' 
  AND is_school = true
")


# Update oldest school (slug: 90411-lothar-von-faber-schule-staatliche-fachoberschule-nuernberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fos-n.de',
              phone_number = '+49 911 23133530',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '90411-lothar-von-faber-schule-staatliche-fachoberschule-nuernberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Lothar-von-Faber-Schule Staatliche Fachoberschule Nürnberg (slug: lothar-von-faber-schule-staatliche-fachoberschule-nurnberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'lothar-von-faber-schule-staatliche-fachoberschule-nurnberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'lothar-von-faber-schule-staatliche-fachoberschule-nurnberg' 
  AND is_school = true
")


# Update oldest school (slug: 90429-geschwister-scholl-realschule-staatl-realschule-nuernberg-ii) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gsr-nuernberg.de',
              phone_number = '+49 911 23127320',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '90429-geschwister-scholl-realschule-staatl-realschule-nuernberg-ii' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Geschwister-Scholl-Realschule Staatl. Realschule Nürnberg II (slug: geschwister-scholl-realschule-staatl-realschule-nurnberg-ii)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'geschwister-scholl-realschule-staatl-realschule-nurnberg-ii' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'geschwister-scholl-realschule-staatl-realschule-nurnberg-ii' 
  AND is_school = true
")


# Update oldest school (slug: 90429-duerer-gymnasium-nuernberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.duerer-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '90429-duerer-gymnasium-nuernberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Dürer-Gymnasium Nürnberg (slug: durer-gymnasium-nurnberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'durer-gymnasium-nurnberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'durer-gymnasium-nurnberg' 
  AND is_school = true
")


# Update oldest school (slug: 90443-staedtisches-sigena-gymnasium-nuernberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.nuernberg.de/internet/sigena_gymnasium/',
              phone_number = '+49 911 2317229',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '90443-staedtisches-sigena-gymnasium-nuernberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtisches Sigena-Gymnasium Nürnberg (slug: stadtisches-sigena-gymnasium-nurnberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtisches-sigena-gymnasium-nurnberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtisches-sigena-gymnasium-nurnberg' 
  AND is_school = true
")


# Update oldest school (slug: 90443-pirckheimer-gymnasium-nuernberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.pirckheimer-gymnasium.de',
              phone_number = '+49 911 23114033',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '90443-pirckheimer-gymnasium-nuernberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Pirckheimer-Gymnasium Nürnberg (slug: pirckheimer-gymnasium-nurnberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'pirckheimer-gymnasium-nurnberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'pirckheimer-gymnasium-nurnberg' 
  AND is_school = true
")


# Update oldest school (slug: 90451-peter-henlein-realschule-staatl-realschule-nuernberg-i) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.peter-henlein-realschule.de',
              phone_number = '+49 911 23168150',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '90451-peter-henlein-realschule-staatl-realschule-nuernberg-i' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Peter-Henlein-Realschule Staatl. Realschule Nürnberg I (slug: peter-henlein-realschule-staatl-realschule-nurnberg-i)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'peter-henlein-realschule-staatl-realschule-nurnberg-i' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'peter-henlein-realschule-staatl-realschule-nurnberg-i' 
  AND is_school = true
")


# Update oldest school (slug: 90451-sigmund-schuckert-gymnasium-nuernberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.sigmund-schuckert-gymnasium.de',
              phone_number = '+49 911 23168040',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '90451-sigmund-schuckert-gymnasium-nuernberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Sigmund-Schuckert-Gymnasium Nürnberg (slug: sigmund-schuckert-gymnasium-nurnberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'sigmund-schuckert-gymnasium-nurnberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'sigmund-schuckert-gymnasium-nurnberg' 
  AND is_school = true
")


# Update oldest school (slug: 90459-staedtische-adam-kraft-realschule-nuernberg) with newest data
execute("
  UPDATE addresses 
  SET phone_number = '+49 911 23110740',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '90459-staedtische-adam-kraft-realschule-nuernberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtische Adam-Kraft-Realschule Nürnberg (slug: stadtische-adam-kraft-realschule-nurnberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtische-adam-kraft-realschule-nurnberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtische-adam-kraft-realschule-nurnberg' 
  AND is_school = true
")


# Update oldest school (slug: 90478-neues-gymnasium-nuernberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.ngn-online.de',
              phone_number = '+49 911 23114230',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '90478-neues-gymnasium-nuernberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Neues Gymnasium Nürnberg (slug: neues-gymnasium-nurnberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'neues-gymnasium-nurnberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'neues-gymnasium-nurnberg' 
  AND is_school = true
")


# Update oldest school (slug: 90489-melanchthon-gymnasium-nuernberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.melanchthon-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '90489-melanchthon-gymnasium-nuernberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Melanchthon-Gymnasium Nürnberg (slug: melanchthon-gymnasium-nurnberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'melanchthon-gymnasium-nurnberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'melanchthon-gymnasium-nurnberg' 
  AND is_school = true
")


# Update oldest school (slug: 90491-staedtische-veit-stoss-realschule-nuernberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.kubiss.de/vsr',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '90491-staedtische-veit-stoss-realschule-nuernberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtische Veit-Stoß-Realschule Nürnberg (slug: stadtische-veit-stoss-realschule-nurnberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtische-veit-stoss-realschule-nurnberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtische-veit-stoss-realschule-nurnberg' 
  AND is_school = true
")


# Update oldest school (slug: 90491-staedtische-abendrealschule-an-der-veit-stoss-realschule-nuernberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.abendrealschule-nbg.de',
              phone_number = '+49 911 2313956',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '90491-staedtische-abendrealschule-an-der-veit-stoss-realschule-nuernberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtische Abendrealschule an der Veit-Stoß-Realschule Nürnberg (slug: stadtische-abendrealschule-an-der-veit-stoss-realschule-nurnberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtische-abendrealschule-an-der-veit-stoss-realschule-nurnberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtische-abendrealschule-an-der-veit-stoss-realschule-nurnberg' 
  AND is_school = true
")


# Update oldest school (slug: 90513-staatliche-realschule-zirndorf) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rs-zirndorf.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '90513-staatliche-realschule-zirndorf' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Zirndorf (slug: staatliche-realschule-zirndorf)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-zirndorf' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-zirndorf' 
  AND is_school = true
")


# Update oldest school (slug: 90518-leibniz-gymnasium-altdorf) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.leibniz-gymnasium-altdorf.de',
              phone_number = '+49 9187 409150',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '90518-leibniz-gymnasium-altdorf' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Leibniz-Gymnasium Altdorf (slug: leibniz-gymnasium-altdorf)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'leibniz-gymnasium-altdorf' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'leibniz-gymnasium-altdorf' 
  AND is_school = true
")


# Update oldest school (slug: 90530-volksschule-wendelstein) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.ms-wendelstein.de',
              phone_number = '+49 9129 401165',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '90530-volksschule-wendelstein' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Volksschule Wendelstein (slug: 90530-volksschule-wendelstein-49f4e6ae-b970-11e7-b054-001ec9cdab18)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '90530-volksschule-wendelstein-49f4e6ae-b970-11e7-b054-001ec9cdab18' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = '90530-volksschule-wendelstein-49f4e6ae-b970-11e7-b054-001ec9cdab18' 
  AND is_school = true
")


# No updates needed for school slug: 90537-staatliche-realschule-feucht
# Delete duplicate school: Staatliche Realschule Feucht (slug: staatliche-realschule-feucht)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-feucht' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-feucht' 
  AND is_school = true
")


# Update oldest school (slug: 90542-gymnasium-eckental) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-eckental.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '90542-gymnasium-eckental' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Eckental (slug: gymnasium-eckental)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-eckental' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-eckental' 
  AND is_school = true
")


# Update oldest school (slug: 90547-gymnasium-stein) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-stein.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '90547-gymnasium-stein' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Stein (slug: gymnasium-stein)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-stein' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-stein' 
  AND is_school = true
")


# Update oldest school (slug: 90552-geschwister-scholl-gymnasium-roethenbach-a-d-pegnitz) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gsgym.bayern',
              phone_number = '+49 911 3073920',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '90552-geschwister-scholl-gymnasium-roethenbach-a-d-pegnitz' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Geschwister-Scholl-Gymnasium Röthenbach a.d.Pegnitz (slug: geschwister-scholl-gymnasium-rothenbach-a-d-pegnitz)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'geschwister-scholl-gymnasium-rothenbach-a-d-pegnitz' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'geschwister-scholl-gymnasium-rothenbach-a-d-pegnitz' 
  AND is_school = true
")


# Update oldest school (slug: 90579-wolfgang-borchert-gymnasium-langenzenn) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.wbg-lgz.de',
              phone_number = '+49 9101 904180',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '90579-wolfgang-borchert-gymnasium-langenzenn' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Wolfgang-Borchert-Gymnasium Langenzenn (slug: wolfgang-borchert-gymnasium-langenzenn)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'wolfgang-borchert-gymnasium-langenzenn' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'wolfgang-borchert-gymnasium-langenzenn' 
  AND is_school = true
")


# Update oldest school (slug: 90762-helene-lange-gymnasium-fuerth) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.hlg-fuerth.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '90762-helene-lange-gymnasium-fuerth' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Helene-Lange-Gymnasium Fürth (slug: helene-lange-gymnasium-furth)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'helene-lange-gymnasium-furth' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'helene-lange-gymnasium-furth' 
  AND is_school = true
")


# Update oldest school (slug: 90762-heinrich-schliemann-gymnasium-fuerth) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.schliemann-gym.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '90762-heinrich-schliemann-gymnasium-fuerth' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Heinrich-Schliemann-Gymnasium Fürth (slug: heinrich-schliemann-gymnasium-furth)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'heinrich-schliemann-gymnasium-furth' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'heinrich-schliemann-gymnasium-furth' 
  AND is_school = true
")


# Update oldest school (slug: 90762-volksschule-fuerth-maistrasse) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.ms-otto-seeling.de',
              phone_number = '+49 911 9742141',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '90762-volksschule-fuerth-maistrasse' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Volksschule Fürth, Maistraße (slug: 90762-volksschule-fuerth-maistrasse-49e78784-b970-11e7-8294-001ec9cdab18)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '90762-volksschule-fuerth-maistrasse-49e78784-b970-11e7-8294-001ec9cdab18' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = '90762-volksschule-fuerth-maistrasse-49e78784-b970-11e7-8294-001ec9cdab18' 
  AND is_school = true
")


# Update oldest school (slug: 90763-hans-boeckler-schule-staedt-realschule-fuerth) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.hans-boeckler-schule.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '90763-hans-boeckler-schule-staedt-realschule-fuerth' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Hans-Böckler-Schule Städt. Realschule Fürth (slug: hans-bockler-schule-stadt-realschule-furth)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'hans-bockler-schule-stadt-realschule-furth' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'hans-bockler-schule-stadt-realschule-furth' 
  AND is_school = true
")


# Update oldest school (slug: 90763-hardenberg-gymnasium-fuerth) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.hardenberg-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '90763-hardenberg-gymnasium-fuerth' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Hardenberg-Gymnasium Fürth (slug: hardenberg-gymnasium-furth)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'hardenberg-gymnasium-furth' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'hardenberg-gymnasium-furth' 
  AND is_school = true
")


# Update oldest school (slug: 91052-ohm-gymnasium-erlangen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.ohm-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91052-ohm-gymnasium-erlangen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Ohm-Gymnasium Erlangen (slug: ohm-gymnasium-erlangen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'ohm-gymnasium-erlangen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'ohm-gymnasium-erlangen' 
  AND is_school = true
")


# Update oldest school (slug: 91054-staedtisches-marie-therese-gymnasium-erlangen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.mtg-erlangen.de',
              phone_number = '+49 9131 401430',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91054-staedtisches-marie-therese-gymnasium-erlangen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtisches Marie-Therese-Gymnasium Erlangen (slug: stadtisches-marie-therese-gymnasium-erlangen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtisches-marie-therese-gymnasium-erlangen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtisches-marie-therese-gymnasium-erlangen' 
  AND is_school = true
")


# Update oldest school (slug: 91054-christian-ernst-gymnasium-erlangen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.ceg-erlangen.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91054-christian-ernst-gymnasium-erlangen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Christian-Ernst-Gymnasium Erlangen (slug: christian-ernst-gymnasium-erlangen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'christian-ernst-gymnasium-erlangen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'christian-ernst-gymnasium-erlangen' 
  AND is_school = true
")


# Update oldest school (slug: 91056-realschule-am-europakanal-staatliche-realschule-erlangen-ii) with newest data
execute("
  UPDATE addresses 
  SET phone_number = '+49 9131 402130',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91056-realschule-am-europakanal-staatliche-realschule-erlangen-ii' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Realschule am Europakanal Staatliche Realschule Erlangen II (slug: realschule-am-europakanal-staatliche-realschule-erlangen-ii)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'realschule-am-europakanal-staatliche-realschule-erlangen-ii' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'realschule-am-europakanal-staatliche-realschule-erlangen-ii' 
  AND is_school = true
")


# Update oldest school (slug: 91056-albert-schweitzer-gymnasium-erlangen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.asg-er.de',
              phone_number = '+49 9131 5332440',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91056-albert-schweitzer-gymnasium-erlangen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Albert-Schweitzer-Gymnasium Erlangen (slug: albert-schweitzer-gymnasium-erlangen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'albert-schweitzer-gymnasium-erlangen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'albert-schweitzer-gymnasium-erlangen' 
  AND is_school = true
")


# Update oldest school (slug: 91058-werner-von-siemens-realschule-staatliche-realschule-erlangen-i) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.wvs-er.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91058-werner-von-siemens-realschule-staatliche-realschule-erlangen-i' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Werner-von-Siemens-Realschule Staatliche Realschule Erlangen I (slug: werner-von-siemens-realschule-staatliche-realschule-erlangen-i)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'werner-von-siemens-realschule-staatliche-realschule-erlangen-i' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'werner-von-siemens-realschule-staatliche-realschule-erlangen-i' 
  AND is_school = true
")


# Update oldest school (slug: 91058-gymnasium-fridericianum-erlangen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-fridericianum.de',
              phone_number = '+49 9131 687080',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91058-gymnasium-fridericianum-erlangen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Fridericianum Erlangen (slug: gymnasium-fridericianum-erlangen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-fridericianum-erlangen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-fridericianum-erlangen' 
  AND is_school = true
")


# Update oldest school (slug: 91074-gymnasium-herzogenaurach) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-herzogenaurach.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91074-gymnasium-herzogenaurach' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Herzogenaurach (slug: gymnasium-herzogenaurach)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-herzogenaurach' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-herzogenaurach' 
  AND is_school = true
")


# Update oldest school (slug: 91074-staatliche-realschule-herzogenaurach) with newest data
execute("
  UPDATE addresses 
  SET phone_number = '+49 9132 750390',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91074-staatliche-realschule-herzogenaurach' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Herzogenaurach (slug: staatliche-realschule-herzogenaurach)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-herzogenaurach' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-herzogenaurach' 
  AND is_school = true
")


# Update oldest school (slug: 91080-emil-von-behring-gymnasium-spardorf) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.evbg.de',
              phone_number = '+49 9131 53690',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91080-emil-von-behring-gymnasium-spardorf' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Emil-von-Behring-Gymnasium Spardorf (slug: emil-von-behring-gymnasium-spardorf)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'emil-von-behring-gymnasium-spardorf' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'emil-von-behring-gymnasium-spardorf' 
  AND is_school = true
")


# Update oldest school (slug: 91126-adam-kraft-gymnasium-schwabach) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.akg-schwabach.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91126-adam-kraft-gymnasium-schwabach' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Adam-Kraft-Gymnasium Schwabach (slug: adam-kraft-gymnasium-schwabach)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'adam-kraft-gymnasium-schwabach' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'adam-kraft-gymnasium-schwabach' 
  AND is_school = true
")


# No updates needed for school slug: 91126-wolfram-von-eschenbach-gymnasium-schwabach
# Delete duplicate school: Wolfram-von-Eschenbach-Gymnasium Schwabach (slug: wolfram-von-eschenbach-gymnasium-schwabach)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'wolfram-von-eschenbach-gymnasium-schwabach' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'wolfram-von-eschenbach-gymnasium-schwabach' 
  AND is_school = true
")


# Update oldest school (slug: 91154-gymnasium-roth) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-roth.de',
              phone_number = '+49 9171 968460',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91154-gymnasium-roth' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Roth (slug: gymnasium-roth)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-roth' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-roth' 
  AND is_school = true
")


# Update oldest school (slug: 91161-gymnasium-hilpoltstein) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gym-hip.de',
              phone_number = '+49 9171 817730',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91161-gymnasium-hilpoltstein' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Hilpoltstein (slug: gymnasium-hilpoltstein)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-hilpoltstein' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-hilpoltstein' 
  AND is_school = true
")


# Update oldest school (slug: 91161-staatliche-realschule-hilpoltstein) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rea-hip.de',
              phone_number = '+49 9171 817000',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91161-staatliche-realschule-hilpoltstein' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Hilpoltstein (slug: staatliche-realschule-hilpoltstein)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-hilpoltstein' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-hilpoltstein' 
  AND is_school = true
")


# Update oldest school (slug: 91207-christoph-jacob-treu-gymnasium-lauf-a-d-pegnitz) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.cjt-gym-lauf.de',
              phone_number = '+49 9123 942880',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91207-christoph-jacob-treu-gymnasium-lauf-a-d-pegnitz' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Christoph-Jacob-Treu-Gymnasium Lauf a.d.Pegnitz (slug: christoph-jacob-treu-gymnasium-lauf-a-d-pegnitz)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'christoph-jacob-treu-gymnasium-lauf-a-d-pegnitz' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'christoph-jacob-treu-gymnasium-lauf-a-d-pegnitz' 
  AND is_school = true
")


# Update oldest school (slug: 91207-oskar-sembach-realschule-staatl-realschule-lauf-a-d-pegnitz) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-lauf.de',
              phone_number = '+49 9123 966460',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91207-oskar-sembach-realschule-staatl-realschule-lauf-a-d-pegnitz' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Oskar-Sembach-Realschule Staatl. Realschule Lauf a.d.Pegnitz (slug: oskar-sembach-realschule-staatl-realschule-lauf-a-d-pegnitz)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'oskar-sembach-realschule-staatl-realschule-lauf-a-d-pegnitz' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'oskar-sembach-realschule-staatl-realschule-lauf-a-d-pegnitz' 
  AND is_school = true
")


# Update oldest school (slug: 91217-johannes-scharrer-realschule-staatliche-realschule-hersbruck) with newest data
execute("
  UPDATE addresses 
  SET phone_number = '+49 9151 8390270',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91217-johannes-scharrer-realschule-staatliche-realschule-hersbruck' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Johannes-Scharrer-Realschule Staatliche Realschule Hersbruck (slug: johannes-scharrer-realschule-staatliche-realschule-hersbruck)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'johannes-scharrer-realschule-staatliche-realschule-hersbruck' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'johannes-scharrer-realschule-staatliche-realschule-hersbruck' 
  AND is_school = true
")


# Update oldest school (slug: 91217-paul-pfinzing-gymnasium-hersbruck) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-hersbruck.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91217-paul-pfinzing-gymnasium-hersbruck' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Paul-Pfinzing-Gymnasium Hersbruck (slug: paul-pfinzing-gymnasium-hersbruck)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'paul-pfinzing-gymnasium-hersbruck' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'paul-pfinzing-gymnasium-hersbruck' 
  AND is_school = true
")


# Update oldest school (slug: 91257-gymnasium-pegnitz) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gympeg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91257-gymnasium-pegnitz' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Pegnitz (slug: gymnasium-pegnitz)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-pegnitz' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-pegnitz' 
  AND is_school = true
")


# Update oldest school (slug: 91257-staatliche-realschule-pegnitz) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rspegnitz.de',
              phone_number = '+49 9241 489270',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91257-staatliche-realschule-pegnitz' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Pegnitz (slug: staatliche-realschule-pegnitz)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-pegnitz' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-pegnitz' 
  AND is_school = true
")


# Update oldest school (slug: 91275-realschule-des-zweckverbandes-auerbach) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-auerbach.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91275-realschule-des-zweckverbandes-auerbach' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Realschule des Zweckverbandes Auerbach (slug: realschule-des-zweckverbandes-auerbach)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'realschule-des-zweckverbandes-auerbach' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'realschule-des-zweckverbandes-auerbach' 
  AND is_school = true
")


# Update oldest school (slug: 91301-ehrenbuerg-gymnasium-forchheim) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.egf-online.de',
              phone_number = '+49 9191 70010',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91301-ehrenbuerg-gymnasium-forchheim' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Ehrenbürg-Gymnasium Forchheim (slug: ehrenburg-gymnasium-forchheim)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'ehrenburg-gymnasium-forchheim' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'ehrenburg-gymnasium-forchheim' 
  AND is_school = true
")


# Update oldest school (slug: 91301-staatl-fachoberschule-forchheim) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.bszfo.de/fachoberschule',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91301-staatl-fachoberschule-forchheim' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatl. Fachoberschule Forchheim (slug: staatl-fachoberschule-forchheim)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatl-fachoberschule-forchheim' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatl-fachoberschule-forchheim' 
  AND is_school = true
")


# Update oldest school (slug: 91301-herder-gymnasium-forchheim) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.herder-forchheim.de',
              phone_number = '+49 9191 70990',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91301-herder-gymnasium-forchheim' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Herder-Gymnasium Forchheim (slug: herder-gymnasium-forchheim)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'herder-gymnasium-forchheim' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'herder-gymnasium-forchheim' 
  AND is_school = true
")


# Update oldest school (slug: 91315-staatl-realschule-hoechstadt-a-d-aisch) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-hoechstadt.de',
              phone_number = '+49 9193 508190',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91315-staatl-realschule-hoechstadt-a-d-aisch' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatl. Realschule Höchstadt a.d.Aisch (slug: staatl-realschule-hochstadt-a-d-aisch)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatl-realschule-hochstadt-a-d-aisch' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatl-realschule-hochstadt-a-d-aisch' 
  AND is_school = true
")


# Update oldest school (slug: 91315-gymnasium-hoechstadt-a-d-aisch) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-hoechstadt.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91315-gymnasium-hoechstadt-a-d-aisch' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Höchstadt a.d.Aisch (slug: gymnasium-hochstadt-a-d-aisch)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-hochstadt-a-d-aisch' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-hochstadt-a-d-aisch' 
  AND is_school = true
")


# Update oldest school (slug: 91320-staatliche-realschule-ebermannstadt) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rsebs.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91320-staatliche-realschule-ebermannstadt' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Ebermannstadt (slug: staatliche-realschule-ebermannstadt)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-ebermannstadt' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-ebermannstadt' 
  AND is_school = true
")


# Update oldest school (slug: 91320-gymnasium-fraenkische-schweiz-ebermannstadt) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gfs-ebs.de',
              phone_number = '+49 9194 73720',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91320-gymnasium-fraenkische-schweiz-ebermannstadt' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Fränkische Schweiz Ebermannstadt (slug: gymnasium-frankische-schweiz-ebermannstadt)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-frankische-schweiz-ebermannstadt' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-frankische-schweiz-ebermannstadt' 
  AND is_school = true
")


# Update oldest school (slug: 91413-dietrich-bonhoeffer-schule-staatliche-realschule-neustadt-a-d-aisch) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-neustadt-aisch.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91413-dietrich-bonhoeffer-schule-staatliche-realschule-neustadt-a-d-aisch' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Dietrich-Bonhoeffer-Schule Staatliche Realschule Neustadt a.d.Aisch (slug: dietrich-bonhoeffer-schule-staatliche-realschule-neustadt-a-d-aisch)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'dietrich-bonhoeffer-schule-staatliche-realschule-neustadt-a-d-aisch' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'dietrich-bonhoeffer-schule-staatliche-realschule-neustadt-a-d-aisch' 
  AND is_school = true
")


# Update oldest school (slug: 91438-georg-wilhelm-steller-gymnasium-bad-windsheim) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gwsg.net',
              phone_number = '+49 9841 4014090',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91438-georg-wilhelm-steller-gymnasium-bad-windsheim' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Georg-Wilhelm-Steller-Gymnasium Bad Windsheim (slug: georg-wilhelm-steller-gymnasium-bad-windsheim)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'georg-wilhelm-steller-gymnasium-bad-windsheim' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'georg-wilhelm-steller-gymnasium-bad-windsheim' 
  AND is_school = true
")


# Update oldest school (slug: 91443-gymnasium-scheinfeld) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-scheinfeld.de',
              phone_number = '+49 9162 388980',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91443-gymnasium-scheinfeld' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Scheinfeld (slug: gymnasium-scheinfeld)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-scheinfeld' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-scheinfeld' 
  AND is_school = true
")


# Update oldest school (slug: 91522-gymnasium-carolinum-ansbach) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-carolinum.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91522-gymnasium-carolinum-ansbach' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Carolinum Ansbach (slug: gymnasium-carolinum-ansbach)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-carolinum-ansbach' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-carolinum-ansbach' 
  AND is_school = true
")


# Update oldest school (slug: 91522-staatliche-fachoberschule-ansbach) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fosbosansbach.de',
              phone_number = '+49 981 97223900',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91522-staatliche-fachoberschule-ansbach' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Fachoberschule Ansbach (slug: staatliche-fachoberschule-ansbach)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-fachoberschule-ansbach' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-fachoberschule-ansbach' 
  AND is_school = true
")


# Update oldest school (slug: 91522-johann-steingruber-schule-staatliche-realschule-ansbach) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-ansbach.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91522-johann-steingruber-schule-staatliche-realschule-ansbach' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Johann-Steingruber-Schule Staatliche Realschule Ansbach (slug: johann-steingruber-schule-staatliche-realschule-ansbach)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'johann-steingruber-schule-staatliche-realschule-ansbach' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'johann-steingruber-schule-staatliche-realschule-ansbach' 
  AND is_school = true
")


# Update oldest school (slug: 91522-platen-gymnasium-ansbach) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.platen-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91522-platen-gymnasium-ansbach' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Platen-Gymnasium Ansbach (slug: platen-gymnasium-ansbach)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'platen-gymnasium-ansbach' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'platen-gymnasium-ansbach' 
  AND is_school = true
")


# Update oldest school (slug: 91522-theresien-gymnasium-ansbach) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.thg-ansbach.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91522-theresien-gymnasium-ansbach' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Theresien-Gymnasium Ansbach (slug: theresien-gymnasium-ansbach)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'theresien-gymnasium-ansbach' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'theresien-gymnasium-ansbach' 
  AND is_school = true
")


# Update oldest school (slug: 91522-staatliche-berufsoberschule-ansbach) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fosbosansbach.de',
              phone_number = '+49 981 97223900',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91522-staatliche-berufsoberschule-ansbach' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Berufsoberschule Ansbach (slug: staatliche-berufsoberschule-ansbach)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-berufsoberschule-ansbach' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-berufsoberschule-ansbach' 
  AND is_school = true
")


# Update oldest school (slug: 91541-reichsstadt-gymnasium-rothenburg-o-d-tauber) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.reichsstadt-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91541-reichsstadt-gymnasium-rothenburg-o-d-tauber' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Reichsstadt-Gymnasium Rothenburg o.d.Tauber (slug: reichsstadt-gymnasium-rothenburg-o-d-tauber)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'reichsstadt-gymnasium-rothenburg-o-d-tauber' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'reichsstadt-gymnasium-rothenburg-o-d-tauber' 
  AND is_school = true
")


# Update oldest school (slug: 91541-oskar-von-miller-realschule-staatliche-realschule-rothenburg-o-d-ta) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rs-rothenburg.de',
              phone_number = '+49 9861 874790',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91541-oskar-von-miller-realschule-staatliche-realschule-rothenburg-o-d-ta' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Oskar-von-Miller-Realschule Staatliche Realschule Rothenburg o.d.Tauber (slug: oskar-von-miller-realschule-staatliche-realschule-rothenburg-o-d-tauber)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'oskar-von-miller-realschule-staatliche-realschule-rothenburg-o-d-tauber' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'oskar-von-miller-realschule-staatliche-realschule-rothenburg-o-d-tauber' 
  AND is_school = true
")


# Update oldest school (slug: 91555-johann-georg-von-soldner-schule-staatl-realschule-feuchtwangen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-feuchtwangen.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91555-johann-georg-von-soldner-schule-staatl-realschule-feuchtwangen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Johann-Georg-von-Soldner-Schule Staatl. Realschule Feuchtwangen (slug: johann-georg-von-soldner-schule-staatl-realschule-feuchtwangen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'johann-georg-von-soldner-schule-staatl-realschule-feuchtwangen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'johann-georg-von-soldner-schule-staatl-realschule-feuchtwangen' 
  AND is_school = true
")


# Update oldest school (slug: 91555-gymnasium-feuchtwangen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-feuchtwangen.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91555-gymnasium-feuchtwangen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Feuchtwangen (slug: gymnasium-feuchtwangen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-feuchtwangen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-feuchtwangen' 
  AND is_school = true
")


# Update oldest school (slug: 91560-markgraf-georg-friedrich-realschule-staatliche-realschule-heilsbronn) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-heilsbronn.de',
              phone_number = '+49 9872 9570910',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91560-markgraf-georg-friedrich-realschule-staatliche-realschule-heilsbronn' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Markgraf-Georg-Friedrich-Realschule Staatliche Realschule Heilsbronn (slug: markgraf-georg-friedrich-realschule-staatliche-realschule-heilsbronn)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'markgraf-georg-friedrich-realschule-staatliche-realschule-heilsbronn' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'markgraf-georg-friedrich-realschule-staatliche-realschule-heilsbronn' 
  AND is_school = true
")


# Update oldest school (slug: 91567-realschule-herrieden) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-herrieden.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91567-realschule-herrieden' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Realschule Herrieden (slug: realschule-herrieden)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'realschule-herrieden' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'realschule-herrieden' 
  AND is_school = true
")


# Update oldest school (slug: 91710-simon-marius-gymnasium-gunzenhausen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.simon-marius-gymnasium.de',
              phone_number = '+49 9831 883190',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91710-simon-marius-gymnasium-gunzenhausen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Simon-Marius-Gymnasium Gunzenhausen (slug: simon-marius-gymnasium-gunzenhausen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'simon-marius-gymnasium-gunzenhausen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'simon-marius-gymnasium-gunzenhausen' 
  AND is_school = true
")


# Update oldest school (slug: 91717-staatliche-realschule-wassertruedingen) with newest data
execute("
  UPDATE addresses 
  SET phone_number = '+49 9832 7064960',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91717-staatliche-realschule-wassertruedingen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Wassertrüdingen (slug: staatliche-realschule-wassertrudingen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-wassertrudingen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-wassertrudingen' 
  AND is_school = true
")


# Update oldest school (slug: 91781-staatliche-berufsoberschule-weissenburg-i-bay) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fosboswug.de',
              phone_number = '+49 9141 85970',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91781-staatliche-berufsoberschule-weissenburg-i-bay' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Berufsoberschule Weißenburg i.Bay. (slug: staatliche-berufsoberschule-weissenburg-i-bay)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-berufsoberschule-weissenburg-i-bay' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-berufsoberschule-weissenburg-i-bay' 
  AND is_school = true
")


# Update oldest school (slug: 91781-werner-von-siemens-gymnasium-weissenburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.wvsgym.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91781-werner-von-siemens-gymnasium-weissenburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Werner-von-Siemens-Gymnasium Weißenburg (slug: werner-von-siemens-gymnasium-weissenburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'werner-von-siemens-gymnasium-weissenburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'werner-von-siemens-gymnasium-weissenburg' 
  AND is_school = true
")


# Update oldest school (slug: 91781-staatliche-fachoberschule-weissenburg-i-bay) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fosboswug.de',
              phone_number = '+49 9141 85970',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '91781-staatliche-fachoberschule-weissenburg-i-bay' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Fachoberschule Weißenburg i.Bay. (slug: staatliche-fachoberschule-weissenburg-i-bay)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-fachoberschule-weissenburg-i-bay' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-fachoberschule-weissenburg-i-bay' 
  AND is_school = true
")


# Update oldest school (slug: 92224-max-reger-gymnasium-amberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.max-reger-gymnasium.de',
              phone_number = '+49 9621 47180',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '92224-max-reger-gymnasium-amberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Max-Reger-Gymnasium Amberg (slug: max-reger-gymnasium-amberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'max-reger-gymnasium-amberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'max-reger-gymnasium-amberg' 
  AND is_school = true
")


# Update oldest school (slug: 92224-gregor-mendel-gymnasium-amberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gmg.amberg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '92224-gregor-mendel-gymnasium-amberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gregor-Mendel-Gymnasium Amberg (slug: gregor-mendel-gymnasium-amberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gregor-mendel-gymnasium-amberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gregor-mendel-gymnasium-amberg' 
  AND is_school = true
")


# Update oldest school (slug: 92224-dr-johanna-decker-gymnasium-amberg-der-schulstiftung-der-dioezese-r) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.djds.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '92224-dr-johanna-decker-gymnasium-amberg-der-schulstiftung-der-dioezese-r' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Dr.-Johanna-Decker-Gymnasium Amberg der Schulstiftung der Diözese Regensburg (slug: dr-johanna-decker-gymnasium-amberg-der-schulstiftung-der-diozese-regensburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'dr-johanna-decker-gymnasium-amberg-der-schulstiftung-der-diozese-regensburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'dr-johanna-decker-gymnasium-amberg-der-schulstiftung-der-diozese-regensburg' 
  AND is_school = true
")


# Update oldest school (slug: 92224-erasmus-gymnasium-amberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.eg-amberg.de',
              phone_number = '+49 9621 103800',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '92224-erasmus-gymnasium-amberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Erasmus-Gymnasium Amberg (slug: erasmus-gymnasium-amberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'erasmus-gymnasium-amberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'erasmus-gymnasium-amberg' 
  AND is_school = true
")


# Update oldest school (slug: 92237-herzog-christian-august-gymnasium-sulzbach-rosenberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.hca-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '92237-herzog-christian-august-gymnasium-sulzbach-rosenberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Herzog-Christian-August-Gymnasium Sulzbach-Rosenberg (slug: herzog-christian-august-gymnasium-sulzbach-rosenberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'herzog-christian-august-gymnasium-sulzbach-rosenberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'herzog-christian-august-gymnasium-sulzbach-rosenberg' 
  AND is_school = true
")


# Update oldest school (slug: 92237-staatliche-realschule-sulzbach-rosenberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rs-su-ro.de',
              phone_number = '+49 9661 813490',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '92237-staatliche-realschule-sulzbach-rosenberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Sulzbach-Rosenberg (slug: staatliche-realschule-sulzbach-rosenberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-sulzbach-rosenberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-sulzbach-rosenberg' 
  AND is_school = true
")


# Update oldest school (slug: 92318-staatliche-realschule-fuer-knaben-neumarkt-i-d-opf) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.knabenrealschule-neumarkt.de',
              phone_number = '+49 9181 320720',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '92318-staatliche-realschule-fuer-knaben-neumarkt-i-d-opf' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule für Knaben Neumarkt i.d.Opf. (slug: staatliche-realschule-fur-knaben-neumarkt-i-d-opf)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-fur-knaben-neumarkt-i-d-opf' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-fur-knaben-neumarkt-i-d-opf' 
  AND is_school = true
")


# Update oldest school (slug: 92318-maximilian-kolbe-schule-staatliche-fachoberschule-neumarkt-i-d-opf) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fosbos.net',
              phone_number = '+49 9181 4061790',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '92318-maximilian-kolbe-schule-staatliche-fachoberschule-neumarkt-i-d-opf' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Maximilian-Kolbe-Schule Staatliche Fachoberschule Neumarkt i.d.OPf. (slug: maximilian-kolbe-schule-staatliche-fachoberschule-neumarkt-i-d-opf)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'maximilian-kolbe-schule-staatliche-fachoberschule-neumarkt-i-d-opf' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'maximilian-kolbe-schule-staatliche-fachoberschule-neumarkt-i-d-opf' 
  AND is_school = true
")


# Update oldest school (slug: 92318-maximilian-kolbe-schule-staatliche-berufsoberschule-neumarkt-i-d-opf) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fosbos.net',
              phone_number = '+49 9181 4061790',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '92318-maximilian-kolbe-schule-staatliche-berufsoberschule-neumarkt-i-d-opf' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Maximilian-Kolbe-Schule Staatliche Berufsoberschule Neumarkt i.d.OPf. (slug: maximilian-kolbe-schule-staatliche-berufsoberschule-neumarkt-i-d-opf)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'maximilian-kolbe-schule-staatliche-berufsoberschule-neumarkt-i-d-opf' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'maximilian-kolbe-schule-staatliche-berufsoberschule-neumarkt-i-d-opf' 
  AND is_school = true
")


# Update oldest school (slug: 92318-ostendorfer-gymnasium-neumarkt) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.ostendorfer.de',
              phone_number = '+49 9181 298400',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '92318-ostendorfer-gymnasium-neumarkt' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Ostendorfer-Gymnasium Neumarkt (slug: ostendorfer-gymnasium-neumarkt)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'ostendorfer-gymnasium-neumarkt' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'ostendorfer-gymnasium-neumarkt' 
  AND is_school = true
")


# Update oldest school (slug: 92331-edith-stein-realschule-staatliche-realschule-parsberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-parsberg.de/',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '92331-edith-stein-realschule-staatliche-realschule-parsberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Edith-Stein-Realschule Staatliche Realschule Parsberg (slug: edith-stein-realschule-staatliche-realschule-parsberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'edith-stein-realschule-staatliche-realschule-parsberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'edith-stein-realschule-staatliche-realschule-parsberg' 
  AND is_school = true
")


# Update oldest school (slug: 92331-gymnasium-parsberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-parsberg.de',
              phone_number = '+49 9492 6010050',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '92331-gymnasium-parsberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Parsberg (slug: gymnasium-parsberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-parsberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-parsberg' 
  AND is_school = true
")


# Update oldest school (slug: 92334-staatl-realschule-berching) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-berching.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '92334-staatl-realschule-berching' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatl. Realschule Berching (slug: staatl-realschule-berching)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatl-realschule-berching' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatl-realschule-berching' 
  AND is_school = true
")


# Update oldest school (slug: 92339-gymnasium-beilngries) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-beilngries.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '92339-gymnasium-beilngries' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Beilngries (slug: gymnasium-beilngries)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-beilngries' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-beilngries' 
  AND is_school = true
")


# Update oldest school (slug: 92339-altmuehltal-realschule-staatliche-realschule-beilngries) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-beilngries.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '92339-altmuehltal-realschule-staatliche-realschule-beilngries' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Altmühltal-Realschule Staatliche Realschule Beilngries (slug: altmuhltal-realschule-staatliche-realschule-beilngries)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'altmuhltal-realschule-staatliche-realschule-beilngries' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'altmuhltal-realschule-staatliche-realschule-beilngries' 
  AND is_school = true
")


# Update oldest school (slug: 92421-staatliche-fachoberschule-schwandorf) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fos-bos-schwandorf.de',
              phone_number = '+49 9431 728800',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '92421-staatliche-fachoberschule-schwandorf' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Fachoberschule Schwandorf (slug: staatliche-fachoberschule-schwandorf)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-fachoberschule-schwandorf' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-fachoberschule-schwandorf' 
  AND is_school = true
")


# Update oldest school (slug: 92421-carl-friedrich-gauss-gymnasium-schwandorf) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.c-f-g.de',
              phone_number = '+49 9431 8023300',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '92421-carl-friedrich-gauss-gymnasium-schwandorf' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Carl-Friedrich-Gauß-Gymnasium Schwandorf (slug: carl-friedrich-gauss-gymnasium-schwandorf)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'carl-friedrich-gauss-gymnasium-schwandorf' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'carl-friedrich-gauss-gymnasium-schwandorf' 
  AND is_school = true
")


# Update oldest school (slug: 92421-staatliche-berufsoberschule-schwandorf) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fos-bos-schwandorf.de',
              phone_number = '+49 9431 728800',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '92421-staatliche-berufsoberschule-schwandorf' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Berufsoberschule Schwandorf (slug: staatliche-berufsoberschule-schwandorf)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-berufsoberschule-schwandorf' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-berufsoberschule-schwandorf' 
  AND is_school = true
")


# Update oldest school (slug: 92421-konrad-max-kunz-realschule-staatl-realschule-schwandorf) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.kmk-rs.de',
              phone_number = '+49 9431 8023500',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '92421-konrad-max-kunz-realschule-staatl-realschule-schwandorf' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Konrad-Max-Kunz-Realschule Staatl. Realschule Schwandorf (slug: konrad-max-kunz-realschule-staatl-realschule-schwandorf)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'konrad-max-kunz-realschule-staatl-realschule-schwandorf' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'konrad-max-kunz-realschule-staatl-realschule-schwandorf' 
  AND is_school = true
")


# Update oldest school (slug: 92421-maedchenrealschule-st-josef-schwandorf) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.mrsstjosef.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '92421-maedchenrealschule-st-josef-schwandorf' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Mädchenrealschule St. Josef Schwandorf (slug: madchenrealschule-st-josef-schwandorf)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'madchenrealschule-st-josef-schwandorf' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'madchenrealschule-st-josef-schwandorf' 
  AND is_school = true
")


# Update oldest school (slug: 92431-gregor-von-scherr-schule-staatliche-realschule-neunburg-vorm-wald) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rs-neunburg.de',
              phone_number = '+49 9672 7630200',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '92431-gregor-von-scherr-schule-staatliche-realschule-neunburg-vorm-wald' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gregor-von-Scherr-Schule Staatliche Realschule Neunburg vorm Wald (slug: gregor-von-scherr-schule-staatliche-realschule-neunburg-vorm-wald)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gregor-von-scherr-schule-staatliche-realschule-neunburg-vorm-wald' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gregor-von-scherr-schule-staatliche-realschule-neunburg-vorm-wald' 
  AND is_school = true
")


# Update oldest school (slug: 92507-johann-andreas-schmeller-gymnasium-nabburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.jas-gymnasium.de',
              phone_number = '+49 9433 41194400',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '92507-johann-andreas-schmeller-gymnasium-nabburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Johann-Andreas-Schmeller-Gymnasium Nabburg (slug: johann-andreas-schmeller-gymnasium-nabburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'johann-andreas-schmeller-gymnasium-nabburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'johann-andreas-schmeller-gymnasium-nabburg' 
  AND is_school = true
")


# Update oldest school (slug: 92507-naabtal-realschule-staatliche-realschule-nabburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.naabtal-realschule.de',
              phone_number = '+49 9433 41194300',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '92507-naabtal-realschule-staatliche-realschule-nabburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Naabtal-Realschule Staatliche Realschule Nabburg (slug: naabtal-realschule-staatliche-realschule-nabburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'naabtal-realschule-staatliche-realschule-nabburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'naabtal-realschule-staatliche-realschule-nabburg' 
  AND is_school = true
")


# Update oldest school (slug: 92526-ortenburg-gymnasium-oberviechtach) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.ortenburg-gymnasium.de',
              phone_number = '+49 9671 7440300',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '92526-ortenburg-gymnasium-oberviechtach' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Ortenburg-Gymnasium Oberviechtach (slug: ortenburg-gymnasium-oberviechtach)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'ortenburg-gymnasium-oberviechtach' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'ortenburg-gymnasium-oberviechtach' 
  AND is_school = true
")


# Update oldest school (slug: 92637-kepler-gymnasium-weiden) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.kepler-weiden.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '92637-kepler-gymnasium-weiden' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Kepler-Gymnasium Weiden (slug: kepler-gymnasium-weiden)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'kepler-gymnasium-weiden' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'kepler-gymnasium-weiden' 
  AND is_school = true
")


# Update oldest school (slug: 92637-sophie-scholl-realschule-staatl-realschule-fuer-maedchen-weiden) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.sophie-scholl-rs.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '92637-sophie-scholl-realschule-staatl-realschule-fuer-maedchen-weiden' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Sophie-Scholl-Realschule Staatl. Realschule für Mädchen Weiden (slug: sophie-scholl-realschule-staatl-realschule-fur-madchen-weiden)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'sophie-scholl-realschule-staatl-realschule-fur-madchen-weiden' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'sophie-scholl-realschule-staatl-realschule-fur-madchen-weiden' 
  AND is_school = true
")


# Update oldest school (slug: 92637-augustinus-gymnasium-weiden) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.augustinus-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '92637-augustinus-gymnasium-weiden' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Augustinus-Gymnasium Weiden (slug: augustinus-gymnasium-weiden)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'augustinus-gymnasium-weiden' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'augustinus-gymnasium-weiden' 
  AND is_school = true
")


# Update oldest school (slug: 92637-hans-scholl-realschule-staatliche-realschule-fuer-knaben-weiden) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.hans-scholl-rs.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '92637-hans-scholl-realschule-staatliche-realschule-fuer-knaben-weiden' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Hans-Scholl-Realschule Staatliche Realschule für Knaben Weiden (slug: hans-scholl-realschule-staatliche-realschule-fur-knaben-weiden)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'hans-scholl-realschule-staatliche-realschule-fur-knaben-weiden' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'hans-scholl-realschule-staatliche-realschule-fur-knaben-weiden' 
  AND is_school = true
")


# Update oldest school (slug: 92637-elly-heuss-gymnasium-weiden) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.ehg-wen.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '92637-elly-heuss-gymnasium-weiden' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Elly-Heuss-Gymnasium Weiden (slug: elly-heuss-gymnasium-weiden)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'elly-heuss-gymnasium-weiden' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'elly-heuss-gymnasium-weiden' 
  AND is_school = true
")


# Update oldest school (slug: 92648-staatliche-realschule-vohenstrauss) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-vohenstrauss.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '92648-staatliche-realschule-vohenstrauss' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Vohenstrauß (slug: staatliche-realschule-vohenstrauss)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-vohenstrauss' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-vohenstrauss' 
  AND is_school = true
")


# Update oldest school (slug: 92660-gymnasium-neustadt-a-d-waldnaab) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gym-new.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '92660-gymnasium-neustadt-a-d-waldnaab' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Neustadt a.d.Waldnaab (slug: gymnasium-neustadt-a-d-waldnaab)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-neustadt-a-d-waldnaab' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-neustadt-a-d-waldnaab' 
  AND is_school = true
")


# Update oldest school (slug: 92676-gymnasium-eschenbach) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-eschenbach.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '92676-gymnasium-eschenbach' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Eschenbach (slug: gymnasium-eschenbach)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-eschenbach' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-eschenbach' 
  AND is_school = true
")


# Update oldest school (slug: 93047-realschule-am-judenstein-staatliche-realschule-regensburg-i) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-am-judenstein.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '93047-realschule-am-judenstein-staatliche-realschule-regensburg-i' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Realschule am Judenstein Staatliche Realschule Regensburg I (slug: realschule-am-judenstein-staatliche-realschule-regensburg-i)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'realschule-am-judenstein-staatliche-realschule-regensburg-i' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'realschule-am-judenstein-staatliche-realschule-regensburg-i' 
  AND is_school = true
")


# Update oldest school (slug: 93047-albrecht-altdorfer-gymnasium-regensburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.regensburg-aag.de/',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '93047-albrecht-altdorfer-gymnasium-regensburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Albrecht-Altdorfer-Gymnasium Regensburg (slug: albrecht-altdorfer-gymnasium-regensburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'albrecht-altdorfer-gymnasium-regensburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'albrecht-altdorfer-gymnasium-regensburg' 
  AND is_school = true
")


# Update oldest school (slug: 93047-staedtische-berufsoberschule-regensburg-ausbildungsrichtung-wirtschaft) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.regensburg.de/bs3',
              phone_number = '+49 941 5074240',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '93047-staedtische-berufsoberschule-regensburg-ausbildungsrichtung-wirtschaft' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtische Berufsoberschule Regensburg Ausbildungsrichtung Wirtschaft (slug: stadtische-berufsoberschule-regensburg-ausbildungsrichtung-wirtschaft)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtische-berufsoberschule-regensburg-ausbildungsrichtung-wirtschaft' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtische-berufsoberschule-regensburg-ausbildungsrichtung-wirtschaft' 
  AND is_school = true
")


# Update oldest school (slug: 93047-maedchenrealschule-der-armen-schulschwestern-von-unserer-lieben-frau) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.niedermuenster.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '93047-maedchenrealschule-der-armen-schulschwestern-von-unserer-lieben-frau' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Mädchenrealschule der Armen Schulschwestern von Unserer Lieben Frau Regensburg-Niedermünster (slug: madchenrealschule-der-armen-schulschwestern-von-unserer-lieben-frau-regensburg-niedermunster)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'madchenrealschule-der-armen-schulschwestern-von-unserer-lieben-frau-regensburg-niedermunster' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'madchenrealschule-der-armen-schulschwestern-von-unserer-lieben-frau-regensburg-niedermunster' 
  AND is_school = true
")


# Update oldest school (slug: 93049-albertus-magnus-gymnasium-regensburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.amg-regensburg.de/',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '93049-albertus-magnus-gymnasium-regensburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Albertus-Magnus-Gymnasium Regensburg (slug: albertus-magnus-gymnasium-regensburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'albertus-magnus-gymnasium-regensburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'albertus-magnus-gymnasium-regensburg' 
  AND is_school = true
")


# Update oldest school (slug: 93049-goethe-gymnasium-regensburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.schulen.regensburg.de/goegy',
              phone_number = '+49 941 5074052',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '93049-goethe-gymnasium-regensburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Goethe-Gymnasium Regensburg (slug: goethe-gymnasium-regensburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'goethe-gymnasium-regensburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'goethe-gymnasium-regensburg' 
  AND is_school = true
")


# Update oldest school (slug: 93059-werner-von-siemens-gymnasium-regensburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.siemensgymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '93059-werner-von-siemens-gymnasium-regensburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Werner-von-Siemens-Gymnasium Regensburg (slug: werner-von-siemens-gymnasium-regensburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'werner-von-siemens-gymnasium-regensburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'werner-von-siemens-gymnasium-regensburg' 
  AND is_school = true
")


# Update oldest school (slug: 93073-staatliche-realschule-neutraubling) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rs-neutraubling.de',
              phone_number = '+49 9401 8819280',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '93073-staatliche-realschule-neutraubling' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Neutraubling (slug: staatliche-realschule-neutraubling)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-neutraubling' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-neutraubling' 
  AND is_school = true
")


# Update oldest school (slug: 93073-gymnasium-neutraubling) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasiumneutraubling.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '93073-gymnasium-neutraubling' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Neutraubling (slug: gymnasium-neutraubling)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-neutraubling' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-neutraubling' 
  AND is_school = true
")


# Update oldest school (slug: 93128-max-ulrich-von-drechsel-realschule-staatliche-realschule-regenstauf) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rs-regenstauf.de',
              phone_number = '+49 9402 7818140',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '93128-max-ulrich-von-drechsel-realschule-staatliche-realschule-regenstauf' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Max-Ulrich-von-Drechsel-Realschule Staatliche Realschule Regenstauf (slug: max-ulrich-von-drechsel-realschule-staatliche-realschule-regenstauf)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'max-ulrich-von-drechsel-realschule-staatliche-realschule-regenstauf' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'max-ulrich-von-drechsel-realschule-staatliche-realschule-regenstauf' 
  AND is_school = true
")


# Update oldest school (slug: 93133-johann-michael-fischer-gymnasium-burglengenfeld) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.jmf-gym.org/',
              phone_number = '+49 9471 31993300',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '93133-johann-michael-fischer-gymnasium-burglengenfeld' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Johann-Michael-Fischer-Gymnasium Burglengenfeld (slug: johann-michael-fischer-gymnasium-burglengenfeld)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'johann-michael-fischer-gymnasium-burglengenfeld' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'johann-michael-fischer-gymnasium-burglengenfeld' 
  AND is_school = true
")


# Update oldest school (slug: 93309-staatl-fachoberschule-kelheim) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.bsz-kelheim.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '93309-staatl-fachoberschule-kelheim' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatl. Fachoberschule Kelheim (slug: staatl-fachoberschule-kelheim)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatl-fachoberschule-kelheim' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatl-fachoberschule-kelheim' 
  AND is_school = true
")


# Update oldest school (slug: 93309-donau-gymnasium-kelheim) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.donau-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '93309-donau-gymnasium-kelheim' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Donau-Gymnasium Kelheim (slug: donau-gymnasium-kelheim)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'donau-gymnasium-kelheim' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'donau-gymnasium-kelheim' 
  AND is_school = true
")


# Update oldest school (slug: 93326-johann-turmair-realschule-staatliche-realschule-abensberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rs-abensberg.de',
              phone_number = '+49 9443 91430',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '93326-johann-turmair-realschule-staatliche-realschule-abensberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Johann-Turmair-Realschule Staatliche Realschule Abensberg (slug: johann-turmair-realschule-staatliche-realschule-abensberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'johann-turmair-realschule-staatliche-realschule-abensberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'johann-turmair-realschule-staatliche-realschule-abensberg' 
  AND is_school = true
")


# Update oldest school (slug: 93339-maedchenrealschule-st-anna-riedenburg-der-schulstiftung-der-dioezese) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://https://www.mrsstanna.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '93339-maedchenrealschule-st-anna-riedenburg-der-schulstiftung-der-dioezese' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Mädchenrealschule St. Anna Riedenburg der Schulstiftung der Diözese Regensburg (slug: madchenrealschule-st-anna-riedenburg-der-schulstiftung-der-diozese-regensburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'madchenrealschule-st-anna-riedenburg-der-schulstiftung-der-diozese-regensburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'madchenrealschule-st-anna-riedenburg-der-schulstiftung-der-diozese-regensburg' 
  AND is_school = true
")


# Update oldest school (slug: 93339-johann-simon-mayr-schule-staatliche-realschule-riedenburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.jsm-realschule.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '93339-johann-simon-mayr-schule-staatliche-realschule-riedenburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Johann-Simon-Mayr-Schule Staatliche Realschule Riedenburg (slug: johann-simon-mayr-schule-staatliche-realschule-riedenburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'johann-simon-mayr-schule-staatliche-realschule-riedenburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'johann-simon-mayr-schule-staatliche-realschule-riedenburg' 
  AND is_school = true
")


# Update oldest school (slug: 93352-johannes-nepomuk-gymnasium-der-benediktiner-rohr) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.jngrohr.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '93352-johannes-nepomuk-gymnasium-der-benediktiner-rohr' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Johannes-Nepomuk-Gymnasium der Benediktiner Rohr (slug: johannes-nepomuk-gymnasium-der-benediktiner-rohr)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'johannes-nepomuk-gymnasium-der-benediktiner-rohr' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'johannes-nepomuk-gymnasium-der-benediktiner-rohr' 
  AND is_school = true
")


# Update oldest school (slug: 93413-staatliche-berufsoberschule-cham) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fos-cham.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '93413-staatliche-berufsoberschule-cham' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Berufsoberschule Cham (slug: staatliche-berufsoberschule-cham)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-berufsoberschule-cham' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-berufsoberschule-cham' 
  AND is_school = true
")


# Update oldest school (slug: 93413-staatliche-fachoberschule-cham) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fos-cham.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '93413-staatliche-fachoberschule-cham' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Fachoberschule Cham (slug: staatliche-fachoberschule-cham)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-fachoberschule-cham' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-fachoberschule-cham' 
  AND is_school = true
")


# Update oldest school (slug: 93413-joseph-von-fraunhofer-gymnasium-cham) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.jvfg-cham.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '93413-joseph-von-fraunhofer-gymnasium-cham' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Joseph-von-Fraunhofer-Gymnasium Cham (slug: joseph-von-fraunhofer-gymnasium-cham)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'joseph-von-fraunhofer-gymnasium-cham' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'joseph-von-fraunhofer-gymnasium-cham' 
  AND is_school = true
")


# Update oldest school (slug: 93413-robert-schuman-gymnasium-cham) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rsg-cham.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '93413-robert-schuman-gymnasium-cham' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Robert-Schuman-Gymnasium Cham (slug: robert-schuman-gymnasium-cham)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'robert-schuman-gymnasium-cham' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'robert-schuman-gymnasium-cham' 
  AND is_school = true
")


# Update oldest school (slug: 93426-konrad-adenauer-schule-staatliche-realschule-roding) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rs-roding.de',
              phone_number = '+49 9461 912870',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '93426-konrad-adenauer-schule-staatliche-realschule-roding' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Konrad-Adenauer-Schule Staatliche Realschule Roding (slug: konrad-adenauer-schule-staatliche-realschule-roding)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'konrad-adenauer-schule-staatliche-realschule-roding' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'konrad-adenauer-schule-staatliche-realschule-roding' 
  AND is_school = true
")


# Update oldest school (slug: 94032-gymnasium-leopoldinum-passau) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.leopoldinum-passau.de',
              phone_number = '+49 851 9885940',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94032-gymnasium-leopoldinum-passau' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Leopoldinum Passau (slug: gymnasium-leopoldinum-passau)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-leopoldinum-passau' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-leopoldinum-passau' 
  AND is_school = true
")


# Update oldest school (slug: 94032-gisela-realschule-passau-niedernburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gisela-schulen.de',
              phone_number = '+49 851 9885930',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94032-gisela-realschule-passau-niedernburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gisela-Realschule Passau-Niedernburg (slug: gisela-realschule-passau-niedernburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gisela-realschule-passau-niedernburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gisela-realschule-passau-niedernburg' 
  AND is_school = true
")


# Update oldest school (slug: 94032-adalbert-stifter-gymnasium-passau) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.asg-passau.de',
              phone_number = '+49 851 3793090',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94032-adalbert-stifter-gymnasium-passau' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Adalbert-Stifter-Gymnasium Passau (slug: adalbert-stifter-gymnasium-passau)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'adalbert-stifter-gymnasium-passau' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'adalbert-stifter-gymnasium-passau' 
  AND is_school = true
")


# Update oldest school (slug: 94032-staatliche-berufsoberschule-passau) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fos-bos-passau.de',
              phone_number = '+49 851 756823111',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94032-staatliche-berufsoberschule-passau' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Berufsoberschule Passau (slug: staatliche-berufsoberschule-passau)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-berufsoberschule-passau' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-berufsoberschule-passau' 
  AND is_school = true
")


# Update oldest school (slug: 94032-staatliche-fachoberschule-passau) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fos-bos-passau.de',
              phone_number = '+49 851 756823110',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94032-staatliche-fachoberschule-passau' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Fachoberschule Passau (slug: staatliche-fachoberschule-passau)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-fachoberschule-passau' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-fachoberschule-passau' 
  AND is_school = true
")


# Update oldest school (slug: 94032-gisela-gymnasium-passau-niedernburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gisela-schulen.de',
              phone_number = '+49 851 9885930',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94032-gisela-gymnasium-passau-niedernburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gisela-Gymnasium Passau-Niedernburg (slug: gisela-gymnasium-passau-niedernburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gisela-gymnasium-passau-niedernburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gisela-gymnasium-passau-niedernburg' 
  AND is_school = true
")


# Update oldest school (slug: 94051-johann-riederer-schule-staatliche-realschule-hauzenberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-hauzenberg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94051-johann-riederer-schule-staatliche-realschule-hauzenberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Johann-Riederer-Schule Staatliche Realschule Hauzenberg (slug: johann-riederer-schule-staatliche-realschule-hauzenberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'johann-riederer-schule-staatliche-realschule-hauzenberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'johann-riederer-schule-staatliche-realschule-hauzenberg' 
  AND is_school = true
")


# Update oldest school (slug: 94060-wilhelm-diess-gymnasium-pocking) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.wdg-pocking.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94060-wilhelm-diess-gymnasium-pocking' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Wilhelm-Diess-Gymnasium Pocking (slug: wilhelm-diess-gymnasium-pocking)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'wilhelm-diess-gymnasium-pocking' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'wilhelm-diess-gymnasium-pocking' 
  AND is_school = true
")


# Update oldest school (slug: 94065-staatl-fachoberschule-waldkirchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.bs-waldkirchen.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94065-staatl-fachoberschule-waldkirchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatl. Fachoberschule Waldkirchen (slug: staatl-fachoberschule-waldkirchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatl-fachoberschule-waldkirchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatl-fachoberschule-waldkirchen' 
  AND is_school = true
")


# Update oldest school (slug: 94065-johannes-gutenberg-gymnasium-waldkirchen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.jgg-waldkirchen.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94065-johannes-gutenberg-gymnasium-waldkirchen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Johannes-Gutenberg-Gymnasium Waldkirchen (slug: johannes-gutenberg-gymnasium-waldkirchen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'johannes-gutenberg-gymnasium-waldkirchen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'johannes-gutenberg-gymnasium-waldkirchen' 
  AND is_school = true
")


# Update oldest school (slug: 94078-gymnasium-freyung) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-freyung.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94078-gymnasium-freyung' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Freyung (slug: gymnasium-freyung)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-freyung' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-freyung' 
  AND is_school = true
")


# Update oldest school (slug: 94078-staatliche-realschule-freyung) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://https://www.realschule-freyung.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94078-staatliche-realschule-freyung' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Freyung (slug: staatliche-realschule-freyung)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-freyung' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-freyung' 
  AND is_school = true
")


# Update oldest school (slug: 94081-maristengymnasium-fuerstenzell) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.mgf.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94081-maristengymnasium-fuerstenzell' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Maristengymnasium Fürstenzell (slug: maristengymnasium-furstenzell)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'maristengymnasium-furstenzell' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'maristengymnasium-furstenzell' 
  AND is_school = true
")


# Update oldest school (slug: 94209-siegfried-von-vegesack-realschule-staatliche-realschule-regen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-regen.de',
              phone_number = '+49 9921 9712780',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94209-siegfried-von-vegesack-realschule-staatliche-realschule-regen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Siegfried-von-Vegesack-Realschule Staatliche Realschule Regen (slug: siegfried-von-vegesack-realschule-staatliche-realschule-regen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'siegfried-von-vegesack-realschule-staatliche-realschule-regen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'siegfried-von-vegesack-realschule-staatliche-realschule-regen' 
  AND is_school = true
")


# Update oldest school (slug: 94209-staatliche-fachoberschule-regen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fos-regen.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94209-staatliche-fachoberschule-regen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Fachoberschule Regen (slug: staatliche-fachoberschule-regen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-fachoberschule-regen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-fachoberschule-regen' 
  AND is_school = true
")


# Update oldest school (slug: 94227-gymnasium-zwiesel) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-zwiesel.de',
              phone_number = '+49 9922 5003000',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94227-gymnasium-zwiesel' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Zwiesel (slug: gymnasium-zwiesel)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-zwiesel' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-zwiesel' 
  AND is_school = true
")


# Update oldest school (slug: 94227-staatliche-realschule-zwiesel) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-zwiesel.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94227-staatliche-realschule-zwiesel' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Zwiesel (slug: staatliche-realschule-zwiesel)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-zwiesel' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-zwiesel' 
  AND is_school = true
")


# Update oldest school (slug: 94234-dominicus-von-linprun-gymnasium-viechtach) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-viechtach.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94234-dominicus-von-linprun-gymnasium-viechtach' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Dominicus-von-Linprun-Gymnasium Viechtach (slug: dominicus-von-linprun-gymnasium-viechtach)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'dominicus-von-linprun-gymnasium-viechtach' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'dominicus-von-linprun-gymnasium-viechtach' 
  AND is_school = true
")


# Update oldest school (slug: 94234-staatliche-realschule-viechtach) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rsvit.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94234-staatliche-realschule-viechtach' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Viechtach (slug: staatliche-realschule-viechtach)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-viechtach' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-viechtach' 
  AND is_school = true
")


# Update oldest school (slug: 94315-anton-bruckner-gymnasium-straubing) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.dasbruckner.de',
              phone_number = '+49 9421 974850',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94315-anton-bruckner-gymnasium-straubing' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Anton-Bruckner-Gymnasium Straubing (slug: anton-bruckner-gymnasium-straubing)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'anton-bruckner-gymnasium-straubing' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'anton-bruckner-gymnasium-straubing' 
  AND is_school = true
")


# Update oldest school (slug: 94315-jakob-sandtner-schule-staatliche-realschule-fuer-knaben-straubing) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.jsr-straubing.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94315-jakob-sandtner-schule-staatliche-realschule-fuer-knaben-straubing' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Jakob-Sandtner-Schule Staatliche Realschule für Knaben Straubing (slug: jakob-sandtner-schule-staatliche-realschule-fur-knaben-straubing)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'jakob-sandtner-schule-staatliche-realschule-fur-knaben-straubing' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'jakob-sandtner-schule-staatliche-realschule-fur-knaben-straubing' 
  AND is_school = true
")


# Update oldest school (slug: 94315-ludwigsgymnasium-straubing) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.ludwigsgymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94315-ludwigsgymnasium-straubing' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Ludwigsgymnasium Straubing (slug: ludwigsgymnasium-straubing)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'ludwigsgymnasium-straubing' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'ludwigsgymnasium-straubing' 
  AND is_school = true
")


# Update oldest school (slug: 94315-johannes-turmair-gymnasium-straubing) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.turmair-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94315-johannes-turmair-gymnasium-straubing' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Johannes-Turmair-Gymnasium Straubing (slug: johannes-turmair-gymnasium-straubing)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'johannes-turmair-gymnasium-straubing' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'johannes-turmair-gymnasium-straubing' 
  AND is_school = true
")


# Update oldest school (slug: 94327-ludmilla-schule-staatliche-realschule-bogen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.ludmilla-realschule.com',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94327-ludmilla-schule-staatliche-realschule-bogen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Ludmilla-Schule Staatliche Realschule Bogen (slug: ludmilla-schule-staatliche-realschule-bogen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'ludmilla-schule-staatliche-realschule-bogen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'ludmilla-schule-staatliche-realschule-bogen' 
  AND is_school = true
")


# Update oldest school (slug: 94327-veit-hoeser-gymnasium-bogen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.vhg-bogen.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94327-veit-hoeser-gymnasium-bogen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Veit-Höser-Gymnasium Bogen (slug: veit-hoser-gymnasium-bogen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'veit-hoser-gymnasium-bogen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'veit-hoser-gymnasium-bogen' 
  AND is_school = true
")


# Update oldest school (slug: 94405-gymnasium-landau-a-d-isar) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-landau.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94405-gymnasium-landau-a-d-isar' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Landau a.d.Isar (slug: gymnasium-landau-a-d-isar)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-landau-a-d-isar' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-landau-a-d-isar' 
  AND is_school = true
")


# Update oldest school (slug: 94424-staatl-realschule-arnstorf) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rsarnstorf.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94424-staatl-realschule-arnstorf' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatl. Realschule Arnstorf (slug: staatl-realschule-arnstorf)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatl-realschule-arnstorf' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatl-realschule-arnstorf' 
  AND is_school = true
")


# Update oldest school (slug: 94447-conrad-graf-preysing-realschule-staatliche-realschule-plattling) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-plattling.de',
              phone_number = '+49 9931 91350',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94447-conrad-graf-preysing-realschule-staatliche-realschule-plattling' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Conrad-Graf-Preysing-Realschule Staatliche Realschule Plattling (slug: conrad-graf-preysing-realschule-staatliche-realschule-plattling)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'conrad-graf-preysing-realschule-staatliche-realschule-plattling' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'conrad-graf-preysing-realschule-staatliche-realschule-plattling' 
  AND is_school = true
")


# Update oldest school (slug: 94469-comenius-gymnasium-deggendorf) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.comenius-deg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94469-comenius-gymnasium-deggendorf' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Comenius-Gymnasium Deggendorf (slug: comenius-gymnasium-deggendorf)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'comenius-gymnasium-deggendorf' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'comenius-gymnasium-deggendorf' 
  AND is_school = true
")


# Update oldest school (slug: 94469-aloys-fischer-schule-staatliche-berufsoberschule-deggendorf) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.afs-fosbos.de',
              phone_number = '+49 991 28090810',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94469-aloys-fischer-schule-staatliche-berufsoberschule-deggendorf' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Aloys-Fischer-Schule Staatliche Berufsoberschule Deggendorf (slug: aloys-fischer-schule-staatliche-berufsoberschule-deggendorf)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'aloys-fischer-schule-staatliche-berufsoberschule-deggendorf' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'aloys-fischer-schule-staatliche-berufsoberschule-deggendorf' 
  AND is_school = true
")


# Update oldest school (slug: 94469-aloys-fischer-schule-staatliche-fachoberschule-deggendorf) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.afs-fosbos.de',
              phone_number = '+49 991 28090810',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94469-aloys-fischer-schule-staatliche-fachoberschule-deggendorf' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Aloys-Fischer-Schule Staatliche Fachoberschule Deggendorf (slug: aloys-fischer-schule-staatliche-fachoberschule-deggendorf)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'aloys-fischer-schule-staatliche-fachoberschule-deggendorf' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'aloys-fischer-schule-staatliche-fachoberschule-deggendorf' 
  AND is_school = true
")


# Update oldest school (slug: 94474-gymnasium-vilshofen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gym-vilshofen.de',
              phone_number = '+49 8541 91920',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94474-gymnasium-vilshofen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Vilshofen (slug: gymnasium-vilshofen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-vilshofen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-vilshofen' 
  AND is_school = true
")


# Update oldest school (slug: 94474-coelestin-maier-realschule-schweiklberg-in-vilshofen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschuleschweiklberg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94474-coelestin-maier-realschule-schweiklberg-in-vilshofen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Coelestin-Maier-Realschule Schweiklberg in Vilshofen (slug: coelestin-maier-realschule-schweiklberg-in-vilshofen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'coelestin-maier-realschule-schweiklberg-in-vilshofen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'coelestin-maier-realschule-schweiklberg-in-vilshofen' 
  AND is_school = true
")


# Update oldest school (slug: 94481-landgraf-leuchtenberg-gymnasium-grafenau) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.llg-grafenau.de',
              phone_number = '+49 8552 96620',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94481-landgraf-leuchtenberg-gymnasium-grafenau' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Landgraf-Leuchtenberg-Gymnasium Grafenau (slug: landgraf-leuchtenberg-gymnasium-grafenau)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'landgraf-leuchtenberg-gymnasium-grafenau' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'landgraf-leuchtenberg-gymnasium-grafenau' 
  AND is_school = true
")


# Update oldest school (slug: 94481-staatl-realschule-grafenau) with newest data
execute("
  UPDATE addresses 
  SET phone_number = '+49 8552 96120',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94481-staatl-realschule-grafenau' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatl. Realschule Grafenau (slug: staatl-realschule-grafenau)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatl-realschule-grafenau' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatl-realschule-grafenau' 
  AND is_school = true
")


# No updates needed for school slug: 94496-columba-neef-realschule-der-benediktinerinnen-der-anbetung-neustift
# Delete duplicate school: Columba-Neef-Realschule der Benediktinerinnen der Anbetung Neustift (slug: columba-neef-realschule-der-benediktinerinnen-der-anbetung-neustift)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'columba-neef-realschule-der-benediktinerinnen-der-anbetung-neustift' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'columba-neef-realschule-der-benediktinerinnen-der-anbetung-neustift' 
  AND is_school = true
")


# Update oldest school (slug: 94508-staatliche-realschule-schoellnach) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-schoellnach.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94508-staatliche-realschule-schoellnach' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Schöllnach (slug: staatliche-realschule-schollnach)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-schollnach' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-schollnach' 
  AND is_school = true
")


# Update oldest school (slug: 94526-st-michaels-gymnasium-der-benediktiner-metten) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.kloster-metten.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '94526-st-michaels-gymnasium-der-benediktiner-metten' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: St.-Michaels-Gymnasium der Benediktiner Metten (slug: st-michaels-gymnasium-der-benediktiner-metten)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'st-michaels-gymnasium-der-benediktiner-metten' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'st-michaels-gymnasium-der-benediktiner-metten' 
  AND is_school = true
")


# Update oldest school (slug: 95028-staatliche-fachoberschule-hof) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fos-bos-hof.de',
              phone_number = '+49 9281 8156100',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '95028-staatliche-fachoberschule-hof' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Fachoberschule Hof (slug: staatliche-fachoberschule-hof)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-fachoberschule-hof' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-fachoberschule-hof' 
  AND is_school = true
")


# Update oldest school (slug: 95028-schiller-gymnasium-hof) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.schillergym.de/',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '95028-schiller-gymnasium-hof' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Schiller-Gymnasium Hof (slug: schiller-gymnasium-hof)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'schiller-gymnasium-hof' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'schiller-gymnasium-hof' 
  AND is_school = true
")


# Update oldest school (slug: 95028-staatliche-berufsoberschule-hof) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fos-bos-hof.de',
              phone_number = '+49 9281 8156100',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '95028-staatliche-berufsoberschule-hof' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Berufsoberschule Hof (slug: staatliche-berufsoberschule-hof)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-berufsoberschule-hof' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-berufsoberschule-hof' 
  AND is_school = true
")


# Update oldest school (slug: 95030-joh-georg-august-wirth-realschule-staatliche-realschule-hof) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rs-hof.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '95030-joh-georg-august-wirth-realschule-staatliche-realschule-hof' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Joh.-Georg-August-Wirth-Realschule Staatliche Realschule Hof (slug: joh-georg-august-wirth-realschule-staatliche-realschule-hof)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'joh-georg-august-wirth-realschule-staatliche-realschule-hof' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'joh-georg-august-wirth-realschule-staatliche-realschule-hof' 
  AND is_school = true
")


# Update oldest school (slug: 95030-johann-christian-reinhart-gymnasium-hof) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.reinhart-gymnasium-hof.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '95030-johann-christian-reinhart-gymnasium-hof' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Johann-Christian-Reinhart-Gymnasium Hof (slug: johann-christian-reinhart-gymnasium-hof)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'johann-christian-reinhart-gymnasium-hof' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'johann-christian-reinhart-gymnasium-hof' 
  AND is_school = true
")


# Update oldest school (slug: 95100-walter-gropius-gymnasium-selb) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.wggselb.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '95100-walter-gropius-gymnasium-selb' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Walter-Gropius-Gymnasium Selb (slug: walter-gropius-gymnasium-selb)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'walter-gropius-gymnasium-selb' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'walter-gropius-gymnasium-selb' 
  AND is_school = true
")


# Update oldest school (slug: 95100-staatliche-realschule-selb) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rs-selb.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '95100-staatliche-realschule-selb' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Selb (slug: staatliche-realschule-selb)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-selb' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-selb' 
  AND is_school = true
")


# Update oldest school (slug: 95111-markgraf-friedrich-schule-staatliche-realschule-rehau) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rsrehau.de',
              phone_number = '+49 9283 898070',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '95111-markgraf-friedrich-schule-staatliche-realschule-rehau' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Markgraf-Friedrich-Schule Staatliche Realschule Rehau (slug: markgraf-friedrich-schule-staatliche-realschule-rehau)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'markgraf-friedrich-schule-staatliche-realschule-rehau' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'markgraf-friedrich-schule-staatliche-realschule-rehau' 
  AND is_school = true
")


# Update oldest school (slug: 95213-gymnasium-muenchberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-muenchberg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '95213-gymnasium-muenchberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Münchberg (slug: gymnasium-munchberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-munchberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-munchberg' 
  AND is_school = true
")


# Update oldest school (slug: 95233-staatliche-realschule-helmbrechts) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-helmbrechts.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '95233-staatliche-realschule-helmbrechts' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Helmbrechts (slug: staatliche-realschule-helmbrechts)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-helmbrechts' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-helmbrechts' 
  AND is_school = true
")


# Update oldest school (slug: 95326-adalbert-raps-schule-staatliche-berufsoberschule-kulmbach) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.bsz-kulmbach.de/fosbos',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '95326-adalbert-raps-schule-staatliche-berufsoberschule-kulmbach' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Adalbert-Raps-Schule Staatliche Berufsoberschule Kulmbach (slug: adalbert-raps-schule-staatliche-berufsoberschule-kulmbach)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'adalbert-raps-schule-staatliche-berufsoberschule-kulmbach' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'adalbert-raps-schule-staatliche-berufsoberschule-kulmbach' 
  AND is_school = true
")


# Update oldest school (slug: 95326-markgraf-georg-friedrich-gymnasium-kulmbach) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.mgf-kulmbach.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '95326-markgraf-georg-friedrich-gymnasium-kulmbach' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Markgraf-Georg-Friedrich-Gymnasium Kulmbach (slug: markgraf-georg-friedrich-gymnasium-kulmbach)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'markgraf-georg-friedrich-gymnasium-kulmbach' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'markgraf-georg-friedrich-gymnasium-kulmbach' 
  AND is_school = true
")


# Update oldest school (slug: 95326-carl-von-linde-schule-staatliche-realschule-kulmbach) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-kulmbach.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '95326-carl-von-linde-schule-staatliche-realschule-kulmbach' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Carl-von-Linde-Schule Staatliche Realschule Kulmbach (slug: carl-von-linde-schule-staatliche-realschule-kulmbach)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'carl-von-linde-schule-staatliche-realschule-kulmbach' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'carl-von-linde-schule-staatliche-realschule-kulmbach' 
  AND is_school = true
")


# Update oldest school (slug: 95326-adalbert-raps-schule-staatl-fachoberschule-kulmbach) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.bsz-kulmbach.de/fosbos',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '95326-adalbert-raps-schule-staatl-fachoberschule-kulmbach' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Adalbert-Raps-Schule Staatl. Fachoberschule Kulmbach (slug: adalbert-raps-schule-staatl-fachoberschule-kulmbach)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'adalbert-raps-schule-staatl-fachoberschule-kulmbach' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'adalbert-raps-schule-staatl-fachoberschule-kulmbach' 
  AND is_school = true
")


# Update oldest school (slug: 95326-caspar-vischer-gymnasium-kulmbach) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.cvg-kulmbach.de',
              phone_number = '+49 9221 750010',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '95326-caspar-vischer-gymnasium-kulmbach' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Caspar-Vischer-Gymnasium Kulmbach (slug: caspar-vischer-gymnasium-kulmbach)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'caspar-vischer-gymnasium-kulmbach' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'caspar-vischer-gymnasium-kulmbach' 
  AND is_school = true
")


# Update oldest school (slug: 95444-graf-muenster-gymnasium-bayreuth) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gmg-bayreuth.de',
              phone_number = '+49 921 759830',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '95444-graf-muenster-gymnasium-bayreuth' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Graf-Münster-Gymnasium Bayreuth (slug: graf-munster-gymnasium-bayreuth)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'graf-munster-gymnasium-bayreuth' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'graf-munster-gymnasium-bayreuth' 
  AND is_school = true
")


# Update oldest school (slug: 95444-richard-wagner-gymnasium-bayreuth) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rwg-bayreuth.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '95444-richard-wagner-gymnasium-bayreuth' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Richard-Wagner-Gymnasium Bayreuth (slug: richard-wagner-gymnasium-bayreuth)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'richard-wagner-gymnasium-bayreuth' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'richard-wagner-gymnasium-bayreuth' 
  AND is_school = true
")


# Update oldest school (slug: 95445-alexander-von-humboldt-realschule-staatliche-realschule-bayreuth-i) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.r1-bayreuth.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '95445-alexander-von-humboldt-realschule-staatliche-realschule-bayreuth-i' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Alexander-von-Humboldt-Realschule Staatliche Realschule Bayreuth I (slug: alexander-von-humboldt-realschule-staatliche-realschule-bayreuth-i)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'alexander-von-humboldt-realschule-staatliche-realschule-bayreuth-i' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'alexander-von-humboldt-realschule-staatliche-realschule-bayreuth-i' 
  AND is_school = true
")


# Update oldest school (slug: 95447-johannes-kepler-realschule-staatliche-realschule-bayreuth-ii) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://https://www.jkr-bt.de',
              phone_number = '+49 921 5070388200',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '95447-johannes-kepler-realschule-staatliche-realschule-bayreuth-ii' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Johannes-Kepler-Realschule Staatliche Realschule Bayreuth II (slug: johannes-kepler-realschule-staatliche-realschule-bayreuth-ii)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'johannes-kepler-realschule-staatliche-realschule-bayreuth-ii' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'johannes-kepler-realschule-staatliche-realschule-bayreuth-ii' 
  AND is_school = true
")


# Update oldest school (slug: 95448-markgraefin-wilhelmine-gymnasium-bayreuth) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.mwg-bayreuth.de',
              phone_number = '+49 921 799910',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '95448-markgraefin-wilhelmine-gymnasium-bayreuth' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Markgräfin-Wilhelmine-Gymnasium Bayreuth (slug: markgrafin-wilhelmine-gymnasium-bayreuth)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'markgrafin-wilhelmine-gymnasium-bayreuth' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'markgrafin-wilhelmine-gymnasium-bayreuth' 
  AND is_school = true
")


# Update oldest school (slug: 95448-staatliche-berufsoberschule-bayreuth) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fosbos-bayreuth.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '95448-staatliche-berufsoberschule-bayreuth' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Berufsoberschule Bayreuth (slug: staatliche-berufsoberschule-bayreuth)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-berufsoberschule-bayreuth' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-berufsoberschule-bayreuth' 
  AND is_school = true
")


# Update oldest school (slug: 95448-staatliche-fachoberschule-bayreuth) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fosbos-bayreuth.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '95448-staatliche-fachoberschule-bayreuth' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Fachoberschule Bayreuth (slug: staatliche-fachoberschule-bayreuth)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-fachoberschule-bayreuth' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-fachoberschule-bayreuth' 
  AND is_school = true
")


# Update oldest school (slug: 95448-gymnasium-christian-ernestinum-bayreuth) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gce-bayreuth.de',
              phone_number = '+49 921 726030',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '95448-gymnasium-christian-ernestinum-bayreuth' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Christian-Ernestinum Bayreuth (slug: gymnasium-christian-ernestinum-bayreuth)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-christian-ernestinum-bayreuth' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-christian-ernestinum-bayreuth' 
  AND is_school = true
")


# Update oldest school (slug: 95482-jacob-ellrod-realschule-evang-ganztagsschule-gefrees) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.jesgefrees.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '95482-jacob-ellrod-realschule-evang-ganztagsschule-gefrees' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Jacob-Ellrod-Realschule Evang. Ganztagsschule Gefrees (slug: jacob-ellrod-realschule-evang-ganztagsschule-gefrees)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'jacob-ellrod-realschule-evang-ganztagsschule-gefrees' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'jacob-ellrod-realschule-evang-ganztagsschule-gefrees' 
  AND is_school = true
")


# Update oldest school (slug: 95615-otto-hahn-gymnasium-marktredwitz) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.ohg-marktredwitz.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '95615-otto-hahn-gymnasium-marktredwitz' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Otto-Hahn-Gymnasium Marktredwitz (slug: otto-hahn-gymnasium-marktredwitz)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'otto-hahn-gymnasium-marktredwitz' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'otto-hahn-gymnasium-marktredwitz' 
  AND is_school = true
")


# Update oldest school (slug: 95615-fichtelgebirgsrealschule-staatliche-realschule-marktredwitz) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-mak.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '95615-fichtelgebirgsrealschule-staatliche-realschule-marktredwitz' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Fichtelgebirgsrealschule Staatliche Realschule Marktredwitz (slug: fichtelgebirgsrealschule-staatliche-realschule-marktredwitz)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'fichtelgebirgsrealschule-staatliche-realschule-marktredwitz' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'fichtelgebirgsrealschule-staatliche-realschule-marktredwitz' 
  AND is_school = true
")


# Update oldest school (slug: 95632-sigmund-wann-realschule-staatliche-realschule-wunsiedel) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rswun.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '95632-sigmund-wann-realschule-staatliche-realschule-wunsiedel' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Sigmund-Wann-Realschule Staatliche Realschule Wunsiedel (slug: sigmund-wann-realschule-staatliche-realschule-wunsiedel)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'sigmund-wann-realschule-staatliche-realschule-wunsiedel' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'sigmund-wann-realschule-staatliche-realschule-wunsiedel' 
  AND is_school = true
")


# Update oldest school (slug: 95632-luisenburg-gymnasium-wunsiedel) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.lugy.de',
              phone_number = '+49 9232 99040',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '95632-luisenburg-gymnasium-wunsiedel' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Luisenburg-Gymnasium Wunsiedel (slug: luisenburg-gymnasium-wunsiedel)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'luisenburg-gymnasium-wunsiedel' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'luisenburg-gymnasium-wunsiedel' 
  AND is_school = true
")


# Update oldest school (slug: 95643-stiftland-gymnasium-tirschenreuth) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.stiftland-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '95643-stiftland-gymnasium-tirschenreuth' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Stiftland-Gymnasium Tirschenreuth (slug: stiftland-gymnasium-tirschenreuth)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stiftland-gymnasium-tirschenreuth' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stiftland-gymnasium-tirschenreuth' 
  AND is_school = true
")


# Update oldest school (slug: 96047-franz-ludwig-gymnasium-bamberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.franz-ludwig-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '96047-franz-ludwig-gymnasium-bamberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Franz-Ludwig-Gymnasium Bamberg (slug: franz-ludwig-gymnasium-bamberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'franz-ludwig-gymnasium-bamberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'franz-ludwig-gymnasium-bamberg' 
  AND is_school = true
")


# Update oldest school (slug: 96047-clavius-gymnasium-bamberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.cg-bamberg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '96047-clavius-gymnasium-bamberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Clavius-Gymnasium Bamberg (slug: clavius-gymnasium-bamberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'clavius-gymnasium-bamberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'clavius-gymnasium-bamberg' 
  AND is_school = true
")


# Update oldest school (slug: 96049-kaiser-heinrich-gymnasium-bamberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.khg.bamberg.de',
              phone_number = '+49 951 9520200',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '96049-kaiser-heinrich-gymnasium-bamberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Kaiser-Heinrich-Gymnasium Bamberg (slug: kaiser-heinrich-gymnasium-bamberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'kaiser-heinrich-gymnasium-bamberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'kaiser-heinrich-gymnasium-bamberg' 
  AND is_school = true
")


# Update oldest school (slug: 96049-e-t-a-hoffmann-gymnasium-bamberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.eta-hoffmann-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '96049-e-t-a-hoffmann-gymnasium-bamberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: E.T.A.Hoffmann-Gymnasium Bamberg (slug: e-t-a-hoffmann-gymnasium-bamberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'e-t-a-hoffmann-gymnasium-bamberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'e-t-a-hoffmann-gymnasium-bamberg' 
  AND is_school = true
")


# Update oldest school (slug: 96050-staatliche-berufsoberschule-bamberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.bos-bamberg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '96050-staatliche-berufsoberschule-bamberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Berufsoberschule Bamberg (slug: staatliche-berufsoberschule-bamberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-berufsoberschule-bamberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-berufsoberschule-bamberg' 
  AND is_school = true
")


# Update oldest school (slug: 96050-staedtische-graf-stauffenberg-realschule-bamberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gsr-bamberg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '96050-staedtische-graf-stauffenberg-realschule-bamberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtische Graf-Stauffenberg-Realschule Bamberg (slug: stadtische-graf-stauffenberg-realschule-bamberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtische-graf-stauffenberg-realschule-bamberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtische-graf-stauffenberg-realschule-bamberg' 
  AND is_school = true
")


# Update oldest school (slug: 96050-staatliche-fachoberschule-bamberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.bos-bamberg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '96050-staatliche-fachoberschule-bamberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Fachoberschule Bamberg (slug: staatliche-fachoberschule-bamberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-fachoberschule-bamberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-fachoberschule-bamberg' 
  AND is_school = true
")


# Update oldest school (slug: 96050-staedtisches-eichendorff-gymnasium-bamberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.eg-bamberg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '96050-staedtisches-eichendorff-gymnasium-bamberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städtisches Eichendorff-Gymnasium Bamberg (slug: stadtisches-eichendorff-gymnasium-bamberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadtisches-eichendorff-gymnasium-bamberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadtisches-eichendorff-gymnasium-bamberg' 
  AND is_school = true
")


# Update oldest school (slug: 96052-dientzenhofer-gymnasium-bamberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.dg-info.de',
              phone_number = '+49 951 932390',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '96052-dientzenhofer-gymnasium-bamberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Dientzenhofer-Gymnasium Bamberg (slug: dientzenhofer-gymnasium-bamberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'dientzenhofer-gymnasium-bamberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'dientzenhofer-gymnasium-bamberg' 
  AND is_school = true
")


# Update oldest school (slug: 96106-friedrich-rueckert-gymnasium-ebern) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.frg-ebern.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '96106-friedrich-rueckert-gymnasium-ebern' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Friedrich-Rückert-Gymnasium Ebern (slug: friedrich-ruckert-gymnasium-ebern)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'friedrich-ruckert-gymnasium-ebern' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'friedrich-ruckert-gymnasium-ebern' 
  AND is_school = true
")


# Update oldest school (slug: 96110-staatliche-realschule-schesslitz) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.real-schesslitz.de',
              phone_number = '+49 9542 772050',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '96110-staatliche-realschule-schesslitz' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Scheßlitz (slug: staatliche-realschule-schesslitz)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-schesslitz' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-schesslitz' 
  AND is_school = true
")


# Update oldest school (slug: 96157-steigerwaldschule-staatliche-realschule-ebrach) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.steigerwaldschule-ebrach.de',
              phone_number = '+49 9553 9899080',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '96157-steigerwaldschule-staatliche-realschule-ebrach' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Steigerwaldschule Staatliche Realschule Ebrach (slug: steigerwaldschule-staatliche-realschule-ebrach)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'steigerwaldschule-staatliche-realschule-ebrach' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'steigerwaldschule-staatliche-realschule-ebrach' 
  AND is_school = true
")


# Update oldest school (slug: 96215-meranier-gymnasium-lichtenfels) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.meranier-gymnasium.de',
              phone_number = '+49 9571 95130',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '96215-meranier-gymnasium-lichtenfels' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Meranier-Gymnasium Lichtenfels (slug: meranier-gymnasium-lichtenfels)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'meranier-gymnasium-lichtenfels' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'meranier-gymnasium-lichtenfels' 
  AND is_school = true
")


# Update oldest school (slug: 96224-staatliche-realschule-burgkunstadt) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-burgkunstadt.de',
              phone_number = '+49 9572 6097800',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '96224-staatliche-realschule-burgkunstadt' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Burgkunstadt (slug: staatliche-realschule-burgkunstadt)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-burgkunstadt' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-burgkunstadt' 
  AND is_school = true
")


# Update oldest school (slug: 96224-gymnasium-burgkunstadt) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-burgkunstadt.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '96224-gymnasium-burgkunstadt' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Burgkunstadt (slug: gymnasium-burgkunstadt)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-burgkunstadt' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-burgkunstadt' 
  AND is_school = true
")


# Update oldest school (slug: 96317-siegmund-loewe-schule-staatliche-realschule-kronach-ii) with newest data
execute("
  UPDATE addresses 
  SET phone_number = '+49 9261 569950',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '96317-siegmund-loewe-schule-staatliche-realschule-kronach-ii' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Siegmund-Loewe-Schule Staatliche Realschule Kronach II (slug: siegmund-loewe-schule-staatliche-realschule-kronach-ii)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'siegmund-loewe-schule-staatliche-realschule-kronach-ii' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'siegmund-loewe-schule-staatliche-realschule-kronach-ii' 
  AND is_school = true
")


# No updates needed for school slug: 96317-maximilian-von-welsch-schule-staatliche-realschule-kronach-i
# Delete duplicate school: Maximilian-von-Welsch-Schule Staatliche Realschule Kronach I (slug: maximilian-von-welsch-schule-staatliche-realschule-kronach-i)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'maximilian-von-welsch-schule-staatliche-realschule-kronach-i' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'maximilian-von-welsch-schule-staatliche-realschule-kronach-i' 
  AND is_school = true
")


# Update oldest school (slug: 96317-frankenwald-gymnasium-kronach) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.frankenwald-gymnasium.de',
              phone_number = '+49 9261 62120',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '96317-frankenwald-gymnasium-kronach' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Frankenwald-Gymnasium Kronach (slug: frankenwald-gymnasium-kronach)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'frankenwald-gymnasium-kronach' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'frankenwald-gymnasium-kronach' 
  AND is_school = true
")


# Update oldest school (slug: 96317-kaspar-zeuss-gymnasium-kronach) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.kzg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '96317-kaspar-zeuss-gymnasium-kronach' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Kaspar-Zeuß-Gymnasium Kronach (slug: kaspar-zeuss-gymnasium-kronach)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'kaspar-zeuss-gymnasium-kronach' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'kaspar-zeuss-gymnasium-kronach' 
  AND is_school = true
")


# Update oldest school (slug: 96450-gymnasium-casimirianum-coburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.casimirianum.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '96450-gymnasium-casimirianum-coburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Casimirianum Coburg (slug: gymnasium-casimirianum-coburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-casimirianum-coburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-casimirianum-coburg' 
  AND is_school = true
")


# Update oldest school (slug: 96450-staatliche-realschule-coburg-i) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rscoburg1.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '96450-staatliche-realschule-coburg-i' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Coburg I (slug: staatliche-realschule-coburg-i)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-coburg-i' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-coburg-i' 
  AND is_school = true
")


# Update oldest school (slug: 96450-gymnasium-albertinum-coburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gym-albertinum.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '96450-gymnasium-albertinum-coburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Albertinum Coburg (slug: gymnasium-albertinum-coburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-albertinum-coburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-albertinum-coburg' 
  AND is_school = true
")


# Update oldest school (slug: 96450-gymnasium-alexandrinum-coburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.alexandrinum-coburg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '96450-gymnasium-alexandrinum-coburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Alexandrinum Coburg (slug: gymnasium-alexandrinum-coburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-alexandrinum-coburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-alexandrinum-coburg' 
  AND is_school = true
")


# Update oldest school (slug: 96450-gymnasium-ernestinum-coburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.ernestinum-coburg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '96450-gymnasium-ernestinum-coburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Ernestinum Coburg (slug: gymnasium-ernestinum-coburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-ernestinum-coburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-ernestinum-coburg' 
  AND is_school = true
")


# Update oldest school (slug: 96450-regiomontanus-schule-staatliche-fachoberschule-coburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fos-coburg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '96450-regiomontanus-schule-staatliche-fachoberschule-coburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Regiomontanus-Schule Staatliche Fachoberschule Coburg (slug: regiomontanus-schule-staatliche-fachoberschule-coburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'regiomontanus-schule-staatliche-fachoberschule-coburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'regiomontanus-schule-staatliche-fachoberschule-coburg' 
  AND is_school = true
")


# Update oldest school (slug: 96450-regiomontanus-schule-staatliche-berufsoberschule-coburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fos-coburg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '96450-regiomontanus-schule-staatliche-berufsoberschule-coburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Regiomontanus-Schule Staatliche Berufsoberschule Coburg (slug: regiomontanus-schule-staatliche-berufsoberschule-coburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'regiomontanus-schule-staatliche-berufsoberschule-coburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'regiomontanus-schule-staatliche-berufsoberschule-coburg' 
  AND is_school = true
")


# Update oldest school (slug: 96465-arnold-gymnasium-neustadt-bei-coburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.arnold-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '96465-arnold-gymnasium-neustadt-bei-coburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Arnold-Gymnasium Neustadt bei Coburg (slug: arnold-gymnasium-neustadt-bei-coburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'arnold-gymnasium-neustadt-bei-coburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'arnold-gymnasium-neustadt-bei-coburg' 
  AND is_school = true
")


# Update oldest school (slug: 96465-staatliche-realschule-neustadt-b-coburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rsnec.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '96465-staatliche-realschule-neustadt-b-coburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Neustadt b.Coburg (slug: staatliche-realschule-neustadt-b-coburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-neustadt-b-coburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-neustadt-b-coburg' 
  AND is_school = true
")


# Update oldest school (slug: 97070-riemenschneider-gymnasium-wuerzburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.riemenschneider-gymnasium.de',
              phone_number = '+49 931 322650',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97070-riemenschneider-gymnasium-wuerzburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Riemenschneider-Gymnasium Würzburg (slug: riemenschneider-gymnasium-wurzburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'riemenschneider-gymnasium-wurzburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'riemenschneider-gymnasium-wurzburg' 
  AND is_school = true
")


# Update oldest school (slug: 97070-siebold-gymnasium-wuerzburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.siebold-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97070-siebold-gymnasium-wuerzburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Siebold-Gymnasium Würzburg (slug: siebold-gymnasium-wurzburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'siebold-gymnasium-wurzburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'siebold-gymnasium-wurzburg' 
  AND is_school = true
")


# Update oldest school (slug: 97070-roentgen-gymnasium-wuerzburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.roentgen-gym.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97070-roentgen-gymnasium-wuerzburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Röntgen-Gymnasium Würzburg (slug: rontgen-gymnasium-wurzburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'rontgen-gymnasium-wurzburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'rontgen-gymnasium-wurzburg' 
  AND is_school = true
")


# Update oldest school (slug: 97070-wirsberg-gymnasium-wuerzburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.wirsberg-gymnasium.de',
              phone_number = '+49 931 3211511',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97070-wirsberg-gymnasium-wuerzburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Wirsberg-Gymnasium Würzburg (slug: wirsberg-gymnasium-wurzburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'wirsberg-gymnasium-wurzburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'wirsberg-gymnasium-wurzburg' 
  AND is_school = true
")


# Update oldest school (slug: 97074-david-schuster-realschule-staatl-realschule-wuerzburg-iii) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.david-schuster-realschule.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97074-david-schuster-realschule-staatl-realschule-wuerzburg-iii' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: David-Schuster-Realschule Staatl. Realschule Würzburg III (slug: david-schuster-realschule-staatl-realschule-wurzburg-iii)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'david-schuster-realschule-staatl-realschule-wurzburg-iii' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'david-schuster-realschule-staatl-realschule-wurzburg-iii' 
  AND is_school = true
")


# Update oldest school (slug: 97074-matthias-gruenewald-gymnasium-wuerzburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.mgg-wuerzburg.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97074-matthias-gruenewald-gymnasium-wuerzburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Matthias-Grünewald-Gymnasium Würzburg (slug: matthias-grunewald-gymnasium-wurzburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'matthias-grunewald-gymnasium-wurzburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'matthias-grunewald-gymnasium-wurzburg' 
  AND is_school = true
")


# Update oldest school (slug: 97078-wolffskeel-schule-staatliche-realschule-wuerzburg-ii) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://https://www.wolffskeelrealschule.de/',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97078-wolffskeel-schule-staatliche-realschule-wuerzburg-ii' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Wolffskeel-Schule Staatliche Realschule Würzburg II (slug: wolffskeel-schule-staatliche-realschule-wurzburg-ii)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'wolffskeel-schule-staatliche-realschule-wurzburg-ii' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'wolffskeel-schule-staatliche-realschule-wurzburg-ii' 
  AND is_school = true
")


# Update oldest school (slug: 97082-friedrich-koenig-gymnasium-wuerzburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fkg-wuerzburg.de',
              phone_number = '+49 931 453610',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97082-friedrich-koenig-gymnasium-wuerzburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Friedrich-Koenig-Gymnasium Würzburg (slug: friedrich-koenig-gymnasium-wurzburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'friedrich-koenig-gymnasium-wurzburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'friedrich-koenig-gymnasium-wurzburg' 
  AND is_school = true
")


# Update oldest school (slug: 97082-jakob-stoll-schule-staatliche-realschule-wuerzburg-i) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.jakob-stoll-realschule.de',
              phone_number = '+49 931 453450',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97082-jakob-stoll-schule-staatliche-realschule-wuerzburg-i' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Jakob-Stoll-Schule Staatliche Realschule Würzburg I (slug: jakob-stoll-schule-staatliche-realschule-wurzburg-i)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'jakob-stoll-schule-staatliche-realschule-wurzburg-i' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'jakob-stoll-schule-staatliche-realschule-wurzburg-i' 
  AND is_school = true
")


# Update oldest school (slug: 97082-deutschhaus-gymnasium-wuerzburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.deutschhaus.de',
              phone_number = '+49 931 359400',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97082-deutschhaus-gymnasium-wuerzburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Deutschhaus-Gymnasium Würzburg (slug: deutschhaus-gymnasium-wurzburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'deutschhaus-gymnasium-wurzburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'deutschhaus-gymnasium-wurzburg' 
  AND is_school = true
")


# Update oldest school (slug: 97199-realschule-am-maindreieck-staatliche-realschule-ochsenfurt) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rs-ochsenfurt.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97199-realschule-am-maindreieck-staatliche-realschule-ochsenfurt' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Realschule am Maindreieck Staatliche Realschule Ochsenfurt (slug: realschule-am-maindreieck-staatliche-realschule-ochsenfurt)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'realschule-am-maindreieck-staatliche-realschule-ochsenfurt' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'realschule-am-maindreieck-staatliche-realschule-ochsenfurt' 
  AND is_school = true
")


# Update oldest school (slug: 97204-leopold-sonnemann-realschule-staatliche-realschule-hoechberg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-hoechberg.de',
              phone_number = '+49 931 467973',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97204-leopold-sonnemann-realschule-staatliche-realschule-hoechberg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Leopold-Sonnemann-Realschule Staatliche Realschule Höchberg (slug: leopold-sonnemann-realschule-staatliche-realschule-hochberg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'leopold-sonnemann-realschule-staatliche-realschule-hochberg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'leopold-sonnemann-realschule-staatliche-realschule-hochberg' 
  AND is_school = true
")


# Update oldest school (slug: 97209-gymnasium-veitshoechheim) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-veitshoechheim.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97209-gymnasium-veitshoechheim' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Veitshöchheim (slug: gymnasium-veitshochheim)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-veitshochheim' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-veitshochheim' 
  AND is_school = true
")


# Update oldest school (slug: 97215-private-christian-von-bomhard-fachoberschule-fuer-sozialwesen-uffenh) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.bomhardschule.de',
              phone_number = '+49 9842 93670',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97215-private-christian-von-bomhard-fachoberschule-fuer-sozialwesen-uffenh' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Private Christian-von-Bomhard-Fachoberschule für Sozialwesen Uffenheim (slug: private-christian-von-bomhard-fachoberschule-fur-sozialwesen-uffenheim)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'private-christian-von-bomhard-fachoberschule-fur-sozialwesen-uffenheim' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'private-christian-von-bomhard-fachoberschule-fur-sozialwesen-uffenheim' 
  AND is_school = true
")


# Update oldest school (slug: 97318-armin-knab-gymnasium-kitzingen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.armin-knab-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97318-armin-knab-gymnasium-kitzingen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Armin-Knab-Gymnasium Kitzingen (slug: armin-knab-gymnasium-kitzingen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'armin-knab-gymnasium-kitzingen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'armin-knab-gymnasium-kitzingen' 
  AND is_school = true
")


# Update oldest school (slug: 97318-volksschule-kitzingen-siedlung) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.mittelschule-kitzingen-siedlung.de',
              phone_number = '+49 9321 9305010',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97318-volksschule-kitzingen-siedlung' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Volksschule Kitzingen-Siedlung (slug: 97318-volksschule-kitzingen-siedlung-4973f724-b970-11e7-bb22-001ec9cdab18)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97318-volksschule-kitzingen-siedlung-4973f724-b970-11e7-bb22-001ec9cdab18' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = '97318-volksschule-kitzingen-siedlung-4973f724-b970-11e7-bb22-001ec9cdab18' 
  AND is_school = true
")


# Update oldest school (slug: 97337-staatliche-realschule-dettelbach) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://https://www.rs-dettelbach.de/',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97337-staatliche-realschule-dettelbach' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Dettelbach (slug: staatliche-realschule-dettelbach)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-dettelbach' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-dettelbach' 
  AND is_school = true
")


# Update oldest school (slug: 97340-gymnasium-marktbreit) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-marktbreit.de',
              phone_number = '+49 9332 59260',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97340-gymnasium-marktbreit' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Marktbreit (slug: gymnasium-marktbreit)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-marktbreit' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-marktbreit' 
  AND is_school = true
")


# Update oldest school (slug: 97340-leo-weismantel-realschule-priv-realschule-d-realschulver-marktbr) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://https://www.realschule-marktbreit.de/',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97340-leo-weismantel-realschule-priv-realschule-d-realschulver-marktbr' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Leo Weismantel-Realschule Priv. Realschule d. Realschulver. Marktbreit e.V. (slug: leo-weismantel-realschule-priv-realschule-d-realschulver-marktbreit-e-v)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'leo-weismantel-realschule-priv-realschule-d-realschulver-marktbreit-e-v' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'leo-weismantel-realschule-priv-realschule-d-realschulver-marktbreit-e-v' 
  AND is_school = true
")


# Update oldest school (slug: 97421-walther-rathenau-realschule-der-stadt-schweinfurt) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://https://www.walther-rathenau-sw.de/',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97421-walther-rathenau-realschule-der-stadt-schweinfurt' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Walther-Rathenau-Realschule der Stadt Schweinfurt (slug: walther-rathenau-realschule-der-stadt-schweinfurt)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'walther-rathenau-realschule-der-stadt-schweinfurt' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'walther-rathenau-realschule-der-stadt-schweinfurt' 
  AND is_school = true
")


# Update oldest school (slug: 97421-friedrich-fischer-schule-staatliche-fachoberschule-schweinfurt) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fosbos-sw.de',
              phone_number = '+49 9721 978070',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97421-friedrich-fischer-schule-staatliche-fachoberschule-schweinfurt' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Friedrich-Fischer-Schule Staatliche Fachoberschule Schweinfurt (slug: friedrich-fischer-schule-staatliche-fachoberschule-schweinfurt)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'friedrich-fischer-schule-staatliche-fachoberschule-schweinfurt' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'friedrich-fischer-schule-staatliche-fachoberschule-schweinfurt' 
  AND is_school = true
")


# Update oldest school (slug: 97421-staedt-walther-rathenau-gymnasium-schweinfurt) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.walther-rathenau-sw.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97421-staedt-walther-rathenau-gymnasium-schweinfurt' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Städt. Walther-Rathenau-Gymnasium Schweinfurt (slug: stadt-walther-rathenau-gymnasium-schweinfurt)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'stadt-walther-rathenau-gymnasium-schweinfurt' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'stadt-walther-rathenau-gymnasium-schweinfurt' 
  AND is_school = true
")


# Update oldest school (slug: 97421-friedrich-fischer-schule-staatl-berufsoberschule-schweinfurt) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fosbos-sw.de',
              phone_number = '+49 9721 978070',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97421-friedrich-fischer-schule-staatl-berufsoberschule-schweinfurt' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Friedrich-Fischer-Schule Staatl.Berufsoberschule Schweinfurt (slug: friedrich-fischer-schule-staatl-berufsoberschule-schweinfurt)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'friedrich-fischer-schule-staatl-berufsoberschule-schweinfurt' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'friedrich-fischer-schule-staatl-berufsoberschule-schweinfurt' 
  AND is_school = true
")


# Update oldest school (slug: 97421-wilhelm-sattler-realschule-staatl-realschule-schweinfurt) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.wsr-sw.de',
              phone_number = '+49 9721 519351',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97421-wilhelm-sattler-realschule-staatl-realschule-schweinfurt' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Wilhelm-Sattler-Realschule Staatl. Realschule Schweinfurt (slug: wilhelm-sattler-realschule-staatl-realschule-schweinfurt)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'wilhelm-sattler-realschule-staatl-realschule-schweinfurt' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'wilhelm-sattler-realschule-staatl-realschule-schweinfurt' 
  AND is_school = true
")


# Update oldest school (slug: 97421-celtis-gymnasium-schweinfurt) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.celtis.de',
              phone_number = '+49 9721 675060',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97421-celtis-gymnasium-schweinfurt' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Celtis-Gymnasium Schweinfurt (slug: celtis-gymnasium-schweinfurt)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'celtis-gymnasium-schweinfurt' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'celtis-gymnasium-schweinfurt' 
  AND is_school = true
")


# Update oldest school (slug: 97421-olympia-morata-gymnasium-schweinfurt) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.olympia-morata-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97421-olympia-morata-gymnasium-schweinfurt' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Olympia-Morata-Gymnasium Schweinfurt (slug: olympia-morata-gymnasium-schweinfurt)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'olympia-morata-gymnasium-schweinfurt' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'olympia-morata-gymnasium-schweinfurt' 
  AND is_school = true
")


# Update oldest school (slug: 97424-alexander-von-humboldt-gymnasium-schweinfurt) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.avhsw.de',
              phone_number = '+49 9721 518100',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97424-alexander-von-humboldt-gymnasium-schweinfurt' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Alexander-von-Humboldt-Gymnasium Schweinfurt (slug: alexander-von-humboldt-gymnasium-schweinfurt)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'alexander-von-humboldt-gymnasium-schweinfurt' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'alexander-von-humboldt-gymnasium-schweinfurt' 
  AND is_school = true
")


# Update oldest school (slug: 97437-regiomontanus-gymnasium-hassfurt) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.regiomontanus-gymnasium.de',
              phone_number = '+49 9521 944413',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97437-regiomontanus-gymnasium-hassfurt' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Regiomontanus-Gymnasium Haßfurt (slug: regiomontanus-gymnasium-hassfurt)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'regiomontanus-gymnasium-hassfurt' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'regiomontanus-gymnasium-hassfurt' 
  AND is_school = true
")


# Update oldest school (slug: 97447-ludwig-derleth-realschule-staatliche-realschule-gerolzhofen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.ldr-geo.de',
              phone_number = '+49 9382 3196950',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97447-ludwig-derleth-realschule-staatliche-realschule-gerolzhofen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Ludwig-Derleth-Realschule Staatliche Realschule Gerolzhofen (slug: ludwig-derleth-realschule-staatliche-realschule-gerolzhofen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'ludwig-derleth-realschule-staatliche-realschule-gerolzhofen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'ludwig-derleth-realschule-staatliche-realschule-gerolzhofen' 
  AND is_school = true
")


# Update oldest school (slug: 97450-michael-ignaz-schmidt-schule-staatliche-realschule-arnstein) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-arnstein.de',
              phone_number = '+49 9363 997730',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97450-michael-ignaz-schmidt-schule-staatliche-realschule-arnstein' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Michael-Ignaz-Schmidt-Schule Staatliche Realschule Arnstein (slug: michael-ignaz-schmidt-schule-staatliche-realschule-arnstein)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'michael-ignaz-schmidt-schule-staatliche-realschule-arnstein' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'michael-ignaz-schmidt-schule-staatliche-realschule-arnstein' 
  AND is_school = true
")


# Update oldest school (slug: 97483-wallburg-realschule-staatliche-realschule-eltmann) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rs-eltmann.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97483-wallburg-realschule-staatliche-realschule-eltmann' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Wallburg-Realschule Staatliche Realschule Eltmann (slug: wallburg-realschule-staatliche-realschule-eltmann)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'wallburg-realschule-staatliche-realschule-eltmann' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'wallburg-realschule-staatliche-realschule-eltmann' 
  AND is_school = true
")


# No updates needed for school slug: 97526-volksschule-sennfeld
# Delete duplicate school: Volksschule Sennfeld (slug: 97526-volksschule-sennfeld-496935be-b970-11e7-b438-001ec9cdab18)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97526-volksschule-sennfeld-496935be-b970-11e7-b438-001ec9cdab18' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = '97526-volksschule-sennfeld-496935be-b970-11e7-b438-001ec9cdab18' 
  AND is_school = true
")


# Update oldest school (slug: 97616-staatliche-berufsoberschule-bad-neustadt-a-d-saale) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fosnes.de',
              phone_number = '+49 9771 7038',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97616-staatliche-berufsoberschule-bad-neustadt-a-d-saale' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Berufsoberschule Bad Neustadt a.d.Saale (slug: staatliche-berufsoberschule-bad-neustadt-a-d-saale)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-berufsoberschule-bad-neustadt-a-d-saale' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-berufsoberschule-bad-neustadt-a-d-saale' 
  AND is_school = true
")


# Update oldest school (slug: 97616-staatliche-fachoberschule-bad-neustadt-a-d-saale) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fosnes.de',
              phone_number = '+49 9771 7038',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97616-staatliche-fachoberschule-bad-neustadt-a-d-saale' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Fachoberschule Bad Neustadt a.d.Saale (slug: staatliche-fachoberschule-bad-neustadt-a-d-saale)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-fachoberschule-bad-neustadt-a-d-saale' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-fachoberschule-bad-neustadt-a-d-saale' 
  AND is_school = true
")


# Update oldest school (slug: 97616-werner-von-siemens-realschule-staatl-realschule-bad-neustadt-a-d-s) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rs-nes.de',
              phone_number = '+49 9771 63080100',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97616-werner-von-siemens-realschule-staatl-realschule-bad-neustadt-a-d-s' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Werner-von-Siemens-Realschule Staatl. Realschule Bad Neustadt a.d.Saale (slug: werner-von-siemens-realschule-staatl-realschule-bad-neustadt-a-d-saale)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'werner-von-siemens-realschule-staatl-realschule-bad-neustadt-a-d-saale' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'werner-von-siemens-realschule-staatl-realschule-bad-neustadt-a-d-saale' 
  AND is_school = true
")


# Update oldest school (slug: 97616-rhoen-gymnasium-bad-neustadt) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rhoengymnasium.de',
              phone_number = '+49 9771 630150',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97616-rhoen-gymnasium-bad-neustadt' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Rhön-Gymnasium Bad Neustadt (slug: rhon-gymnasium-bad-neustadt)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'rhon-gymnasium-bad-neustadt' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'rhon-gymnasium-bad-neustadt' 
  AND is_school = true
")


# Update oldest school (slug: 97631-gymnasium-bad-koenigshofen-i-gr) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-badkoenigshofen.de',
              phone_number = '+49 9761 395650',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97631-gymnasium-bad-koenigshofen-i-gr' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Gymnasium Bad Königshofen i.Gr. (slug: gymnasium-bad-konigshofen-i-gr)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'gymnasium-bad-konigshofen-i-gr' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'gymnasium-bad-konigshofen-i-gr' 
  AND is_school = true
")


# Update oldest school (slug: 97631-dr-karl-gruenewald-schule-staatliche-realschule-bad-koenigshofen-i-gr) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://https://www.rs-badkoenigshofen.de/',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97631-dr-karl-gruenewald-schule-staatliche-realschule-bad-koenigshofen-i-gr' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Dr.-Karl-Grünewald-Schule Staatliche Realschule Bad Königshofen i.Gr. (slug: dr-karl-grunewald-schule-staatliche-realschule-bad-konigshofen-i-gr)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'dr-karl-grunewald-schule-staatliche-realschule-bad-konigshofen-i-gr' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'dr-karl-grunewald-schule-staatliche-realschule-bad-konigshofen-i-gr' 
  AND is_school = true
")


# Update oldest school (slug: 97638-ignaz-reder-realschule-staatliche-realschule-mellrichstadt) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rs-met.de',
              phone_number = '+49 9776 705600',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97638-ignaz-reder-realschule-staatliche-realschule-mellrichstadt' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Ignaz-Reder-Realschule Staatliche Realschule Mellrichstadt (slug: ignaz-reder-realschule-staatliche-realschule-mellrichstadt)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'ignaz-reder-realschule-staatliche-realschule-mellrichstadt' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'ignaz-reder-realschule-staatliche-realschule-mellrichstadt' 
  AND is_school = true
")


# Update oldest school (slug: 97638-martin-pollich-gymnasium-mellrichstadt) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.mpg-met.de',
              phone_number = '+49 9776 7090970',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97638-martin-pollich-gymnasium-mellrichstadt' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Martin-Pollich-Gymnasium Mellrichstadt (slug: martin-pollich-gymnasium-mellrichstadt)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'martin-pollich-gymnasium-mellrichstadt' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'martin-pollich-gymnasium-mellrichstadt' 
  AND is_school = true
")


# Update oldest school (slug: 97688-jack-steinberger-gymnasium-bad-kissingen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.jack-steinberger-gymnasium.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97688-jack-steinberger-gymnasium-bad-kissingen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Jack-Steinberger-Gymnasium Bad Kissingen (slug: jack-steinberger-gymnasium-bad-kissingen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'jack-steinberger-gymnasium-bad-kissingen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'jack-steinberger-gymnasium-bad-kissingen' 
  AND is_school = true
")


# Update oldest school (slug: 97688-staatliche-realschule-bad-kissingen) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschulebadkissingen.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97688-staatliche-realschule-bad-kissingen' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Bad Kissingen (slug: staatliche-realschule-bad-kissingen)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-bad-kissingen' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-bad-kissingen' 
  AND is_school = true
")


# Update oldest school (slug: 97702-freiherr-von-lutz-volksschule-muennerstadt) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.ms-muen.de',
              phone_number = '+49 9733 810220',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97702-freiherr-von-lutz-volksschule-muennerstadt' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Freiherr-von-Lutz-Volksschule Münnerstadt (slug: 97702-freiherr-von-lutz-volksschule-muennerstadt-4966579a-b970-11e7-ac61-001ec9cdab18)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97702-freiherr-von-lutz-volksschule-muennerstadt-4966579a-b970-11e7-ac61-001ec9cdab18' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = '97702-freiherr-von-lutz-volksschule-muennerstadt-4966579a-b970-11e7-ac61-001ec9cdab18' 
  AND is_school = true
")


# Update oldest school (slug: 97737-friedrich-list-gymnasium-gemuenden) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.flg-gemuenden.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97737-friedrich-list-gymnasium-gemuenden' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Friedrich-List-Gymnasium Gemünden (slug: friedrich-list-gymnasium-gemunden)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'friedrich-list-gymnasium-gemunden' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'friedrich-list-gymnasium-gemunden' 
  AND is_school = true
")


# Update oldest school (slug: 97737-staatliche-realschule-gemuenden-a-main) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://https://www.rs-gemuenden.de/',
              phone_number = '+49 9351 604220',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97737-staatliche-realschule-gemuenden-a-main' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Gemünden a.Main (slug: staatliche-realschule-gemunden-a-main)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-gemunden-a-main' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-gemunden-a-main' 
  AND is_school = true
")


# Update oldest school (slug: 97753-johann-schoener-gymnasium-karlstadt) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.jsg-karlstadt.de',
              phone_number = '+49 9353 985750',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97753-johann-schoener-gymnasium-karlstadt' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Johann-Schöner-Gymnasium Karlstadt (slug: johann-schoner-gymnasium-karlstadt)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'johann-schoner-gymnasium-karlstadt' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'johann-schoner-gymnasium-karlstadt' 
  AND is_school = true
")


# Update oldest school (slug: 97753-johann-rudolph-glauber-schule-staatliche-realschule-karlstadt) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.realschule-karlstadt.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97753-johann-rudolph-glauber-schule-staatliche-realschule-karlstadt' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Johann-Rudolph-Glauber-Schule Staatliche Realschule Karlstadt (slug: johann-rudolph-glauber-schule-staatliche-realschule-karlstadt)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'johann-rudolph-glauber-schule-staatliche-realschule-karlstadt' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'johann-rudolph-glauber-schule-staatliche-realschule-karlstadt' 
  AND is_school = true
")


# Update oldest school (slug: 97762-jakob-kaiser-realschule-staatliche-realschule-hammelburg) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.jakob-kaiser-realschule.de',
              phone_number = '+49 9732 789030',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97762-jakob-kaiser-realschule-staatliche-realschule-hammelburg' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Jakob-Kaiser-Realschule Staatliche Realschule Hammelburg (slug: jakob-kaiser-realschule-staatliche-realschule-hammelburg)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'jakob-kaiser-realschule-staatliche-realschule-hammelburg' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'jakob-kaiser-realschule-staatliche-realschule-hammelburg' 
  AND is_school = true
")


# Update oldest school (slug: 97769-staatliche-realschule-bad-brueckenau) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://https://www.rsbrk.de/',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97769-staatliche-realschule-bad-brueckenau' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Bad Brückenau (slug: staatliche-realschule-bad-bruckenau)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-bad-bruckenau' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-bad-bruckenau' 
  AND is_school = true
")


# Update oldest school (slug: 97769-franz-miltenberger-gymnasium-bad-brueckenau) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fmg-brk.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97769-franz-miltenberger-gymnasium-bad-brueckenau' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Franz-Miltenberger-Gymnasium Bad Brückenau (slug: franz-miltenberger-gymnasium-bad-bruckenau)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'franz-miltenberger-gymnasium-bad-bruckenau' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'franz-miltenberger-gymnasium-bad-bruckenau' 
  AND is_school = true
")


# Update oldest school (slug: 97816-franz-ludwig-von-erthal-gymnasium-lohr) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.gymnasium-lohr.de',
              phone_number = '+49 9352 5004220',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97816-franz-ludwig-von-erthal-gymnasium-lohr' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Franz-Ludwig-von-Erthal-Gymnasium Lohr (slug: franz-ludwig-von-erthal-gymnasium-lohr)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'franz-ludwig-von-erthal-gymnasium-lohr' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'franz-ludwig-von-erthal-gymnasium-lohr' 
  AND is_school = true
")


# Update oldest school (slug: 97816-georg-ludwig-rexroth-realschule-staatliche-realschule-lohr) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rs-lohr.de',
              phone_number = '+49 9352 6032720',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97816-georg-ludwig-rexroth-realschule-staatliche-realschule-lohr' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Georg-Ludwig-Rexroth-Realschule Staatliche Realschule Lohr (slug: georg-ludwig-rexroth-realschule-staatliche-realschule-lohr)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'georg-ludwig-rexroth-realschule-staatliche-realschule-lohr' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'georg-ludwig-rexroth-realschule-staatliche-realschule-lohr' 
  AND is_school = true
")


# Update oldest school (slug: 97828-staatliche-realschule-marktheidenfeld) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.rsmar.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97828-staatliche-realschule-marktheidenfeld' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Realschule Marktheidenfeld (slug: staatliche-realschule-marktheidenfeld)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-realschule-marktheidenfeld' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-realschule-marktheidenfeld' 
  AND is_school = true
")


# Update oldest school (slug: 97828-staatliche-berufsoberschule-marktheidenfeld) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fosbos-marktheidenfeld.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97828-staatliche-berufsoberschule-marktheidenfeld' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Berufsoberschule Marktheidenfeld (slug: staatliche-berufsoberschule-marktheidenfeld)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-berufsoberschule-marktheidenfeld' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-berufsoberschule-marktheidenfeld' 
  AND is_school = true
")


# Update oldest school (slug: 97828-staatliche-fachoberschule-marktheidenfeld) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.fosbos-marktheidenfeld.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97828-staatliche-fachoberschule-marktheidenfeld' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Staatliche Fachoberschule Marktheidenfeld (slug: staatliche-fachoberschule-marktheidenfeld)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'staatliche-fachoberschule-marktheidenfeld' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'staatliche-fachoberschule-marktheidenfeld' 
  AND is_school = true
")


# Update oldest school (slug: 97828-balthasar-neumann-gymnasium-marktheidenfeld) with newest data
execute("
  UPDATE addresses 
  SET homepage_url = 'https://www.bng-online.de',
              
      updated_at = NOW()
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = '97828-balthasar-neumann-gymnasium-marktheidenfeld' 
    AND is_school = true
    LIMIT 1
  )
")

# Delete duplicate school: Balthasar-Neumann-Gymnasium Marktheidenfeld (slug: balthasar-neumann-gymnasium-marktheidenfeld)
execute("
  DELETE FROM addresses 
  WHERE school_location_id = (
    SELECT id FROM locations 
    WHERE slug = 'balthasar-neumann-gymnasium-marktheidenfeld' 
    AND is_school = true
    LIMIT 1
  )
")
execute("
  DELETE FROM locations 
  WHERE slug = 'balthasar-neumann-gymnasium-marktheidenfeld' 
  AND is_school = true
")

  end
  
  def down do
    # This migration is not reversible
    IO.puts("This migration cannot be reversed - deleted schools cannot be restored")
  end
end
