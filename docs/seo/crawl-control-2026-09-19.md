# Crawl-Steuerung, 19. September 2026

Release: 4.33.6, zur Veröffentlichung am 19. September 2026 freigegeben. Der erfolgreiche Produktions-Workflow markiert den Beginn der Nachher-Messung. Produktionslogs wurden ausschließlich gelesen; keine Nginx-Konfiguration oder Zugriffsrechte verändert.

## Befund: 5.–18. September 2026

15 aktuelle/rotierte Nginx-Logs ausgewertet, 14 vollständige lokale Kalendertage. Googlebot wurde anhand User-Agent **und** Reverse-DNS mit anschließendem Forward-DNS-Abgleich verifiziert. 101 von 187 Kandidaten-IP-Adressen bestanden diese Prüfung. 426 Anfragen nicht verifizierter Adressen sind aus den folgenden Zahlen ausgeschlossen; fehlgeschlagene DNS-Abfragen sind kein Beweis für einen gefälschten Bot.

| URL-Gruppe | Verifizierte Abrufe | Antwortkörper, gerundet |
|---|---:|---:|
| Schulferien-Schulseiten | 8.702 | 147,4 MB |
| Schulbezogene Briefgeneratoren | 3.551 | 41,5 MB |
| Stadtseiten | 3.444 | 56,3 MB |
| Stadt-/Schul-Jahresweiterleitungen | 1.276 | 0,14 MB |
| Urlaubsplaner | 999 | 10,4 MB |
| Alte `/land/`, `/cities/`, `/schools/`-Pfade | 878 | 0,11 MB |
| Saisonseiten | 365 | 2,9 MB |
| Bundesland-Ferienseiten | 166 | 1,7 MB |
| Weitere Feiertags-/Brückentagsseiten | 127 | 1,1 MB |
| `today=` / konkrete Datumsabfragen | 0 | 0 |

Briefgeneratoren und Planer ergeben **4.550 Abrufe und 51.879.646 Antwortkörper-Bytes**, rund 325 Abrufe täglich. Das sind 23,3 % der 19.508 anhand ihrer Pfade zugeordneten Abrufe. Beide Gruppen antworteten mit HTTP 200. Sie tragen bereits seit Juli `noindex`, stehen nicht in den Sitemaps und sind keine gewünschten Suchziele. Die neuen robots-Regeln verhindern ihre erneute Verarbeitung, sobald kooperierende Crawler die aktualisierten Regeln übernehmen. Das ist ein Ausgangswert und keine bereits gemessene Einsparung.

**Messgrenzen:** Das gemeinsame Combined-Log enthält keinen Hostnamen. Zusätzlich gab es 4.473 verifizierte Abrufe nicht eindeutig zuordenbarer Pfade; diese sind nicht in den 19.508 enthalten. Die Zuordnung der obigen Gruppen erfolgt anhand projektspezifischer Pfade, nicht per Hostfeld. Antwortkörper-Bytes sind weder gesamte Netzwerkbytes noch CPU-Kosten. Antwort-/Upstream-Zeiten fehlen. Die Auswertung belegt keinen Serverengpass.

[Aggregierte Rohwerte](crawl-baseline-2026-09-05--18.json) enthalten keine IP-Adressen oder personenbezogenen URL-Parameterwerte.

## Umgesetzte Regeln

```text
Disallow: /*?today=
Disallow: /*?*&today=
Disallow: /briefe/
Allow: /briefe/$
Disallow: /urlaubsplaner/
Disallow: /urlaubsplaner-guenstig/
```

Die `today`-Regeln sind vorbeugend; im gemessenen Zeitraum war dort keine nachweisbare Last. Unterschiedliche Parameterreihenfolgen werden erfasst, ähnlich benannte Parameter wie `not_today` bleiben unberührt. `/briefe` und `/briefe/` bleiben offen, nur die schulbezogenen Unterseiten werden gesperrt.

Unverändert offen bleiben Bundesländer, Städte, Schulen, wichtige Jahres- und Saisonseiten, Datums-Landingpages, CSS/JavaScript und alte Weiterleitungen. Konkrete Datumsabfragen werden mangels gemessener Abrufe nicht vorsorglich blockiert. Einbettungs-Widgets bleiben vorerst ebenfalls unverändert. Der irreführende Kommentar „crawl as fast as you can“ wurde entfernt; er war technisch ohnehin keine Anweisung zur Crawlgeschwindigkeit.

`noindex` bleibt auf den Tools bestehen. Robots-Sperren entfernen eine eventuell noch indexierte URL nicht zuverlässig aus Google. Der vorhandene GSC-Bericht weist seit Juli viele erfolgreiche noindex-Ausschlüsse aus, ist aber kein vollständiger Nachweis für jede Tool-URL. Falls eine dieser URLs weiterhin als Suchergebnis auftaucht und entfernt werden soll, die betreffende Sperre vorübergehend aufheben, bis Google `noindex` erneut lesen konnte. Keine pauschalen Jahressperren einführen.

## Wiederholbare Kontrolle

Das Skript läuft lesend auf dem Loghost. Es prüft DNS zur Laufzeit und schreibt nur aggregiertes JSON auf den lokalen Rechner:

```bash
ssh root@mehr-schulferien.de \
  'python3 - --start 2026-09-05 --end 2026-09-19' \
  < scripts/report_googlebot_crawls.py > /tmp/googlebot-report.json
```

`--start` ist einschließlich, `--end` ausschließlich. Benötigt Python 3 ohne Zusatzpakete sowie lesbare `access.log`/`access.log-YYYYMMDD[.gz]` und DNS-Zugriff. Das aktuelle Log plus passende Rotationen werden anhand der tatsächlichen Eintragsdaten gefiltert. Nicht verifizierte Abrufe werden separat ausgewiesen; sie zählen nicht als bestätigter Googlebot.

Nach Veröffentlichung:

1. Live-robots.txt prüfen. Google cached sie üblicherweise bis zu 24 Stunden, unter Fehlerbedingungen länger.
2. Nach 7 und 14 vollständigen Tagen dieselben Gruppen auswerten. Ziel: weniger Tool-Abrufe, wichtige Inhaltsseiten bleiben erreichbar und werden weiterhin abgerufen. Keine garantierte Umlenkung des frei werdenden Crawlvolumens auf Bundesländer behaupten.
3. GSC-Indexierung und Klicks der wichtigen Landingpages kontrollieren. Mehr Meldungen „Durch robots.txt blockiert“ sind für die ausgeschlossenen Tools erwartbar und allein kein Fehler.
4. Bei Bedarf später ein separates Nginx-Log mit Host, Request-Time und Upstream-Time einrichten. Das wurde in dieser Änderung nicht aktiviert; ohne diese Felder keine präzisen Laufzeit-Einsparungen behaupten.

## Quellen

- [Google: Crawl-Budget verwalten](https://developers.google.com/crawling/docs/crawl-budget)
- [Google: robots.txt-Auswertung](https://developers.google.com/crawling/docs/robots-txt/robots-txt-spec)
- [Google: Crawler verifizieren](https://developers.google.com/crawling/docs/crawlers-fetchers/verify-google-requests)
