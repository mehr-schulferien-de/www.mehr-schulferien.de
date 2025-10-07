defmodule MehrSchulferien.Maps.Address do
  @moduledoc """
  Address schema for storing address information.

  ## PaperTrail Integration

  This model is configured to work with PaperTrail for audit logging. 
  To track changes, use PaperTrail functions instead of direct Repo calls:

      # Instead of: Repo.insert(changeset)
      PaperTrail.insert(changeset)

      # Instead of: Repo.update(changeset)  
      PaperTrail.update(changeset)

      # Instead of: Repo.delete(address)
      PaperTrail.delete(address)

  ## Examples

      # Create a new address with tracking
      changeset = Address.changeset(%Address{}, %{
        street: "123 Main St",
        city: "Berlin",
        zip_code: "10115",
        school_location_id: 1
      })
      {:ok, %{model: address, version: version}} = PaperTrail.insert(changeset)

      # Update an address with tracking
      update_changeset = Address.changeset(address, %{street: "456 Oak Ave"})
      {:ok, %{model: updated_address, version: version}} = PaperTrail.update(update_changeset)

      # Get version history
      versions = PaperTrail.get_versions(address)

      # Get the latest version
      latest_version = PaperTrail.get_version(address)
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias MehrSchulferien.Locations.Location

  schema "addresses" do
    field :line1, :string
    field :street, :string
    field :zip_code, :string
    field :city, :string
    field :email_address, :string
    field :phone_number, :string
    field :fax_number, :string
    field :homepage_url, :string
    field :schuelerzeitung_url, :string
    field :wikipedia_url, :string
    field :school_type, :string
    field :official_id, :string
    field :lon, :float
    field :lat, :float
    field :instagram_url, :string
    field :students_count, :integer
    field :founded_year, :integer
    field :description, :string

    belongs_to :school_location, Location

    timestamps()
  end

  @doc false
  def changeset(address, attrs) do
    attrs = update_attrs(attrs)

    address
    |> cast(attrs, [
      :line1,
      :street,
      :zip_code,
      :city,
      :email_address,
      :phone_number,
      :fax_number,
      :homepage_url,
      :schuelerzeitung_url,
      :wikipedia_url,
      :school_type,
      :official_id,
      :lon,
      :lat,
      :school_location_id,
      :instagram_url,
      :students_count,
      :founded_year,
      :description
    ])
    |> validate_required([:school_location_id])
    |> normalize_phone_number()
    |> normalize_urls()
    |> validate_homepage_url()
    |> validate_schuelerzeitung_url()
    |> validate_instagram_url()
    |> validate_coordinates()
    |> validate_founded_year()
  end

  # Validates homepage URL is well-formed when present (optional field)
  defp validate_homepage_url(changeset) do
    case get_field(changeset, :homepage_url) do
      nil ->
        changeset

      "" ->
        changeset

      url when is_binary(url) ->
        if String.match?(url, ~r/^https?:\/\/.+\..+/) do
          changeset
        else
          add_error(
            changeset,
            :homepage_url,
            "muss eine gültige URL sein (z.B. https://www.schule.de)"
          )
        end

      _ ->
        changeset
    end
  end

  # Validates schuelerzeitung URL is well-formed when present (optional field)
  defp validate_schuelerzeitung_url(changeset) do
    case get_field(changeset, :schuelerzeitung_url) do
      nil ->
        changeset

      "" ->
        changeset

      url when is_binary(url) ->
        if String.match?(url, ~r/^https?:\/\/.+\..+/) do
          changeset
        else
          add_error(
            changeset,
            :schuelerzeitung_url,
            "muss eine gültige URL sein (z.B. https://schuelerzeitung.schule.de)"
          )
        end

      _ ->
        changeset
    end
  end

  defp update_attrs(attrs) do
    # Handle both legacy parameter names (address_street, etc.) and current ones (street, etc.)
    line1 = attrs["address_line1"] || attrs["line1"]
    street = attrs["address_street"] || attrs["street"]
    zip_code = attrs["address_zip_code"] || attrs["zip_code"]
    city = attrs["address_city"] || attrs["city"]
    school_type = attrs["school_type_entity"] || attrs["school_type"]

    Map.merge(attrs, %{
      "line1" => line1,
      "street" => street,
      "zip_code" => zip_code,
      "city" => city,
      "school_type" => school_type
    })
  end

  # Normalizes URLs by removing trailing slashes from domain-only URLs
  defp normalize_urls(changeset) do
    changeset
    |> normalize_url_field(:homepage_url)
    |> normalize_url_field(:schuelerzeitung_url)
    |> normalize_url_field(:wikipedia_url)
    |> normalize_url_field(:instagram_url)
  end

  defp normalize_url_field(changeset, field) do
    case get_change(changeset, field) do
      nil ->
        changeset

      url when is_binary(url) ->
        normalized = normalize_url(url)

        if normalized != url do
          put_change(changeset, field, normalized)
        else
          changeset
        end

      _ ->
        changeset
    end
  end

  defp normalize_url(url) when is_binary(url) do
    # Parse the URL to check if it has a path
    case URI.parse(url) do
      %URI{scheme: scheme, host: host, path: path}
      when scheme in ["http", "https"] and is_binary(host) ->
        # If path is nil, "/" or empty, it's a domain-only URL
        if path in [nil, "/", ""] do
          # Remove trailing slash for domain-only URLs
          "#{scheme}://#{host}"
        else
          # Keep the URL as-is if it has a real path
          url
        end

      _ ->
        # Return unchanged if parsing fails or it's not a valid HTTP(S) URL
        url
    end
  end

  defp normalize_url(url), do: url

  # Normalizes phone numbers to international format.
  # German phone numbers are converted to international format (+49).
  # Already international numbers are left unchanged.
  # Invalid numbers are left as-is to avoid data loss.
  defp normalize_phone_number(changeset) do
    case get_change(changeset, :phone_number) do
      nil ->
        changeset

      phone_number when is_binary(phone_number) and phone_number != "" ->
        # Only normalize non-empty strings
        normalized = normalize_german_phone(phone_number)
        put_change(changeset, :phone_number, normalized)

      _ ->
        # For empty strings or other types, leave unchanged
        changeset
    end
  end

  # Converts a German phone number to international format.
  # Examples:
  #   - "030 12345678" -> "+49 30 12345678"
  #   - "0711 123456" -> "+49 711 123456"
  #   - "+49 30 12345678" -> "+49 30 12345678" (unchanged)
  #   - "invalid" -> "invalid" (unchanged)
  defp normalize_german_phone(phone_number) do
    # Clean the input by removing common separators but keep spaces for formatting
    cleaned = String.replace(phone_number, ~r/[-\/\(\)]/, "")

    cond do
      # Already in international format
      String.starts_with?(cleaned, "+") ->
        phone_number

      # Try to parse as German number
      true ->
        case ExPhoneNumber.parse(cleaned, "DE") do
          {:ok, parsed_number} ->
            ExPhoneNumber.format(parsed_number, :international)

          _ ->
            # If parsing fails, leave original unchanged to avoid data loss
            phone_number
        end
    end
  end

  # Validates coordinates if present
  defp validate_coordinates(changeset) do
    changeset
    |> validate_number(:lat,
      greater_than_or_equal_to: -90,
      less_than_or_equal_to: 90,
      message: "muss zwischen -90 und 90 liegen"
    )
    |> validate_number(:lon,
      greater_than_or_equal_to: -180,
      less_than_or_equal_to: 180,
      message: "muss zwischen -180 und 180 liegen"
    )
    |> validate_coordinate_pair()
  end

  # Ensures that if one coordinate is provided, both must be provided
  defp validate_coordinate_pair(changeset) do
    lat = get_field(changeset, :lat)
    lon = get_field(changeset, :lon)

    case {lat, lon} do
      {nil, nil} ->
        changeset

      {nil, _} ->
        add_error(changeset, :lat, "muss angegeben werden, wenn Längengrad vorhanden ist")

      {_, nil} ->
        add_error(changeset, :lon, "muss angegeben werden, wenn Breitengrad vorhanden ist")

      {_, _} ->
        changeset
    end
  end

  # Validates Instagram URL is from instagram.com when present
  defp validate_instagram_url(changeset) do
    case get_field(changeset, :instagram_url) do
      nil ->
        changeset

      "" ->
        changeset

      url ->
        if String.contains?(url, "instagram.com") do
          changeset
        else
          add_error(changeset, :instagram_url, "muss eine Instagram URL sein")
        end
    end
  end

  # Validates founded year is reasonable (between 1800 and current year)
  defp validate_founded_year(changeset) do
    case get_field(changeset, :founded_year) do
      nil ->
        changeset

      year ->
        current_year = Date.utc_today().year

        if year >= 1200 and year <= current_year do
          changeset
        else
          add_error(changeset, :founded_year, "muss zwischen 1200 und #{current_year} liegen")
        end
    end
  end
end
