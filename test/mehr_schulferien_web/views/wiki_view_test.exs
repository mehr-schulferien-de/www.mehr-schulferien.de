defmodule MehrSchulferienWeb.WikiViewTest do
  use ExUnit.Case, async: true

  alias MehrSchulferienWeb.WikiView

  describe "format_originator/1" do
    test "obfuscates IPv4 addresses correctly" do
      version = %{meta: %{"ip_address" => "192.168.1.100"}}

      result = WikiView.format_originator(version)

      assert result == "IP: *.*.1.100"
    end

    test "handles unknown originator" do
      version = %{meta: %{}}

      result = WikiView.format_originator(version)

      assert result == "Unbekannt"
    end

    test "handles malformed IP addresses" do
      version = %{meta: %{"ip_address" => "malformed-ip"}}

      result = WikiView.format_originator(version)

      assert result == "IP: *d-ip"
    end

    test "handles nil IP address" do
      version = %{meta: %{"ip_address" => nil}}

      result = WikiView.format_originator(version)

      assert result == "IP: *"
    end
  end

  describe "version_summary/1" do
    test "shows old values for changed fields" do
      version = %{
        item_changes: %{
          "street" => ["Alte Straße 123", "Neue Straße 456"],
          "phone_number" => ["+49 30 11111111", "+49 30 22222222"]
        }
      }

      result = WikiView.version_summary(version)

      assert result ==
               "Geändert: Straße: \"Alte Straße 123\" → \"Neue Straße 456\", Telefon: \"+49 30 11111111\" → \"+49 30 22222222\""
    end

    test "handles nil old values" do
      version = %{
        item_changes: %{
          "street" => [nil, "Neue Straße 456"],
          "email_address" => ["", "new@example.com"]
        }
      }

      result = WikiView.version_summary(version)

      assert result ==
               "Geändert: Straße: leer → \"Neue Straße 456\", E-Mail: leer → \"new@example.com\""
    end

    test "shows no relevant changes when no tracked fields changed" do
      version = %{
        item_changes: %{
          "untracked_field" => ["old", "new"]
        }
      }

      result = WikiView.version_summary(version)

      assert result == "Keine relevanten Änderungen"
    end

    test "handles empty item_changes" do
      version = %{item_changes: %{}}

      result = WikiView.version_summary(version)

      assert result == "Keine relevanten Änderungen"
    end

    test "handles missing item_changes" do
      version = %{}

      result = WikiView.version_summary(version)

      assert result == "Keine relevanten Änderungen"
    end

    test "handles different change formats gracefully" do
      version = %{
        item_changes: %{
          "street" => "some-different-format",
          "phone_number" => ["+49 30 11111111", "+49 30 22222222"]
        }
      }

      result = WikiView.version_summary(version)

      assert result ==
               "Geändert: Straße: \"some-different-format\", Telefon: \"+49 30 11111111\" → \"+49 30 22222222\""
    end
  end
end
