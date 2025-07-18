defmodule MehrSchulferienWeb.LocationTrackingHelpers do
  @moduledoc """
  Helper functions for tracking location visits in cookies
  """
  
  import Plug.Conn
  
  @cookie_name "recent_locations"
  @max_locations 3
  @cookie_max_age 365 * 24 * 60 * 60
  
  @doc """
  Track a location visit. Location format: "type:slug"
  Types: f = federal_state, c = city, s = school
  """
  def track_location_visit(conn, type, slug) when type in ["f", "c", "s"] do
    location_entry = "#{type}:#{slug}"
    
    # Get existing locations
    existing_locations = case conn.req_cookies[@cookie_name] do
      nil -> []
      locations_str -> String.split(locations_str, ",")
    end
    
    # Add new location at the beginning, remove duplicates, keep only max locations
    updated_locations = 
      [location_entry | Enum.reject(existing_locations, &(&1 == location_entry))]
      |> Enum.take(@max_locations)
      |> Enum.join(",")
    
    put_resp_cookie(conn, @cookie_name, updated_locations, max_age: @cookie_max_age)
  end
  
  @doc """
  Get recent locations from cookies
  Returns a list of {type, slug} tuples
  """
  def get_recent_locations(cookies) do
    case cookies[@cookie_name] do
      nil -> []
      locations_str ->
        locations_str
        |> String.split(",")
        |> Enum.map(&parse_location_entry/1)
        |> Enum.reject(&is_nil/1)
    end
  end
  
  defp parse_location_entry(entry) do
    case String.split(entry, ":") do
      [type, slug] when type in ["f", "c", "s"] -> {type, slug}
      _ -> nil
    end
  end
end