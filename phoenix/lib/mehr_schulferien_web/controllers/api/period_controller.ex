defmodule MehrSchulferienWeb.Api.PeriodController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Timetables
  alias MehrSchulferien.Timetables.Period

  action_fallback MehrSchulferienWeb.FallbackController

  def index(conn, _params) do
    periods = Timetables.list_periods()
    render(conn, "index.json", periods: periods)
  end

  def show(conn, %{"id" => id}) do
    period = Timetables.get_period!(id)
    render(conn, "show.json", period: period)
  end

end
