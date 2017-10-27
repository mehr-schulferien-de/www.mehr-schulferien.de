defmodule MehrSchulferienWeb.Api.PeriodView do
  use MehrSchulferienWeb, :view
  alias MehrSchulferienWeb.Api.PeriodView

  def render("index.json", %{periods: periods}) do
    %{data: render_many(periods, PeriodView, "period.json")}
  end

  def render("show.json", %{period: period}) do
    %{data: render_one(period, PeriodView, "period.json")}
  end

  def render("period.json", %{period: period}) do
    %{id: period.id,
      name: period.name,
      slug: period.slug,
      starts_on: period.starts_on,
      ends_on: period.ends_on,
      school_id: period.school_id,
      country_id: period.country_id,
      federal_state_id: period.federal_state_id,
      city_id: period.city_id}
  end
end
