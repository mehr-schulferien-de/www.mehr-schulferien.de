defmodule Mix.Tasks.SchoolQuarantine do
  @moduledoc """
  Mix task for managing school quarantine status.

  ## Usage

      # Quarantine a school
      mix school_quarantine --quarantine 12345-gymnasium-musterstadt

      # Remove quarantine from a school
      mix school_quarantine --unquarantine 12345-gymnasium-musterstadt

      # List all quarantined schools
      mix school_quarantine --list

      # Check status of a specific school
      mix school_quarantine --status 12345-gymnasium-musterstadt
  """
  use Mix.Task

  @shortdoc "Manage school quarantine status"

  @impl Mix.Task
  def run(args) do
    # Start the application
    Mix.Task.run("app.start")

    case parse_args(args) do
      {:quarantine, slug} ->
        quarantine_school(slug)

      {:unquarantine, slug} ->
        unquarantine_school(slug)

      {:list, _} ->
        list_quarantined_schools()

      {:status, slug} ->
        check_status(slug)

      {:error, message} ->
        Mix.shell().error(message)
        print_usage()
    end
  end

  defp parse_args(args) do
    case OptionParser.parse(args,
           strict: [
             quarantine: :string,
             unquarantine: :string,
             list: :boolean,
             status: :string
           ]
         ) do
      {[quarantine: slug], _, _} -> {:quarantine, slug}
      {[unquarantine: slug], _, _} -> {:unquarantine, slug}
      {[list: true], _, _} -> {:list, nil}
      {[status: slug], _, _} -> {:status, slug}
      _ -> {:error, "Invalid arguments"}
    end
  end

  defp quarantine_school(slug) do
    alias MehrSchulferien.Locations

    case Locations.get_school_by_slug_including_quarantined(slug) do
      nil ->
        Mix.shell().error("School not found: #{slug}")

      school ->
        if school.is_quarantined do
          Mix.shell().info("School is already quarantined: #{school.name}")
        else
          case Locations.quarantine_school(school) do
            {:ok, %{model: updated_school}} ->
              Mix.shell().info("✓ School quarantined: #{updated_school.name} (#{slug})")

            {:error, changeset} ->
              Mix.shell().error("Failed to quarantine school: #{inspect(changeset.errors)}")
          end
        end
    end
  end

  defp unquarantine_school(slug) do
    alias MehrSchulferien.Locations

    case Locations.get_school_by_slug_including_quarantined(slug) do
      nil ->
        Mix.shell().error("School not found: #{slug}")

      school ->
        if school.is_quarantined do
          case Locations.unquarantine_school(school) do
            {:ok, %{model: updated_school}} ->
              Mix.shell().info("✓ Quarantine removed: #{updated_school.name} (#{slug})")

            {:error, changeset} ->
              Mix.shell().error("Failed to remove quarantine: #{inspect(changeset.errors)}")
          end
        else
          Mix.shell().info("School is not quarantined: #{school.name}")
        end
    end
  end

  defp list_quarantined_schools do
    alias MehrSchulferien.Locations

    schools = Locations.list_quarantined_schools()

    if Enum.empty?(schools) do
      Mix.shell().info("No quarantined schools found.")
    else
      Mix.shell().info("Quarantined schools (#{length(schools)}):")
      Mix.shell().info("")

      Enum.each(schools, fn school ->
        address_info =
          if school.address do
            "#{school.address.zip_code || "N/A"} #{school.address.city || "N/A"}"
          else
            "No address"
          end

        Mix.shell().info("  • #{school.name}")
        Mix.shell().info("    Slug: #{school.slug}")
        Mix.shell().info("    Address: #{address_info}")
        Mix.shell().info("")
      end)
    end
  end

  defp check_status(slug) do
    alias MehrSchulferien.Locations

    case Locations.get_school_by_slug_including_quarantined(slug) do
      nil ->
        Mix.shell().error("School not found: #{slug}")

      school ->
        status = if school.is_quarantined, do: "QUARANTINED", else: "ACTIVE"

        Mix.shell().info("School: #{school.name}")
        Mix.shell().info("Slug: #{school.slug}")
        Mix.shell().info("Status: #{status}")

        if school.address do
          Mix.shell().info(
            "Address: #{school.address.street}, #{school.address.zip_code} #{school.address.city}"
          )
        end
    end
  end

  defp print_usage do
    Mix.shell().info("""

    Usage:
      mix school_quarantine --quarantine <slug>     Quarantine a school
      mix school_quarantine --unquarantine <slug>   Remove quarantine from a school
      mix school_quarantine --list                  List all quarantined schools
      mix school_quarantine --status <slug>         Check status of a school
    """)
  end
end
