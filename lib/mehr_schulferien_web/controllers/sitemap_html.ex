defmodule MehrSchulferienWeb.SitemapHTML do
  use Phoenix.View,
    root: "lib/mehr_schulferien_web/templates",
    path: "sitemap"

  # Sitemap controller uses XML template (sitemap.xml.eex) not HTML
  # SitemapXML module handles the actual rendering
end
