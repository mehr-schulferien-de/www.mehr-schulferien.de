defmodule MehrSchulferienWeb.Api.SchoolController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Locations
  alias MehrSchulferien.Locations.School

  action_fallback MehrSchulferienWeb.FallbackController

  def index(conn, _params) do
    schools = Locations.list_schools()
    render(conn, "index.json", schools: schools)
  end

  def show(conn, %{"id" => id}) do
    school = Locations.get_school!(id)
    render(conn, "show.json", school: school)
  end

end
