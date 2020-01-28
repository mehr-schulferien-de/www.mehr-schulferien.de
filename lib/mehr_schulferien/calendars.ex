defmodule MehrSchulferien.Calendars do
  @moduledoc """
  The Calendars context.
  """

  import Ecto.Query, warn: false
  alias MehrSchulferien.Repo

  alias MehrSchulferien.Calendars.Religion

  @doc """
  Returns the list of religions.

  ## Examples

      iex> list_religions()
      [%Religion{}, ...]

  """
  def list_religions do
    Repo.all(Religion)
  end

  @doc """
  Gets a single religion.

  Raises `Ecto.NoResultsError` if the Religion does not exist.

  ## Examples

      iex> get_religion!(123)
      %Religion{}

      iex> get_religion!(456)
      ** (Ecto.NoResultsError)

  """
  def get_religion!(id), do: Repo.get!(Religion, id)

  @doc """
  Creates a religion.

  ## Examples

      iex> create_religion(%{field: value})
      {:ok, %Religion{}}

      iex> create_religion(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_religion(attrs \\ %{}) do
    %Religion{}
    |> Religion.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a religion.

  ## Examples

      iex> update_religion(religion, %{field: new_value})
      {:ok, %Religion{}}

      iex> update_religion(religion, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_religion(%Religion{} = religion, attrs) do
    religion
    |> Religion.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a religion.

  ## Examples

      iex> delete_religion(religion)
      {:ok, %Religion{}}

      iex> delete_religion(religion)
      {:error, %Ecto.Changeset{}}

  """
  def delete_religion(%Religion{} = religion) do
    Repo.delete(religion)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking religion changes.

  ## Examples

      iex> change_religion(religion)
      %Ecto.Changeset{source: %Religion{}}

  """
  def change_religion(%Religion{} = religion) do
    Religion.changeset(religion, %{})
  end

  alias MehrSchulferien.Calendars.HolidayOrVacationType

  @doc """
  Returns the list of holiday_or_vacation_types.

  ## Examples

      iex> list_holiday_or_vacation_types()
      [%HolidayOrVacationType{}, ...]

  """
  def list_holiday_or_vacation_types do
    Repo.all(HolidayOrVacationType)
  end

  @doc """
  Gets a single holiday_or_vacation_type.

  Raises `Ecto.NoResultsError` if the Holiday or vacation type does not exist.

  ## Examples

      iex> get_holiday_or_vacation_type!(123)
      %HolidayOrVacationType{}

      iex> get_holiday_or_vacation_type!(456)
      ** (Ecto.NoResultsError)

  """
  def get_holiday_or_vacation_type!(id), do: Repo.get!(HolidayOrVacationType, id)

  @doc """
  Creates a holiday_or_vacation_type.

  ## Examples

      iex> create_holiday_or_vacation_type(%{field: value})
      {:ok, %HolidayOrVacationType{}}

      iex> create_holiday_or_vacation_type(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_holiday_or_vacation_type(attrs \\ %{}) do
    %HolidayOrVacationType{}
    |> HolidayOrVacationType.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a holiday_or_vacation_type.

  ## Examples

      iex> update_holiday_or_vacation_type(holiday_or_vacation_type, %{field: new_value})
      {:ok, %HolidayOrVacationType{}}

      iex> update_holiday_or_vacation_type(holiday_or_vacation_type, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_holiday_or_vacation_type(%HolidayOrVacationType{} = holiday_or_vacation_type, attrs) do
    holiday_or_vacation_type
    |> HolidayOrVacationType.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a holiday_or_vacation_type.

  ## Examples

      iex> delete_holiday_or_vacation_type(holiday_or_vacation_type)
      {:ok, %HolidayOrVacationType{}}

      iex> delete_holiday_or_vacation_type(holiday_or_vacation_type)
      {:error, %Ecto.Changeset{}}

  """
  def delete_holiday_or_vacation_type(%HolidayOrVacationType{} = holiday_or_vacation_type) do
    Repo.delete(holiday_or_vacation_type)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking holiday_or_vacation_type changes.

  ## Examples

      iex> change_holiday_or_vacation_type(holiday_or_vacation_type)
      %Ecto.Changeset{source: %HolidayOrVacationType{}}

  """
  def change_holiday_or_vacation_type(%HolidayOrVacationType{} = holiday_or_vacation_type) do
    HolidayOrVacationType.changeset(holiday_or_vacation_type, %{})
  end
end
