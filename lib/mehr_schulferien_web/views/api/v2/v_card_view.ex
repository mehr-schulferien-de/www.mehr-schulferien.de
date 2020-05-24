defmodule MehrSchulferienWeb.Api.V2.VCardView do
  use MehrSchulferienWeb, :view

  @vcard_version 3.0

  def render("vcard.vcf", %{location: location}) do
    location |> generate_vcard() |> List.flatten() |> Enum.join("\n")
  end

  def generate_vcard(location) do
    [
      "BEGIN:VCARD",
      "VERSION:#{@vcard_version}",
      "N:;;;;",
      "FN:#{location.name}",
      "ORG:#{location.name}",
      "KIND:organization",
      "LANG:de-DE",
      "EMAIL;INTERNET:#{location.address.email_address}",
      "URL:#{location.address.homepage_url}",
      "URL:https://www.mehr-schulferien.de/ferien/d/schule/#{location.slug}",
      "ADR;TYPE=WORK:;;#{location.address.street};#{location.address.city};;#{
        location.address.zip_code
      };Deutschland",
      "TEL;TYPE=WORK,VOICE:#{location.address.phone_number}",
      "TEL;TYPE=WORK,FAX:#{location.address.fax_number}",
      "NOTE:Importiert aus https://www.mehr-schulferien.de",
      "X-ABShowAs:COMPANY",
      "REV:#{vcard_timestamp()}Z",
      "END:VCARD"
    ]
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
