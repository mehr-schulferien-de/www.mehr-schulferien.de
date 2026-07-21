defmodule MehrSchulferien.Calendars do
  @moduledoc """
  The Calendars context.
  """

  import Ecto.Query, warn: false

  alias MehrSchulferien.Cache
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
  Results are cached for 24 hours since vacation types rarely change.
  """
  def list_holiday_or_vacation_types do
    Cache.cached_query_operation(
      "vacation_types:all",
      fn ->
        Repo.all(HolidayOrVacationType)
      end,
      # Cache for 24 hours
      ttl: 86_400
    )
  end

  @doc """
  Returns the list of holiday_or_vacation_types which are is_school_vacation == true.
  Results are cached for 24 hours since vacation types rarely change.
  """
  def list_is_school_vacation_types(country) do
    Cache.cached_query_operation(
      "vacation_types:school:#{country.id}",
      fn ->
        query =
          from(p in HolidayOrVacationType,
            where:
              p.default_is_school_vacation == true and
                p.country_location_id == ^country.id
          )

        Repo.all(query)
      end,
      # Cache for 24 hours
      ttl: 86_400
    )
  end

  @doc """
  Gets a single holiday_or_vacation_type.
  Results are cached for 24 hours since vacation types rarely change.

  Raises `Ecto.NoResultsError` if the Holiday or vacation type does not exist.
  """
  def get_holiday_or_vacation_type!(id) do
    Cache.cached_query_operation(
      "vacation_type:#{id}",
      fn ->
        Repo.get!(HolidayOrVacationType, id)
      end,
      # Cache for 24 hours
      ttl: 86_400
    )
  end

  def get_holiday_or_vacation_type_by_name!(name) do
    Cache.cached_query_operation(
      "vacation_type:name:#{name}",
      fn ->
        Repo.get_by!(HolidayOrVacationType, name: name)
      end,
      # Cache for 24 hours
      ttl: 86_400
    )
  end

  @doc """
  Gets a single get_holiday_or_vacation_type by querying for the slug.
  Results are cached for 24 hours since vacation types rarely change.

  Raises `Ecto.NoResultsError` if the federal state does not exist.
  """
  def get_holiday_or_vacation_type_by_slug!(slug) do
    Cache.cached_query_operation(
      "vacation_type:slug:#{slug}",
      fn ->
        Repo.get_by!(HolidayOrVacationType, slug: slug)
      end,
      # Cache for 24 hours
      ttl: 86_400
    )
  end

  @doc """
  Gets the school vacation type for a "...ferien" URL slug (e.g. "osterferien").

  Resolves the URL slug (canonical or legacy) to the database slug via
  `MehrSchulferien.Calendars.VacationSlug` and returns the matching
  `HolidayOrVacationType` where `default_is_school_vacation` is `true`,
  or `nil` if none exists.
  """
  def get_vacation_type_by_ferien_slug(ferien_slug) do
    case MehrSchulferien.Calendars.VacationSlug.resolve(ferien_slug) do
      {_canonical_or_legacy, db_slug} -> get_school_vacation_type_by_slug(db_slug)
      :error -> nil
    end
  end

  @doc """
  Gets the school vacation type for a database slug (e.g. "ostern"),
  or `nil` if none exists.
  """
  def get_school_vacation_type_by_slug(db_slug) do
    Repo.one(
      from hvt in HolidayOrVacationType,
        where: hvt.slug == ^db_slug and hvt.default_is_school_vacation == true
    )
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
