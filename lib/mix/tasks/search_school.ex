defmodule Mix.Tasks.SearchSchool do
  @moduledoc """
  Searches for a school using Google Search API and extracts comprehensive information.

  ## Usage

      mix search_school <school_slug>

  By default, this command extracts comprehensive school information including phone,
  description, social media links, and more.

  ## Options

    * `--pretty` - Pretty print the raw JSON output instead of extracted info
    * `--extract-urls` - Only show extracted homepage URLs
    * `--find-homepage` - Find the most likely homepage URL
    * `--extract-info` - Extract comprehensive school information (DEFAULT)
    * `--force-refresh` - Force a new API call even if cached results exist

  ## Examples

      # Get comprehensive school information (default)
      mix search_school gymnasium-am-kurfuerstlichen-schloss
      
      # Get pretty printed raw JSON results
      mix search_school gymnasium-am-kurfuerstlichen-schloss --pretty
      
      # Extract only URLs from results
      mix search_school gymnasium-am-kurfuerstlichen-schloss --extract-urls
      
      # Find the most likely homepage
      mix search_school gymnasium-am-kurfuerstlichen-schloss --find-homepage
      
      # Force refresh to get fresh data
      mix search_school gymnasium-am-kurfuerstlichen-schloss --force-refresh

  """
  use Mix.Task

  alias MehrSchulferien.SearchEngineAPI

  @shortdoc "Search for a school using Google Search API"

  @impl Mix.Task
  def run(args) do
    # Start the application
    Mix.Task.run("app.start")

    # Parse arguments
    {opts, args_list, _} =
      OptionParser.parse(args,
        switches: [
          pretty: :boolean,
          extract_urls: :boolean,
          find_homepage: :boolean,
          extract_info: :boolean,
          force_refresh: :boolean
        ]
      )

    # Check if school slug was provided
    case args_list do
      [] ->
        display_help()
        exit(:normal)

      [school_slug | _] ->
        # Continue with the school slug
        process_school_search(school_slug, opts)
    end
  end

  defp process_school_search(school_slug, opts) do
    Mix.shell().info("Searching for school with slug: #{school_slug}")
    Mix.shell().info("")

    # Build API options
    api_opts =
      if opts[:force_refresh] do
        Mix.shell().info("🔄 Force refresh enabled - bypassing cache")
        Mix.shell().info("")
        [force_refresh: true]
      else
        []
      end

    case SearchEngineAPI.search_school_by_slug(school_slug, api_opts) do
      {:ok, %{school: school, location_hierarchy: locations, search_results: results}} ->
        # Display school information
        display_school_info(school, locations)

        cond do
          opts[:extract_urls] ->
            display_extracted_urls(results)

          opts[:find_homepage] ->
            display_homepage_finding(results, school.name)

          opts[:pretty] ->
            display_full_results(results, true)

          true ->
            # Default to extract_info if no other option is specified
            display_comprehensive_info(results, school.name)
        end

      {:error, reason} ->
        Mix.shell().error("Error: #{reason}")
        exit(:normal)
    end
  end

  defp display_school_info(school, locations) do
    Mix.shell().info("School Information:")
    Mix.shell().info("  Name: #{school.name}")
    Mix.shell().info("  Slug: #{school.slug}")
    Mix.shell().info("  City: #{locations.city.name}")
    Mix.shell().info("  County: #{locations.county.name}")
    Mix.shell().info("  Federal State: #{locations.federal_state.name}")
    Mix.shell().info("  Country: #{locations.country.name}")

    if school.address do
      Mix.shell().info("\nAddress Information:")
      if school.address.street, do: Mix.shell().info("  Street: #{school.address.street}")
      if school.address.zip_code, do: Mix.shell().info("  Zip Code: #{school.address.zip_code}")
      if school.address.city, do: Mix.shell().info("  City: #{school.address.city}")

      if school.address.homepage_url,
        do: Mix.shell().info("  Current Homepage: #{school.address.homepage_url}")

      if school.address.email_address,
        do: Mix.shell().info("  Email: #{school.address.email_address}")

      if school.address.phone_number,
        do: Mix.shell().info("  Phone: #{school.address.phone_number}")
    end

    Mix.shell().info("\n" <> String.duplicate("-", 80) <> "\n")
  end

  defp display_full_results(results, pretty?) do
    Mix.shell().info("Google Search Results:")
    Mix.shell().info("")

    json =
      if pretty? do
        Jason.encode!(results, pretty: true)
      else
        Jason.encode!(results)
      end

    Mix.shell().info(json)
  end

  defp display_extracted_urls(results) do
    Mix.shell().info("Extracted URLs from Search Results:")
    Mix.shell().info("")

    urls = SearchEngineAPI.extract_homepage_urls(results)

    if Enum.empty?(urls) do
      Mix.shell().info("No URLs found in search results.")
    else
      Enum.each(urls, fn url_info ->
        Mix.shell().info("Position #{url_info.position}:")
        Mix.shell().info("  Title: #{url_info.title}")
        Mix.shell().info("  URL: #{url_info.link}")
        Mix.shell().info("  Display: #{url_info.displayed_link}")

        if url_info.snippet do
          Mix.shell().info("  Snippet: #{String.slice(url_info.snippet, 0, 100)}...")
        end

        Mix.shell().info("")
      end)
    end
  end

  defp display_homepage_finding(results, school_name) do
    Mix.shell().info("Finding Most Likely Homepage:")
    Mix.shell().info("")

    case SearchEngineAPI.find_most_likely_homepage(results, school_name) do
      {:ok, homepage_url} ->
        Mix.shell().info("✓ Most likely homepage found: #{homepage_url}")

        # Also show all URLs for comparison
        Mix.shell().info("\nAll URLs found (for reference):")
        urls = SearchEngineAPI.extract_homepage_urls(results)

        Enum.each(urls, fn url_info ->
          marker = if url_info.link == homepage_url, do: " ← SELECTED", else: ""
          Mix.shell().info("  #{url_info.position}. #{url_info.link}#{marker}")
        end)

      {:error, :not_found} ->
        Mix.shell().info("✗ No suitable homepage URL found in search results.")

        # Show what was found
        urls = SearchEngineAPI.extract_homepage_urls(results)

        if Enum.empty?(urls) do
          Mix.shell().info("\nNo URLs were found in the search results.")
        else
          Mix.shell().info("\nURLs found but none matched criteria:")

          Enum.each(urls, fn url_info ->
            Mix.shell().info("  #{url_info.position}. #{url_info.link}")
          end)
        end
    end
  end

  defp display_comprehensive_info(results, school_name) do
    Mix.shell().info("Extracting Comprehensive School Information:")
    Mix.shell().info("")

    info = SearchEngineAPI.extract_school_info(results, school_name)

    # Display main information
    if info.homepage_url do
      Mix.shell().info("📌 Homepage: #{info.homepage_url}")
    end

    if info.phone_number do
      Mix.shell().info("📞 Phone: #{info.phone_number}")
    end

    if info.description do
      Mix.shell().info("\n📝 Description:")
      Mix.shell().info("   #{info.description}")
    end

    # Display social media
    Mix.shell().info("\n🌐 Social Media:")

    if info.instagram_url do
      Mix.shell().info("   Instagram: #{info.instagram_url}")
    else
      Mix.shell().info("   Instagram: Not found")
    end

    if info.wikipedia_url do
      Mix.shell().info("   Wikipedia: #{info.wikipedia_url}")
    else
      Mix.shell().info("   Wikipedia: Not found")
    end

    # Display additional info if available
    additional = info.additional_info

    if map_size(additional) > 0 do
      Mix.shell().info("\n📊 Additional Information:")

      if additional[:youtube_url] do
        Mix.shell().info("   YouTube: #{additional.youtube_url}")
      end

      if additional[:facebook_url] do
        Mix.shell().info("   Facebook: #{additional.facebook_url}")
      end

      if additional[:students_count] do
        Mix.shell().info("   Students: #{additional.students_count}")
      end

      if additional[:founded] do
        Mix.shell().info("   Founded: #{additional.founded}")
      end

      if additional[:address] do
        Mix.shell().info("   Google Address: #{additional.address}")
      end

      if additional[:website_from_kg] do
        Mix.shell().info("   Website (from Google): #{additional.website_from_kg}")
      end
    end

    # Show raw data availability
    Mix.shell().info("\n💡 Data Sources:")

    if results["knowledge_graph"] do
      Mix.shell().info("   ✓ Google Knowledge Graph available")
    else
      Mix.shell().info("   ✗ No Google Knowledge Graph found")
    end

    organic_count = length(results["organic_results"] || [])
    Mix.shell().info("   ✓ #{organic_count} organic search results analyzed")

    # Show cache status
    if results["search_metadata"] && results["search_metadata"]["created_at"] do
      Mix.shell().info("\n🔍 Search performed at: #{results["search_metadata"]["created_at"]}")
    else
      Mix.shell().info("\n📦 Note: Results may be from cache. Use --force-refresh for fresh data.")
    end
  end

  defp display_help do
    Mix.shell().info("""

    📚 School Search Tool - Google Search API Integration
    ====================================================

    USAGE:
      mix search_school <school_slug> [options]

    DESCRIPTION:
      Searches for a school using Google Search API and extracts comprehensive 
      information. By default, displays formatted school information including 
      contact details, description, and social media links.

    OPTIONS:
      --extract-info      Extract comprehensive school information (DEFAULT)
                          Shows: homepage, phone, description, social media
      
      --find-homepage     Find and display the most likely official homepage
                          Uses intelligent scoring to identify the school's website
      
      --extract-urls      List all URLs found in search results
                          Shows each result with title, link, and snippet
      
      --pretty            Display the raw JSON response in formatted output
                          Useful for debugging or accessing all API data
      
      --force-refresh     Force a new API call, bypassing cached results
                          Use when you need the latest information

    EXAMPLES:
      # Get comprehensive school information (default)
      mix search_school 73430-schubart-gymnasium-partnerschule-fuer-europa
      
      # Find the school's homepage
      mix search_school 73430-schubart-gymnasium-partnerschule-fuer-europa --find-homepage
      
      # Get fresh data, ignoring cache
      mix search_school 73430-schubart-gymnasium-partnerschule-fuer-europa --force-refresh
      
      # View raw API response
      mix search_school 73430-schubart-gymnasium-partnerschule-fuer-europa --pretty

    CACHING:
      Results are automatically cached in the database to save API calls.
      Use --force-refresh to bypass the cache when needed.

    ERROR: No school slug provided!
    Please specify a school slug to search for.
    """)
  end
end
