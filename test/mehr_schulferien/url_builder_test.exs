defmodule MehrSchulferien.UrlBuilderTest do
  use ExUnit.Case, async: true

  alias MehrSchulferien.UrlBuilder

  describe "base_url/0" do
    test "returns the correct base URL" do
      assert UrlBuilder.base_url() == "https://www.mehr-schulferien.de"
    end
  end

  describe "school_url/2" do
    test "constructs correct school URL" do
      school = %{slug: "test-schule"}

      assert UrlBuilder.school_url("d", school) ==
               "https://www.mehr-schulferien.de/ferien/d/schule/test-schule"
    end

    test "handles school with special characters in slug" do
      school = %{slug: "schule-mit-umlaut-münchen"}

      assert UrlBuilder.school_url("d", school) ==
               "https://www.mehr-schulferien.de/ferien/d/schule/schule-mit-umlaut-münchen"
    end
  end

  describe "federal_state_url/3" do
    test "constructs correct federal state URL" do
      federal_state = %{slug: "bayern"}

      assert UrlBuilder.federal_state_url("d", federal_state, 2024) ==
               "https://www.mehr-schulferien.de/ferien/d/bundesland/bayern/2024"
    end

    test "handles different years" do
      federal_state = %{slug: "nordrhein-westfalen"}

      assert UrlBuilder.federal_state_url("d", federal_state, 2025) ==
               "https://www.mehr-schulferien.de/ferien/d/bundesland/nordrhein-westfalen/2025"
    end
  end

  describe "city_url/3" do
    test "constructs correct city URL" do
      city = %{slug: "muenchen"}

      assert UrlBuilder.city_url("d", city, 2024) ==
               "https://www.mehr-schulferien.de/ferien/d/stadt/muenchen/2024"
    end

    test "handles city with complex slug" do
      city = %{slug: "frankfurt-am-main"}

      assert UrlBuilder.city_url("d", city, 2024) ==
               "https://www.mehr-schulferien.de/ferien/d/stadt/frankfurt-am-main/2024"
    end
  end

  describe "google_maps_url/1" do
    test "constructs correct Google Maps URL" do
      query = "Schule München, Germany"
      expected = "https://www.google.com/maps?q=Schule%20M%C3%BCnchen,%20Germany"
      assert UrlBuilder.google_maps_url(query) == expected
    end

    test "handles special characters in query" do
      query = "Müller-Schule & Partner GmbH"
      result = UrlBuilder.google_maps_url(query)
      assert String.starts_with?(result, "https://www.google.com/maps?q=")
      assert String.contains?(result, "M%C3%BCller")
    end
  end

  describe "openstreetmap_url/1" do
    test "constructs correct OpenStreetMap URL" do
      query = "Berlin School"
      expected = "https://www.openstreetmap.org/search?query=Berlin%20School"
      assert UrlBuilder.openstreetmap_url(query) == expected
    end

    test "encodes query properly" do
      query = "Köln Hauptbahnhof"
      result = UrlBuilder.openstreetmap_url(query)
      assert String.starts_with?(result, "https://www.openstreetmap.org/search?query=")
      assert String.contains?(result, "K%C3%B6ln")
    end
  end

  describe "apple_maps_url/1" do
    test "constructs correct Apple Maps URL" do
      query = "Hamburg Airport"
      expected = "https://maps.apple.com/?q=Hamburg%20Airport"
      assert UrlBuilder.apple_maps_url(query) == expected
    end

    test "handles complex queries" do
      query = "Düsseldorf, Königsallee 1"
      result = UrlBuilder.apple_maps_url(query)
      assert String.starts_with?(result, "https://maps.apple.com/?q=")
      assert String.contains?(result, "D%C3%BCsseldorf")
    end
  end
end
