defmodule MehrSchulferien.Maps do
  @moduledoc """
  The Maps context.
  """

  import Ecto.Query, warn: false

  alias MehrSchulferien.Maps.{Location, ZipCode, ZipCodeMapping}
  alias MehrSchulferien.Repo

  @doc """
  Returns the list of locations.
  """
  def list_locations do
    Repo.all(Location)
  end

  @doc """
  Gets a single location.

  Raises `Ecto.NoResultsError` if the Location does not exist.
  """
  def get_location!(id), do: Repo.get!(Location, id)

  @doc """
  Returns a list of ids of the location and all it's ancestors.
  """
  def recursive_location_ids(location) do
    build_ids_list([], location)
  end

  defp build_ids_list(ids_list, %Location{id: id, parent_location_id: nil}) do
    [id | ids_list]
  end

  defp build_ids_list(ids_list, %Location{id: id, parent_location_id: parent_location_id}) do
    build_ids_list([id | ids_list], Repo.get(Location, parent_location_id))
  end

  @doc """
  Creates a location.
  """
  def create_location(attrs \\ %{}) do
    %Location{}
    |> Location.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a location.
  """
  def update_location(%Location{} = location, attrs) do
    location
    |> Location.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a location.
  """
  def delete_location(%Location{} = location) do
    Repo.delete(location)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking location changes.
  """
  def change_location(%Location{} = location) do
    Location.changeset(location, %{})
  end

  @doc """
  Returns the list of zip_codes.
  """
  def list_zip_codes do
    Repo.all(ZipCode)
  end

  @doc """
  Gets a single zip_code.

  Raises `Ecto.NoResultsError` if the Zip code does not exist.
  """
  def get_zip_code!(id), do: Repo.get!(ZipCode, id)

  @doc """
  Creates a zip_code.
  """
  def create_zip_code(attrs \\ %{}) do
    %ZipCode{}
    |> ZipCode.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a zip_code.
  """
  def update_zip_code(%ZipCode{} = zip_code, attrs) do
    zip_code
    |> ZipCode.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a zip_code.
  """
  def delete_zip_code(%ZipCode{} = zip_code) do
    Repo.delete(zip_code)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking zip_code changes.
  """
  def change_zip_code(%ZipCode{} = zip_code) do
    ZipCode.changeset(zip_code, %{})
  end

  @doc """
  Returns the list of zip_code_mappings.
  """
  def list_zip_code_mappings do
    Repo.all(ZipCodeMapping)
  end

  @doc """
  Gets a single zip_code_mapping.

  Raises `Ecto.NoResultsError` if the Zip code mapping does not exist.
  """
  def get_zip_code_mapping!(id), do: Repo.get!(ZipCodeMapping, id)

  @doc """
  Creates a zip_code_mapping.
  """
  def create_zip_code_mapping(attrs \\ %{}) do
    %ZipCodeMapping{}
    |> ZipCodeMapping.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a zip_code_mapping.
  """
  def update_zip_code_mapping(%ZipCodeMapping{} = zip_code_mapping, attrs) do
    zip_code_mapping
    |> ZipCodeMapping.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a zip_code_mapping.
  """
  def delete_zip_code_mapping(%ZipCodeMapping{} = zip_code_mapping) do
    Repo.delete(zip_code_mapping)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking zip_code_mapping changes.
  """
  def change_zip_code_mapping(%ZipCodeMapping{} = zip_code_mapping) do
    ZipCodeMapping.changeset(zip_code_mapping, %{})
  end
end
