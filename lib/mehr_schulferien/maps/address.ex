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
    field :wikipedia_url, :string
    field :school_type, :string
    field :official_id, :string
    field :lon, :float
    field :lat, :float

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
      :wikipedia_url,
      :school_type,
      :official_id,
      :lon,
      :lat,
      :school_location_id
    ])
    |> validate_required([:school_location_id])
    |> normalize_phone_number()
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
end
