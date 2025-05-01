defmodule MehrSchulferien.Calendars.HolidayOperations do
  @moduledoc """
  Operations on holiday and vacation types.

  This module handles all operations related to holiday and vacation types in the calendars context.
  """

  import Ecto.Query, warn: false

  alias MehrSchulferien.Calendars.HolidayOrVacationType
  alias MehrSchulferien.Repo

  @doc """
  Returns the list of holiday_or_vacation_types.
  """
  def list_holiday_or_vacation_types do
    Repo.all(HolidayOrVacationType)
  end

  @doc """
  Returns the list of holiday_or_vacation_types which are is_school_vacation == true.
  """
  def list_is_school_vacation_types(country) do
    query =
      from(p in HolidayOrVacationType,
        where:
          p.default_is_school_vacation == true and
            p.country_location_id == ^country.id
      )

    Repo.all(query)
  end

  @doc """
  Gets a single holiday_or_vacation_type.

  Raises `Ecto.NoResultsError` if the Holiday or vacation type does not exist.
  """
  def get_holiday_or_vacation_type!(id), do: Repo.get!(HolidayOrVacationType, id)

  @doc """
  Gets a single holiday_or_vacation_type by name.

  Raises `Ecto.NoResultsError` if the Holiday or vacation type does not exist.
  """
  def get_holiday_or_vacation_type_by_name!(name) do
    Repo.get_by!(HolidayOrVacationType, name: name)
  end

  @doc """
  Gets a single get_holiday_or_vacation_type by querying for the slug.

  Raises `Ecto.NoResultsError` if the federal state does not exist.
  """
  def get_holiday_or_vacation_type_by_slug!(slug) do
    Repo.get_by!(HolidayOrVacationType, slug: slug)
  end

  @doc """
  Creates a holiday_or_vacation_type.
  """
  def create_holiday_or_vacation_type(attrs \\ %{}) do
    %HolidayOrVacationType{}
    |> HolidayOrVacationType.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a holiday_or_vacation_type.
  """
  def update_holiday_or_vacation_type(%HolidayOrVacationType{} = holiday_or_vacation_type, attrs) do
    holiday_or_vacation_type
    |> HolidayOrVacationType.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a holiday_or_vacation_type.
  """
  def delete_holiday_or_vacation_type(%HolidayOrVacationType{} = holiday_or_vacation_type) do
    Repo.delete(holiday_or_vacation_type)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking holiday_or_vacation_type changes.
  """
  def change_holiday_or_vacation_type(%HolidayOrVacationType{} = holiday_or_vacation_type) do
    HolidayOrVacationType.changeset(holiday_or_vacation_type, %{})
  end
end
