defmodule MehrSchulferien.Helpers.PhoneFormatter do
  @moduledoc """
  Helper module for formatting phone numbers consistently throughout the application.
  Uses ExPhoneNumber library for parsing and formatting German phone numbers.
  """

  @doc """
  Formats a phone number for display purposes.

  ## Examples

      iex> format_phone_number("+49 30 12345678")
      "030 12345678"
      
      iex> format_phone_number("030-12345678")
      "030 12345678"
      
      iex> format_phone_number("+49301234567890") # invalid
      "+49301234567890"
  """
  def format_phone_number(nil), do: nil
  def format_phone_number(""), do: ""

  def format_phone_number(phone_number) when is_binary(phone_number) do
    case ExPhoneNumber.parse(phone_number, "DE") do
      {:ok, parsed_number} ->
        ExPhoneNumber.format(parsed_number, :national)

      {:error, _} ->
        # If parsing fails, return the original number
        phone_number
    end
  end

  @doc """
  Formats a phone number as a tel: link.
  Removes spaces and special characters for the link.

  ## Examples

      iex> format_tel_link("+49 30 12345678")
      "tel:+493012345678"
      
      iex> format_tel_link("030-12345678")
      "tel:03012345678"
  """
  def format_tel_link(nil), do: nil
  def format_tel_link(""), do: ""

  def format_tel_link(phone_number) when is_binary(phone_number) do
    cleaned = clean_phone_number(phone_number)
    "tel:#{cleaned}"
  end

  @doc """
  Cleans a phone number by removing spaces, dashes, and other formatting.

  ## Examples

      iex> clean_phone_number("+49 30 12345678")
      "+493012345678"
      
      iex> clean_phone_number("030-12345678")
      "03012345678"
  """
  def clean_phone_number(nil), do: nil
  def clean_phone_number(""), do: ""

  def clean_phone_number(phone_number) when is_binary(phone_number) do
    phone_number
    |> String.replace(~r/[\s\-\(\)\.\/]/, "")
  end

  @doc """
  Validates if a phone number is valid for Germany.

  ## Examples

      iex> valid_phone_number?("+49 30 12345678")
      true
      
      iex> valid_phone_number?("030-12345678")
      true
      
      iex> valid_phone_number?("123")
      false
  """
  def valid_phone_number?(nil), do: false
  def valid_phone_number?(""), do: false

  def valid_phone_number?(phone_number) when is_binary(phone_number) do
    case ExPhoneNumber.parse(phone_number, "DE") do
      {:ok, parsed_number} -> ExPhoneNumber.is_valid_number?(parsed_number)
      {:error, _} -> false
    end
  end

  @doc """
  Formats a phone number for international display.

  ## Examples

      iex> format_international("+49 30 12345678")
      "+49 30 12345678"
      
      iex> format_international("030-12345678")
      "+49 30 12345678"
  """
  def format_international(nil), do: nil
  def format_international(""), do: ""

  def format_international(phone_number) when is_binary(phone_number) do
    case ExPhoneNumber.parse(phone_number, "DE") do
      {:ok, parsed_number} ->
        ExPhoneNumber.format(parsed_number, :international)

      {:error, _} ->
        phone_number
    end
  end
end
