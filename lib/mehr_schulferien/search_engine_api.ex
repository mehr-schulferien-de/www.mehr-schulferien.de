defmodule MehrSchulferien.SearchEngineAPI do
  @moduledoc """
  Module for interacting with search engines via SerpApi.

  This module provides functionality to search for schools using search engine results
  to enrich or verify school homepage URLs.

  ## Configuration

  This module requires the `SERPAPI_API_KEY` environment variable to be set
  with your SerpApi API key.

  Example:
      export GOOGLE_SEARCH_API_KEY="your_api_key_here"

  To get an API key, visit: https://serpapi.com
  """

  require Logger

  @base_url "https://serpapi.com/search"

  @doc """
  Gets the SerpApi key from environment variable.
  Returns {:ok, api_key} if set, {:error, message} if not.
  """
  def get_api_key do
    case System.get_env("SERPAPI_API_KEY") do
      nil ->
        {:error, "SERPAPI_API_KEY environment variable is not set"}

      "" ->
        {:error, "SERPAPI_API_KEY environment variable is empty"}

      api_key ->
        {:ok, api_key}
    end
  end

  @doc """
  Searches for a school using Google Search API.

  ## Parameters

    * `school_name` - The name of the school to search for
    * `location` - The location string (e.g., "Koblenz, Rhineland-Palatinate, Germany")
    * `opts` - Optional parameters (keyword list)
      * `:google_domain` - Google domain to use (default: "google.de")
      * `:gl` - Country code for Google (default: "de")
      * `:hl` - Language code (default: "de")

  ## Returns

    * `{:ok, results}` - On success, returns the parsed JSON response
    * `{:error, reason}` - On failure, returns error reason

  ## Examples

      iex> SearchEngineAPI.search_school("Görres Gymnasium", "Koblenz, Rhineland-Palatinate, Germany")
      {:ok, %{"organic_results" => [...], ...}}

  """
  def search_school(school_name, location, opts \\ []) do
    # Get API key first
    case get_api_key() do
      {:ok, api_key} ->
        google_domain = Keyword.get(opts, :google_domain, "google.de")
        gl = Keyword.get(opts, :gl, "de")
        hl = Keyword.get(opts, :hl, "de")

        params = %{
          api_key: api_key,
          engine: "google",
          q: school_name,
          location: location,
          google_domain: google_domain,
          gl: gl,
          hl: hl
        }

        Logger.info("Searching for school: #{school_name} in #{location}")

        case Req.get(@base_url, params: params) do
          {:ok, %{status: 200, body: body}} ->
            {:ok, body}

          {:ok, %{status: status, body: body}} ->
            Logger.error("Google Search API returned status #{status}: #{inspect(body)}")
            {:error, "API returned status #{status}"}

          {:error, reason} ->
            Logger.error("Failed to search Google: #{inspect(reason)}")
            {:error, reason}
        end

      {:error, reason} ->
        Logger.error("Cannot perform search: #{reason}")
        {:error, reason}
    end
  end

  @doc """
  Searches for a school by its slug using the database to get full location information.

  ## Parameters

    * `school_slug` - The slug of the school in the database
    * `opts` - Optional parameters (see `search_school/3`)
      * `:force_refresh` - Force a new API call even if cached results exist (default: false)

  ## Returns

    * `{:ok, %{school: school, search_results: results}}` - On success
    * `{:error, reason}` - On failure

  ## Caching

  Results are cached in the school's address record to save API calls.
  Use `force_refresh: true` to bypass the cache and fetch fresh results.

  """
  def search_school_by_slug(school_slug, opts \\ []) do
    alias MehrSchulferien.Locations
    alias MehrSchulferien.Repo

    try do
      # Get the school with address
      school = Locations.get_school_by_slug!(school_slug)

      # Get the location hierarchy
      city = Locations.get_location!(school.parent_location_id)
      county = Locations.get_location!(city.parent_location_id)
      federal_state = Locations.get_location!(county.parent_location_id)
      country = Locations.get_location!(federal_state.parent_location_id)

      location_map = %{
        school: school,
        city: city,
        county: county,
        federal_state: federal_state,
        country: country
      }

      # Check if we should use cached results
      force_refresh = Keyword.get(opts, :force_refresh, false)

      search_results =
        if school.address && school.address.google_search_cache && !force_refresh do
          # Use cached results
          Logger.info("Using cached Google search results for school: #{school.name}")
          school.address.google_search_cache
        else
          # Perform new search
          Logger.info("Fetching fresh Google search results for school: #{school.name}")

          # Build location string for Google search
          location_string = build_location_string(city, federal_state, country)

          case search_school(school.name, location_string, opts) do
            {:ok, results} ->
              # Save results to cache if school has an address
              if school.address do
                save_search_cache(school.address, results)
              end

              results

            {:error, reason} ->
              raise "Failed to search Google: #{reason}"
          end
        end

      {:ok,
       %{
         school: school,
         location_hierarchy: location_map,
         search_results: search_results
       }}
    rescue
      _e in Ecto.NoResultsError ->
        {:error, "School with slug '#{school_slug}' not found"}

      e in Ecto.StaleEntryError ->
        # Handle stale entry gracefully - this can happen in tests with concurrent updates
        if Application.get_env(:mehr_schulferien, :env) != :test do
          Logger.error("Stale entry error searching for school: #{inspect(e)}")
        end

        {:error, "Stale entry error: #{Exception.message(e)}"}

      e ->
        Logger.error("Error searching for school: #{inspect(e)}")
        {:error, "Unexpected error: #{Exception.message(e)}"}
    end
  end

  @doc """
  Extracts potential homepage URLs from Google search results.

  ## Parameters

    * `search_results` - The search results from Google Search API

  ## Returns

    List of maps containing URL information from organic results

  """
  def extract_homepage_urls(search_results) do
    organic_results = Map.get(search_results, "organic_results", [])

    Enum.map(organic_results, fn result ->
      %{
        position: Map.get(result, "position"),
        title: Map.get(result, "title"),
        link: Map.get(result, "link"),
        displayed_link: Map.get(result, "displayed_link"),
        snippet: Map.get(result, "snippet")
      }
    end)
    |> Enum.filter(fn result -> result.link != nil end)
  end

  @doc """
  Finds the most likely homepage URL from search results.

  Prioritizes results that:
  1. Are in the first position
  2. Have the school name in the title
  3. Have common school domain patterns (.schule., .gymnasium., etc.)

  ## Parameters

    * `search_results` - The search results from Google Search API
    * `school_name` - The name of the school to match against

  ## Returns

    * `{:ok, url}` - If a likely homepage is found
    * `{:error, :not_found}` - If no suitable homepage is found

  """
  def find_most_likely_homepage(search_results, school_name) do
    urls = extract_homepage_urls(search_results)

    # Normalize school name for comparison
    normalized_school_name = String.downcase(school_name)

    # Score each URL based on likelihood of being the official homepage
    scored_urls =
      Enum.map(urls, fn url_info ->
        score = calculate_homepage_score(url_info, normalized_school_name)
        Map.put(url_info, :score, score)
      end)

    # Sort by score (highest first) and position (lowest first)
    sorted_urls =
      Enum.sort_by(scored_urls, fn url ->
        {-url.score, url.position}
      end)

    case sorted_urls do
      [best | _] when best.score > 0 ->
        {:ok, best.link}

      _ ->
        {:error, :not_found}
    end
  end

  # Private functions

  defp build_location_string(city, federal_state, country) do
    # Build a location string in English for consistency with the API
    federal_state_name = translate_federal_state(federal_state.name)
    country_name = translate_country(country.name)

    "#{city.name}, #{federal_state_name}, #{country_name}"
  end

  defp calculate_homepage_score(url_info, normalized_school_name) do
    score = 0

    # Check if school name appears in title (high confidence)
    score =
      if String.contains?(String.downcase(url_info.title || ""), normalized_school_name) do
        score + 10
      else
        score
      end

    # Check for common school domain patterns
    link = String.downcase(url_info.link || "")

    school_patterns = [
      ".schule.",
      ".gymnasium.",
      ".realschule.",
      ".gesamtschule.",
      ".grundschule.",
      ".hauptschule.",
      ".mittelschule."
    ]

    score =
      if Enum.any?(school_patterns, &String.contains?(link, &1)) do
        score + 5
      else
        score
      end

    # First position gets bonus points
    score =
      if url_info.position == 1 do
        score + 3
      else
        score
      end

    # Check if it's not a social media or directory site
    excluded_domains = [
      "facebook.com",
      "instagram.com",
      "twitter.com",
      "wikipedia.org",
      "schulen.de",
      "schule-studium.de",
      "meinestadt.de",
      "youtube.com",
      "mehr-schulferien.de"
    ]

    score =
      if Enum.any?(excluded_domains, &String.contains?(link, &1)) do
        score - 10
      else
        score
      end

    # Bonus for official-looking domains
    score =
      if String.contains?(link, ".de/") and not String.contains?(link, "aalen.de") do
        score + 2
      else
        score
      end

    score
  end

  @doc """
  Extracts comprehensive school information from search results.

  Returns a map with:
  - phone_number: Extracted phone number from knowledge graph or snippets
  - description: School description from knowledge graph or snippets
  - wikipedia_url: Wikipedia page if found
  - instagram_url: Instagram profile if found
  - homepage_url: Most likely homepage
  - additional_info: Other useful information found
  """
  def extract_school_info(search_results, school_name) do
    info = %{
      phone_number: nil,
      description: nil,
      wikipedia_url: nil,
      instagram_url: nil,
      homepage_url: nil,
      street: nil,
      zip_code: nil,
      city: nil,
      additional_info: %{}
    }

    # Find the most likely homepage first
    info =
      case find_most_likely_homepage(search_results, school_name) do
        {:ok, homepage} -> %{info | homepage_url: homepage}
        _ -> info
      end

    # Extract from knowledge graph if available
    info =
      if kg = search_results["knowledge_graph"] do
        info
        |> extract_from_knowledge_graph(kg)
      else
        info
      end

    # Extract from organic results (can now use homepage_url for better description matching)
    info = extract_from_organic_results(info, search_results["organic_results"] || [])

    info
  end

  defp extract_from_knowledge_graph(info, kg) do
    alias MehrSchulferien.Helpers.PhoneFormatter

    # Try different possible field names for description
    description =
      kg["description"] || kg["beschreibung"] || kg["about"] || kg["type"] || kg["art"]

    # Extract Wikipedia URL if present
    wikipedia_url = kg["wikipedia"] || kg["wikipedia_url"] || kg["wiki"]

    # Extract address components
    {street, zip_code, city} = extract_address_components(kg["address"] || kg["adresse"])

    info
    |> Map.put(:phone_number, PhoneFormatter.format_international(kg["telefon"]))
    |> Map.put(:description, summarize_description(description))
    |> Map.put(:wikipedia_url, wikipedia_url)
    |> Map.put(:street, street)
    |> Map.put(:zip_code, zip_code)
    |> Map.put(:city, city)
    |> Map.put(
      :additional_info,
      Map.merge(info.additional_info, %{
        website_from_kg: kg["website"],
        address: kg["address"],
        students_count: extract_student_count(kg["schüler"]),
        founded: kg["gründung"],
        coordinates: kg["koordinaten"]
      })
    )
    |> extract_social_profiles(kg["profile"] || [])
  end

  defp extract_student_count(nil), do: nil

  defp extract_student_count(text) when is_binary(text) do
    # Extract number from strings like "etwa 570 Schüler" or "570 students"
    case Regex.run(~r/(\d+)/, text) do
      [_, number_str] -> String.to_integer(number_str)
      _ -> nil
    end
  end

  defp extract_student_count(_), do: nil

  defp extract_address_components(nil), do: {nil, nil, nil}
  defp extract_address_components(""), do: {nil, nil, nil}

  defp extract_address_components(address) when is_binary(address) do
    # Try to parse German address format: "Street Number, ZIP City"
    # Examples: 
    # "Gymnasialstraße 4, 56068 Koblenz"
    # "Riesstraße 40, 56077 Koblenz"

    case Regex.run(~r/^(.+?),\s*(\d{5})\s+(.+)$/, address) do
      [_, street, zip_code, city] ->
        {String.trim(street), String.trim(zip_code), String.trim(city)}

      _ ->
        # Try alternative format without comma
        case Regex.run(~r/^(.+?)\s+(\d{5})\s+(.+)$/, address) do
          [_, street, zip_code, city] ->
            {String.trim(street), String.trim(zip_code), String.trim(city)}

          _ ->
            # Could not parse, return nil values
            {nil, nil, nil}
        end
    end
  end

  defp extract_address_components(_), do: {nil, nil, nil}

  defp extract_social_profiles(info, profiles) do
    Enum.reduce(profiles, info, fn profile, acc ->
      link = profile["link"] || ""
      name = profile["name"] || ""

      cond do
        String.contains?(link, "instagram.com") ->
          %{acc | instagram_url: link}

        String.contains?(link, "youtube.com") ->
          put_in(acc, [:additional_info, :youtube_url], link)

        String.contains?(link, "facebook.com") ->
          put_in(acc, [:additional_info, :facebook_url], link)

        String.contains?(link, "wikipedia.org") ||
            String.contains?(String.downcase(name), "wikipedia") ->
          # Only update if we don't already have a Wikipedia URL
          if is_nil(acc.wikipedia_url) do
            %{acc | wikipedia_url: link}
          else
            acc
          end

        true ->
          acc
      end
    end)
  end

  defp extract_from_organic_results(info, organic_results) do
    # First pass: extract URLs
    info_with_urls =
      Enum.reduce(organic_results, info, fn result, acc ->
        link = result["link"] || ""

        acc
        |> maybe_extract_wikipedia(link)
        |> maybe_extract_instagram(link)
      end)

    # Second pass: extract content (can now use homepage_url for description matching)
    Enum.reduce(organic_results, info_with_urls, fn result, acc ->
      link = result["link"] || ""
      snippet = result["snippet"] || ""

      acc
      |> maybe_extract_phone_from_snippet(snippet)
      |> maybe_extract_description_from_snippet(snippet, link)
    end)
  end

  defp maybe_extract_wikipedia(info, link) do
    if String.contains?(link, "wikipedia.org") and is_nil(info.wikipedia_url) do
      %{info | wikipedia_url: link}
    else
      info
    end
  end

  defp maybe_extract_instagram(info, link) do
    if String.contains?(link, "instagram.com") and is_nil(info.instagram_url) do
      %{info | instagram_url: link}
    else
      info
    end
  end

  defp maybe_extract_phone_from_snippet(info, snippet) do
    alias MehrSchulferien.Helpers.PhoneFormatter

    if is_nil(info.phone_number) do
      # Look for German phone number patterns
      case Regex.run(
             ~r/(?:Tel\.?|Telefon|Fon|☎️?):?\s*([+]?49[\s.-]?[\d\s.-]+|\(?\d{3,5}\)?[\s.-]?\d{3,10})/,
             snippet
           ) do
        [_, phone] -> %{info | phone_number: PhoneFormatter.format_international(phone)}
        _ -> info
      end
    else
      info
    end
  end

  defp maybe_extract_description_from_snippet(info, snippet, link) do
    # Only use snippets from school's own website or Wikipedia for description
    is_from_school_site =
      String.contains?(link, ".schule.") or
        String.contains?(link, ".gymnasium.") or
        String.contains?(link, "gymnasium") or
        String.contains?(link, "schule") or
        String.contains?(link, "wikipedia.org") or
        (info.homepage_url &&
           String.contains?(link, URI.parse(info.homepage_url || "").host || ""))

    if is_nil(info.description) and is_from_school_site do
      # Clean up the snippet
      cleaned =
        snippet
        |> String.replace(~r/\s+/, " ")
        |> String.trim()

      if String.length(cleaned) > 50 do
        Logger.info("Extracting description from snippet: #{String.slice(cleaned, 0, 100)}...")
        %{info | description: summarize_description(cleaned)}
      else
        info
      end
    else
      info
    end
  end

  defp translate_federal_state(name) do
    # Translate German federal state names to English for the API
    translations = %{
      "Baden-Württemberg" => "Baden-Württemberg",
      "Bayern" => "Bavaria",
      "Berlin" => "Berlin",
      "Brandenburg" => "Brandenburg",
      "Bremen" => "Bremen",
      "Hamburg" => "Hamburg",
      "Hessen" => "Hesse",
      "Mecklenburg-Vorpommern" => "Mecklenburg-Western Pomerania",
      "Niedersachsen" => "Lower Saxony",
      "Nordrhein-Westfalen" => "North Rhine-Westphalia",
      "Rheinland-Pfalz" => "Rhineland-Palatinate",
      "Saarland" => "Saarland",
      "Sachsen" => "Saxony",
      "Sachsen-Anhalt" => "Saxony-Anhalt",
      "Schleswig-Holstein" => "Schleswig-Holstein",
      "Thüringen" => "Thuringia"
    }

    Map.get(translations, name, name)
  end

  defp translate_country(name) do
    # Translate country name to English
    case name do
      "Deutschland" -> "Germany"
      _ -> name
    end
  end

  defp save_search_cache(address, search_results) do
    alias MehrSchulferien.Repo

    # Use Ecto.Changeset.change to bypass the custom changeset function
    changeset =
      address
      |> Ecto.Changeset.change(%{
        google_search_cache: search_results,
        google_search_cached_at: DateTime.truncate(DateTime.utc_now(), :second)
      })

    case Repo.update(changeset) do
      {:ok, _updated_address} ->
        Logger.info("Saved Google search results to cache for address ID: #{address.id}")
        :ok

      {:error, changeset} ->
        Logger.error("Failed to save Google search cache: #{inspect(changeset.errors)}")
        :error
    end
  rescue
    e in Ecto.StaleEntryError ->
      # Handle stale entry gracefully - this can happen in tests with concurrent updates
      if Application.get_env(:mehr_schulferien, :env) != :test do
        Logger.warning(
          "Stale entry when updating cache for address ID: #{address.id}: #{inspect(e)}"
        )
      end

      :error
  end

  @doc """
  Summarizes a school description using Ollama to extract only the essential information.
  Removes details about staff, student counts, and focuses on school type and specializations.
  """
  def summarize_description(nil), do: nil
  def summarize_description(""), do: ""

  def summarize_description(description) when is_binary(description) do
    # Check if Ollama is available
    if ollama_available?() do
      prompt = """
      Fasse die folgende Schulbeschreibung in maximal 35 Wörtern zusammen. 
      Konzentriere dich NUR auf: Schultyp (Gymnasium, Realschule, etc.) und Hauptspezialisierungen (naturwissenschaftlich, sprachlich, musisch, etc.).
      Ignoriere: Schülerzahlen, Lehrernamen, Verwaltung, Gründungsjahr, Standortdetails.

      Beschreibung: #{description}

      Kurze Zusammenfassung:
      """

      case run_ollama_prompt(prompt) do
        {:ok, summary} ->
          summary
          |> String.trim()
          |> String.trim_trailing(".")
          |> Kernel.<>(".")

        {:error, reason} ->
          Logger.warning("Failed to summarize description with Ollama: #{reason}")
          # Return simple cleaned description as fallback
          clean_description_fallback(description)
      end
    else
      # If Ollama is not available, use simple cleaning
      clean_description_fallback(description)
    end
  end

  defp clean_description_fallback(description) do
    # Simple fallback: clean and truncate the description
    cleaned =
      description
      |> String.replace(~r/\s+/, " ")
      # Remove reference markers like [1], [2]
      |> String.replace(~r/\[\d+\]/, "")
      |> String.replace(~r/\.\.+/, ".")
      |> String.trim()

    # Take first 200 characters and ensure it ends at a word boundary
    if String.length(cleaned) > 200 do
      cleaned
      |> String.slice(0, 200)
      |> String.replace(~r/\s+\S*$/, "")
      |> Kernel.<>("...")
    else
      cleaned
    end
  end

  defp ollama_available? do
    case System.cmd("which", ["ollama"]) do
      {_path, 0} ->
        # Check if the llama3.2:latest model is available
        case System.cmd("ollama", ["list"]) do
          {output, 0} ->
            String.contains?(output, "llama3.2:latest")

          _ ->
            false
        end

      _ ->
        false
    end
  end

  defp run_ollama_prompt(prompt) do
    # Build the Ollama API request
    body =
      Jason.encode!(%{
        model: "llama3.2:latest",
        prompt: prompt,
        stream: false,
        options: %{
          temperature: 0.1,
          max_tokens: 60
        }
      })

    # Call Ollama API
    case System.cmd("curl", [
           "-s",
           "-X",
           "POST",
           "http://localhost:11434/api/generate",
           "-H",
           "Content-Type: application/json",
           "-d",
           body
         ]) do
      {output, 0} ->
        case Jason.decode(output) do
          {:ok, %{"response" => response}} ->
            {:ok, response}

          {:ok, %{"error" => error}} ->
            {:error, error}

          {:error, _} ->
            {:error, "Failed to parse Ollama response"}
        end

      {error_output, _exit_code} ->
        {:error, "Ollama command failed: #{error_output}"}
    end
  end
end
