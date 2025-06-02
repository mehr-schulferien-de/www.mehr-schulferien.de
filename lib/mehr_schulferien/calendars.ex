defmodule MehrSchulferien.Calendars do
  @moduledoc """
  The Calendars context.
  """

  import Ecto.Query, warn: false

  alias MehrSchulferien.Calendars.{HolidayOrVacationType, Religion}
  alias MehrSchulferien.Repo

  @doc """
  Returns the list of religions.
  """
  def list_religions do
    Repo.all(Religion)
  end

  @doc """
  Gets a single religion.

  Raises `Ecto.NoResultsError` if the Religion does not exist.
  """
  def get_religion!(id), do: Repo.get!(Religion, id)

  @doc """
  Creates a religion.
  """
  def create_religion(attrs \\ %{}) do
    %Religion{}
    |> Religion.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a religion.
  """
  def update_religion(%Religion{} = religion, attrs) do
    religion
    |> Religion.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a religion.
  """
  def delete_religion(%Religion{} = religion) do
    Repo.delete(religion)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking religion changes.
  """
  def change_religion(%Religion{} = religion) do
    Religion.changeset(religion, %{})
  end

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
