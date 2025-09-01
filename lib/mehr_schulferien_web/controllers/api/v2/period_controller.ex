defmodule MehrSchulferienWeb.Api.V2.PeriodController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Periods

  def index(conn, _params) do
    periods = Periods.list_periods()
    render(conn, :index, periods: periods)
  end

  def show(conn, %{"id" => id}) do
    period = Periods.get_period!(id)
    render(conn, :show, period: period)
  end
end
