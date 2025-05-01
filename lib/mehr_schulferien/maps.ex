defmodule MehrSchulferien.Maps do
  @moduledoc """
  The Maps context.

  This module handles geographic and address-related operations, including:
  - Address management for schools and other locations
  - Zip code (postal code) management 
  - Mappings between zip codes and locations
  """

  import Ecto.Query, warn: false

  alias MehrSchulferien.Maps.{Address, ZipCode, ZipCodeMapping}
  alias MehrSchulferien.Repo

  #
  # Address operations
  #

  @doc """
  Returns the list of addresses.
  """
  def list_addresses do
    Repo.all(Address)
  end

  @doc """
  Gets a single address.

  Raises `Ecto.NoResultsError` if the address does not exist.
  """
  def get_address!(id), do: Repo.get!(Address, id)

  @doc """
  Creates an address.
  """
  def create_address(attrs \\ %{}) do
    %Address{}
    |> Address.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an address.
  """
  def update_address(%Address{} = address, attrs) do
    address
    |> Address.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an address.
  """
  def delete_address(%Address{} = address) do
    Repo.delete(address)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking address changes.
  """
  def change_address(%Address{} = address) do
    Address.changeset(address, %{})
  end

  #
  # Zip code operations
  #

  @doc """
  Returns the list of zip_codes.
  """
  def list_zip_codes do
    Repo.all(ZipCode)
  end

  @doc """
  Gets a single zip_code.

  Raises `Ecto.NoResultsError` if the zip code does not exist.
  """
  def get_zip_code!(id), do: Repo.get!(ZipCode, id)

  @doc """
  Gets a single zip_code by querying the value.

  This function also preloads all locations data.

  Raises `Ecto.NoResultsError` if the zip code does not exist.
  """
  def get_zip_code_by_value!(zip_code_value) do
    ZipCode
    |> Repo.get_by!(value: zip_code_value)
    |> Repo.preload([:locations])
  end

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
  Loads locations data for a zip_code.
  """
  def with_zip_code_locations(%ZipCode{} = zip_code) do
    Repo.preload(zip_code, [:locations])
  end

  #
  # Zip code mapping operations
  #

  @doc """
  Returns the list of zip_code_mappings.
  """
  def list_zip_code_mappings do
    Repo.all(ZipCodeMapping)
  end

  @doc """
  Gets a single zip_code_mapping.

  Raises `Ecto.NoResultsError` if the zip code mapping does not exist.
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
