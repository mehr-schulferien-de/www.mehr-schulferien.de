defmodule MehrSchulferienWeb.FerienContent do
  @moduledoc "Shared, source-linked editorial context and date-led search snippets."

  @kmk "https://www.kmk.org/service/ferienregelung.html"
  @sources %{
    "nordrhein-westfalen" => {
      "Ferienordnung des Schulministeriums NRW",
      "https://bass.schule.nrw/191.htm",
      "Die Termine beweglicher Ferientage legt die Schulkonferenz fest. Prüfen Sie deshalb zusätzlich den Kalender Ihrer Schule, insbesondere rund um Karneval."
    },
    "bayern" => {
      "Ferientermine des Bayerischen Kultusministeriums",
      "https://www.km.bayern.de/termine/ferien-und-feiertage",
      "Die Frühjahrsferien werden häufig Faschingsferien genannt. Zusätzlich zu den Ferien ist der Buß- und Bettag für Schülerinnen und Schüler unterrichtsfrei."
    },
    "niedersachsen" => {
      "Ferienübersicht des Niedersächsischen Kultusministeriums",
      "https://www.mk.niedersachsen.de/startseite/leichte_sprache/ferien/ferien-223892.html",
      "Zu den Ferienterminen gehören auch die Halbjahresferien und einzelne freie Tage rund um Himmelfahrt und Pfingsten. Beachten Sie daher auch eintägige Einträge in der Tabelle."
    },
    "baden-wuerttemberg" => {
      "Ferientermine des Kultusministeriums Baden-Württemberg",
      "https://km.baden-wuerttemberg.de/de/service/ferien",
      "Zusätzlich zu den landesweiten Ferien gibt es bewegliche Ferientage. Ob Ihre Schule etwa in der Fasnachtszeit schließt, erfahren Sie im schuleigenen Kalender."
    }
  }

  def source(slug),
    do: Map.get(@sources, slug, {"Ferienregelung der Kultusministerkonferenz", @kmk, nil})

  def search_name(%{slug: "nordrhein-westfalen"}), do: "NRW"
  def search_name(state), do: state.name

  def next_period(periods, today) do
    periods
    |> Enum.filter(&(Date.compare(&1.ends_on, today) != :lt))
    |> Enum.sort_by(& &1.starts_on, Date)
    |> List.first()
  end

  def period_name(period),
    do: period.holiday_or_vacation_type.colloquial || period.holiday_or_vacation_type.name

  def school_return(periods, all_periods, today) do
    active =
      Enum.find(periods, fn p ->
        Date.compare(p.starts_on, today) != :gt and Date.compare(p.ends_on, today) != :lt
      end)

    recent =
      periods
      |> Enum.filter(&(Date.diff(today, &1.ends_on) in 1..14))
      |> Enum.sort_by(& &1.ends_on, {:desc, Date})
      |> List.first()

    case active || recent || next_period(periods, today) do
      nil ->
        nil

      period ->
        day = Date.add(period.ends_on, 1)

        first_school_day =
          Stream.iterate(day, &Date.add(&1, 1))
          |> Enum.find(fn date ->
            Date.day_of_week(date) < 6 and
              not Enum.any?(all_periods, fn p ->
                Date.compare(p.starts_on, date) != :gt and Date.compare(p.ends_on, date) != :lt
              end)
          end)

        {period, first_school_day}
    end
  end

  def dates(period),
    do:
      "#{Calendar.strftime(period.starts_on, "%d.%m.%Y")} bis #{Calendar.strftime(period.ends_on, "%d.%m.%Y")}"

  def season_title(name, state, year, nil),
    do: "#{name} #{search_name(state)} #{year}: Ferientermine"

  def season_title(name, state, year, period) do
    "#{name} #{search_name(state)} #{year}: #{Calendar.strftime(period.starts_on, "%d.%m.")}–#{Calendar.strftime(period.ends_on, "%d.%m.")}"
  end

  def description(place, years, periods, today) do
    case next_period(periods, today) do
      nil ->
        "Schulferien #{place} #{years}: Ferientermine und Kalender zum Herunterladen. Schulindividuelle freie Tage bitte bei der Schule prüfen."

      period ->
        label =
          if Date.compare(period.starts_on, today) == :gt,
            do: "Nächste Ferien",
            else: "Aktuelle Ferien"

        "#{label} in #{place}: #{period_name(period)} vom #{dates(period)}. Schulferien #{years} mit Kalender-Download."
    end
  end
end
