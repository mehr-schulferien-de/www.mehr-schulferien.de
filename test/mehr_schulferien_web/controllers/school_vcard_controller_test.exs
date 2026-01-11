defmodule MehrSchulferienWeb.SchoolVCardControllerTest do
  use MehrSchulferienWeb.ConnCase

  import MehrSchulferien.Factory
  import MehrSchulferien.TestHelpers

  describe "download/2" do
    test "returns a vCard file for a school", %{conn: conn} do
      {:ok, %{country: country, school: school}} = create_school()

      conn = get(conn, ~p"/ferien/#{country.slug}/schule/#{school.slug}/vcard")

      assert response(conn, 200)
      assert get_resp_header(conn, "content-type") == ["text/vcard;charset=utf-8"]
      assert [content_disposition] = get_resp_header(conn, "content-disposition")
      assert content_disposition =~ "_vcard.vcf"

      body = response(conn, 200)
      assert body =~ "BEGIN:VCARD"
      assert body =~ "VERSION:3.0"
      assert body =~ "FN:Test-Gymnasium"
      assert body =~ "ORG:Test-Gymnasium"
      assert body =~ "END:VCARD"
    end

    test "includes contact information when school has an address", %{conn: conn} do
      {:ok, %{country: country, city: city}} = create_school()

      # Create a school with address
      school = insert(:school_with_address)

      # Update the school to have correct parent
      school =
        MehrSchulferien.Repo.update!(
          Ecto.Changeset.change(school, %{
            parent_location_id: city.id
          })
        )

      # Reload the school with address
      school = MehrSchulferien.Locations.get_school_by_slug!(school.slug)

      conn = get(conn, ~p"/ferien/#{country.slug}/schule/#{school.slug}/vcard")

      body = response(conn, 200)
      assert body =~ "BEGIN:VCARD"
      assert body =~ "EMAIL;INTERNET:"
      assert body =~ "TEL;TYPE=WORK,VOICE:"
      assert body =~ "ADR;TYPE=WORK:"
      assert body =~ "END:VCARD"
    end

    test "returns 404 for non-existent school", %{conn: conn} do
      {:ok, %{country: country}} = create_school()

      assert_error_sent 404, fn ->
        get(conn, ~p"/ferien/#{country.slug}/schule/non-existent-school/vcard")
      end
    end
  end
end
