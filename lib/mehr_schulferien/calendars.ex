defmodule MehrSchulferien.Calendars do
  @moduledoc """
  The Calendars context.
  """

  import Ecto.Query, warn: false

  alias MehrSchulferien.Calendars.{HolidayOrVacationType, Period, Religion}
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
  Gets a single holiday_or_vacation_type.

  Raises `Ecto.NoResultsError` if the Holiday or vacation type does not exist.
  """
  def get_holiday_or_vacation_type!(id), do: Repo.get!(HolidayOrVacationType, id)

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

  @doc """
  Returns the list of periods.
  """
  def list_periods do
    Repo.all(Period)
  end

  @doc """
  Gets a single period.

  Raises `Ecto.NoResultsError` if the Period does not exist.
  """
  def get_period!(id), do: Repo.get!(Period, id)

  # FIXME: riverrun (2020-01-31)
  # Remove this function when possible - it is still being used by the controller.
  @doc """
  Creates a period.
  """
  def create_period(attrs) do
    %Period{}
    |> Period.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a period.
  """
  def create_period(holiday_or_vacation_type, attrs) do
    %HolidayOrVacationType{
      id: id,
      default_html_class: html_class,
      default_is_listed_below_month: is_listed_below_month,
      default_is_public_holiday: is_public_holiday,
      default_is_school_vacation: is_school_vacation,
      default_is_valid_for_everybody: is_valid_for_everybody,
      default_is_valid_for_students: is_valid_for_students,
      default_religion_id: religion_id
    } = holiday_or_vacation_type

    attrs =
      Map.merge(
        %{
          holiday_or_vacation_type_id: id,
          html_class: html_class,
          is_listed_below_month: is_listed_below_month,
          is_public_holiday: is_public_holiday,
          is_school_vacation: is_school_vacation,
          is_valid_for_everybody: is_valid_for_everybody,
          is_valid_for_students: is_valid_for_students,
          religion_id: religion_id
        },
        attrs
      )

    %Period{}
    |> Period.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a period.
  """
  def update_period(%Period{} = period, attrs) do
    period
    |> Period.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a period.
  """
  def delete_period(%Period{} = period) do
    Repo.delete(period)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking period changes.
  """
  def change_period(%Period{} = period) do
    Period.changeset(period, %{})
  end
end
