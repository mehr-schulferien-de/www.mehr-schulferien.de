defmodule MehrSchulferien.Periods.FederalStateFerientageLimit do
  use Ecto.Schema
  import Ecto.Changeset

  schema "federal_state_ferientage_limits" do
    field :school_year, :string
    field :max_bewegliche_ferientage, :integer
    belongs_to :federal_state, MehrSchulferien.Locations.Location

    timestamps()
  end

  @doc false
  def changeset(limit, attrs) do
    limit
    |> cast(attrs, [:federal_state_id, :school_year, :max_bewegliche_ferientage])
    |> validate_required([:federal_state_id, :school_year, :max_bewegliche_ferientage])
    |> validate_number(:max_bewegliche_ferientage, greater_than_or_equal_to: 0)
    |> validate_format(:school_year, ~r/^\d{4}\/\d{4}$/)
    |> validate_school_year_sequence()
    |> unique_constraint([:federal_state_id, :school_year],
      name: :federal_state_ferientage_limits_state_year_unique,
      message: "Es existiert bereits ein Eintrag für dieses Bundesland und Schuljahr"
    )
  end

  # Validate that the school year follows the pattern YYYY/YYYY+1
  defp validate_school_year_sequence(changeset) do
    case get_change(changeset, :school_year) do
      nil ->
        changeset

      school_year ->
        case String.split(school_year, "/") do
          [start_year_str, end_year_str] ->
            with {start_year, ""} <- Integer.parse(start_year_str),
                 {end_year, ""} <- Integer.parse(end_year_str),
                 true <- end_year == start_year + 1 do
              changeset
            else
              _ ->
                add_error(
                  changeset,
                  :school_year,
                  "muss im Format YYYY/YYYY+1 sein (z.B. 2024/2025)"
                )
            end

          _ ->
            add_error(changeset, :school_year, "muss im Format YYYY/YYYY+1 sein")
        end
    end
  end
end
