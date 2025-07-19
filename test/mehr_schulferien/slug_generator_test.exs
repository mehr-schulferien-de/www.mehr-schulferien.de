defmodule MehrSchulferien.SlugGeneratorTest do
  use ExUnit.Case
  alias MehrSchulferien.SlugGenerator

  describe "slugify_downcase/1" do
    test "converts basic text to slug" do
      assert SlugGenerator.slugify_downcase("Hello World") == "hello-world"
    end

    test "handles German umlauts" do
      assert SlugGenerator.slugify_downcase("München") == "muenchen"
      assert SlugGenerator.slugify_downcase("Köln") == "koeln"
      assert SlugGenerator.slugify_downcase("Düsseldorf") == "duesseldorf"
      assert SlugGenerator.slugify_downcase("Straße") == "strasse"
    end

    test "handles uppercase umlauts" do
      assert SlugGenerator.slugify_downcase("MÜNCHEN") == "muenchen"
      assert SlugGenerator.slugify_downcase("KÖLN") == "koeln"
      assert SlugGenerator.slugify_downcase("DÜSSELDORF") == "duesseldorf"
    end

    test "removes special characters" do
      assert SlugGenerator.slugify_downcase("Test@123!") == "test123"
      assert SlugGenerator.slugify_downcase("Hello, World!") == "hello-world"
    end

    test "handles multiple spaces and hyphens" do
      assert SlugGenerator.slugify_downcase("Hello   World") == "hello-world"
      assert SlugGenerator.slugify_downcase("Hello---World") == "hello-world"
      assert SlugGenerator.slugify_downcase("Hello - - World") == "hello-world"
    end

    test "trims hyphens from start and end" do
      assert SlugGenerator.slugify_downcase("-Hello World-") == "hello-world"
      assert SlugGenerator.slugify_downcase("---Hello---") == "hello"
    end

    test "handles empty strings and nil" do
      assert SlugGenerator.slugify_downcase("") == ""
      assert SlugGenerator.slugify_downcase(nil) == ""
    end

    test "preserves numbers" do
      assert SlugGenerator.slugify_downcase("Test 123") == "test-123"
      assert SlugGenerator.slugify_downcase("2023 Jahr") == "2023-jahr"
    end

    test "handles mixed German text" do
      assert SlugGenerator.slugify_downcase("Schöne Grüße aus München") ==
               "schoene-gruesse-aus-muenchen"

      assert SlugGenerator.slugify_downcase("Büro für Öffentlichkeitsarbeit") ==
               "buero-fuer-oeffentlichkeitsarbeit"
    end
  end
end
