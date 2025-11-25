defmodule MehrSchulferienWeb.Live.Shared.LocationHistoryHelpers do
  @moduledoc """
  Shared helpers for loading and parsing location history from session/cookies.
  Used by HomeLive and SchoolSearchLive for recent location tracking.
  """

  alias MehrSchulferien.Locations

  @doc """
  Loads recent locations from a comma-separated string stored in the session.
  Returns a list of location maps with type, name, slug, and optional city_name.
  """
  def load_recent_locations(nil), do: []
  def load_recent_locations(""), do: []

  def load_recent_locations(locations_str) do
    # Get country for lookups
    country =
      try do
        Locations.get_country_by_slug!("d")
      rescue
        _ -> nil
      end

    locations_str
    |> String.split(",")
    |> Enum.map(&parse_location_entry/1)
    |> Enum.reject(&is_nil/1)
    |> Enum.map(fn {type, slug} -> load_location(type, slug, country) end)
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Determines if recent locations should be shown based on search params.
  Only shows when both location and school_name fields are empty.
  """
  def should_show_recent_locations(search_params) do
    location = Map.get(search_params, "location", "")
    school_name = Map.get(search_params, "school_name", "")

    location == "" and school_name == ""
  end

  @doc """
  Parses a location entry from the format "type:slug".
  Returns {type, slug} tuple or nil if invalid.
  """
  def parse_location_entry(entry) do
    case String.split(entry, ":") do
      [type, slug] when type in ["f", "c", "s"] -> {type, slug}
      _ -> nil
    end
  end

  # Private helpers

  defp load_location("f", slug, country) do
    try do
      fs = Locations.get_federal_state_by_slug!(slug, country)
      %{type: :federal_state, location: fs, name: fs.name, slug: fs.slug}
    rescue
      _ -> nil
    end
  end

  defp load_location("c", slug, _country) do
    try do
      city = Locations.get_city_by_slug!(slug)
      %{type: :city, location: city, name: city.name, slug: city.slug}
    rescue
      _ -> nil
    end
  end

  defp load_location("s", slug, _country) do
    try do
      school = Locations.get_school_by_slug!(slug)
      # Get parent city for display
      city = Locations.get_location!(school.parent_location_id)

      %{
        type: :school,
        location: school,
        name: school.name,
        slug: school.slug,
        city_name: city.name
      }
    rescue
      _ -> nil
    end
  end

  defp load_location(_, _, _), do: nil
end
