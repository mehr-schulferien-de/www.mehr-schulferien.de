defmodule MehrSchulferienWeb.Api.V2.VCardController do
  use MehrSchulferienWeb, :controller
  alias MehrSchulferien.Locations

  def school_show(conn, %{"slug" => slug}) do
    location = Locations.get_school_by_slug!(slug)

    conn
    |> update_headers(slug)
    # Reuse the vCard renderer of the regular download route - Phoenix cannot
    # infer it here because no Api.V2.VCardVCF module exists.
    |> put_view(MehrSchulferienWeb.SchoolVCardVCF)
    |> render("vcard.vcf", location: location)
  end

  defp update_headers(conn, slug) do
    filename = "#{String.replace(slug, ".", "_")}_vcard.vcf"

    conn
    |> put_resp_header("content-type", "text/vcard;charset=utf-8")
    |> put_resp_header("content-disposition", "attachment;filename=#{filename}")
  end
end
