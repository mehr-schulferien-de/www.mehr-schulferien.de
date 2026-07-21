defmodule MehrSchulferien.Calendars.VacationSlug do
  @moduledoc """
  Maps between the database slugs of school vacation types ("ostern") and
  the URL slugs used in routes ("osterferien").

  The URL slug is the German compound word searchers actually type
  (Osterferien, Weihnachtsferien, Pfingstferien). Historically the URLs
  were generated as `"\#{db_slug}ferien"`, which produced non-words like
  "osternferien" and "weihnachtenferien". `resolve/1` still recognizes
  those as `:legacy` so controllers can 301 them to the canonical URL.
  """

  alias MehrSchulferien.Calendars.HolidayOrVacationType

  # Database slugs whose generated "<slug>ferien" form is not the German
  # compound word. Everything else (sommer, herbst, winter) works with the
  # plain suffix.
  @custom %{
    "ostern" => "osterferien",
    "weihnachten" => "weihnachtsferien",
    "pfingsten" => "pfingstferien",
    "fruehjahr" => "fruehjahrsferien",
    "himmelfahrt" => "himmelfahrtsferien",
    "himmelfahrt-pfingsten" => "himmelfahrt-pfingstferien",
    "beweglicher-ferientag" => "bewegliche-ferientage"
  }

  @canonical_to_db Map.new(@custom, fn {db, url} -> {url, db} end)

  @doc """
  Returns the canonical URL slug for a vacation type or its database slug.

      iex> MehrSchulferien.Calendars.VacationSlug.url_slug("ostern")
      "osterferien"
  """
  def url_slug(%HolidayOrVacationType{slug: db_slug}), do: url_slug(db_slug)

  def url_slug(db_slug) when is_binary(db_slug) do
    Map.get(@custom, db_slug, db_slug <> "ferien")
  end

  @doc """
  Resolves a URL slug to `{:canonical, db_slug}`, `{:legacy, db_slug}`
  (an old generated URL that should 301 to the canonical one) or `:error`
  for slugs that cannot belong to a vacation type.
  """
  def resolve(url_slug) when is_binary(url_slug) do
    case Map.fetch(@canonical_to_db, url_slug) do
      {:ok, db_slug} -> {:canonical, db_slug}
      :error -> resolve_generated(url_slug)
    end
  end

  defp resolve_generated(url_slug) do
    suffix = "ferien"

    if String.ends_with?(url_slug, suffix) and byte_size(url_slug) > byte_size(suffix) do
      stem = binary_part(url_slug, 0, byte_size(url_slug) - byte_size(suffix))

      # A stem with a custom mapping means the visitor used the old
      # generated URL ("osternferien"); anything else is canonical as-is.
      if Map.has_key?(@custom, stem) do
        {:legacy, stem}
      else
        {:canonical, stem}
      end
    else
      :error
    end
  end
end
