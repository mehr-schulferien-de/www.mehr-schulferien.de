# Seeds for religions
alias MehrSchulferien.Calendars
alias MehrSchulferien.Repo

# Clear existing data
Repo.delete_all(MehrSchulferien.Calendars.Religion)

{:ok, _religion_1} =
  Calendars.create_religion(%{name: "Christentum", wikipedia_url: "https://de.wikipedia.org/wiki/Christentum"})

{:ok, _religion_2} =
  Calendars.create_religion(%{name: "Judentum", wikipedia_url: "https://de.wikipedia.org/wiki/Judentum"})

{:ok, _religion_3} =
  Calendars.create_religion(%{name: "Islam", wikipedia_url: "https://de.wikipedia.org/wiki/Islam"})

