defmodule MehrSchulferienWeb.WikiSchoolNewLive do
  use MehrSchulferienWeb, :live_view

  on_mount {MehrSchulferienWeb.WikiAuth, :require_auth}

  import Ecto.Query

  alias MehrSchulferien.{Blacklist, Maps, Wiki, Locations, Email, Mailer, Config}
  alias MehrSchulferien.Maps.Address
  alias MehrSchulferien.Locations.Location
  alias MehrSchulferien.Geocoding.Nominatim
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    {daily_changes, limit_reached} = get_daily_limit_info()

    %Ecto.Changeset{} = base_changeset = Ecto.Changeset.change(%Address{})
    changeset = %{base_changeset | action: nil}

    {:ok,
     socket
     |> assign(
       page_title: "Neue Schule anlegen",
       changeset: changeset,
       school_name: "",
       daily_changes: daily_changes,
       limit_reached: limit_reached,
       existing_schools: [],
       zip_code_valid: nil,
       city_from_zip: nil,
       blacklist_error: nil,
       school_contact_info_enabled: Config.school_contact_info_enabled?()
     )}
  end

  @impl true
  def handle_event("validate", params, socket) do
    name = Map.get(params, "name", "")
    address_params = Map.get(params, "address", %{})
    zip_code = Map.get(address_params, "zip_code", "")

    # Check if we need to lookup schools for this zip code
    socket =
      if String.length(zip_code) == 5 and zip_code != socket.assigns[:last_searched_zip] do
        case validate_and_get_city_from_zip(zip_code) do
          {:ok, city} ->
            # Get existing schools in this zip code
            existing_schools = Locations.get_schools_by_zip_code(zip_code)

            socket
            |> assign(
              existing_schools: existing_schools,
              zip_code_valid: true,
              city_from_zip: city,
              last_searched_zip: zip_code
            )

          {:error, :invalid_zip_code} ->
            socket
            |> assign(
              existing_schools: [],
              zip_code_valid: false,
              city_from_zip: nil,
              last_searched_zip: zip_code
            )
        end
      else
        socket
      end

    # Don't validate the changeset during typing, just preserve the form data
    %Ecto.Changeset{} = current_changeset = socket.assigns.changeset

    changeset = %{
      current_changeset
      | changes: Map.merge(current_changeset.changes, address_params),
        data: %Address{
          street: address_params["street"] || "",
          zip_code: address_params["zip_code"] || "",
          city:
            address_params["city"] ||
              (socket.assigns[:city_from_zip] && socket.assigns.city_from_zip.name) || "",
          email_address: address_params["email_address"] || "",
          phone_number: address_params["phone_number"] || "",
          homepage_url: address_params["homepage_url"] || "",
          wikipedia_url: address_params["wikipedia_url"] || "",
          instagram_url: address_params["instagram_url"] || "",
          description: address_params["description"] || "",
          students_count: parse_int(address_params["students_count"]),
          founded_year: parse_int(address_params["founded_year"])
        }
    }

    # Check for blacklisted values
    blacklist_error =
      case Blacklist.check_params_for_blacklisted_values(address_params) do
        :ok -> nil
        {:error, blocked_fields} -> Blacklist.format_blocked_fields_error(blocked_fields)
      end

    {:noreply,
     assign(socket, changeset: changeset, school_name: name, blacklist_error: blacklist_error)}
  end

  @impl true
  def handle_event("save", %{"name" => school_name, "address" => address_params}, socket) do
    cond do
      socket.assigns.limit_reached ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Das tägliche Limit von #{Config.daily_change_limit()} Änderungen wurde erreicht. Bitte versuchen Sie es morgen erneut."
         )}

      # Check blacklist before allowing creation
      match?({:error, _}, Blacklist.check_params_for_blacklisted_values(address_params)) ->
        {:error, blocked_fields} = Blacklist.check_params_for_blacklisted_values(address_params)
        error_message = Blacklist.format_blocked_fields_error(blocked_fields)
        {:noreply, put_flash(socket, :error, error_message)}

      true ->
        zip_code = Map.get(address_params, "zip_code", "")

        # Validate zip code and get city
        case validate_and_get_city_from_zip(zip_code) do
          {:ok, city} ->
            # Try to create school with address
            case create_school_with_address(school_name, address_params, city, socket) do
              {:ok, school} ->
                # Increment daily change count
                Wiki.increment_daily_change_count(Date.utc_today())

                # Get country slug for redirect
                country_slug = get_country_slug_from_school(school)

                {:noreply,
                 socket
                 |> put_flash(:info, "Schule wurde erfolgreich angelegt. Danke für Ihre Hilfe!")
                 |> redirect(to: ~p"/ferien/#{country_slug || "d"}/schule/#{school.slug}")}

              {:error, :invalid_address} ->
                changeset =
                  %Address{}
                  |> Address.changeset(address_params)
                  |> Map.put(:errors,
                    street:
                      {"Die Adresse konnte nicht georeferenziert werden. Bitte überprüfen Sie die Eingaben.",
                       []}
                  )
                  |> Map.put(:action, :insert)
                  |> Map.put(:valid?, false)

                {:noreply, assign(socket, changeset: changeset)}

              {:error, changeset} ->
                {:noreply, assign(socket, changeset: changeset)}
            end

          {:error, :invalid_zip_code} ->
            changeset =
              %Address{}
              |> Address.changeset(address_params)
              |> Map.put(:errors,
                zip_code: {"Postleitzahl wurde nicht gefunden oder ist ungültig", []}
              )
              |> Map.put(:action, :insert)
              |> Map.put(:valid?, false)

            {:noreply, assign(socket, changeset: changeset)}
        end
    end
  end

  defp validate_and_get_city_from_zip(zip_code) when is_binary(zip_code) and zip_code != "" do
    try do
      zip_code_record = Maps.get_zip_code_by_value!(zip_code)

      case zip_code_record.locations do
        [city | _] -> {:ok, city}
        [] -> {:error, :invalid_zip_code}
      end
    rescue
      Ecto.NoResultsError -> {:error, :invalid_zip_code}
    end
  end

  defp validate_and_get_city_from_zip(_), do: {:error, :invalid_zip_code}

  defp create_school_with_address(school_name, address_params, city, socket) do
    # Generate unique slug with zip code prefix
    zip_code = Map.get(address_params, "zip_code", "")

    # Use centralized function to generate unique slug
    {:ok, school_slug} = Locations.generate_unique_school_slug(school_name, zip_code)

    # Create school location attrs
    school_attrs = %{
      name: school_name,
      slug: school_slug,
      is_school: true,
      parent_location_id: city.id
    }

    school_changeset = Location.changeset(%Location{}, school_attrs)

    # First check if we can get coordinates for this address
    coords_result =
      get_coordinates_with_fallback(
        school_name,
        address_params["street"],
        zip_code,
        address_params["city"] || city.name
      )

    case coords_result do
      {:ok, {lon, lat}} ->
        # Coordinates found, proceed with school creation
        case PaperTrail.insert(school_changeset, meta: %{ip_address: get_client_ip(socket)}) do
          {:ok, %{model: school, version: _}} ->
            # Create address for the school
            address_attrs =
              address_params
              |> Map.put("school_location_id", school.id)
              |> Map.put("line1", school_name)
              |> Map.put("lon", lon)
              |> Map.put("lat", lat)

            address_changeset = Address.changeset(%Address{}, address_attrs)

            case PaperTrail.insert(address_changeset, meta: %{ip_address: get_client_ip(socket)}) do
              {:ok, %{model: address, version: _}} ->
                # Reload school with address and parent location chain
                school =
                  Locations.get_location!(school.id)
                  |> MehrSchulferien.Repo.preload([:address, :parent_location])

                # Send email notification
                Task.start(fn ->
                  try do
                    # Get country slug for the email
                    country_slug = get_country_slug_from_school(school)

                    Email.school_created_notification(school, address, country_slug)
                    |> Mailer.deliver()
                  rescue
                    error ->
                      Logger.error(
                        "Failed to send school creation notification: #{inspect(error)}"
                      )
                  end
                end)

                {:ok, school}

              {:error, changeset} ->
                # Delete the school if address creation fails
                PaperTrail.delete(school, meta: %{ip_address: get_client_ip(socket)})
                {:error, changeset}
            end

          {:error, changeset} ->
            {:error, changeset}
        end

      {:error, :no_coordinates} ->
        # No coordinates found - return invalid address error
        {:error, :invalid_address}
    end
  end

  defp get_coordinates_with_fallback(name, street, zip_code, city) do
    # First try Nominatim with full address
    case Nominatim.geocode_address(street, zip_code, city) do
      {:ok, {lon, lat}} ->
        Logger.info("Coordinates found via Nominatim for #{name}: #{lon}, #{lat}")
        {:ok, {lon, lat}}

      {:error, reason} ->
        Logger.warning(
          "Nominatim failed for #{name}: #{inspect(reason)}, trying zip_code_mappings"
        )

        # Fallback to zip_code_mappings
        case get_coordinates_from_zip_mappings(zip_code) do
          {lon, lat} when not is_nil(lon) and not is_nil(lat) ->
            Logger.info("Coordinates found via zip_code_mappings for #{name}: #{lon}, #{lat}")
            {:ok, {lon, lat}}

          _ ->
            if Application.get_env(:mehr_schulferien, :env) != :test do
              Logger.error("No coordinates found for #{name} at #{street}, #{zip_code} #{city}")
            end

            {:error, :no_coordinates}
        end
    end
  end

  defp get_coordinates_from_zip_mappings(zip_code) when is_binary(zip_code) and zip_code != "" do
    zip_query =
      from zm in MehrSchulferien.Maps.ZipCodeMapping,
        join: z in MehrSchulferien.Maps.ZipCode,
        on: zm.zip_code_id == z.id,
        where: z.value == ^zip_code,
        select: {zm.lon, zm.lat},
        limit: 1

    case MehrSchulferien.Repo.one(zip_query) do
      {lon, lat} when not is_nil(lon) and not is_nil(lat) -> {lon, lat}
      _ -> {nil, nil}
    end
  end

  defp get_coordinates_from_zip_mappings(_), do: {nil, nil}

  defp get_client_ip(socket) do
    case socket.assigns[:remote_ip] do
      {a, b, c, d} -> "#{a}.#{b}.#{c}.#{d}"
      _ -> "unknown"
    end
  end

  defp get_country_slug_from_school(school) do
    Locations.get_country_slug_from_location(school)
  end

  defp get_daily_limit_info do
    today = Date.utc_today()
    daily_changes = Wiki.get_daily_change_count(today)
    limit_reached = daily_changes >= Config.daily_change_limit()
    {daily_changes, limit_reached}
  end

  defp parse_int(nil), do: nil
  defp parse_int(""), do: nil

  defp parse_int(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} -> int
      _ -> nil
    end
  end

  defp parse_int(value) when is_integer(value), do: value
  defp parse_int(_), do: nil
end
