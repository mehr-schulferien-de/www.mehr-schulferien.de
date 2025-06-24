defmodule MehrSchulferienWeb.WikiSchoolNewLive do
  use MehrSchulferienWeb, :live_view

  alias MehrSchulferien.{Maps, Wiki, Locations}
  alias MehrSchulferien.Maps.Address
  alias MehrSchulferien.Locations.Location
  alias MehrSchulferien.Geocoding.Nominatim
  require Logger

  @impl true
  def mount(_params, _session, socket) do
    {daily_changes, limit_reached} = get_daily_limit_info()

    changeset = %Ecto.Changeset{Ecto.Changeset.change(%Address{}) | action: nil}

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
       css_framework: :tailwind_new
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
    changeset = %Ecto.Changeset{
      socket.assigns.changeset
      | changes: Map.merge(socket.assigns.changeset.changes, address_params),
        data: %Address{
          street: address_params["street"] || "",
          zip_code: address_params["zip_code"] || "",
          city: address_params["city"] || socket.assigns[:city_from_zip] && socket.assigns.city_from_zip.name || "",
          email_address: address_params["email_address"] || "",
          phone_number: address_params["phone_number"] || "",
          homepage_url: address_params["homepage_url"] || "",
          wikipedia_url: address_params["wikipedia_url"] || ""
        }
    }

    {:noreply, assign(socket, changeset: changeset, school_name: name)}
  end

  @impl true
  def handle_event("save", params, socket) do
    if socket.assigns.limit_reached do
      {:noreply,
       put_flash(
         socket,
         :error,
         "Das tägliche Limit von 20 Änderungen wurde erreicht. Bitte versuchen Sie es morgen erneut."
       )}
    else
      school_name = Map.get(params, "name", "")
      address_params = Map.get(params, "address", %{})
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
               |> redirect(
                 to: Routes.school_path(socket, :show, country_slug || "d", school.slug)
               )}

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
    # Generate slug with zip code prefix
    zip_code = Map.get(address_params, "zip_code", "")
    base_slug = Slugger.slugify_downcase(school_name)
    school_slug = "#{zip_code}-#{base_slug}"

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
              {:ok, %{model: _address, version: _}} ->
                # Reload school with address and parent location chain
                school =
                  Locations.get_location!(school.id)
                  |> MehrSchulferien.Repo.preload([:address, :parent_location])

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
            Logger.error("No coordinates found for #{name} at #{street}, #{zip_code} #{city}")
            {:error, :no_coordinates}
        end
    end
  end

  defp get_coordinates_from_zip_mappings(zip_code) when is_binary(zip_code) and zip_code != "" do
    import Ecto.Query

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
    # Traverse up the hierarchy to find the country
    location = traverse_to_country(school)

    case location do
      %{slug: slug, is_country: true} -> slug
      # Default to Germany
      _ -> "d"
    end
  end

  defp traverse_to_country(%{is_country: true} = location), do: location
  defp traverse_to_country(%{parent_location_id: nil}), do: nil

  defp traverse_to_country(%{parent_location_id: parent_id}) do
    parent = Locations.get_location!(parent_id)
    traverse_to_country(parent)
  end

  defp traverse_to_country(_), do: nil

  defp get_daily_limit_info do
    today = Date.utc_today()
    daily_changes = Wiki.get_daily_change_count(today)
    limit_reached = daily_changes >= 20
    {daily_changes, limit_reached}
  end
end
