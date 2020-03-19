defmodule MehrSchulferienWeb.SchoolViewTest do
  use MehrSchulferienWeb.ConnCase, async: true

  import MehrSchulferienWeb.SchoolView

  describe "#truncate" do
    test "it truncates a string with length > 28" do
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

    test "it doesn't truncate string of length < 28" do
      string = "emmanuel@me.com"

      assert truncate(string) == "emmanuel@me.com"
    end
  end
end
