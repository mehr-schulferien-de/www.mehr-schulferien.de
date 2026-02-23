defmodule MehrSchulferienWeb.Live.Shared.SchoolSearchLogic do
  @moduledoc """
  Shared search logic for school searches across LiveViews.
  Implements improved search features including:
  - Single character search support
  - Wildcard search with * character
  - Progressive zip code search (1-5 digits)
  - Starts-with search by default
  - Auto federal state detection for single city results
  """

  import Ecto.Query
  alias MehrSchulferien.Repo

  # Helper to safely parse federal_state_id
  defp parse_federal_state_id(nil), do: :error
  defp parse_federal_state_id(""), do: :error

  defp parse_federal_state_id(value) when is_integer(value), do: {:ok, value}

  defp parse_federal_state_id(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} -> {:ok, int}
      _ -> :error
    end
  end

  defp parse_federal_state_id(_), do: :error

  @doc """
  Checks if text is a partial or full zip code (1-5 digits)
  """
  def is_partial_or_full_zip_code?(nil), do: false

  def is_partial_or_full_zip_code?(text) do
    String.length(text) >= 1 and String.length(text) <= 5 and Regex.match?(~r/^\d+$/, text)
  end

  @doc """
  Converts search params, detecting zip codes and applying appropriate fields
  """
  def convert_search_params(search_params) do
    location = Map.get(search_params, "location", "")

    if is_partial_or_full_zip_code?(location) do
      # It's a zip code (partial or full)
      search_params
      |> Map.delete("location")
      |> Map.put("zip_code", location)
      |> Map.put("city", "")
    else
      # It's a city name or empty
      search_params
      |> Map.delete("location")
      |> Map.put("city", location)
      |> Map.put("zip_code", "")
    end
  end

  @doc """
  Prepares search pattern with wildcard support
  """
  def prepare_search_pattern(text, default_prefix \\ true) do
    cond do
      String.contains?(text, "*") ->
        # Replace * with % for SQL wildcard
        String.replace(text, "*", "%")

      default_prefix ->
        # Default: search from beginning (starts with)
        "#{text}%"

      true ->
        # Contains search
        "%#{text}%"
    end
  end

  @doc """
  Searches for schools with zip code (partial or full)
  """
  def search_schools_by_zip(zip_code, school_name, federal_state_id \\ nil) do
    zip_pattern = "#{zip_code}%"

    base_query =
      from s in MehrSchulferien.Locations.Location,
        join: city in MehrSchulferien.Locations.Location,
        on: city.id == s.parent_location_id,
        join: county in MehrSchulferien.Locations.Location,
        on: county.id == city.parent_location_id,
        left_join: a in MehrSchulferien.Maps.Address,
        on: a.school_location_id == s.id,
        left_join: zcm in MehrSchulferien.Maps.ZipCodeMapping,
        on: zcm.location_id == city.id,
        left_join: zc in MehrSchulferien.Maps.ZipCode,
        on: zc.id == zcm.zip_code_id,
        where: s.is_school == true and s.is_quarantined == false,
        where: like(zc.value, ^zip_pattern) or like(a.zip_code, ^zip_pattern)

    query =
      case parse_federal_state_id(federal_state_id) do
        {:ok, federal_state_id_int} ->
          from [s, city, county, a, zcm, zc] in base_query,
            where: county.parent_location_id == ^federal_state_id_int

        :error ->
          base_query
      end

    query =
      if String.length(school_name) >= 1 do
        school_pattern = prepare_search_pattern(school_name)

        from [s, city, county, a, zcm, zc] in query,
          where: ilike(s.name, ^school_pattern)
      else
        query
      end

    query =
      from [s, city, county, a, zcm, zc] in query,
        distinct: true,
        order_by: [city.name, s.name],
        select: %{
          # School fields
          id: s.id,
          name: s.name,
          slug: s.slug,
          # City fields
          city_id: city.id,
          city_name: city.name,
          city_slug: city.slug,
          # County & State for hierarchy
          county_id: county.id,
          federal_state_id: county.parent_location_id,
          # Address fields
          street: a.street,
          zip_code: a.zip_code
        }

    Repo.all(query)
  end

  @doc """
  Searches for schools by city name
  """
  def search_schools_by_city(city_name, school_name, federal_state_id \\ nil) do
    city_pattern = prepare_search_pattern(city_name)

    base_query =
      from c in MehrSchulferien.Locations.Location,
        join: county in MehrSchulferien.Locations.Location,
        on: county.id == c.parent_location_id,
        join: federal_state in MehrSchulferien.Locations.Location,
        on: federal_state.id == county.parent_location_id,
        join: s in MehrSchulferien.Locations.Location,
        on: s.parent_location_id == c.id and s.is_school == true and s.is_quarantined == false,
        left_join: a in MehrSchulferien.Maps.Address,
        on: a.school_location_id == s.id,
        where: c.is_city == true and ilike(c.name, ^city_pattern)

    query =
      if federal_state_id && federal_state_id != "" do
        from [c, county, federal_state, s, a] in base_query,
          where: federal_state.id == ^String.to_integer(federal_state_id)
      else
        base_query
      end

    query =
      if String.length(school_name) >= 1 do
        school_pattern = prepare_search_pattern(school_name)

        from [c, county, federal_state, s, a] in query,
          where: ilike(s.name, ^school_pattern)
      else
        query
      end

    query =
      from [c, county, federal_state, s, a] in query,
        distinct: true,
        select: %{
          # City fields
          city_id: c.id,
          city_name: c.name,
          city_slug: c.slug,
          # County & State fields for hierarchy
          county_id: county.id,
          federal_state_id: federal_state.id,
          # School fields
          school_id: s.id,
          school_name: s.name,
          school_slug: s.slug,
          # Address fields
          street: a.street,
          zip_code: a.zip_code
        },
        order_by: [c.name, s.name]

    Repo.all(query)
  end

  @doc """
  Searches for schools by name only
  """
  def search_schools_by_name(school_name, federal_state_id \\ nil) do
    school_pattern = prepare_search_pattern(school_name)

    base_query =
      from s in MehrSchulferien.Locations.Location,
        join: city in MehrSchulferien.Locations.Location,
        on: city.id == s.parent_location_id,
        join: county in MehrSchulferien.Locations.Location,
        on: county.id == city.parent_location_id,
        join: federal_state in MehrSchulferien.Locations.Location,
        on: federal_state.id == county.parent_location_id,
        left_join: a in MehrSchulferien.Maps.Address,
        on: a.school_location_id == s.id,
        where:
          s.is_school == true and s.is_quarantined == false and ilike(s.name, ^school_pattern)

    query =
      if federal_state_id && federal_state_id != "" do
        from [s, city, county, federal_state, a] in base_query,
          where: federal_state.id == ^String.to_integer(federal_state_id)
      else
        base_query
      end

    query =
      from [s, city, county, federal_state, a] in query,
        distinct: true,
        select: %{
          # School fields
          id: s.id,
          name: s.name,
          slug: s.slug,
          # City fields
          city_id: city.id,
          city_name: city.name,
          city_slug: city.slug,
          # County & State for hierarchy
          county_id: county.id,
          federal_state_id: federal_state.id,
          federal_state_name: federal_state.name,
          # Address fields
          street: a.street,
          zip_code: a.zip_code
        },
        order_by: s.name,
        limit: 500

    Repo.all(query)
  end

  @doc """
  Optimized search for schools by federal state only
  """
  def search_schools_by_federal_state(federal_state_id) do
    federal_state_id_int = String.to_integer(federal_state_id)

    query =
      from s in MehrSchulferien.Locations.Location,
        join: city in MehrSchulferien.Locations.Location,
        on: city.id == s.parent_location_id,
        join: county in MehrSchulferien.Locations.Location,
        on: county.id == city.parent_location_id,
        left_join: a in MehrSchulferien.Maps.Address,
        on: a.school_location_id == s.id,
        where: s.is_school == true and s.is_quarantined == false,
        where: county.parent_location_id == ^federal_state_id_int,
        distinct: true,
        order_by: [city.name, s.name],
        select: %{
          id: s.id,
          name: s.name,
          slug: s.slug,
          parent_location: %{
            id: city.id,
            name: city.name,
            slug: city.slug,
            parent_location: %{
              id: county.id,
              parent_location: %{
                id: county.parent_location_id
              }
            }
          },
          address: %{
            street: a.street,
            zip_code: a.zip_code
          }
        }

    Repo.all(query)
  end

  @doc """
  Converts search results to school structures
  """
  def results_to_schools(results) do
    Enum.map(results, fn r ->
      # Check if this is already a structured result (from search_schools_by_federal_state)
      if Map.has_key?(r, :parent_location) do
        r
      else
        # Convert flat result to structured format
        %{
          id: Map.get(r, :school_id, Map.get(r, :id)),
          name: Map.get(r, :school_name, Map.get(r, :name)),
          slug: Map.get(r, :school_slug, Map.get(r, :slug)),
          parent_location: %{
            id: r.city_id,
            name: r.city_name,
            slug: Map.get(r, :city_slug),
            parent_location: %{
              id: r.county_id,
              parent_location: %{
                id: r.federal_state_id,
                name: Map.get(r, :federal_state_name)
              }
            }
          },
          address:
            if(r.street || r.zip_code, do: %{street: r.street, zip_code: r.zip_code}, else: nil)
        }
      end
    end)
  end

  @doc """
  Groups schools by city
  """
  def group_schools_by_city(results) do
    results
    |> Enum.group_by(fn r ->
      {r.city_id, r.city_name, Map.get(r, :city_slug), r.county_id, r.federal_state_id}
    end)
    |> Enum.map(fn {{city_id, city_name, city_slug, county_id, federal_state_id}, school_results} ->
      city = %{
        id: city_id,
        name: city_name,
        slug: city_slug,
        parent_location: %{
          id: county_id,
          parent_location: %{id: federal_state_id}
        }
      }

      schools =
        Enum.map(school_results, fn r ->
          %{
            id: Map.get(r, :school_id, Map.get(r, :id)),
            name: Map.get(r, :school_name, Map.get(r, :name)),
            slug: Map.get(r, :school_slug, Map.get(r, :slug)),
            address:
              if(r.street || r.zip_code,
                do: %{street: r.street, zip_code: r.zip_code},
                else: nil
              )
          }
        end)

      {city, schools}
    end)
  end

  @doc """
  Detects and returns federal state ID if all schools are from the same federal state
  """
  def detect_single_federal_state(results) do
    federal_states =
      results
      |> Enum.map(& &1.federal_state_id)
      |> Enum.uniq()

    case federal_states do
      [single_state_id] -> to_string(single_state_id)
      _ -> nil
    end
  end

  @doc """
  Formats number with thousands separator
  """
  def format_number(number) when is_integer(number) do
    number
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1.")
    |> String.reverse()
  end

  @doc """
  Sorts schools by the given field and order.
  Returns schools unchanged if field is nil.
  """
  def sort_schools(schools, nil, _order), do: schools

  def sort_schools(schools, field, order) do
    Enum.sort_by(
      schools,
      fn school ->
        case field do
          :name ->
            school.name || ""

          :street ->
            if school.address, do: school.address.street || "", else: ""

          :zip_code ->
            if school.address, do: school.address.zip_code || "", else: ""

          :city ->
            if school.parent_location, do: school.parent_location.name || "", else: ""

          _ ->
            ""
        end
      end,
      if(order == :asc, do: &<=/2, else: &>=/2)
    )
  end

  @doc """
  Fetches federal states for the dropdown.
  Returns a list of {name, id} tuples sorted by name.
  """
  def get_federal_states do
    alias MehrSchulferien.Locations

    case Locations.get_country_by_slug("d") do
      nil ->
        []

      country ->
        Locations.list_federal_states(country)
        |> Enum.map(fn state -> {state.name, state.id} end)
        |> Enum.sort_by(&elem(&1, 0))
    end
  end
end
