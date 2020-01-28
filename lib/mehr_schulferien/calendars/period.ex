defmodule MehrSchulferien.Calendars.Period do
  use Ecto.Schema
  import Ecto.Changeset
  alias MehrSchulferien.Maps.Location
  alias MehrSchulferien.Calendars.HolidayOrVacationType

  schema "periods" do
    field :author_email_address, :string
    field :ends_on, :date
    field :starts_on, :date
    belongs_to :location, Location
    belongs_to :holiday_or_vacation_type, HolidayOrVacationType

    timestamps()
  end

  @doc false
  def changeset(period, attrs) do
    period
    |> cast(attrs, [
      :starts_on,
      :ends_on,
      :author_email_address,
      :location_id,
      :holiday_or_vacation_type_id
    ])
    |> validate_required([
      :starts_on,
      :ends_on,
      :author_email_address,
      :location_id,
      :holiday_or_vacation_type_id
    ])
    |> assoc_constraint(:location)
    |> assoc_constraint(:holiday_or_vacation_type)
  end

  # TODO: Validation that starts_on <= ends_on
end
