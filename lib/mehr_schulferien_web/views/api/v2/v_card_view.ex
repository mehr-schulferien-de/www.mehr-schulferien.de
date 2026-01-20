defmodule MehrSchulferienWeb.Api.V2.VCardView do
  use MehrSchulferienWeb, :view

  alias MehrSchulferien.Config

  @vcard_version 3.0

  def render("vcard.vcf", %{location: location}) do
    location |> generate_vcard() |> List.flatten() |> Enum.join("\n")
  end

  def generate_vcard(location) do
    contact_info_enabled = Config.school_contact_info_enabled?()

    base_fields = [
      "BEGIN:VCARD",
      "VERSION:#{@vcard_version}",
      "N:;;;;",
      "FN:#{location.name}",
      "ORG:#{location.name}",
      "KIND:organization",
      "LANG:de-DE"
    ]

    # Only add email if contact info is enabled
    email_field =
      if contact_info_enabled && location.address && location.address.email_address do
        ["EMAIL;INTERNET:#{location.address.email_address}"]
      else
        []
      end

    url_fields = [
      "URL:#{location.address.homepage_url}",
      "URL:https://www.mehr-schulferien.de/ferien/d/schule/#{location.slug}"
    ]

    address_field = [
      "ADR;TYPE=WORK:;;#{location.address.street};#{location.address.city};;#{location.address.zip_code};Deutschland"
    ]

    # Only add phone and fax if contact info is enabled
    phone_fields =
      if contact_info_enabled do
        [
          "TEL;TYPE=WORK,VOICE:#{location.address.phone_number}",
          "TEL;TYPE=WORK,FAX:#{location.address.fax_number}"
        ]
      else
        []
      end

    footer_fields = [
      "NOTE:Importiert aus https://www.mehr-schulferien.de",
      "X-ABShowAs:COMPANY",
      "REV:#{vcard_timestamp()}Z",
      "END:VCARD"
    ]

    (base_fields ++ email_field ++ url_fields ++ address_field ++ phone_fields ++ footer_fields)
    |> Enum.reject(fn x -> String.match?(x, ~r/:$/) end)
  end

  defp vcard_timestamp do
    DateTime.utc_now()
    |> DateTime.to_string()
    |> String.split(".")
    |> hd
    |> String.replace(~r/[-:\s]/, "")
  end
end
