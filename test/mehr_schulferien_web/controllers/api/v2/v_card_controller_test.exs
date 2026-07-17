defmodule MehrSchulferienWeb.Api.V2.VCardControllerTest do
  use MehrSchulferienWeb.ConnCase

  import MehrSchulferien.Factory
  import MehrSchulferien.TestHelpers

  test "GET /api/v2.0/vcards/schools/:slug returns a vCard download", %{conn: conn} do
    country = get_or_create_deutschland()
    federal_state = insert(:federal_state, parent_location_id: country.id)
    county = insert(:county, parent_location_id: federal_state.id)
    city = insert(:city, parent_location_id: county.id)
    school = insert(:school, parent_location_id: city.id)

    conn = get(conn, "/api/v2.0/vcards/schools/#{school.slug}")

    body = response(conn, 200)
    assert body =~ "BEGIN:VCARD"
    assert body =~ school.name
    assert get_resp_header(conn, "content-type") == ["text/vcard;charset=utf-8"]
    [disposition] = get_resp_header(conn, "content-disposition")
    assert disposition =~ "attachment"
  end
end
