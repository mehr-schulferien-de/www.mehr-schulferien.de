defmodule MehrSchulferien.Calendars.VacationSlugTest do
  use ExUnit.Case, async: true

  alias MehrSchulferien.Calendars.VacationSlug

  describe "url_slug/1" do
    test "uses the correct German compound for irregular types" do
      assert VacationSlug.url_slug("ostern") == "osterferien"
      assert VacationSlug.url_slug("weihnachten") == "weihnachtsferien"
      assert VacationSlug.url_slug("pfingsten") == "pfingstferien"
      assert VacationSlug.url_slug("fruehjahr") == "fruehjahrsferien"
      assert VacationSlug.url_slug("himmelfahrt") == "himmelfahrtsferien"
      assert VacationSlug.url_slug("himmelfahrt-pfingsten") == "himmelfahrt-pfingstferien"
      assert VacationSlug.url_slug("beweglicher-ferientag") == "bewegliche-ferientage"
    end

    test "appends ferien for regular types" do
      assert VacationSlug.url_slug("sommer") == "sommerferien"
      assert VacationSlug.url_slug("herbst") == "herbstferien"
      assert VacationSlug.url_slug("winter") == "winterferien"
    end

    test "accepts a HolidayOrVacationType struct" do
      type = %MehrSchulferien.Calendars.HolidayOrVacationType{slug: "ostern"}
      assert VacationSlug.url_slug(type) == "osterferien"
    end
  end

  describe "resolve/1" do
    test "resolves canonical URL slugs to database slugs" do
      assert VacationSlug.resolve("osterferien") == {:canonical, "ostern"}
      assert VacationSlug.resolve("weihnachtsferien") == {:canonical, "weihnachten"}
      assert VacationSlug.resolve("pfingstferien") == {:canonical, "pfingsten"}
      assert VacationSlug.resolve("fruehjahrsferien") == {:canonical, "fruehjahr"}
      assert VacationSlug.resolve("sommerferien") == {:canonical, "sommer"}
      assert VacationSlug.resolve("herbstferien") == {:canonical, "herbst"}
      assert VacationSlug.resolve("winterferien") == {:canonical, "winter"}

      assert VacationSlug.resolve("bewegliche-ferientage") ==
               {:canonical, "beweglicher-ferientag"}
    end

    test "flags the historic generated slugs as legacy" do
      assert VacationSlug.resolve("osternferien") == {:legacy, "ostern"}
      assert VacationSlug.resolve("weihnachtenferien") == {:legacy, "weihnachten"}
      assert VacationSlug.resolve("pfingstenferien") == {:legacy, "pfingsten"}
      assert VacationSlug.resolve("fruehjahrferien") == {:legacy, "fruehjahr"}
      assert VacationSlug.resolve("himmelfahrtferien") == {:legacy, "himmelfahrt"}

      assert VacationSlug.resolve("himmelfahrt-pfingstenferien") ==
               {:legacy, "himmelfahrt-pfingsten"}
    end

    test "unknown ferien slugs resolve to their stem so the DB lookup decides" do
      assert VacationSlug.resolve("fantasieferien") == {:canonical, "fantasie"}
    end

    test "slugs without a ferien suffix are errors" do
      assert VacationSlug.resolve("feiertage") == :error
      assert VacationSlug.resolve("brueckentage") == :error
    end
  end
end
