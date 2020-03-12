defmodule MehrSchulferien.Calendars.Religion do
  use Ecto.Schema

  import Ecto.Changeset

  alias MehrSchulferien.NameSlug
  alias MehrSchulferien.Calendars.{HolidayOrVacationType, Period}

  schema "religions" do
    field :name, :string
    field :slug, NameSlug.Type
    field :wikipedia_url, :string

    has_many :holiday_or_vacation_types, HolidayOrVacationType,
      foreign_key: :default_religion_id,
      on_delete: :delete_all

    has_many :periods, Period, on_delete: :delete_all

    timestamps()
  end

  @doc false
  def changeset(religion, attrs) do
    religion
    |> cast(attrs, [:name, :slug, :wikipedia_url])
    |> validate_required([:name])
    |> NameSlug.maybe_generate_slug()
    |> NameSlug.unique_constraint()
  end
end
