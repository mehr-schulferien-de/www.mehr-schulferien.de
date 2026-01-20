defmodule MehrSchulferienWeb.SchoolVCardVCF do
  @moduledoc """
  VCF format module for rendering vCard files for schools.
  """
  use Phoenix.View,
    root: "lib/mehr_schulferien_web/templates",
    path: "school_vcard"

  alias MehrSchulferien.Config

  @vcard_version 3.0

  def render("vcard.vcf", %{location: location}) do
    location |> generate_vcard() |> List.flatten() |> Enum.join("\n")
  end

  defp generate_vcard(location) do
    [
      "BEGIN:VCARD",
      "VERSION:#{@vcard_version}",
      "N:;;;;",
      "FN:#{location.name}",
      "ORG:#{location.name}",
      "KIND:organization",
      "LANG:de-DE",
      maybe_add_email(location),
      maybe_add_homepage(location),
      "URL:https://www.mehr-schulferien.de/ferien/d/schule/#{location.slug}",
      maybe_add_address(location),
      maybe_add_phone(location),
      "NOTE:Importiert aus https://www.mehr-schulferien.de",
      "X-ABShowAs:COMPANY",
      "REV:#{vcard_timestamp()}Z",
      "END:VCARD"
    ]
    |> Enum.reject(fn x -> is_nil(x) or String.match?(x, ~r/:$/) end)
  end

  defp maybe_add_email(location) do
    if Config.school_contact_info_enabled?() && location.address &&
         location.address.email_address do
      "EMAIL;INTERNET:#{location.address.email_address}"
    end
  end

  defp maybe_add_homepage(location) do
    if location.address && location.address.homepage_url do
      "URL:#{location.address.homepage_url}"
    end
  end

  defp maybe_add_address(location) do
    if location.address do
      "ADR;TYPE=WORK:;;#{location.address.street};#{location.address.city};;#{location.address.zip_code};Deutschland"
    end
  end

  defp maybe_add_phone(location) do
    if Config.school_contact_info_enabled?() && location.address &&
         location.address.phone_number do
      "TEL;TYPE=WORK,VOICE:#{location.address.phone_number}"
    end
  end

  defp vcard_timestamp do
    DateTime.utc_now()
    |> DateTime.to_string()
    |> String.split(".")
    |> hd
    |> String.replace(~r/[-:\s]/, "")
  end
end
