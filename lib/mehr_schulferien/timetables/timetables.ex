defmodule MehrSchulferien.Timetables do
  @moduledoc """
  The Timetables context.
  """

  import Ecto.Query, warn: false
  alias MehrSchulferien.Repo

  alias MehrSchulferien.Timetables.Year

  @doc """
  Returns the list of years.

  ## Examples

      iex> list_years()
      [%Year{}, ...]

  """
  def list_years do
    Repo.all(Year)
  end

  @doc """
  Gets a single year by id or slug.

  Raises `Ecto.NoResultsError` if the Year does not exist.

  ## Examples

      iex> get_year!(123)
      %Year{}

      iex> get_year!("2017")
      %Year{}

      iex> get_year!(456)
      ** (Ecto.NoResultsError)

  """
  def get_year!(id_or_slug) do
    query = case is_integer(id_or_slug) do
              true -> as_string = Integer.to_string(id_or_slug)
                   from y in Year, where: y.slug == ^as_string
              _ -> from y in Year, where: y.slug == ^id_or_slug
            end
    year = Repo.one(query)

    case year do
      nil -> Repo.get!(Year, id_or_slug)
      _ -> year
    end
  end

  @doc """
  Creates a year.

  ## Examples

      iex> create_year(%{field: value})
      {:ok, %Year{}}

      iex> create_year(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_year(attrs \\ %{}) do
    %Year{}
    |> Year.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a year.

  ## Examples

      iex> update_year(year, %{field: new_value})
      {:ok, %Year{}}

      iex> update_year(year, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_year(%Year{} = year, attrs) do
    year
    |> Year.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Year.

  ## Examples

      iex> delete_year(year)
      {:ok, %Year{}}

      iex> delete_year(year)
      {:error, %Ecto.Changeset{}}

  """
  def delete_year(%Year{} = year) do
    Repo.delete(year)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking year changes.

  ## Examples

      iex> change_year(year)
      %Ecto.Changeset{source: %Year{}}

  """
  def change_year(%Year{} = year) do
    Year.changeset(year, %{})
  end

  alias MehrSchulferien.Timetables.Month

  @doc """
  Returns the list of months.

  ## Examples

      iex> list_months()
      [%Month{}, ...]

  """
  def list_months do
    Repo.all(Month)
  end

  @doc """
  Gets a single month by id or slug.

  Raises `Ecto.NoResultsError` if the Month does not exist.

  ## Examples

      iex> get_month!(123)
      %Month{}

      iex> get_month!("2017-02")
      %Month{}

      iex> get_month!(456)
      ** (Ecto.NoResultsError)

  """
  def get_month!(id_or_slug) do
    case is_integer(id_or_slug) or Regex.match?(~r/^[1-9][0-9]*$/, id_or_slug) do
      true ->
        Repo.get!(Month, id_or_slug)
      false ->
        query = from f in Month, where: f.slug == ^id_or_slug
        Repo.one!(query)
    end
  end

  @doc """
  Creates a month.

  ## Examples

      iex> create_month(%{field: value})
      {:ok, %Month{}}

      iex> create_month(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_month(attrs \\ %{}) do
    %Month{}
    |> Month.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a month.

  ## Examples

      iex> update_month(month, %{field: new_value})
      {:ok, %Month{}}

      iex> update_month(month, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_month(%Month{} = month, attrs) do
    month
    |> Month.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Month.

  ## Examples

      iex> delete_month(month)
      {:ok, %Month{}}

      iex> delete_month(month)
      {:error, %Ecto.Changeset{}}

  """
  def delete_month(%Month{} = month) do
    Repo.delete(month)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking month changes.

  ## Examples

      iex> change_month(month)
      %Ecto.Changeset{source: %Month{}}

  """
  def change_month(%Month{} = month) do
    Month.changeset(month, %{})
  end

  alias MehrSchulferien.Timetables.Day

  @doc """
  Returns the list of days.

  ## Examples

      iex> list_days()
      [%Day{}, ...]

  """
  def list_days do
    Repo.all(Day)
  end

  @doc """
  Gets a single day by id or slug.

  Raises `Ecto.NoResultsError` if the Day does not exist.

  ## Examples

      iex> get_day!(123)
      %Day{}

      iex> get_day!("2017-12-24")
      %Day{}

      iex> get_day!(456)
      ** (Ecto.NoResultsError)

  """
  def get_day!(id_or_slug) do
    case is_integer(id_or_slug) or Regex.match?(~r/^[1-9]+[0-9]*$/, id_or_slug) do
      true ->
        Repo.get!(Day, id_or_slug)
      false ->
        query = from f in Day, where: f.slug == ^id_or_slug
        Repo.one!(query)
    end
  end

  @doc """
  Creates a day.

  ## Examples

      iex> create_day(%{field: value})
      {:ok, %Day{}}

      iex> create_day(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_day(attrs \\ %{}) do
    %Day{}
    |> Day.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a day.

  ## Examples

      iex> update_day(day, %{field: new_value})
      {:ok, %Day{}}

      iex> update_day(day, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_day(%Day{} = day, attrs) do
    day
    |> Day.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Day.

  ## Examples

      iex> delete_day(day)
      {:ok, %Day{}}

      iex> delete_day(day)
      {:error, %Ecto.Changeset{}}

  """
  def delete_day(%Day{} = day) do
    Repo.delete(day)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking day changes.

  ## Examples

      iex> change_day(day)
      %Ecto.Changeset{source: %Day{}}

  """
  def change_day(%Day{} = day) do
    Day.changeset(day, %{})
  end
end
