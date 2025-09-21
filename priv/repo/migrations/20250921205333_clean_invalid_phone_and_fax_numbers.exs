defmodule MehrSchulferien.Repo.Migrations.CleanInvalidPhoneAndFaxNumbers do
  use Ecto.Migration
  import Ecto.Query
  alias MehrSchulferien.Repo
  alias MehrSchulferien.Maps.Address

  def up do
    # Ensure the application is started for ExPhoneNumber
    Application.ensure_all_started(:ex_phone_number)

    # Clean invalid phone numbers
    clean_invalid_phone_numbers()

    # Clean invalid fax numbers
    clean_invalid_fax_numbers()
  end

  def down do
    # This migration cannot be reversed as we're removing invalid data
    # The original invalid values are lost
    :ok
  end

  defp clean_invalid_phone_numbers do
    addresses_with_phones =
      from(a in Address, where: not is_nil(a.phone_number))
      |> Repo.all()

    invalid_count =
      Enum.reduce(addresses_with_phones, 0, fn address, count ->
        if valid_german_phone_number?(address.phone_number) do
          count
        else
          # Update the address to set phone_number to NULL
          from(a in Address, where: a.id == ^address.id)
          |> Repo.update_all(set: [phone_number: nil])

          IO.puts(
            "Cleaned invalid phone number '#{address.phone_number}' from address ID: #{address.id}"
          )

          count + 1
        end
      end)

    IO.puts("Cleaned #{invalid_count} invalid phone numbers")
  end

  defp clean_invalid_fax_numbers do
    addresses_with_faxes =
      from(a in Address, where: not is_nil(a.fax_number))
      |> Repo.all()

    invalid_count =
      Enum.reduce(addresses_with_faxes, 0, fn address, count ->
        if valid_german_phone_number?(address.fax_number) do
          count
        else
          # Update the address to set fax_number to NULL
          from(a in Address, where: a.id == ^address.id)
          |> Repo.update_all(set: [fax_number: nil])

          IO.puts(
            "Cleaned invalid fax number '#{address.fax_number}' from address ID: #{address.id}"
          )

          count + 1
        end
      end)

    IO.puts("Cleaned #{invalid_count} invalid fax numbers")
  end

  defp valid_german_phone_number?(phone_number) when is_binary(phone_number) do
    # Remove common separators for parsing
    cleaned = String.replace(phone_number, ~r/[-\/\(\)]/, "")

    # Try to parse as German number or check if already in international format
    case ExPhoneNumber.parse(cleaned, "DE") do
      {:ok, parsed_number} ->
        # Check if it's a valid German number
        ExPhoneNumber.is_valid_number?(parsed_number)

      {:error, _} ->
        # Could not parse - it's invalid
        false
    end
  end

  defp valid_german_phone_number?(_), do: false
end
