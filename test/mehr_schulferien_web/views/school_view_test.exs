defmodule MehrSchulferienWeb.SchoolViewTest do
  use MehrSchulferienWeb.ConnCase, async: true

  import MehrSchulferienWeb.SchoolView

  describe "truncate function" do
    test "snips a string with length > 28" do
      string = "http://localhost:4000/ferien/d/schule/56077-grundschule-arenberg"
      html_string =
        {:safe,
         [
           "<abbr title=\"",
           "http://localhost:4000/ferien/d/schule/56077-grundschule-arenberg",
           "\">",
           "http://localhost:4000/fer...",
           "</abbr>\n"
         ]}

      assert truncate(string) == html_string
    end

    test "doesn't truncate string of length < 28" do
      string = "emmanuelhayford.com"

      assert truncate(string) == "emmanuelhayford.com"
    end
  end
end
