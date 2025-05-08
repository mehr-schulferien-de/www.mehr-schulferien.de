defmodule MehrSchulferienWeb.OldSchoolViewTest do
  use MehrSchulferienWeb.ConnCase, async: true

  import MehrSchulferienWeb.OldSchoolView

  describe "truncate" do
    test "snips a url with length > 28" do
      url = "http://localhost:4000/ferien/d/schule/56077-grundschule-arenberg"

      html_url =
        {:safe,
         [
           "<a href=\"",
           "http://localhost:4000/ferien/d/schule/56077-grundschule-arenberg",
           "\">",
           "localhost:4000/ferien/d/s...",
           "</a>\n"
         ]}

      assert truncate_url(url) == html_url
    end

    test "doesn't truncate a url of length < 28" do
      string = "emmanuelhayford.com"

      assert truncate_url(string) ==
               {:safe,
                ["<a href=\"", "emmanuelhayford.com", "\">", "emmanuelhayford.com", "</a>\n"]}
    end

    test "snips an email of length > 28" do
      email = "emmanuelhayfordsveryveryverylongemail@emmanuelhayford.com"

      assert truncate_email(email) ==
               {:safe,
                [
                  "<a href=\"mailto:",
                  "emmanuelhayfordsveryveryverylongemail@emmanuelhayford.com",
                  "\">",
                  "emmanuelhayfordsveryveryv...",
                  "</a>\n"
                ]}
    end

    test "does not truncate an email of length < 28" do
      email = "email@example.com"

      assert truncate_email(email) ==
               {:safe,
                ["<a href=\"mailto:", "email@example.com", "\">", "email@example.com", "</a>\n"]}
    end
  end
end
