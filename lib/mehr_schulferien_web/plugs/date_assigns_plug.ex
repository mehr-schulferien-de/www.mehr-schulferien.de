defmodule MehrSchulferienWeb.Plugs.DateAssignsPlug do
  @moduledoc """
  Plug to parse date parameters and add them to the conn.

  This plug parses the `today` parameter (format: `DD.MM.YYYY`) and adds
  the parsed date to the connection assigns for use throughout the application.
  When a custom date is specified, it also sets `noindex: true` to prevent search engines
  from indexing time-specific pages.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    today_param = conn.params["today"]
    custom_date = parse_date(today_param)

    # Set noindex flag when a custom date is present
    noindex = custom_date != nil

    conn
    |> assign(:custom_date, custom_date)
    |> assign(:noindex, noindex)
  end

  # Parse a date in DD.MM.YYYY format into a Date struct
  defp parse_date(nil), do: nil

  defp parse_date(date_str) do
    with [day, month, year] <- String.split(date_str, "."),
         {day, _} <- Integer.parse(day),
         {month, _} <- Integer.parse(month),
         {year, _} <- Integer.parse(year),
         {:ok, date} <- Date.new(year, month, day) do
      date
    else
      _ -> nil
    end
  end
end
