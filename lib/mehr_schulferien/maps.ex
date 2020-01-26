defmodule MehrSchulferien.Maps do
  @moduledoc """
  The Maps context.
  """

  import Ecto.Query, warn: false
  alias MehrSchulferien.Repo

  alias MehrSchulferien.Maps.Location

  @doc """
  Returns the list of locations.

  ## Examples

      iex> list_locations()
      [%Location{}, ...]

  """
  def list_locations do
    Repo.all(Location)
  end

  @doc """
  Gets a single location.

  Raises `Ecto.NoResultsError` if the Location does not exist.

  ## Examples

      iex> get_location!(123)
      %Location{}

      iex> get_location!(456)
      ** (Ecto.NoResultsError)

  """
  def get_location!(id), do: Repo.get!(Location, id)

  @doc """
  Creates a location.

  ## Examples

      iex> create_location(%{field: value})
      {:ok, %Location{}}

      iex> create_location(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_location(attrs \\ %{}) do
    %Location{}
    |> Location.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a location.

  ## Examples

      iex> update_location(location, %{field: new_value})
      {:ok, %Location{}}

      iex> update_location(location, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_location(%Location{} = location, attrs) do
    location
    |> Location.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a location.

  ## Examples

      iex> delete_location(location)
      {:ok, %Location{}}

      iex> delete_location(location)
      {:error, %Ecto.Changeset{}}

  """
  def delete_location(%Location{} = location) do
    Repo.delete(location)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking location changes.

  ## Examples

      iex> change_location(location)
      %Ecto.Changeset{source: %Location{}}

  """
  def change_location(%Location{} = location) do
    Location.changeset(location, %{})
  end

  alias MehrSchulferien.Maps.ZipCode

  @doc """
  Returns the list of zip_codes.

  ## Examples

      iex> list_zip_codes()
      [%ZipCode{}, ...]

  """
  def list_zip_codes do
    Repo.all(ZipCode)
  end

  @doc """
  Gets a single zip_code.

  Raises `Ecto.NoResultsError` if the Zip code does not exist.

  ## Examples

      iex> get_zip_code!(123)
      %ZipCode{}

      iex> get_zip_code!(456)
      ** (Ecto.NoResultsError)

  """
  def get_zip_code!(id), do: Repo.get!(ZipCode, id)

  @doc """
  Creates a zip_code.

  ## Examples

      iex> create_zip_code(%{field: value})
      {:ok, %ZipCode{}}

      iex> create_zip_code(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_zip_code(attrs \\ %{}) do
    %ZipCode{}
    |> ZipCode.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a zip_code.

  ## Examples

      iex> update_zip_code(zip_code, %{field: new_value})
      {:ok, %ZipCode{}}

      iex> update_zip_code(zip_code, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_zip_code(%ZipCode{} = zip_code, attrs) do
    zip_code
    |> ZipCode.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a zip_code.

  ## Examples

      iex> delete_zip_code(zip_code)
      {:ok, %ZipCode{}}

      iex> delete_zip_code(zip_code)
      {:error, %Ecto.Changeset{}}

  """
  def delete_zip_code(%ZipCode{} = zip_code) do
    Repo.delete(zip_code)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking zip_code changes.

  ## Examples

      iex> change_zip_code(zip_code)
      %Ecto.Changeset{source: %ZipCode{}}

  """
  def change_zip_code(%ZipCode{} = zip_code) do
    ZipCode.changeset(zip_code, %{})
  end

  alias MehrSchulferien.Maps.ZipCodeMapping

  @doc """
  Returns the list of zip_code_mappings.

  ## Examples

      iex> list_zip_code_mappings()
      [%ZipCodeMapping{}, ...]

  """
  def list_zip_code_mappings do
    Repo.all(ZipCodeMapping)
  end

  @doc """
  Gets a single zip_code_mapping.

  Raises `Ecto.NoResultsError` if the Zip code mapping does not exist.

  ## Examples

      iex> get_zip_code_mapping!(123)
      %ZipCodeMapping{}

      iex> get_zip_code_mapping!(456)
      ** (Ecto.NoResultsError)

  """
  def get_zip_code_mapping!(id), do: Repo.get!(ZipCodeMapping, id)

  @doc """
  Creates a zip_code_mapping.

  ## Examples

      iex> create_zip_code_mapping(%{field: value})
      {:ok, %ZipCodeMapping{}}

      iex> create_zip_code_mapping(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_zip_code_mapping(attrs \\ %{}) do
    %ZipCodeMapping{}
    |> ZipCodeMapping.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a zip_code_mapping.

  ## Examples

      iex> update_zip_code_mapping(zip_code_mapping, %{field: new_value})
      {:ok, %ZipCodeMapping{}}

      iex> update_zip_code_mapping(zip_code_mapping, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_zip_code_mapping(%ZipCodeMapping{} = zip_code_mapping, attrs) do
    zip_code_mapping
    |> ZipCodeMapping.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a zip_code_mapping.

  ## Examples

      iex> delete_zip_code_mapping(zip_code_mapping)
      {:ok, %ZipCodeMapping{}}

      iex> delete_zip_code_mapping(zip_code_mapping)
      {:error, %Ecto.Changeset{}}

  """
  def delete_zip_code_mapping(%ZipCodeMapping{} = zip_code_mapping) do
    Repo.delete(zip_code_mapping)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking zip_code_mapping changes.

  ## Examples

      iex> change_zip_code_mapping(zip_code_mapping)
      %Ecto.Changeset{source: %ZipCodeMapping{}}

  """
  def change_zip_code_mapping(%ZipCodeMapping{} = zip_code_mapping) do
    ZipCodeMapping.changeset(zip_code_mapping, %{})
  end
end
