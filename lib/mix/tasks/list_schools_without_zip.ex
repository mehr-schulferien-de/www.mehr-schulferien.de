defmodule Mix.Tasks.ListSchoolsWithoutZip do
  @moduledoc """
  Lists all schools that don't have a zip code in their address.

  ## Usage

      mix list_schools_without_zip

  ## Options

    * `--count` - Only show the count of schools without zip codes
    * `--export` - Export the list to a CSV file
    * `--state <slug>` - Filter by federal state slug

  ## Examples

      # List all schools without zip codes
      mix list_schools_without_zip
      
      # Show only the count
      mix list_schools_without_zip --count
      
      # Export to CSV
      mix list_schools_without_zip --export
      
      # Filter by federal state
      mix list_schools_without_zip --state bayern

  """
  use Mix.Task

  import Ecto.Query

  alias MehrSchulferien.Repo
  alias MehrSchulferien.Locations.Location
  alias MehrSchulferien.Maps.Address

  @shortdoc "Lists schools without zip codes"

  @impl Mix.Task
  def run(args) do
    # Start the application
    Mix.Task.run("app.start")

    # Parse arguments
    {opts, _, _} =
      OptionParser.parse(args,
        switches: [
          count: :boolean,
          export: :boolean,
          state: :string
        ]
      )

    # Execute the task
    list_schools_without_zip(opts)
  end

  defp list_schools_without_zip(opts) do
    query = build_query(opts)

    schools =
      query
      |> Repo.all()
      |> Repo.preload([:address, :parent_location])
      |> load_location_hierarchy()

    cond do
      opts[:count] ->
        display_count(schools)

      opts[:export] ->
        export_to_csv(schools)

      true ->
        display_schools(schools, opts)
    end
  end

  defp build_query(opts) do
    base_query =
      from l in Location,
        left_join: a in Address,
        on: a.school_location_id == l.id,
        where: l.is_school == true,
        where: is_nil(a.zip_code) or a.zip_code == "",
        select: l,
        order_by: [asc: l.name]

    case opts[:state] do
      nil -> base_query
      state_slug -> filter_by_state(base_query, state_slug)
    end
  end

  defp filter_by_state(query, state_slug) do
    from l in query,
      join: city in Location,
      on: l.parent_location_id == city.id and city.is_city == true,
      join: county in Location,
      on: city.parent_location_id == county.id and county.is_county == true,
      join: state in Location,
      on: county.parent_location_id == state.id and state.is_federal_state == true,
      where: state.slug == ^state_slug
  end

  defp load_location_hierarchy(schools) do
    Enum.map(schools, fn school ->
      hierarchy = get_location_hierarchy(school)
      Map.put(school, :hierarchy, hierarchy)
    end)
  end

  defp get_location_hierarchy(school) do
    city = get_parent_location(school.parent_location_id)
    county = if city, do: get_parent_location(city.parent_location_id), else: nil
    state = if county, do: get_parent_location(county.parent_location_id), else: nil

    %{
      city: city,
      county: county,
      federal_state: state
    }
  end

  defp get_parent_location(nil), do: nil

  defp get_parent_location(id) do
    Repo.get(Location, id)
  end

  defp display_count(schools) do
    count = length(schools)
    Mix.shell().info("Schools without zip code: #{count}")
  end

  defp display_schools(schools, opts) do
    if opts[:state] do
      Mix.shell().info("Schools without zip code in #{opts[:state]}:")
    else
      Mix.shell().info("Schools without zip code:")
    end

    Mix.shell().info("\n" <> String.duplicate("=", 80))

    if Enum.empty?(schools) do
      Mix.shell().info("\nNo schools found without zip codes.")
    else
      Enum.each(schools, fn school ->
        display_school(school)
        Mix.shell().info(String.duplicate("-", 80))
      end)

      Mix.shell().info("\nTotal: #{length(schools)} schools")
    end
  end

  defp display_school(school) do
    Mix.shell().info("\nSchool: #{school.name}")
    Mix.shell().info("Slug: #{school.slug}")

    if school.hierarchy.city do
      Mix.shell().info("City: #{school.hierarchy.city.name}")
    end

    if school.hierarchy.county do
      Mix.shell().info("County: #{school.hierarchy.county.name}")
    end

    if school.hierarchy.federal_state do
      Mix.shell().info("Federal State: #{school.hierarchy.federal_state.name}")
    end

    if school.address do
      Mix.shell().info("\nAddress Details:")
      if school.address.street, do: Mix.shell().info("  Street: #{school.address.street}")
      if school.address.city, do: Mix.shell().info("  City: #{school.address.city}")
      Mix.shell().info("  Zip Code: [MISSING]")

      if school.address.phone_number do
        Mix.shell().info("  Phone: #{school.address.phone_number}")
      end

      if school.address.homepage_url do
        Mix.shell().info("  Homepage: #{school.address.homepage_url}")
      end
    else
      Mix.shell().info("\nNo address record found for this school.")
    end
  end

  defp export_to_csv(schools) do
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601(:basic) |> String.replace(~r/[:\-]/, "")
    filename = "schools_without_zip_#{timestamp}.csv"

    csv_content = build_csv_content(schools)

    case File.write(filename, csv_content) do
      :ok ->
        Mix.shell().info("Exported #{length(schools)} schools to #{filename}")

      {:error, reason} ->
        Mix.shell().error("Failed to write CSV file: #{reason}")
    end
  end

  defp build_csv_content(schools) do
    headers = [
      "School Name",
      "School Slug",
      "City",
      "County",
      "Federal State",
      "Street",
      "Address City",
      "Phone",
      "Homepage"
    ]

    rows =
      Enum.map(schools, fn school ->
        [
          school.name,
          school.slug,
          get_in(school, [:hierarchy, :city, :name]) || "",
          get_in(school, [:hierarchy, :county, :name]) || "",
          get_in(school, [:hierarchy, :federal_state, :name]) || "",
          get_in(school, [:address, :street]) || "",
          get_in(school, [:address, :city]) || "",
          get_in(school, [:address, :phone_number]) || "",
          get_in(school, [:address, :homepage_url]) || ""
        ]
      end)

    ([headers] ++ rows)
    |> Enum.map(&format_csv_row/1)
    |> Enum.join("\n")
  end

  defp format_csv_row(row) do
    row
    |> Enum.map(&escape_csv_field/1)
    |> Enum.join(",")
  end

  defp escape_csv_field(field) when is_binary(field) do
    if String.contains?(field, [",", "\"", "\n"]) do
      "\"" <> String.replace(field, "\"", "\"\"") <> "\""
    else
      field
    end
  end

  defp escape_csv_field(field), do: to_string(field)
end
