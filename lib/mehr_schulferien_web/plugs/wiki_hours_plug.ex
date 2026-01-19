defmodule MehrSchulferienWeb.Plugs.WikiHoursPlug do
  @moduledoc """
  Plug to restrict wiki access during night hours.

  The wiki is closed from 22:00 to 06:00 German time (Europe/Berlin).
  Users accessing wiki routes during these hours are shown an error page.
  """

  import Plug.Conn
  import Phoenix.Controller, only: [put_view: 2, render: 3]

  @timezone "Europe/Berlin"
  @closed_start 22
  @closed_end 6

  def init(opts), do: opts

  def call(conn, _opts) do
    if wiki_closed?() do
      conn
      |> put_status(403)
      |> put_view(MehrSchulferienWeb.ErrorHTML)
      |> render("wiki_closed.html", current_time: current_berlin_time())
      |> halt()
    else
      conn
    end
  end

  @doc """
  Checks if the wiki is currently closed.

  Returns `true` if the current Berlin time is between 22:00 and 06:00.
  """
  def wiki_closed? do
    hour = current_berlin_time().hour
    hour >= @closed_start or hour < @closed_end
  end

  @doc """
  Returns the current time in Berlin timezone.
  """
  def current_berlin_time do
    DateTime.utc_now()
    |> DateTime.shift_zone!(@timezone)
  end

  @doc """
  Returns the opening hours as a string.
  """
  def opening_hours, do: "06:00 - 22:00 Uhr"

  @doc """
  Returns the timezone used for restrictions.
  """
  def timezone, do: @timezone
end
