# Seeds for holiday or vacation types
alias MehrSchulferien.Calendars
alias MehrSchulferien.Repo

# Clear existing data
Repo.delete_all(MehrSchulferien.Calendars.HolidayOrVacationType)

{:ok, holiday_or_vacation_type_1} =
  Calendars.create_holiday_or_vacation_type(%{name: "Herbst", colloquial: "Herbstferien", country_location_id: 1, wikipedia_url: "https://de.m.wikipedia.org/wiki/Schulferien#Herbstferien", default_html_class: "success", default_is_listed_below_month: true, default_is_school_vacation: true, default_is_valid_for_students: true, default_is_valid_for_everybody: false, default_display_priority: 5})

{:ok, holiday_or_vacation_type_2} =
  Calendars.create_holiday_or_vacation_type(%{name: "Weihnachten", colloquial: "Weihnachtsferien", country_location_id: 1, wikipedia_url: "https://de.m.wikipedia.org/wiki/Schulferien#Weihnachtsferien", default_html_class: "success", default_is_listed_below_month: true, default_is_school_vacation: true, default_is_valid_for_students: true, default_is_valid_for_everybody: false, default_display_priority: 5})

{:ok, holiday_or_vacation_type_3} =
  Calendars.create_holiday_or_vacation_type(%{name: "Winter", colloquial: "Winterferien", country_location_id: 1, wikipedia_url: "https://de.m.wikipedia.org/wiki/Schulferien#Winter-/Sport-/Zeugnis-/Semester-/Faschingsferien", default_html_class: "success", default_is_listed_below_month: true, default_is_school_vacation: true, default_is_valid_for_students: true, default_is_valid_for_everybody: false, default_display_priority: 5})

{:ok, holiday_or_vacation_type_6} =
  Calendars.create_holiday_or_vacation_type(%{name: "Sommer", colloquial: "Sommerferien", country_location_id: 1, wikipedia_url: "https://de.m.wikipedia.org/wiki/Schulferien#Sommerferien", default_html_class: "success", default_is_listed_below_month: true, default_is_school_vacation: true, default_is_valid_for_students: true, default_is_valid_for_everybody: false, default_display_priority: 5})

{:ok, holiday_or_vacation_type_9} =
  Calendars.create_holiday_or_vacation_type(%{name: "Schulschließung wegen der COVID-19-Pandemie (Corona)", colloquial: "Corona-Schulschließung", country_location_id: 1, wikipedia_url: "https://de.wikipedia.org/wiki/COVID-19-Pandemie", default_html_class: "danger", default_is_listed_below_month: true, default_is_school_vacation: true, default_is_valid_for_students: true, default_is_valid_for_everybody: false, default_display_priority: 20})

{:ok, holiday_or_vacation_type_29} =
  Calendars.create_holiday_or_vacation_type(%{name: "Weltkindertag", colloquial: "Weltkindertag", country_location_id: 1, wikipedia_url: nil, default_html_class: nil, default_is_listed_below_month: false, default_is_school_vacation: false, default_is_valid_for_students: false, default_is_valid_for_everybody: false, default_display_priority: 10})

{:ok, holiday_or_vacation_type_28} =
  Calendars.create_holiday_or_vacation_type(%{name: "Pfingstsonntag", colloquial: "Pfingstsonntag", country_location_id: 1, wikipedia_url: nil, default_html_class: nil, default_is_listed_below_month: false, default_is_school_vacation: false, default_is_valid_for_students: false, default_is_valid_for_everybody: false, default_display_priority: 10})

{:ok, holiday_or_vacation_type_27} =
  Calendars.create_holiday_or_vacation_type(%{name: "Ostersonntag", colloquial: "Ostersonntag", country_location_id: 1, wikipedia_url: nil, default_html_class: nil, default_is_listed_below_month: false, default_is_school_vacation: false, default_is_valid_for_students: false, default_is_valid_for_everybody: false, default_display_priority: 10})

{:ok, holiday_or_vacation_type_26} =
  Calendars.create_holiday_or_vacation_type(%{name: "Frauentag", colloquial: "Frauentag", country_location_id: 1, wikipedia_url: nil, default_html_class: nil, default_is_listed_below_month: false, default_is_school_vacation: false, default_is_valid_for_students: false, default_is_valid_for_everybody: false, default_display_priority: 10})

{:ok, holiday_or_vacation_type_25} =
  Calendars.create_holiday_or_vacation_type(%{name: "Mariä Himmelfahrt", colloquial: "Mariä Himmelfahrt", country_location_id: 1, wikipedia_url: nil, default_html_class: nil, default_is_listed_below_month: false, default_is_school_vacation: false, default_is_valid_for_students: false, default_is_valid_for_everybody: false, default_display_priority: 10})

{:ok, holiday_or_vacation_type_24} =
  Calendars.create_holiday_or_vacation_type(%{name: "Buß- und Bettag", colloquial: "Buß- und Bettag", country_location_id: 1, wikipedia_url: nil, default_html_class: nil, default_is_listed_below_month: false, default_is_school_vacation: false, default_is_valid_for_students: false, default_is_valid_for_everybody: false, default_display_priority: 10})

{:ok, holiday_or_vacation_type_23} =
  Calendars.create_holiday_or_vacation_type(%{name: "Tag der Deutschen Einheit", colloquial: "Tag der Deutschen Einheit", country_location_id: 1, wikipedia_url: nil, default_html_class: nil, default_is_listed_below_month: false, default_is_school_vacation: false, default_is_valid_for_students: false, default_is_valid_for_everybody: false, default_display_priority: 10})

{:ok, holiday_or_vacation_type_22} =
  Calendars.create_holiday_or_vacation_type(%{name: "Tag der Arbeit", colloquial: "Tag der Arbeit", country_location_id: 1, wikipedia_url: nil, default_html_class: nil, default_is_listed_below_month: false, default_is_school_vacation: false, default_is_valid_for_students: false, default_is_valid_for_everybody: false, default_display_priority: 10})

{:ok, holiday_or_vacation_type_21} =
  Calendars.create_holiday_or_vacation_type(%{name: "Reformationstag", colloquial: "Reformationstag", country_location_id: 1, wikipedia_url: nil, default_html_class: nil, default_is_listed_below_month: false, default_is_school_vacation: false, default_is_valid_for_students: false, default_is_valid_for_everybody: false, default_display_priority: 10})

{:ok, holiday_or_vacation_type_20} =
  Calendars.create_holiday_or_vacation_type(%{name: "Pfingstmontag", colloquial: "Pfingstmontag", country_location_id: 1, wikipedia_url: nil, default_html_class: nil, default_is_listed_below_month: false, default_is_school_vacation: false, default_is_valid_for_students: false, default_is_valid_for_everybody: false, default_display_priority: 10})

{:ok, holiday_or_vacation_type_19} =
  Calendars.create_holiday_or_vacation_type(%{name: "Ostermontag", colloquial: "Ostermontag", country_location_id: 1, wikipedia_url: nil, default_html_class: nil, default_is_listed_below_month: false, default_is_school_vacation: false, default_is_valid_for_students: false, default_is_valid_for_everybody: false, default_display_priority: 10})

{:ok, holiday_or_vacation_type_18} =
  Calendars.create_holiday_or_vacation_type(%{name: "Neujahrstag", colloquial: "Neujahrstag", country_location_id: 1, wikipedia_url: nil, default_html_class: nil, default_is_listed_below_month: false, default_is_school_vacation: false, default_is_valid_for_students: false, default_is_valid_for_everybody: false, default_display_priority: 10})

{:ok, holiday_or_vacation_type_17} =
  Calendars.create_holiday_or_vacation_type(%{name: "Karfreitag", colloquial: "Karfreitag", country_location_id: 1, wikipedia_url: nil, default_html_class: nil, default_is_listed_below_month: false, default_is_school_vacation: false, default_is_valid_for_students: false, default_is_valid_for_everybody: false, default_display_priority: 10})

{:ok, holiday_or_vacation_type_16} =
  Calendars.create_holiday_or_vacation_type(%{name: "Heilige Drei Könige", colloquial: "Heilige Drei Könige", country_location_id: 1, wikipedia_url: nil, default_html_class: nil, default_is_listed_below_month: false, default_is_school_vacation: false, default_is_valid_for_students: false, default_is_valid_for_everybody: false, default_display_priority: 10})

{:ok, holiday_or_vacation_type_15} =
  Calendars.create_holiday_or_vacation_type(%{name: "Gründonnerstag", colloquial: "Gründonnerstag", country_location_id: 1, wikipedia_url: nil, default_html_class: nil, default_is_listed_below_month: false, default_is_school_vacation: false, default_is_valid_for_students: false, default_is_valid_for_everybody: false, default_display_priority: 10})

{:ok, holiday_or_vacation_type_14} =
  Calendars.create_holiday_or_vacation_type(%{name: "Fronleichnam", colloquial: "Fronleichnam", country_location_id: 1, wikipedia_url: nil, default_html_class: nil, default_is_listed_below_month: false, default_is_school_vacation: false, default_is_valid_for_students: false, default_is_valid_for_everybody: false, default_display_priority: 10})

{:ok, holiday_or_vacation_type_13} =
  Calendars.create_holiday_or_vacation_type(%{name: "Christi Himmelfahrt", colloquial: "Christi Himmelfahrt", country_location_id: 1, wikipedia_url: nil, default_html_class: nil, default_is_listed_below_month: false, default_is_school_vacation: false, default_is_valid_for_students: false, default_is_valid_for_everybody: false, default_display_priority: 10})

{:ok, holiday_or_vacation_type_12} =
  Calendars.create_holiday_or_vacation_type(%{name: "Allerheiligen", colloquial: "Allerheiligen", country_location_id: 1, wikipedia_url: nil, default_html_class: nil, default_is_listed_below_month: false, default_is_school_vacation: false, default_is_valid_for_students: false, default_is_valid_for_everybody: false, default_display_priority: 10})

{:ok, holiday_or_vacation_type_11} =
  Calendars.create_holiday_or_vacation_type(%{name: "2. Weihnachtstag", colloquial: "2. Weihnachtstag", country_location_id: 1, wikipedia_url: nil, default_html_class: nil, default_is_listed_below_month: false, default_is_school_vacation: false, default_is_valid_for_students: false, default_is_valid_for_everybody: false, default_display_priority: 10})

{:ok, holiday_or_vacation_type_10} =
  Calendars.create_holiday_or_vacation_type(%{name: "1. Weihnachtstag", colloquial: "1. Weihnachtstag", country_location_id: 1, wikipedia_url: nil, default_html_class: nil, default_is_listed_below_month: false, default_is_school_vacation: false, default_is_valid_for_students: false, default_is_valid_for_everybody: false, default_display_priority: 10})

{:ok, holiday_or_vacation_type_7} =
  Calendars.create_holiday_or_vacation_type(%{name: "Beweglicher Ferientag", colloquial: "Beweglicher Ferientag", country_location_id: 1, wikipedia_url: "https://de.wikipedia.org/wiki/Bewegliche_Ferientage", default_html_class: "success", default_is_listed_below_month: true, default_is_school_vacation: true, default_is_valid_for_students: true, default_is_valid_for_everybody: false, default_display_priority: 7})

{:ok, holiday_or_vacation_type_8} =
  Calendars.create_holiday_or_vacation_type(%{name: "Wochenende", colloquial: "Wochenende", country_location_id: 1, wikipedia_url: "https://de.wikipedia.org/wiki/Wochenende", default_html_class: "active", default_is_listed_below_month: false, default_is_school_vacation: false, default_is_valid_for_students: false, default_is_valid_for_everybody: true, default_display_priority: 4})

{:ok, holiday_or_vacation_type_30} =
  Calendars.create_holiday_or_vacation_type(%{name: "Frühjahr", colloquial: "Frühjahrsferien", country_location_id: 1, wikipedia_url: nil, default_html_class: "success", default_is_listed_below_month: true, default_is_school_vacation: true, default_is_valid_for_students: true, default_is_valid_for_everybody: false, default_display_priority: 5})

{:ok, holiday_or_vacation_type_4} =
  Calendars.create_holiday_or_vacation_type(%{name: "Ostern", colloquial: "Osterferien", country_location_id: 1, wikipedia_url: "https://de.m.wikipedia.org/wiki/Schulferien#Oster-/Frühjahrs-/Frühlingsferien", default_html_class: "success", default_is_listed_below_month: true, default_is_school_vacation: true, default_is_valid_for_students: true, default_is_valid_for_everybody: false, default_display_priority: 5})

{:ok, holiday_or_vacation_type_31} =
  Calendars.create_holiday_or_vacation_type(%{name: "Pfingsten", colloquial: "Pfingstferien", country_location_id: 1, wikipedia_url: "https://de.m.wikipedia.org/wiki/Schulferien#Pfingstferien", default_html_class: "success", default_is_listed_below_month: true, default_is_school_vacation: true, default_is_valid_for_students: true, default_is_valid_for_everybody: false, default_display_priority: 5})

{:ok, holiday_or_vacation_type_5} =
  Calendars.create_holiday_or_vacation_type(%{name: "Himmelfahrt", colloquial: "Himmelfahrtsferien", country_location_id: 1, wikipedia_url: "https://de.m.wikipedia.org/wiki/Schulferien#Pfingstferien", default_html_class: "success", default_is_listed_below_month: true, default_is_school_vacation: true, default_is_valid_for_students: true, default_is_valid_for_everybody: false, default_display_priority: 5})

{:ok, holiday_or_vacation_type_32} =
  Calendars.create_holiday_or_vacation_type(%{name: "Himmelfahrt/Pfingsten", colloquial: "Himmelfahrt- und Pfingstferien", country_location_id: 1, wikipedia_url: nil, default_html_class: "success", default_is_listed_below_month: true, default_is_school_vacation: true, default_is_valid_for_students: true, default_is_valid_for_everybody: false, default_display_priority: 5})

{:ok, holiday_or_vacation_type_33} =
  Calendars.create_holiday_or_vacation_type(%{name: "Augsburger Hohes Friedensfest", colloquial: "Augsburger Friedensfest", country_location_id: 1, wikipedia_url: "https://de.wikipedia.org/wiki/Augsburger_Hohes_Friedensfest", default_html_class: nil, default_is_listed_below_month: true, default_is_school_vacation: false, default_is_valid_for_students: false, default_is_valid_for_everybody: true, default_display_priority: 10})

{:ok, holiday_or_vacation_type_34} =
  Calendars.create_holiday_or_vacation_type(%{name: "unterrichtsfreier Tag", colloquial: "schulfrei", country_location_id: 1, wikipedia_url: nil, default_html_class: "success", default_is_listed_below_month: true, default_is_school_vacation: false, default_is_valid_for_students: false, default_is_valid_for_everybody: true, default_display_priority: 5})

