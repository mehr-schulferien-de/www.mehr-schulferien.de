defmodule MehrSchulferienWeb.AdController do
  @moduledoc """
  The house-ad click tracker: `/ads/:id` counts the click and forwards to
  the variant's external target (which keeps its `?ad=` param, so the
  vutuv logs can cross-check the numbers). Unknown or malformed ids go
  quietly to the homepage — old ids from retired variants must never 404.
  """

  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Ads

  def click(conn, %{"id" => id}) do
    with {variant_id, ""} <- Integer.parse(id),
         %{} = variant <- Ads.get_variant(variant_id) do
      Ads.record_click(variant)
      redirect(conn, external: variant.target)
    else
      _unknown -> redirect(conn, to: "/")
    end
  end
end
