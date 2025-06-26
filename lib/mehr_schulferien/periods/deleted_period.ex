defmodule MehrSchulferien.Periods.DeletedPeriod do
  use Ecto.Schema
  import Ecto.Changeset

  schema "deleted_periods" do
    # Original period fields
    field :original_id, :integer
    field :holiday_or_vacation_type_id, :integer
    field :location_id, :integer
    field :starts_on, :date
    field :ends_on, :date
    field :created_by_email_address, :string
    field :html_class, :string
    field :is_listed_below_month, :boolean, default: false
    field :is_public_holiday, :boolean, default: false
    field :is_school_vacation, :boolean, default: false
    field :is_valid_for_students, :boolean, default: false
    field :is_valid_for_everybody, :boolean, default: false
    field :memo, :string
    field :display_priority, :integer, default: 10

    # Reference to deleted school
    field :deleted_school_original_id, :integer

    # Deletion metadata
    field :deleted_at, :utc_datetime
    field :deleted_by_user_id, :integer

    # Original timestamps
    field :original_inserted_at, :utc_datetime
    field :original_updated_at, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(deleted_period, attrs) do
    deleted_period
    |> cast(attrs, [
      :original_id,
      :holiday_or_vacation_type_id,
      :location_id,
      :starts_on,
      :ends_on,
      :created_by_email_address,
      :html_class,
      :is_listed_below_month,
      :is_public_holiday,
      :is_school_vacation,
      :is_valid_for_students,
      :is_valid_for_everybody,
      :memo,
      :display_priority,
      :deleted_school_original_id,
      :deleted_at,
      :deleted_by_user_id,
      :original_inserted_at,
      :original_updated_at
    ])
    |> validate_required([:original_id, :deleted_school_original_id, :deleted_at])
  end
end
