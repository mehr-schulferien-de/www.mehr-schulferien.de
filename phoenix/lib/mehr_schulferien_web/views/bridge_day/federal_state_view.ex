defmodule MehrSchulferienWeb.BridgeDay.FederalStateView do
  use MehrSchulferienWeb, :view
  alias MehrSchulferienWeb.Formatter
  alias MehrSchulferienWeb.CalendarHelper
  alias MehrSchulferienWeb.SchemaOrgHelper

  def render("index.json", %{days: days}) do
    render_many(days, __MODULE__, "show.json", as: :days)
  end

  def render("show.json", %{days: days}) do
    %{
      "slug" => days.slug,
      "value" => days.value,
    }
    end
end
