defmodule MehrSchulferienWeb.FerienWidgetController do
  use MehrSchulferienWeb, :controller
  alias MehrSchulferien.Calendars.DateHelpers
  alias MehrSchulferien.{Locations, Periods}

  def index(conn, params) do
    country = Locations.get_country_by_slug!("d")
    states = Locations.list_federal_states(country) |> Enum.sort_by(& &1.name)
    selected = Enum.find(states, &(&1.slug == params["bundesland"])) || List.first(states)
    code = if selected, do: embed_code(selected), else: nil

    conn
    |> put_view(MehrSchulferienWeb.PageHTML)
    |> render("ferien_widget.html", states: states, selected: selected, embed_code: code)
  end

  # Public data only: this route intentionally has no browser/session/ad plugs.
  def show(conn, %{"slug" => slug}) do
    case Locations.get_federal_state_and_country_by_slug("d", slug) do
      {:ok, {state, country}} ->
        today = DateHelpers.today_berlin()

        periods =
          Periods.list_school_vacation_periods(
            [country.id, state.id],
            today,
            Date.new!(today.year + 1, 12, 31)
          )

        markup =
          MehrSchulferienWeb.FerienWidgetHTML.calendar(%{
            state: state,
            periods: periods,
            today: today
          })

        conn
        |> put_resp_header("x-robots-tag", "noindex, follow")
        |> put_resp_header(
          "content-security-policy",
          "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'"
        )
        |> put_resp_header("x-content-type-options", "nosniff")
        |> put_resp_header("referrer-policy", "no-referrer")
        |> html(markup |> Phoenix.HTML.Safe.to_iodata() |> IO.iodata_to_binary())

      {:error, :not_found} ->
        conn |> put_status(:not_found) |> text("Bundesland nicht gefunden.")
    end
  end

  defp embed_code(state) do
    title = Phoenix.HTML.html_escape("Schulferien #{state.name}") |> Phoenix.HTML.safe_to_string()

    ~s(<iframe src="https://www.mehr-schulferien.de/ferien-widget/#{state.slug}" title="#{title}" width="100%" height="480" style="border:0" loading="lazy" referrerpolicy="no-referrer"></iframe>)
  end
end
