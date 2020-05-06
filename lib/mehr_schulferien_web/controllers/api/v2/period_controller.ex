defmodule MehrSchulferienWeb.Api.V2.PeriodController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Calendars

  def index(conn, _params) do
    periods = Calendars.list_periods()
    render(conn, "index.json", periods: periods)
  end

  def show(conn, %{"id" => id}) do
    period = Calendars.get_period!(id)
    render(conn, "show.json", period: period)
  end
end
