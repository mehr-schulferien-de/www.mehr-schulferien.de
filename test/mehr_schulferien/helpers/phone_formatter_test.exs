defmodule MehrSchulferien.Helpers.PhoneFormatterTest do
  use ExUnit.Case
  alias MehrSchulferien.Helpers.PhoneFormatter

  describe "format_phone_number/1" do
    test "formats German phone numbers correctly" do
      assert PhoneFormatter.format_phone_number("+49 30 12345678") == "030 12345678"
      assert PhoneFormatter.format_phone_number("030-12345678") == "030 12345678"
      assert PhoneFormatter.format_phone_number("+493012345678") == "030 12345678"
    end

    test "handles mobile numbers" do
      assert PhoneFormatter.format_phone_number("+49 171 1234567") == "0171 1234567"
      assert PhoneFormatter.format_phone_number("0171-1234567") == "0171 1234567"
    end

    test "returns original if parsing fails" do
      assert PhoneFormatter.format_phone_number("123") == "123"
      assert PhoneFormatter.format_phone_number("invalid") == "invalid"
    end

    test "handles nil and empty values" do
      assert PhoneFormatter.format_phone_number(nil) == nil
      assert PhoneFormatter.format_phone_number("") == ""
    end
  end

  describe "format_tel_link/1" do
    test "formats tel links correctly" do
      assert PhoneFormatter.format_tel_link("+49 30 12345678") == "tel:+493012345678"
      assert PhoneFormatter.format_tel_link("030-12345678") == "tel:03012345678"
      assert PhoneFormatter.format_tel_link("030 123 45678") == "tel:03012345678"
    end

    test "handles nil and empty values" do
      assert PhoneFormatter.format_tel_link(nil) == nil
      assert PhoneFormatter.format_tel_link("") == ""
    end
  end

  describe "clean_phone_number/1" do
    test "removes formatting characters" do
      assert PhoneFormatter.clean_phone_number("+49 30 12345678") == "+493012345678"
      assert PhoneFormatter.clean_phone_number("030-123-45678") == "03012345678"
      assert PhoneFormatter.clean_phone_number("(030) 123.45678") == "03012345678"
      assert PhoneFormatter.clean_phone_number("030/12345678") == "03012345678"
    end

    test "handles nil and empty values" do
      assert PhoneFormatter.clean_phone_number(nil) == nil
      assert PhoneFormatter.clean_phone_number("") == ""
    end
  end

  describe "valid_phone_number?/1" do
    test "validates German phone numbers" do
      assert PhoneFormatter.valid_phone_number?("+49 30 12345678") == true
      assert PhoneFormatter.valid_phone_number?("030-12345678") == true
      assert PhoneFormatter.valid_phone_number?("+49 171 1234567") == true
    end

    test "rejects invalid numbers" do
      assert PhoneFormatter.valid_phone_number?("123") == false
      assert PhoneFormatter.valid_phone_number?("invalid") == false
      assert PhoneFormatter.valid_phone_number?("") == false
      assert PhoneFormatter.valid_phone_number?(nil) == false
    end
  end

  describe "format_international/1" do
    test "formats to international format" do
      assert PhoneFormatter.format_international("030-12345678") == "+49 30 12345678"
      assert PhoneFormatter.format_international("+493012345678") == "+49 30 12345678"
      assert PhoneFormatter.format_international("0171 1234567") == "+49 171 1234567"
    end

    test "handles short numbers" do
      # ExPhoneNumber actually parses "123" as a valid number and formats it
      assert PhoneFormatter.format_international("123") == "+49 123"
      # Test with truly invalid input
      assert PhoneFormatter.format_international("abc") == "abc"
    end

    test "handles nil and empty values" do
      assert PhoneFormatter.format_international(nil) == nil
      assert PhoneFormatter.format_international("") == ""
    end
  end
end
