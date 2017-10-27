defmodule MehrSchulferienWeb.Api.SchoolView do
  use MehrSchulferienWeb, :view
  alias MehrSchulferienWeb.Api.SchoolView

  def render("index.json", %{schools: schools}) do
    %{data: render_many(schools, SchoolView, "school.json")}
  end

  def render("show.json", %{school: school}) do
    %{data: render_one(school, SchoolView, "school.json")}
  end

  def render("school.json", %{school: school}) do
    %{id: school.id,
      name: school.name,
      slug: school.slug,
      address_line1: school.address_line1,
      address_street: school.address_street,
      address_zip_code: school.address_zip_code,
      address_city: school.address_city,
      email_address: school.email_address,
      fax_number: school.fax_number,
      homepage_url: school.homepage_url,
      phone_number: school.phone_number,
      country_id: school.country_id,
      federal_state_id: school.federal_state_id,
      city_id: school.city_id}
  end
end
