defmodule MehrSchulferienWeb.Helpers.CookieHelpers do
  @moduledoc """
  Helper functions for reading and parsing location history cookies.
  """

  @recent_federal_state_cookie "recent_federal_state"
  @recent_cities_cookie "recent_cities"
  @recent_schools_cookie "recent_schools"

  @doc """
  Reads the recent federal state slug from cookies.
  Returns nil if no cookie is found.
  """
  def get_recent_federal_state_slug(conn) do
    conn.req_cookies[@recent_federal_state_cookie]
  end

  @doc """
  Reads the recent cities from cookies.
  Returns a list of {city_slug, federal_state_slug} tuples.
  """
  def get_recent_cities_slugs(conn) do
    case conn.req_cookies[@recent_cities_cookie] do
      nil -> []
      "" -> []
      cities_str ->
        cities_str
        |> String.split(",")
        |> Enum.map(&parse_city_info/1)
        |> Enum.reject(&is_nil/1)
    end
  end

  @doc """
  Reads the recent schools from cookies.
  Returns a list of {school_slug, city_slug, federal_state_slug} tuples.
  """
  def get_recent_schools_slugs(conn) do
    case conn.req_cookies[@recent_schools_cookie] do
      nil -> []
      "" -> []
      schools_str ->
        schools_str
        |> String.split(",")
        |> Enum.map(&parse_school_info/1)
        |> Enum.reject(&is_nil/1)
    end
  end

  @doc """
  Gets location history slugs from cookies for LiveView.
  """
  def get_location_history_slugs_from_cookies(cookies) do
    %{
      recent_federal_state_slug: cookies[@recent_federal_state_cookie],
      recent_cities_slugs: parse_cities_cookie(cookies[@recent_cities_cookie]),
      recent_schools_slugs: parse_schools_cookie(cookies[@recent_schools_cookie])
    }
  end

  # Private functions

  defp parse_city_info(city_str) do
    case String.split(city_str, ":") do
      [city_slug, federal_state_slug] -> {city_slug, federal_state_slug}
      _ -> nil
    end
  end

  defp parse_school_info(school_str) do
    case String.split(school_str, ":") do
      [school_slug, city_slug, federal_state_slug] -> {school_slug, city_slug, federal_state_slug}
      _ -> nil
    end
  end

  defp parse_cities_cookie(nil), do: []
  defp parse_cities_cookie(""), do: []
  defp parse_cities_cookie(cities_str) do
    cities_str
    |> String.split(",")
    |> Enum.map(&parse_city_info/1)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_schools_cookie(nil), do: []
  defp parse_schools_cookie(""), do: []
  defp parse_schools_cookie(schools_str) do
    schools_str
    |> String.split(",")
    |> Enum.map(&parse_school_info/1)
    |> Enum.reject(&is_nil/1)
  end
end