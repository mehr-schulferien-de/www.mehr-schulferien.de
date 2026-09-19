defmodule MehrSchulferienWeb.FerienWidgetHTML do
  use Phoenix.Component
  alias MehrSchulferienWeb.FerienContent

  def calendar(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="de">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="robots" content="noindex, follow" />
        <title>Schulferien {@state.name}</title>
        <style>
          :root { color-scheme: light dark; font-family: ui-sans-serif, system-ui, sans-serif; color: #111827; background: #fff; }
          body { margin: 0; padding: 16px; line-height: 1.5; }
          h1 { font-size: 1.25rem; margin: 0 0 4px; }
          p { font-size: .875rem; margin: 8px 0 16px; }
          table { border-collapse: collapse; width: 100%; font-size: .875rem; font-variant-numeric: tabular-nums; }
          caption { text-align: left; margin-bottom: 8px; }
          th, td { text-align: left; vertical-align: top; padding: 10px 8px 10px 0; border-bottom: 1px solid #d1d5db; }
          a { color: #1d4ed8; text-underline-offset: 3px; }
          a:hover { color: #1e3a8a; }
          a:focus-visible { outline: 2px solid currentColor; outline-offset: 3px; }
          ::selection { background: #dbeafe; color: #111827; }
          @media (prefers-color-scheme: dark) {
            :root { color: #f3f4f6; background: #111827; }
            th, td { border-color: #4b5563; }
            a { color: #93c5fd; } a:hover { color: #bfdbfe; }
          }
        </style>
      </head>
      <body>
        <main>
          <h1>Schulferien {@state.name}</h1>
          <p>
            Aktuelle und kommende Ferientermine. Erster und letzter Ferientag sind eingeschlossen.
          </p>
          <table :if={@periods != []}>
            <caption>Ferientermine {@today.year} und {@today.year + 1}</caption>
            <thead>
              <tr>
                <th scope="col">Ferien</th>
                <th scope="col">Zeitraum</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={period <- @periods}>
                <th scope="row">{FerienContent.period_name(period)}</th>
                <td>
                  <time datetime={period.starts_on}>
                    {Calendar.strftime(period.starts_on, "%d.%m.%Y")}
                  </time>
                  bis
                  <time datetime={period.ends_on}>
                    {Calendar.strftime(period.ends_on, "%d.%m.%Y")}
                  </time>
                </td>
              </tr>
            </tbody>
          </table>
          <p :if={@periods == []}>Zurzeit sind keine kommenden Ferientermine hinterlegt.</p>
          <p>Bewegliche Ferientage bitte bei der Schule prüfen.</p>
          <a
            href={"https://www.mehr-schulferien.de/ferien/d/bundesland/#{@state.slug}"}
            target="_blank"
            rel="noopener nofollow"
          >
            Alle Termine und Kalender-Download bei mehr-schulferien.de
          </a>
        </main>
      </body>
    </html>
    """
  end
end
