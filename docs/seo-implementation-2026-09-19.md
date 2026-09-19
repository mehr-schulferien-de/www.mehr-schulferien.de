# SEO-Umsetzung vom 19. September 2026

Release: 4.33.4, zur Veröffentlichung am 19.09.2026 freigegeben. Der erfolgreiche Produktions-Workflow ist der maßgebliche Messbeginn. Keine externen Nachrichten versendet. Grundlage: [Search-Console-Auswertung](seo-review-2026-09-19.md).

## Die fünf Maßnahmen

1. **Bundesländer als verlässliche Zielseiten:** aktuelle/nächste Ferien mit vollem Datum direkt über den Tabellen; vollständiges laufendes und nächstes Kalenderjahr; amtliche Quellen und konkrete Hinweise für NRW, Bayern, Niedersachsen und Baden-Württemberg. Andere Länder verweisen auf die KMK. „Datenbestand zuletzt geändert“ bezeichnet bewusst keine redaktionelle Prüfung.
2. **Interne Verlinkung:** Städte und Schulen verweisen im Inhalt auf das Bundesland, Ferienseiten auf die nationale Jahresübersicht. Die Startseite erschließt Oster-, Sommer-, Herbst- und Weihnachtsferien des laufenden und nächsten Jahres.
3. **Suchergebnisse:** NRW als gebräuchliche Kurzform, konkrete Termine im Titel der Ferienseiten, dynamische Datumsbeschreibung für Länder/Städte, Jahreszahl in der Jahresüberschrift. Vorhandene Jahres-URLs bleiben bestehen. Falscher Deutschland-Pfad im Ferien-Breadcrumb korrigiert.
4. **Nützlicher Anlass für Empfehlungen:** `/ferien-widget` mit Bundeslandauswahl, Vorschau und kopierbarem iframe. `/ferien-widget/:slug` liefert nur öffentliche Termine, ohne Skripte, Werbung oder Cookies, mit systemabhängigem Hell-/Dunkelmodus. Einbettungen sind `noindex`, die Anleitung ist in der Sitemap. Automatische Quellenlinks sind `nofollow`; zusätzliche redaktionelle Links bleiben freiwillig. [Kontaktvorlagen](seo-outreach.md).
5. **Städteverluste:** Vergleich einer identischen Suchanfrage nach Land und Gerät; daraus abgeleitet eine direkte Antwort zum Schulbeginn auf Stadtseiten, unter Berücksichtigung hinterlegter Ferien, Feiertage und Wochenenden. Städte erhalten außerdem einen expliziten Self-Canonical und vollständige Folgejahresdaten.

## Kontrollierter GSC-Befund

Quelle: angemeldete Search Console, Suchtyp Web. Verglichen wurden **20.08.–16.09.2026** und **20.08.–16.09.2025**, nicht die letzten sieben Tage. Die folgenden Werte sind manuell aus der Oberfläche abgelesen, kein vollständiger API-Export.

| Filter | Klicks 2025 → 2026 | Impressionen 2025 → 2026 | Position 2025 → 2026 |
|---|---:|---:|---:|
| München, exakte Stadt-URL, alle Suchanfragen/Länder/Geräte | 103 → 21 | 7.500 → 3.210 | 10,3 → 8,8 |
| gleiche URL, „wann beginnt die schule in münchen“, Deutschland, alle Geräte (Summenkarten) | 3 → 1 | 131 → 118 | 1,9 → 4,6 |
| gleiche URL/Suchanfrage, Deutschland, Mobil (Gerätezeile) | 3 → 1 | 123 → 109 | 1,8 → 4,6 |
| gleiche URL/Suchanfrage, Deutschland, Computer (Gerätezeile) | 0 → 0 | 6 → 6 | 2,7 → 4,8 |

Die GSC zeigt bei dieser Suchanfrage zusätzlich eine Unicode-Schreibvariante. Deshalb unterscheiden sich die Einzelzeile (127 Vorjahres-Impressionen) und die gefilterte Summenkarte (131). Obige Gerätezahlen gehören zum gesamten exakten GSC-Filter, nicht zu einer nachträglich normalisierten Query-Zeile.

**Interpretation:** Bei dieser konkreten Schulbeginn-Suche gibt es einen Rankingverlust, auch bei konstantem Land/Gerät. Die bessere aggregierte Position der Stadtseite widerlegt ihn nicht. Die kleine Stichprobe beweist weder eine Ursache des gesamten Städteverlusts noch die Wirksamkeit der neuen Antwort. Unterschiedliche Ferientermine und Suchergebnisdarstellungen können weiterhin mitwirken. Für Lüneburg, Rust, Augsburg und Nürnberg liegen bisher nur die aggregierten Verluste aus der Ausgangsanalyse vor.

## Messplan nach Veröffentlichung

- Release-Datum und Commit im Git-Verlauf festhalten; ab diesem Datum beginnen die Auswertungsfenster.
- Nach 28 und 56 vollständigen Tagen in GSC prüfen. Jeweils dieselben URLs, Deutschland und Mobil getrennt betrachten; zusätzlich denselben Vorjahreszeitraum und die Tage bis zum Ferienbeginn berücksichtigen.
- Bundesländer-Pilot NRW/BY/NI/BW: Klicks, Impressionen und Position für „ferien [Bundesland]“, „schulferien [Bundesland]“ und beide Varianten mit Jahreszahl erfassen. Bestehende Jahres-URLs separat belassen. Kleine Query-Zeilen unter 100 Impressionen nur beschreibend auswerten.
- Saison-Snippet-Pilot: Rheinland-Pfalz Herbstferien 2026 sowie NRW. Nur gleiche Queries und Suchdarstellungen vergleichen; CTR-Änderungen bei stark veränderter Position nicht als reinen Snippet-Effekt bewerten.
- Städte: oben dokumentierte München-Kohorte wiederholen; die vier weiteren Verlustseiten auf Query-Ebene untersuchen, bevor pauschale Maßnahmen abgeleitet werden.
- Widget: echte Einbindungen, Referral-Besuche und neue redaktionelle Verweise zählen. Ein iframe selbst ist kein versprochener Rankinggewinn. Keine neuen Tracker dafür eingeführt.
- Ausgangswerte Bundesland-Familie: 6 Klicks / 22.278 Impressionen / Position 50,4 (20.08.–16.09.2026). Evergreen NRW: 0 / 2.212 / 57,4; Bayern: 0 / 2.377 / 46,0; Niedersachsen: 0 / 1.508 / 57,8; BW: 1 / 1.016 / 45,6. Familienwert umfasst weitere URLs, nicht nur diese vier.

## Gestaltungsrahmen

Bestehendes System fortgeführt: Systemschrift, graue Flächen, blaue Links, Tailwind-Dark-Varianten. Besucher sollen Termine sofort lesen und das Widget ohne Anmeldung einbauen können. Desktop: Vorschau und Einbaucode nebeneinander; Mobil: untereinander. Keine neue Bildwelt oder Rastergrafiken. Das isolierte iframe verwendet eine kleine eigene CSS-Dateidarstellung im HTML, um keine zusätzlichen Assets laden zu müssen.

Der Impeccable-Detektor war mangels installierter Engine nicht verfügbar. Browserprüfung und unabhängige Abschlussprüfung ersetzen keine automatische Detektorauswertung. Panoramascreenshots des In-App-Browsers zeigten Stitching-Artefakte; für die visuelle Prüfung dienen unverzerrte Einzelansichten.

## Prüfung

Abschließende Gesamtsuite: 1.256 Tests, keine Fehler, 17 bewusst ausgeschlossene Tests. Die neuen Regressionstests für vergangene Schultage und aktuell laufende Ferien wurden ausgeführt und bestanden. `mix credo --strict` und `git diff --check` sind ohne Befund abgeschlossen. Die unabhängige UI-Prüfung fand eine falsche Zeitform bei vergangenem Schulbeginn; sie wurde samt Priorisierung aktuell laufender Ferien korrigiert. Die entsprechende Kalenderregel wurde in `AGENTS.md` ergänzt, ebenso robuste Textvergleiche und alphabetische Alias-Reihenfolge.

## Dokumentationsabschluss

Die Erweiterung wurde mit den vorhandenen Länderansichten, `assets/tailwind.config.js` und `assets/css/app.css` abgeglichen: Schrift, graue Flächen, blaue Links und systemabhängiger Dunkelmodus bleiben konsistent. Die neuen Inhaltsabschnitte übernehmen vorhandene Abstände und Trennlinien; das iframe bildet die bestehende Palette ohne zusätzliche Assets nach. Die vorhandenen Farben für Ferien, Feiertage und Brückentage bleiben fachliche Kalenderkennzeichnungen. Ein neues `DESIGN.md` oder `PRODUCT.md` ist für diese Erweiterung nicht angelegt worden.

Nachweise sind die geprüften Desktop-/Mobilansichten unter `/tmp/seo-widget-{desktop,mobile}.png`, `/tmp/seo-state-{desktop,mobile}.png` und `/tmp/seo-city-mobile.png`. Die Abschlussprüfung gibt den geprüften Umfang nach der Zeitformkorrektur frei. Eine automatische Detektorprüfung liegt nicht vor; aus dem Vergleich ergibt sich kein zusätzlicher dokumentationspflichtiger Gestaltungswechsel.
