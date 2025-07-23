defmodule MehrSchulferienWeb.Helpers.UserAgentHelpers do
  @moduledoc """
  Helper functions for detecting user agents and device types.
  """

  @doc """
  Detects if the user agent is from an Apple device (macOS or iOS).

  ## Examples

      iex> is_apple_device?(%Plug.Conn{req_headers: [{"user-agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"}]})
      true
      
      iex> is_apple_device?(%Plug.Conn{req_headers: [{"user-agent", "Mozilla/5.0 (iPhone; CPU iPhone OS 14_7_1 like Mac OS X)"}]})
      true
      
      iex> is_apple_device?(%Plug.Conn{req_headers: [{"user-agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}]})
      false
  """
  def is_apple_device?(conn) do
    user_agent = get_user_agent(conn)

    cond do
      user_agent == nil -> false
      String.contains?(user_agent, "Macintosh") -> true
      String.contains?(user_agent, "iPhone") -> true
      String.contains?(user_agent, "iPad") -> true
      String.contains?(user_agent, "iPod") -> true
      true -> false
    end
  end

  @doc """
  Gets the user agent string from the connection.
  """
  def get_user_agent(conn) do
    case List.keyfind(conn.req_headers, "user-agent", 0) do
      {"user-agent", user_agent} -> user_agent
      nil -> nil
    end
  end
end
