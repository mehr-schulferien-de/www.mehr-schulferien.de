defmodule MehrSchulferienWeb.StaticImagesTest do
  use ExUnit.Case, async: true

  # Every /images/... path in code, templates and LiveViews must exist in
  # assets/static/images, which `mix phx.digest` copies to priv/static/images.
  # A missing file only shows up as a 404 on the live site.

  @image_ref ~r{/images/([\w./-]+\.(?:png|jpe?g|webp|svg|gif|ico))}

  test "every referenced /images/ file exists in assets/static/images" do
    refs =
      Path.wildcard("lib/**/*.{ex,exs,heex,eex}")
      |> Enum.flat_map(fn file ->
        for [_, name] <- Regex.scan(@image_ref, File.read!(file)), do: {name, file}
      end)

    assert refs != [], "found no /images/ references; the scan is broken"

    missing =
      refs
      |> Enum.reject(fn {name, _} -> File.exists?(Path.join("assets/static/images", name)) end)
      |> Enum.map(fn {name, file} -> "#{name} (#{file})" end)
      |> Enum.uniq()

    assert missing == [], "missing images:\n" <> Enum.join(missing, "\n")
  end
end
