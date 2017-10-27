defmodule MehrSchulferienWeb.Api.FederalStateView do
  use MehrSchulferienWeb, :view
  alias MehrSchulferienWeb.Api.FederalStateView

  def render("index.json", %{federal_states: federal_states}) do
    %{data: render_many(federal_states, FederalStateView, "federal_state.json")}
  end

  def render("show.json", %{federal_state: federal_state}) do
    %{data: render_one(federal_state, FederalStateView, "federal_state.json")}
  end

  def render("federal_state.json", %{federal_state: federal_state}) do
    %{id: federal_state.id,
      name: federal_state.name,
      slug: federal_state.slug,
      country_id: federal_state.country_id}
  end
end
