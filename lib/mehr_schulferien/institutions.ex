defmodule MehrSchulferien.Institutions do
  @moduledoc """
  The Institutions context.
  """

  import Ecto.Query, warn: false
  alias MehrSchulferien.Repo

  alias MehrSchulferien.Institutions.SchoolType

  @doc """
  Returns the list of school_types.

  ## Examples

      iex> list_school_types()
      [%SchoolType{}, ...]

  """
  def list_school_types do
    Repo.all(SchoolType)
  end

  @doc """
  Gets a single school_type.

  Raises `Ecto.NoResultsError` if the School type does not exist.

  ## Examples

      iex> get_school_type!(123)
      %SchoolType{}

      iex> get_school_type!(456)
      ** (Ecto.NoResultsError)

  """
  def get_school_type!(id), do: Repo.get!(SchoolType, id)

  @doc """
  Creates a school_type.

  ## Examples

      iex> create_school_type(%{field: value})
      {:ok, %SchoolType{}}

      iex> create_school_type(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_school_type(attrs \\ %{}) do
    %SchoolType{}
    |> SchoolType.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a school_type.

  ## Examples

      iex> update_school_type(school_type, %{field: new_value})
      {:ok, %SchoolType{}}

      iex> update_school_type(school_type, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_school_type(%SchoolType{} = school_type, attrs) do
    school_type
    |> SchoolType.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a SchoolType.

  ## Examples

      iex> delete_school_type(school_type)
      {:ok, %SchoolType{}}

      iex> delete_school_type(school_type)
      {:error, %Ecto.Changeset{}}

  """
  def delete_school_type(%SchoolType{} = school_type) do
    Repo.delete(school_type)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking school_type changes.

  ## Examples

      iex> change_school_type(school_type)
      %Ecto.Changeset{source: %SchoolType{}}

  """
  def change_school_type(%SchoolType{} = school_type) do
    SchoolType.changeset(school_type, %{})
  end

  alias MehrSchulferien.Institutions.School

  @doc """
  Returns the list of schools.

  ## Examples

      iex> list_schools()
      [%School{}, ...]

  """
  def list_schools do
    Repo.all(School)
  end

  @doc """
  Gets a single school.

  Raises `Ecto.NoResultsError` if the School does not exist.

  ## Examples

      iex> get_school!(123)
      %School{}

      iex> get_school!(456)
      ** (Ecto.NoResultsError)

  """
  def get_school!(id), do: Repo.get!(School, id)

  @doc """
  Creates a school.

  ## Examples

      iex> create_school(%{field: value})
      {:ok, %School{}}

      iex> create_school(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_school(attrs \\ %{}) do
    %School{}
    |> School.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a school.

  ## Examples

      iex> update_school(school, %{field: new_value})
      {:ok, %School{}}

      iex> update_school(school, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_school(%School{} = school, attrs) do
    school
    |> School.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a School.

  ## Examples

      iex> delete_school(school)
      {:ok, %School{}}

      iex> delete_school(school)
      {:error, %Ecto.Changeset{}}

  """
  def delete_school(%School{} = school) do
    Repo.delete(school)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking school changes.

  ## Examples

      iex> change_school(school)
      %Ecto.Changeset{source: %School{}}

  """
  def change_school(%School{} = school) do
    School.changeset(school, %{})
  end
end
