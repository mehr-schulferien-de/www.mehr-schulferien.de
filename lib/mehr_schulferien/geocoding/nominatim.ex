defmodule MehrSchulferien.Geocoding.Nominatim do
  @moduledoc """
  Nominatim geocoding service for converting addresses to coordinates.

  Uses OpenStreetMap's Nominatim API to geocode addresses.
  Respects the usage policy with rate limiting and proper User-Agent.

  ## Usage

      iex> Nominatim.geocode_address("Alexanderplatz 1", "10178", "Berlin")
      {:ok, {13.4132, 52.5219}}
      
      iex> Nominatim.geocode_address("Invalid Street", "99999", "Nowhere")
      {:error, :not_found}
  """

  require Logger

  @base_url "https://nominatim.openstreetmap.org/search"
  @user_agent "MehrSchulferien/1.0 (https://www.mehr-schulferien.de)"
  # 10 seconds
  @timeout 10_000

  # Rate limiting: Track last request time
  @rate_limit_key :nominatim_last_request
  # 1 second between requests
  @min_interval_ms 1_000

  @doc """
  Geocodes an address using Nominatim API.

  Returns `{:ok, {longitude, latitude}}` on success, or `{:error, reason}` on failure.
  """
  def geocode_address(street, zip_code, city, country \\ "Deutschland") do
    # Ensure rate limiting
    enforce_rate_limit()

    # Build query parameters
    params = build_params(street, zip_code, city, country)

    # Make the request
    case make_request(params) do
      {:ok, response} -> parse_response(response)
      {:error, reason} -> {:error, reason}
    end
  end

  defp build_params(street, zip_code, city, country) do
    %{
      "street" => street,
      "postalcode" => zip_code,
      "city" => city,
      "country" => country,
      "format" => "json",
      "limit" => "1",
      "addressdetails" => "1"
    }
  end

  defp make_request(params) do
    headers = [
      {"User-Agent", @user_agent},
      {"Accept", "application/json"}
    ]

    url = @base_url <> "?" <> URI.encode_query(params)

    Logger.info("Nominatim request: #{url}")

    case Req.get(url, headers: headers, receive_timeout: @timeout) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: status}} ->
        Logger.error("Nominatim returned status #{status}")
        {:error, :api_error}

      {:error, reason} ->
        Logger.error("Nominatim request failed: #{inspect(reason)}")
        {:error, :request_failed}
    end
  end

  defp parse_response(response) when is_list(response) and response != [] do
    case List.first(response) do
      %{"lon" => lon_str, "lat" => lat_str} ->
        case {parse_coordinate(lon_str), parse_coordinate(lat_str)} do
          {{:ok, lon}, {:ok, lat}} -> {:ok, {lon, lat}}
          _ -> {:error, :invalid_coordinates}
        end

      _ ->
        {:error, :invalid_response}
    end
  end

  defp parse_response(_), do: {:error, :not_found}

  defp parse_coordinate(coord_str) when is_binary(coord_str) do
    case Float.parse(coord_str) do
      {coord, ""} -> {:ok, coord}
      # Accept partial parse
      {coord, _remainder} -> {:ok, coord}
      :error -> {:error, :invalid_format}
    end
  end

  defp parse_coordinate(_), do: {:error, :invalid_format}

  defp enforce_rate_limit do
    now = System.monotonic_time(:millisecond)

    case Process.get(@rate_limit_key) do
      nil ->
        # First request
        Process.put(@rate_limit_key, now)

      last_request ->
        elapsed = now - last_request

        if elapsed < @min_interval_ms do
          # Need to wait
          sleep_time = @min_interval_ms - elapsed
          Logger.debug("Rate limiting: sleeping for #{sleep_time}ms")
          Process.sleep(sleep_time)
        end

        Process.put(@rate_limit_key, System.monotonic_time(:millisecond))
    end
  end
end
