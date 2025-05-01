defmodule MehrSchulferien.Periods.Period do
  @moduledoc """
  Period schema representing a time period such as holidays, vacations, or special days.

  A period has a start and end date and is associated with a location and a holiday/vacation type.
  Periods can be configured with various flags that determine their visibility and behavior
  in the application.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias MehrSchulferien.Locations.Location
  alias MehrSchulferien.Calendars.{HolidayOrVacationType, Religion}

  schema "periods" do
    # Time range fields
    field :starts_on, :date
    field :ends_on, :date

    # Metadata fields
    field :created_by_email_address, :string
    field :memo, :string
    field :display_priority, :integer

    # Display configuration
    field :html_class, :string
    field :is_listed_below_month, :boolean, default: false

    # Period type flags
    field :is_public_holiday, :boolean, default: false
    field :is_school_vacation, :boolean, default: false

    # Validity flags
    field :is_valid_for_everybody, :boolean, default: false
    field :is_valid_for_students, :boolean, default: false

    # Virtual fields for queries
    field :adjoining_duration, :integer, virtual: true
    field :array_agg, {:array, :integer}, virtual: true

    # Associations
    belongs_to :location, Location
    belongs_to :holiday_or_vacation_type, HolidayOrVacationType
    belongs_to :religion, Religion

    timestamps()
  end

  @doc """
  Changeset for the Period schema.

  Validates required fields and ensures that the start date is before or equal to the end date.
  """
  def changeset(period, attrs) do
    period
    |> cast(attrs, [
      :starts_on,
      :ends_on,
      :created_by_email_address,
      :html_class,
      :is_listed_below_month,
      :is_public_holiday,
      :is_school_vacation,
      :is_valid_for_everybody,
      :is_valid_for_students,
      :location_id,
      :religion_id,
      :holiday_or_vacation_type_id,
      :memo,
      :display_priority
    ])
    |> validate_required([
      :starts_on,
      :ends_on,
      :created_by_email_address,
      :location_id,
      :holiday_or_vacation_type_id,
      :display_priority
    ])
    |> validate_dates()
    |> assoc_constraint(:location)
    |> assoc_constraint(:holiday_or_vacation_type)
  end

  # Validates that the start date is before or equal to the end date.
  defp validate_dates(%Ecto.Changeset{valid?: true} = changeset) do
    starts_on = get_field(changeset, :starts_on)
    ends_on = get_field(changeset, :ends_on)

    if Date.compare(starts_on, ends_on) == :gt do
      add_error(changeset, :starts_on, "starts_on should be less than or equal to ends_on")
    else
      changeset
    end
  end

  defp validate_dates(changeset), do: changeset
end
