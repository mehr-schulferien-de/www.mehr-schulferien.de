defmodule MehrSchulferien.Locations.Location do
  use Ecto.Schema

  import Ecto.Changeset

  alias MehrSchulferien.LocationNameSlug
  alias MehrSchulferien.Calendars.HolidayOrVacationType
  alias MehrSchulferien.Periods.Period
  alias MehrSchulferien.Maps.{Address, ZipCode}

  schema "locations" do
    field :is_city, :boolean, default: false
    field :is_country, :boolean, default: false
    field :is_county, :boolean, default: false
    field :is_federal_state, :boolean, default: false
    field :is_school, :boolean, default: false
    field :name, :string
    field :code, :string
    field :slug, LocationNameSlug.Type

    belongs_to :parent_location, __MODULE__
    belongs_to :cachable_calendar_location, __MODULE__

    has_one :address, Address, foreign_key: :school_location_id, on_delete: :delete_all

    has_many :holiday_or_vacation_types, HolidayOrVacationType,
      foreign_key: :country_location_id,
      on_delete: :delete_all

    has_many :periods, Period, on_delete: :delete_all

    many_to_many(
      :zip_codes,
      ZipCode,
      join_through: "zip_code_mappings"
    )

    timestamps()
  end

  @doc false
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
