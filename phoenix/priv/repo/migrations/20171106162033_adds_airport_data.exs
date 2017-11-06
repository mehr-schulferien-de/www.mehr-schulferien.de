defmodule MehrSchulferien.Repo.Migrations.AddsAirportData do
  use Ecto.Migration
  alias MehrSchulferien.Locations
  alias MehrSchulferien.Locations.Airport
  alias MehrSchulferien.Repo
  import Ecto.Query, only: [from: 1]


  def up do
    query = from airports in Airport
    airports = Repo.all(query)

    if length(airports) == 0 do
      Locations.create_airport(%{name: "Berlin-Schönefeld", code: "SXF", federal_state_code: "BB", homepage_url: "http://www.berlin-airport.de/de/reisende-sxf/index.php" })
      Locations.create_airport(%{name: "Berlin-Tegel", code: "TXL", federal_state_code: "BE", homepage_url: "http://www.berlin-airport.de/de/reisende-txl/index.php" })
      Locations.create_airport(%{name: "Bremen", code: "BRE", federal_state_code: "HB", homepage_url: "http://www.bremen-airport.com" })
      Locations.create_airport(%{name: "Dresden", code: "DRS", federal_state_code: "SN", homepage_url: "http://www.dresden-airport.de" })
      Locations.create_airport(%{name: "Düsseldorf", code: "DUS", federal_state_code: "NW", homepage_url: "https://www.dus.com" })
      Locations.create_airport(%{name: "Erfurt-Weimar", code: "ERF", federal_state_code: "TH", homepage_url: "https://www.flughafen-erfurt-weimar.de" })
      Locations.create_airport(%{name: "Frankfurt am Main", code: "FRA", federal_state_code: "HE", homepage_url: "https://www.frankfurt-airport.com" })
      Locations.create_airport(%{name: "Hamburg", code: "HAM", federal_state_code: "HH", homepage_url: "https://www.hamburg-airport.de" })
      Locations.create_airport(%{name: "Hannover-Langenhagen", code: "HAJ", federal_state_code: "NI", homepage_url: "http://www.hannover-airport.de" })
      Locations.create_airport(%{name: "Köln/Bonn", code: "CGN", federal_state_code: "NW", homepage_url: "https://www.koeln-bonn-airport.de" })
      Locations.create_airport(%{name: "Leipzig/Halle", code: "LEJ", federal_state_code: "SN", homepage_url: "https://www.leipzig-halle-airport.de" })
      Locations.create_airport(%{name: "München", code: "MUC", federal_state_code: "BY", homepage_url: "https://www.munich-airport.de" })
      Locations.create_airport(%{name: "Münster/Osnabrück", code: "FMO", federal_state_code: "NW", homepage_url: "https://www.fmo.de" })
      Locations.create_airport(%{name: "Nürnberg", code: "NUE", federal_state_code: "BY", homepage_url: "https://www.airport-nuernberg.de" })
      Locations.create_airport(%{name: "Saarbrücken", code: "SCN", federal_state_code: "SL", homepage_url: "https://www.flughafen-saarbruecken.de" })
      Locations.create_airport(%{name: "Stuttgart", code: "STR", federal_state_code: "BW", homepage_url: "http://www.flughafen-stuttgart.de" })
    end
  end

  def down do

  end
end
