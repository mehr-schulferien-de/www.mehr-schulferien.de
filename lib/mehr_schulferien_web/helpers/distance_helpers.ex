defmodule MehrSchulferienWeb.Helpers.DistanceHelpers do
  @moduledoc """
  Distance formatting utilities to avoid duplication.
  """

  @meters_per_kilometer 1000
  @nearby_radius_meters 3000

  @doc """
  Format distance in meters to human-readable format.
  Shows meters for distances under 1km, kilometers with 1 decimal place for longer distances.
  """
  def format_distance(distance_in_meters) when is_number(distance_in_meters) do
    if distance_in_meters < @meters_per_kilometer do
      "#{round(distance_in_meters)} m"
    else
      km = Float.round(distance_in_meters / @meters_per_kilometer, 1)
      "#{km} km"
    end
  end

  def format_distance(_), do: ""

  @doc """
  Get the nearby radius in meters (default 3km).
  """
  def nearby_radius_meters, do: @nearby_radius_meters

  @doc """
  Check if a distance is within the nearby radius.
  """
  def is_nearby?(distance_in_meters) when is_number(distance_in_meters) do
    distance_in_meters <= @nearby_radius_meters
  end

  def is_nearby?(_), do: false
end
