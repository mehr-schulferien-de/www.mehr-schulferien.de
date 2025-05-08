defmodule MehrSchulferienWeb.SchoolVCardController do
  use MehrSchulferienWeb, :controller
  alias MehrSchulferien.Locations

  def download(conn, %{"school_slug" => slug}) do
    school = Locations.get_school_by_slug!(slug)

    conn
    |> update_headers(slug)
    |> render("vcard.vcf", location: school)
  end

  defp update_headers(conn, slug) do
    filename = "#{String.replace(slug, ".", "_")}_vcard.vcf"

    conn
    |> put_resp_header("content-type", "text/vcard;charset=utf-8")
    |> put_resp_header("content-disposition", "attachment;filename=#{filename}")
  end
end
