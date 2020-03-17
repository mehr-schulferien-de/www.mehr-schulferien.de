defmodule MehrSchulferienWeb.Api.V2.PeriodController do
  use MehrSchulferienWeb, :controller

  def index(conn, _params) do
    periods = MehrSchulferien.Periods.fetch_all()
    render(conn, "index.json", periods: periods)
  end

  def show(conn, %{"id" => id}) do
    period = MehrSchulferien.Periods.fetch_period_by_id(id)
    render(conn, "show.json", period: period)
  end
end
