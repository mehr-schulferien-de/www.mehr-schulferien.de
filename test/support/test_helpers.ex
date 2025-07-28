defmodule MehrSchulferien.TestHelpers do
  @moduledoc """
  Helper functions for tests to handle common operations like
  getting or creating test data.
  """

  import MehrSchulferien.Factory
  alias MehrSchulferien.Locations.Location
  alias MehrSchulferien.Repo

  @doc """
  Gets the existing Deutschland country from the seeded database,
  or creates a new one if it doesn't exist.

  This helps avoid unique constraint violations in tests when
  the database already has seeded data.
  """
  def get_or_create_deutschland do
    Repo.get_by(Location, slug: "d", is_country: true) ||
      insert(:country, %{slug: "d", name: "Deutschland", code: "D"})
  end

  @doc """
  Gets the existing Switzerland country from the seeded database,
  or creates a new one if it doesn't exist.

  This helps avoid unique constraint violations in tests when
  the database already has seeded data.
  """
  def get_or_create_switzerland do
    Repo.get_by(Location, slug: "ch", is_country: true) ||
      insert(:country, %{slug: "ch", name: "Schweiz", code: "CH"})
  end

  @doc """
  Gets or creates a country by slug.
  """
  def get_or_create_country(slug) do
    case slug do
      "d" -> get_or_create_deutschland()
      "ch" -> get_or_create_switzerland()
      _ -> raise ArgumentError, "Unknown country slug: #{slug}"
    end
  end
end
