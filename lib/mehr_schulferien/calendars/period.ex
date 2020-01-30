defmodule MehrSchulferien.Calendars.Period do
  use Ecto.Schema
  import Ecto.Changeset
  alias MehrSchulferien.Maps.Location
  alias MehrSchulferien.Calendars.HolidayOrVacationType
  alias MehrSchulferien.Calendars.Religion

  schema "periods" do
    field :created_by_email_address, :string
    field :ends_on, :date
    field :html_class, :string
    field :is_listed_below_month, :boolean, default: false
    field :is_public_holiday, :boolean, default: false
    field :is_school_vacation, :boolean, default: false
    field :is_valid_for_everybody, :boolean, default: false
    field :is_valid_for_students, :boolean, default: false
    field :starts_on, :date
    field :memo, :string
    belongs_to :location, Location
    belongs_to :holiday_or_vacation_type, HolidayOrVacationType
    belongs_to :religion, Religion

    timestamps()
  end

  @doc false
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
      :memo
    ])
    |> validate_required([
      :starts_on,
      :ends_on,
      :created_by_email_address,
      :location_id,
      :holiday_or_vacation_type_id
    ])
    |> assoc_constraint(:location)
    |> assoc_constraint(:holiday_or_vacation_type)
  end

  # TODO: Validation that starts_on <= ends_on
end
