# SEO-Auswertung vom 19.09.2026

Die Juli-Änderungen haben technische Altlasten reduziert. Ein zusätzlicher Besucherstrom über allgemeine Bundesländer-Ferienseiten ist bisher nicht nachweisbar. Priorität: korrekte, vollständige Bundesländer-Seiten, klare Zielseiten für Suchanfragen und regionale Verlinkungen. Parallel den Rückgang des bestehenden Städte-Traffics untersuchen.

## Datenbasis und Grenzen

- Google Search Console (GSC), Property `https://www.mehr-schulferien.de/`, Suchtyp Web, ohne Länder- oder Gerätefilter, direkt im angemeldeten Chrome gelesen.
- Aktuell: **20.08.–16.09.2026**, 28 vollständige verfügbare Tage. Vor Umbau: **19.06.–16.07.2026**, ebenfalls 28 Tage. Zusätzlich Gesamtseite und Bundesländer gegenüber **20.08.–16.09.2025**.
- Indexbericht: Stand 14.09.2026; Core Web Vitals: Stand 17.09.2026.
- Git-Verlauf, `docs/seo-log.md`, aktuelle Templates/Controller und öffentliches Bayern-HTML geprüft. GitHub Actions bestätigt den erfolgreichen Produktionsdeploy vom 17.09.2026.
- Keine kontrollierte Studie: Ferienkalender, saisonale Nachfrage und Zusammensetzung der Suchanfragen unterscheiden sich. Durchschnittspositionen verschiedener Zeiträume sind keine Messung identischer Keywords. GSC-Tabellen und gefilterte Summen können unvollständig sein; anonymisierte Suchanfragen fehlen. Zahlen sind teils UI-gerundet.
- Historische Ahrefs-Zahlen stammen ausschließlich aus dem Juli-Protokoll; Ahrefs wurde heute nicht neu geprüft. GSC-Impressionen sind kein Suchvolumen des Gesamtmarkts.

## Was geändert wurde

| Datum / Commit | Änderung | Heutige Bewertung |
|---|---|---|
| 07.01., `22d2b0cd` | Startseite auf „Schulferien“ ausgerichtet | Exakte Suchanfrage „schulferien“: 61 statt 9 Klicks im 28-Tage-Vorjahresvergleich. Positives Signal, kein isolierter Wirkungsnachweis dieses Commits. |
| 20.01., `074a88e4` | SEO für Ferienseiten | Von den späteren Änderungen und Saisoneffekten nicht getrennt messbar mit den hier erhobenen Daten. |
| 17.07., `a26b1945` | Echte Bundesländer-Seiten ohne Jahreszahl, Canonicals, Metadaten | Neue URLs erhalten Impressionen; Klickgewinn für die ganze Seitenfamilie noch nicht messbar. |
| 19.07., `c7ad98c4` | Crawl-Bereinigung, noindex für dünne Toolseiten, Sitemap-Index, interne Links, nationale Brückentage-Seiten | Indexbericht entwickelt sich in erwarteter Richtung. |
| 21.07., `1a609a35` | Korrekte Saison-URLs, dauerhafte Saison-/Brückentage-Seiten, Feiertagsseiten, nationale Saisonjahresseiten, Schul-Snippets | Feiertage sind sichtbar, aber praktisch ohne Klicks. Herbstferien gewinnen Sichtbarkeit, teilweise für unpassende bundesweite Anfragen. |
| 10.08. / 17.09. | Slug-, Schuljahres- und Terminkorrekturen | Wichtig für Verlässlichkeit. Der 17.09.-Deploy liegt nach dem ausgewerteten Leistungszeitraum. |

## Gemessene Ergebnisse

### Gesamtseite gegen Vorjahr

| Kennzahl | 20.08.–16.09.2025 | 20.08.–16.09.2026 |
|---|---:|---:|
| Klicks | 28.496 | 13.600 |
| Impressionen | ca. 1,15 Mio. | 491.516 |
| CTR | 2,5 % | 2,8 % |
| Durchschnittsposition | 15,0 | 11,1 |

**Klicks: −52,3 %.** Die bessere mittlere Position widerlegt den Verlust nicht: verschwundene schwache Rankings können den Mittelwert verbessern. Eine Ursache wie Google-Update oder KI-Antworten ist damit nicht bewiesen.

Beispiele aus den größten Seitenverlusten, Klicks Vorjahr → aktuell: München 103 → 21, Rust 121 → 39, Lüneburg 99 → 33, Augsburg 77 → 11, Nürnberg 149 → 91. Das bestehende Städte-Angebot verdient einen eigenen Vergleich derselben Suchanfragen, Länder und Geräte. Jahresverschiebungen und veränderte Ferientermine dabei berücksichtigen.

### Seitenfamilien vor und nach den Juli-Änderungen

URL-Filter jeweils „enthält“, inklusive Jahresvarianten und gegebenenfalls Nebenpfaden. Die folgenden Kennzahlen sind damit keine ausschließlich jahrlose URL-Kohorte.

| URL enthält | Klicks vorher → aktuell | Impressionen vorher → aktuell | Position vorher → aktuell |
|---|---:|---:|---:|
| `/ferien/d/bundesland/` | 7 → 6 | 10.163 → 22.278 | 48,5 → 50,4 |
| `/brueckentage/` | 20 → 9 | 3.640 → 898 | 18,9 → 29,3 |
| `/feiertage/` | 0 → 1 | 0 → 3.620 | keine → 49,0 |
| `/herbstferien/` | 0 → 0 | 865 → 3.960 | 41,6 → 26,9 |

Bei Bundesländern steigen die Impressionen um rund 119 %, aber nicht die Klicks. Gegen Vorjahr: 4 → 6 Klicks, 27.945 → 22.278 Impressionen, Position 70,1 → 50,4. Bei so kleinen Klickzahlen ist „50 % Wachstum“ keine sinnvolle Erfolgsmeldung.

Aktuelle jahrlose Hauptseiten:

| Bundesland | Klicks | Impressionen | Position |
|---|---:|---:|---:|
| Bayern | 0 | 2.377 | 46,0 |
| Nordrhein-Westfalen | 0 | 2.212 | 57,4 |
| Niedersachsen | 0 | 1.508 | 57,8 |
| Hamburg | 0 | 1.477 | 54,6 |
| Thüringen | 1 | 1.143 | 41,7 |
| Baden-Württemberg | 1 | 1.016 | 45,6 |
| Mecklenburg-Vorpommern | 1 | 862 | 51,3 |

Die Thüringen-Jahresseite `/2027` liegt dagegen bei Position 11,2 (276 Impressionen, 1 Klick). Jahres-URLs deshalb nicht pauschal auf jahrlose Seiten umleiten.

### Suchabsicht und Zielseite passen teilweise nicht zusammen

`/herbstferien/rheinland-pfalz/2026` hat 1.326 Impressionen, Position 9,3, null Klicks. Davon entfallen **992 Impressionen auf „herbstferien 2026“, Position 4,3, null Klicks**. Für „herbstferien rlp 2026“: nur 15 Impressionen, Position 28,2. Die gute Seitendurchschnittsposition ist also kein Beweis für gute regionale Rankings.

Hypothese: Eine regionale Seite wird für eine bundesweite Suche ausgespielt, während die passende Übersicht nicht ausreichend als Zielseite etabliert ist. Vor einem Snippet-Test Darstellung in der Suche, Land und Gerät kontrollieren; Position 4,3 bedeutet nicht zwingend einen klassischen blauen Link an vierter Stelle.

### Indexbereinigung

| Status | Juli-Protokoll | 14.09.2026 |
|---|---:|---:|
| Durch robots.txt blockiert | 107.379 | 62.973 |
| Gecrawlt, zurzeit nicht indexiert | 79.086 | 45.158 |
| noindex | 114 | 22.182 |
| Nicht gefunden (404) | 10.716 | 2.058 |
| Indexiert | ca. 54.600 | ca. 50.800 |
| Bekannte URLs | ca. 267.000 | ca. 194.800 |

Die Verschiebung ist mit der beabsichtigten Bereinigung vereinbar. Mehr noindex ist hier erwartbar. Die Indexquote beträgt nun etwa 26 %; sie ist kein eigenständiges Geschäftsziel. Entscheidend sind indexierte wertvolle Zielseiten und deren Klicks.

NRW-Hauptseite individuell geprüft: indexiert, Abruf erfolgreich, Crawling/Indexierung erlaubt, Google wählt die angegebene jahrlose URL als Canonical. Letzter gemeldeter Crawl: **25.07.2026, 08:57 Uhr**. Die Stichprobe spricht gegen eine generelle Canonical-Blockade; sie gilt nicht automatisch für alle 16 Länder.

Core Web Vitals: mobil und Desktop jeweils 3.681 gute URLs, null schlechte und null zu optimierende URLs. Nur für die erfasste Stichprobe, keine Aussage über sämtliche URLs.

GSC-Linkbericht: 186 gemeldete externe Links, davon 144 zur Startseite, 32 nach Braunschweig und 5 zur Entwicklerseite. Diese Stichprobe ist kein vollständiges Backlinkinventar, zeigt aber wenig direkte Unterstützung für Bundesländer-Seiten. Der interne Bericht enthält weiterhin viele Jahresziele; er kann historische Crawlstände spiegeln.

## Priorisierte nächste Schritte

### 1. Verlässliche und vollständige Antworten als Grundlage

Bei der Prüfung gefundene, mit Regressionstests lokal korrigierte Fehler:

- Jahrlose Bundesländer-Seiten zeigten das Folgejahr nur bis zu Ferienbeginn am 2. August. Herbst-/Weihnachtsferien wurden ausgeblendet, obwohl Überschrift und Metadaten das ganze Jahr versprechen. Jetzt kompletter Kalenderjahresbereich.
- Die FAQ erklärte Wochenenden ohne Datenbank-Perioden zu Schultagen. Jetzt explizite Wochenendbehandlung.
- „Nächster Feiertag“ nutzte nach Anzeigepriorität sortierte Daten; Bayern nannte am 19.09.2026 Karfreitag 2027 statt den 3. Oktober. Jetzt chronologische Auswahl.
- Zusätzliches FAQ-JSON-LD zählte Ferien mehrerer Jahre als Jahressumme und sortierte nächste Ferien nach Date-Struct-Reihenfolge. Jetzt jahresbegrenzte eindeutige Tage und explizite chronologische Sortierung mit dem Seitendatum.
- ItemList-JSON-LD bezeichnete 2027-Termine als 2026. Jetzt Terminjahr und korrekte Zweijahresüberschrift.

Noch keine Veröffentlichung. Prüfung der lokalen Korrekturen: `mise exec -- mix test` mit 1.243 Tests, null Fehlern und 17 gemäß bestehender Konfiguration ausgeschlossenen Tests; `mix credo --strict`, Formatprüfung und `git diff --check` erfolgreich. Regressionen wurden vor der jeweiligen Korrektur reproduziert.

Nach Deployment einige repräsentative URLs erneut prüfen. Redaktionell ergänzen: zuständige amtliche Quelle als Link, tatsächliches Prüfdatum und Erklärung regionaler Sonderregeln. Ein alter Datenbank-Zeitstempel ist weder ein Beleg für falsche Termine noch ein Ersatz für eine tatsächliche redaktionelle Prüfung.

### 2. Bundesländer-Seiten gezielt stärker machen

Pilot: NRW, Bayern, Niedersachsen und Baden-Württemberg; zusätzlich Thüringen als bereits etwas stärkeren Kandidaten beobachten. Reihenfolge ist eine strategische Auswahl, keine aus GSC bewiesene Marktvolumenrangliste.

- Direkt unter H1 die nächsten Ferien mit Datum, anschließend übersichtliche vollständige Jahrestabellen und Kalenderexport.
- NRW/RLP/BW als gebräuchliche Abkürzungen natürlich berücksichtigen, beispielsweise „Schulferien NRW 2026 & 2027 – Termine und Kalender“. Keine parallelen Abkürzungs-URLs erzeugen.
- Kurze landesspezifische Informationen, z. B. bewegliche Ferientage und zuständige Quelle. Kein austauschbarer langer SEO-Text auf allen 16 Seiten.
- Von passenden Städte-/Schulseiten einen inhaltlich verständlichen Link „Alle Schulferien in Nordrhein-Westfalen“ setzen, sofern neben Navigation/Breadcrumb noch kein gleichwertiger Kontextlink vorhanden ist. Vorhandene Links erst inventarisieren.
- Auf den Landesübersichten gezielt Herbst-/Weihnachtsferien und das nächste Kalenderjahr verlinken. Bereits im Juli umgesetzte Navigation nicht erneut als neue Maßnahme verkaufen.

### 3. Vorhandene Saisonseiten richtig zuordnen

Die bundesweiten Seiten `/herbstferien/2026`, `/weihnachtsferien/2026`, `/osterferien/2027` existieren bereits. Sie sollten von Startseite und den passenden regionalen Saisonseiten mit eindeutigen Linktexten erreichbar sein. Auf jeder regionalen Saisonseite einen passenden Link „Herbstferien 2026 in allen Bundesländern“ anbieten.

Für die Rheinland-Pfalz-Seite zuerst Suchdarstellung prüfen und bundesweite Übersicht stärken. Regionale Titel und Snippets mit konkretem Termin testen. Jahres-Seiten behalten, solange sie eigene Suchabsicht und Rankings bedienen; kein flächiger Redirect-/Canonical-Umbau ohne Query-/URL-Auswertung.

### 4. Regionale Empfehlungen verdienen

Als Experiment einen nützlichen, barrierearmen Ferienkalender zum Einbetten für Schulen/Elternvereine und ein ordentliches Kalender-Abonnement anbieten; vorhandene API/iCal-Funktionen weiterverwenden. Begleitend eine überprüfbare Datenauswertung mit regionalem Nutzen, z. B. Ferienüberschneidungen benachbarter Länder 2027. Erst konkrete Inhalte erstellen, dann passende Schulen, Vereine und Lokalredaktionen ansprechen. Links freiwillig/redaktionell, keine gekauften oder erzwungenen Keyword-Links. Kontaktaufnahme wurde nicht durchgeführt.

### 5. Bestehenden Traffic zurückgewinnen und Wirkung sauber messen

- Die größten Städteverluste mit gleichem Query, Gerät und Land vergleichen; prüfen, ob Nachfrage, Ranking, Zielseitenwechsel oder Klickrate ausschlaggebend sind.
- Für jede Pilot-Landesseite Klicks, Impressionen und relevante Suchanfragen festhalten; jahrlose Seiten, Jahrgänge und Saisonseiten getrennt auswerten.
- Nach Einführung Änderungen für vier bis sechs Wochen stabil lassen. Gleiche Anfragen sowie Vorjahr mit angepassten Jahreszahlen vergleichen. Die erste Zwischenkontrolle kann nach 28 Tagen erfolgen.
- Wichtigste Messgröße: zusätzliche organische Klicks. Neue Impressionen und bessere Positionen sind Vorindikatoren. Keine Besucherversprechen aus allgemeinen CTR-Kurven ableiten.
- Nicht parallel sämtliche Titles, URLs, Texte und Linkstrukturen ändern; sonst ist die Wirkung kaum zuzuordnen.

## Korrekturen früherer SEO-Annahmen

- Das Juli-Protokoll nennt am 21.07. „5 weeks in“ für die am 17.07. eingeführten Seiten. Diese Zeitangaben widersprechen sich. Auch „pattern validated“ war ohne passenden GSC-Vergleich zu stark formuliert. Bereits vor dem dokumentierten Start gibt es GSC-Impressionen für einzelne jahrlose URLs; eine Null-Baseline ist daher nicht pauschal richtig.
- Jahres-URLs starten nicht automatisch jedes Jahr bei null. Eine klare Zuordnung verschiedener Suchabsichten ist wichtiger als grundsätzlich jahrlose URLs zu bevorzugen.
- Ahrefs DR ist eine externe Kennzahl, kein Google-Rankingfaktor und keine harte Rankingobergrenze. Wenige relevante Links bleiben eine plausible, nicht abschließend bewiesene Schwäche.
- FAQ-Markup ist für diese Website kein erwartbarer Rich-Result-Hebel: Google beschränkt diese Darstellung auf bestimmte bekannte Behörden-/Gesundheitsseiten. Sichtbar hilfreiche Antworten bleiben sinnvoll.
- Google ignoriert Sitemap-`priority` und `changefreq`. Verlässliches `lastmod`, Erreichbarkeit und interne Links sind sinnvoller als Priority-Werte zu verändern.

## Quellen

- [GSC-Leistung, aktueller Zeitraum gegen Vorjahr](https://search.google.com/search-console/performance/search-analytics?resource_id=https%3A%2F%2Fwww.mehr-schulferien.de%2F&hl=de&num_of_days=28&compare_date=YOY)
- [GSC-Bundesländer vor/nach Juli](https://search.google.com/search-console/performance/search-analytics?resource_id=https%3A%2F%2Fwww.mehr-schulferien.de%2F&hl=de&page=*%2Fferien%2Fd%2Fbundesland%2F&start_date=20260820&end_date=20260916&compare_start_date=20260619&compare_end_date=20260716&breakdown=page)
- [GSC-Indexierung](https://search.google.com/search-console/index?resource_id=https%3A%2F%2Fwww.mehr-schulferien.de%2F)
- [GSC-Core-Web-Vitals](https://search.google.com/search-console/core-web-vitals?resource_id=https%3A%2F%2Fwww.mehr-schulferien.de%2F)
- [GSC-Links](https://search.google.com/search-console/links?resource_id=https%3A%2F%2Fwww.mehr-schulferien.de%2F)
- [Google: Canonical-Auswahl](https://developers.google.com/search/docs/crawling-indexing/canonicalization)
- [Google: Einschränkung von FAQ-Rich-Results](https://developers.google.com/search/blog/2023/08/howto-faq-changes)
- [Google: Sitemap-Angaben](https://developers.google.com/search/docs/crawling-indexing/sitemaps/build-sitemap)
