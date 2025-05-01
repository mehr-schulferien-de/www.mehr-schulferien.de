defmodule MehrSchulferien.Locations.Location do
  @moduledoc """
  Location schema that represents different geographic entities.

  This schema can represent various location types such as:
  - Countries
  - Federal states
  - Counties
  - Cities
  - Schools

  Locations form a hierarchical structure with parent-child relationships.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias MehrSchulferien.Slugs.LocationNameSlug
  alias MehrSchulferien.Calendars.HolidayOrVacationType
  alias MehrSchulferien.Periods.Period
  alias MehrSchulferien.Maps.{Address, ZipCode}

  schema "locations" do
    # Location type flags - exactly one must be true
    field :is_country, :boolean, default: false
    field :is_federal_state, :boolean, default: false
    field :is_county, :boolean, default: false
    field :is_city, :boolean, default: false
    field :is_school, :boolean, default: false

    # Basic location attributes
    field :name, :string
    field :code, :string
    field :slug, LocationNameSlug.Type

    # Hierarchy relationships
    belongs_to :parent_location, __MODULE__
    belongs_to :cachable_calendar_location, __MODULE__

    # School-specific associations
    has_one :address, Address, foreign_key: :school_location_id, on_delete: :delete_all

    # Country-specific associations
    has_many :holiday_or_vacation_types, HolidayOrVacationType,
      foreign_key: :country_location_id,
      on_delete: :delete_all

    # Periods associated with this location
    has_many :periods, Period, on_delete: :delete_all

    # City-specific associations
    many_to_many(
      :zip_codes,
      ZipCode,
      join_through: "zip_code_mappings"
    )

    timestamps()
  end

  @doc """
  Changeset for the Location schema.

  Validates that exactly one location type flag is set to true.
  Countries don't require a parent_location, but all other location types do.
  """
  def changeset(location, attrs) do
    location
    |> cast(attrs, [
      :name,
      :slug,
      :code,
      :is_country,
      :is_federal_state,
      :is_county,
      :is_city,
      :is_school,
      :parent_location_id,
      :cachable_calendar_location_id
    ])
    |> validate_required([:name])
    |> validate_one_is_present([:is_country, :is_federal_state, :is_county, :is_city, :is_school])
    |> validate_length(:code, max: 3)
    |> validate_presence_of_parent()
    |> validate_cachable_calendar_location()
    |> LocationNameSlug.maybe_generate_slug()
    |> LocationNameSlug.unique_constraint()
  end

  @doc """
  Validates that a parent location is present for non-country locations.

  Only countries are allowed to have no parent location.
  """
  def validate_presence_of_parent(changeset) do
    # Only a country doesn't have a parent.
    case get_field(changeset, :is_country) do
      true ->
        changeset

      _ ->
        changeset
        |> validate_required([:parent_location_id])
        |> assoc_constraint(:parent_location)
    end
  end

  @doc """
  Validates the cachable calendar location if set.
  """
  def validate_cachable_calendar_location(changeset) do
    # If set the cachable location must exist.
    case get_field(changeset, :cachable_calendar_location_id) do
      id when is_integer(id) ->
        changeset
        |> assoc_constraint(:cachable_calendar_location)

      _ ->
        changeset
    end
  end

  @doc """
  Validates that exactly one location type is set to true.

  Each location must be exactly one of: country, federal_state, county, city, or school.
  """
  def validate_one_is_present(changeset, fields) do
    fields
    |> Enum.filter(fn field ->
      # Checks if a field is "present".
      # The logic is copied from `validate_required` in Ecto.
      case get_field(changeset, field) do
        true -> true
        _ -> false
      end
    end)
    |> case do
      # Exactly one field was present.
      [field] ->
        without_id = field |> Atom.to_string() |> String.to_existing_atom()
        validate_required(changeset, without_id)

      # Zero or more than one fields were present.
      _ ->
        add_error(
          changeset,
          hd(fields),
          "expected exactly one of #{inspect(fields)} to be present"
        )
    end
  end
end
