defmodule MehrSchulferien.Calendars.Period do
  use Ecto.Schema

  import Ecto.Changeset

  alias MehrSchulferien.Maps.Location
  alias MehrSchulferien.Calendars.{HolidayOrVacationType, Religion}

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
    field :display_priority, :integer
    field :adjoining_duration, :integer
    field :array_agg, {:array, :integer}

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
