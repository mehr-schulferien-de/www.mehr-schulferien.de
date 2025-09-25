defmodule MehrSchulferienWeb.AdVisibilityHelper do
  @moduledoc """
  Helper module to determine whether Google Ads should be shown to a visitor
  based on their visit history tracked via cookies.

  Business logic:
  - New visitors (first visit or no cookie) see ads
  - Returning visitors who visited in the last hour see ads
  - Returning visitors who haven't visited in the last 3 months see ads
  - All other returning visitors don't see ads (visited between 1 hour and 3 months ago)
  """

  @cookie_name "visitor_tracking"
  @hour_in_seconds 3600
  @three_months_in_seconds 90 * 24 * 3600

  @doc """
  Determines if ads should be shown to the current visitor.

  Returns true if:
  - Visitor is new (no tracking cookie)
  - Visitor's last visit was within the last hour
  - Visitor hasn't visited in the last 3 months

  Returns false if:
  - Visitor last visited between 1 hour and 3 months ago
  """
  def show_ads?(conn) do
    case get_visitor_info(conn) do
      nil ->
        # New visitor or cookie expired
        true

      {_first_visit, last_visit} ->
        now = System.system_time(:second)
        time_since_last_visit = now - last_visit

        cond do
          # Visited within the last hour
          time_since_last_visit <= @hour_in_seconds ->
            true

          # Haven't visited in 3 months
          time_since_last_visit >= @three_months_in_seconds ->
            true

          # Regular returning visitor (visited between 1 hour and 3 months ago)
          true ->
            false
        end
    end
  end

  @doc """
  Updates the visitor tracking cookie with the current visit time.
  Should be called on every page load to maintain accurate visit tracking.
  """
  def track_visit(conn) do
    now = System.system_time(:second)

    {first_visit, _last_visit} =
      case get_visitor_info(conn) do
        nil -> {now, now}
        {first, _last} -> {first, now}
      end

    cookie_value = "#{first_visit}:#{now}"

    # Set cookie to expire in 3 months
    Plug.Conn.put_resp_cookie(
      conn,
      @cookie_name,
      cookie_value,
      max_age: @three_months_in_seconds,
      http_only: true,
      same_site: "Lax"
    )
  end

  # Private functions

  defp get_visitor_info(conn) do
    conn = Plug.Conn.fetch_cookies(conn)

    case conn.req_cookies[@cookie_name] do
      nil ->
        nil

      cookie_value ->
        case String.split(cookie_value, ":") do
          [first_visit_str, last_visit_str] ->
            case {parse_timestamp(first_visit_str), parse_timestamp(last_visit_str)} do
              {{:ok, first}, {:ok, last}} -> {first, last}
              _ -> nil
            end

          _ ->
            nil
        end
    end
  end

  defp parse_timestamp(str) do
    case Integer.parse(str) do
      {timestamp, ""} -> {:ok, timestamp}
      _ -> :error
    end
  end
end
