defmodule MehrSchulferien.Blacklist.Entry do
  @moduledoc """
  Schema for blacklist entries.

  Each entry contains a pattern to match against contact data fields.
  Patterns support wildcards (* for multiple characters, ? for single character)
  and are matched case-insensitively.
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias MehrSchulferien.Blacklist.PatternMatcher
  alias MehrSchulferien.Blacklist.VerificationRequest

  @allowed_field_types ~w(
    phone_number
    fax_number
    email_address
    homepage_url
    instagram_url
    wikipedia_url
    schuelerzeitung_url
    street
    city
    zip_code
  )

  schema "blacklist_entries" do
    field :pattern, :string
    field :pattern_regex, :string
    field :field_type, :string
    field :reason, :string
    field :requester_name, :string
    field :requester_email, :string
    field :is_active, :boolean, default: true

    belongs_to :verification_request, VerificationRequest

    has_many :removal_logs, MehrSchulferien.Blacklist.RemovalLog, foreign_key: :blacklist_entry_id

    timestamps()
  end

  @doc """
  Returns the list of allowed field types.
  """
  def allowed_field_types, do: @allowed_field_types

  @doc """
  Returns human-readable labels for field types in German.
  """
  def field_type_labels do
    %{
      "phone_number" => "Telefonnummer",
      "fax_number" => "Faxnummer",
      "email_address" => "E-Mail-Adresse",
      "homepage_url" => "Homepage-URL",
      "instagram_url" => "Instagram-URL",
      "wikipedia_url" => "Wikipedia-URL",
      "schuelerzeitung_url" => "Schülerzeitung-URL",
      "street" => "Straße",
      "city" => "Stadt",
      "zip_code" => "Postleitzahl"
    }
  end

  @doc false
  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [
      :pattern,
      :field_type,
      :reason,
      :requester_name,
      :requester_email,
      :is_active,
      :verification_request_id
    ])
    |> validate_required([:pattern, :field_type, :requester_name, :requester_email])
    |> validate_inclusion(:field_type, @allowed_field_types,
      message: "muss ein gültiger Feldtyp sein"
    )
    |> validate_length(:pattern, min: 3, max: 500)
    |> validate_length(:reason, max: 2000)
    |> validate_pattern()
    |> generate_pattern_regex()
    |> normalize_email()
  end

  @doc """
  Changeset for creating a new entry.
  """
  def create_changeset(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
  end

  @doc """
  Changeset for deactivating an entry.
  """
  def deactivate_changeset(entry) do
    entry
    |> change()
    |> put_change(:is_active, false)
  end

  defp validate_pattern(changeset) do
    case get_change(changeset, :pattern) do
      nil ->
        changeset

      pattern ->
        case PatternMatcher.validate_pattern(pattern) do
          :ok -> changeset
          {:error, message} -> add_error(changeset, :pattern, message)
        end
    end
  end

  defp generate_pattern_regex(changeset) do
    case get_change(changeset, :pattern) do
      nil ->
        changeset

      pattern ->
        regex_pattern = PatternMatcher.to_regex_pattern(pattern)
        put_change(changeset, :pattern_regex, regex_pattern)
    end
  end

  defp normalize_email(changeset) do
    case get_change(changeset, :requester_email) do
      nil -> changeset
      email -> put_change(changeset, :requester_email, String.downcase(String.trim(email)))
    end
  end
end
