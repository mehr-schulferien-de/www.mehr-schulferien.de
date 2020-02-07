defmodule MehrSchulferienWeb.ViewHelpersTest do
  use ExUnit.Case

  alias MehrSchulferienWeb.ViewHelpers

  describe "format date range" do
    test "same date just shows one date" do
      assert ViewHelpers.format_date_range(~D[2020-04-06], ~D[2020-04-06]) == "06.04.20"
    end

    test "different dates show range" do
      assert ViewHelpers.format_date_range(~D[2020-04-06], ~D[2020-04-16]) ==
               "06.04.20 - 16.04.20"
    end

    test "setting short value does not show year" do
      assert ViewHelpers.format_date_range(~D[2020-04-06], ~D[2020-04-06], :short) == "06.04."

      assert ViewHelpers.format_date_range(~D[2020-04-06], ~D[2020-04-16], :short) ==
               "06.04. - 16.04."
    end
  end
end
