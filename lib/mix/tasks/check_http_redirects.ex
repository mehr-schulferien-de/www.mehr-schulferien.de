defmodule Mix.Tasks.CheckHttpRedirects do
  use Mix.Task
  import Ecto.Query
  alias MehrSchulferien.Repo
  alias MehrSchulferien.Locations.Location
  alias MehrSchulferien.Maps.Address
  require Logger

  @shortdoc "Check if school HTTP URLs redirect to HTTPS"
  @moduledoc """
  Checks schools with HTTP homepage URLs to see if they redirect to HTTPS.

  Usage:
    mix check_http_redirects [options]

  Options:
    --verbose, -v     Show detailed output for each check
    --resume          Resume from last position
    --output FILE     Output file (default: http_redirects_results.json)
    --progress FILE   Progress file (default: http_redirects_progress.json)

  This task will:
  1. Find all schools with HTTP (not HTTPS) homepage URLs
  2. Test if each URL redirects to HTTPS or if HTTPS version works
  3. Save results to a file
  4. Support resuming interrupted runs
  """

  @impl Mix.Task
  def run(args) do
    # Suppress warnings by setting log level
    Logger.configure(level: :error)
    
    # Start the repo and other necessary apps without the endpoint
    {:ok, _} = Application.ensure_all_started(:postgrex)
    {:ok, _} = Application.ensure_all_started(:ecto)
    {:ok, _} = Application.ensure_all_started(:req)
    
    # Start the Repo manually
    {:ok, _} = MehrSchulferien.Repo.start_link()
    
    # Parse command line options
    {opts, _, _} = OptionParser.parse(args,
      switches: [
        verbose: :boolean,
        resume: :boolean,
        output: :string,
        progress: :string
      ],
      aliases: [v: :verbose]
    )
    
    verbose = Keyword.get(opts, :verbose, false)
    resume = Keyword.get(opts, :resume, false)
    output_file = Keyword.get(opts, :output, "http_redirects_results.json")
    progress_file = Keyword.get(opts, :progress, "http_redirects_progress.json")

    IO.puts("\nChecking HTTP to HTTPS redirects for school homepages...")
    IO.puts("Results will be saved to: #{output_file}")
    if resume, do: IO.puts("Resuming from previous progress...")
    IO.puts("")
    
    # Initialize or load existing results file
    _existing_results = if resume and File.exists?(output_file) do
      load_existing_results(output_file)
    else
      # Initialize empty results file
      File.write!(output_file, "[]")
      []
    end

    # Load previous progress if resuming
    {processed_ids, previous_results} = if resume do
      load_progress(progress_file)
    else
      {[], []}
    end
    
    # Query for schools with HTTP URLs
    query = from(l in Location,
      join: a in Address,
      on: a.school_location_id == l.id,
      where: l.is_school == true,
      where: not is_nil(a.homepage_url),
      where: like(a.homepage_url, "http://%"),
      select: %{
        school_id: l.id,
        school_name: l.name,
        school_slug: l.slug,
        homepage_url: a.homepage_url
      }
    )
    
    # Filter out already processed schools if resuming
    query = if resume and processed_ids != [] do
      from(q in query, where: q.id not in ^processed_ids)
    else
      query
    end
    
    schools_with_http = query |> Repo.all()

    total_count = length(schools_with_http)

    if total_count == 0 do
      IO.puts("No schools found with HTTP homepage URLs.")
      []
    else
      IO.puts("Found #{total_count} schools with HTTP URLs...\n")

      results = check_redirects(schools_with_http, verbose, progress_file, output_file, previous_results)
      IO.puts("\n") # Clear the progress line
      all_results = previous_results ++ results
      
      # Clean up progress file on completion
      File.rm(progress_file)
      
      print_summary(all_results)
      IO.puts("\nResults saved to: #{output_file}")
      IO.puts("Total schools processed: #{length(all_results)}")
      
      # Read final results from file for summary
      final_list = load_existing_results(output_file)
      with_https = Enum.count(final_list, fn %{"new_url" => url} -> url != nil end)
      IO.puts("Schools with HTTPS URLs: #{with_https}")
      IO.puts("Schools without HTTPS option: #{length(final_list) - with_https}")
      
      final_list
    end
  end

  defp check_redirects(schools, verbose, progress_file, output_file, previous_results) do
    total_processed = length(previous_results)
    
    schools
    |> Enum.with_index(total_processed + 1)
    |> Enum.map(fn {school, index} ->
      total = total_processed + length(schools)
      school_name = if String.length(school.school_name) > 40 do
        String.slice(school.school_name, 0, 40) <> "..."
      else
        school.school_name
      end
      IO.write("\r[#{index}/#{total}] #{school_name}                    ")
      
      result = check_single_redirect(school.homepage_url)
      
      # Determine final result with HTTPS check
      final_result = case result do
        {:redirect_to_https, new_url} ->
          if verbose do
            IO.puts(" ✓ Redirects to HTTPS")
            IO.puts("  Before: #{school.homepage_url}")
            IO.puts("  After:  #{new_url}")
          end
          {:redirect_to_https, new_url}

        {:redirect_to_other, new_url} ->
          if verbose do
            IO.puts(" → Redirects to other URL")
            IO.puts("  Before: #{school.homepage_url}")
            IO.puts("  After:  #{new_url}")
          end
          if String.starts_with?(new_url, "https://") do
            {:redirect_to_https, new_url}
          else
            {:redirect_to_other, new_url}
          end

        {:no_redirect, status} ->
          if verbose, do: IO.puts(" ✗ No redirect (Status: #{status})")
          # Check if HTTPS version works
          https_url = String.replace_prefix(school.homepage_url, "http://", "https://")
          case check_https_availability(https_url) do
            {:ok, _status} ->
              if verbose do
                IO.puts("  ✓ HTTPS version works: #{https_url}")
              end
              {:https_replacement_works, https_url}
            {:error, reason} ->
              if verbose do
                IO.puts("  ✗ HTTPS not available: #{reason}")
              end
              {:no_https_available, nil}
          end

        {:error, reason} ->
          if verbose do
            IO.puts(" ✗ Error: #{reason}")
            IO.puts("  URL: #{school.homepage_url}")
          end
          {:error, nil}
      end
      
      # Save progress after each check
      result_entry = {school, final_result}
      save_progress(progress_file, previous_results ++ [result_entry])
      
      # Also save to results file incrementally
      new_url = case final_result do
        {:redirect_to_https, url} -> url
        {:https_replacement_works, url} -> url
        _ -> nil
      end
      
      append_result(output_file, %{school_slug: school.school_slug, new_url: new_url})
      
      result_entry
    end)
  end

  defp check_single_redirect(url) do
    # Properly encode the URL to handle non-ASCII characters
    encoded_url = URI.encode(url)
    
    # Configure Req to not follow redirects automatically
    options = [
      redirect: false,
      retry: false,
      connect_options: [timeout: 3_000],
      receive_timeout: 10_000
    ]

    case Req.get(encoded_url, options) do
      {:ok, %{status: status} = response} when status in 301..303 ->
        # Check Location header
        case Req.Response.get_header(response, "location") do
          [new_url | _] ->
            # Check if the redirect is to HTTPS version of same URL
            https_url = String.replace_prefix(url, "http://", "https://")

            cond do
              new_url == https_url ->
                {:redirect_to_https, new_url}

              String.starts_with?(new_url, "https://") ->
                {:redirect_to_https, new_url}

              true ->
                {:redirect_to_other, new_url}
            end

          _ ->
            {:no_redirect, status}
        end

      {:ok, %{status: status}} ->
        {:no_redirect, status}

      {:error, %Req.TransportError{reason: reason}} ->
        {:error, format_error(reason)}

      {:error, reason} ->
        {:error, inspect(reason)}
    end
  end

  defp format_error(:timeout), do: "Connection timeout"
  defp format_error(:nxdomain), do: "Domain not found"
  defp format_error(:econnrefused), do: "Connection refused"
  defp format_error(reason), do: inspect(reason)

  defp check_https_availability(url) do
    # Properly encode the URL to handle non-ASCII characters
    encoded_url = URI.encode(url)
    
    options = [
      retry: false,
      connect_options: [timeout: 3_000],
      receive_timeout: 10_000
    ]

    case Req.get(encoded_url, options) do
      {:ok, %{status: status}} when status in 200..299 ->
        {:ok, status}

      {:ok, %{status: status}} ->
        {:error, "Status #{status}"}

      {:error, %Req.TransportError{reason: reason}} ->
        {:error, format_error(reason)}

      {:error, reason} ->
        {:error, inspect(reason)}
    end
  end

  defp print_summary(results) do
    IO.puts("\n" <> String.duplicate("=", 60))
    IO.puts("SUMMARY")
    IO.puts(String.duplicate("=", 60))

    redirects_to_https =
      Enum.count(results, fn {_, result} ->
        match?({:redirect_to_https, _}, result)
      end)

    redirects_to_other =
      Enum.count(results, fn {_, result} ->
        match?({:redirect_to_other, _}, result)
      end)

    no_redirects =
      Enum.count(results, fn {_, result} ->
        match?({:no_redirect, _}, result)
      end)

    errors =
      Enum.count(results, fn {_, result} ->
        match?({:error, _}, result)
      end)

    total = length(results)

    IO.puts("Total schools checked: #{total}")

    IO.puts(
      "Redirects to HTTPS: #{redirects_to_https} (#{percentage(redirects_to_https, total)}%)"
    )

    IO.puts(
      "Redirects to other URL: #{redirects_to_other} (#{percentage(redirects_to_other, total)}%)"
    )

    IO.puts("No redirect: #{no_redirects} (#{percentage(no_redirects, total)}%)")
    IO.puts("Errors: #{errors} (#{percentage(errors, total)}%)")

    if redirects_to_https > 0 do
      IO.puts("\n✓ #{redirects_to_https} schools could have their URLs updated to HTTPS")
    end
  end

  defp percentage(count, total) when total > 0 do
    Float.round(count / total * 100, 1)
  end

  defp percentage(_, _), do: 0.0

  
  defp load_progress(progress_file) do
    case File.read(progress_file) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, data} ->
            processed_ids = Enum.map(data, fn entry -> entry["school"]["school_id"] end)
            results = Enum.map(data, fn entry ->
              school = %{
                school_id: entry["school"]["school_id"],
                school_name: entry["school"]["school_name"],
                school_slug: entry["school"]["school_slug"],
                homepage_url: entry["school"]["homepage_url"]
              }
              result_type = String.to_atom(entry["result"]["type"])
              result_url = entry["result"]["url"]
              {school, {result_type, result_url}}
            end)
            {processed_ids, results}
          {:error, _} ->
            IO.puts("Warning: Could not parse progress file. Starting fresh.")
            {[], []}
        end
      {:error, _} ->
        {[], []}
    end
  end
  
  defp save_progress(progress_file, results) do
    data = Enum.map(results, fn {school, {result_type, result_url}} ->
      %{
        school: %{
          school_id: school.school_id,
          school_name: school.school_name,
          school_slug: school.school_slug,
          homepage_url: school.homepage_url
        },
        result: %{
          type: to_string(result_type),
          url: result_url
        }
      }
    end)
    
    json = Jason.encode!(data, pretty: true)
    File.write!(progress_file, json)
  end
  
  
  defp load_existing_results(output_file) do
    case File.read(output_file) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, data} -> data
          {:error, _} -> []
        end
      {:error, _} -> []
    end
  end
  
  defp append_result(output_file, new_result) do
    # Read existing results
    existing = load_existing_results(output_file)
    
    # Append new result
    updated = existing ++ [new_result]
    
    # Write back
    json = Jason.encode!(updated, pretty: true)
    File.write!(output_file, json)
  end
end
