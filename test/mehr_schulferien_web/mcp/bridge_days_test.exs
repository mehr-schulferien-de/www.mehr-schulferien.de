defmodule MehrSchulferienWeb.MCP.BridgeDaysTest do
  use MehrSchulferien.DataCase, async: false

  alias MehrSchulferienWeb.MCP.Server

  setup do
    # Create test data
    {:ok, country} =
      %MehrSchulferien.Locations.Location{}
      |> MehrSchulferien.Locations.Location.changeset(%{
        name: "Deutschland",
        slug: "deutschland",
        code: "DE",
        is_country: true
      })
      |> Repo.insert()

    {:ok, state} =
      %MehrSchulferien.Locations.Location{}
      |> MehrSchulferien.Locations.Location.changeset(%{
        name: "Bayern",
        slug: "bayern",
        code: "BY",
        is_federal_state: true,
        parent_location_id: country.id
      })
      |> Repo.insert()

    # Create a holiday or vacation type
    {:ok, holiday_type} =
      %MehrSchulferien.Calendars.HolidayOrVacationType{}
      |> MehrSchulferien.Calendars.HolidayOrVacationType.changeset(%{
        name: "Tag der Arbeit",
        slug: "tag-der-arbeit",
        colloquial: "Tag der Arbeit",
        html_class: "public_holiday",
        for_students: true,
        for_everybody: true,
        display_priority: 5,
        default_display_priority: 5,
        default_is_public_holiday: true,
        default_is_school_vacation: false,
        wikipedia_url: "https://de.wikipedia.org/wiki/Tag_der_Arbeit",
        country_location_id: country.id
      })
      |> Repo.insert()

    # Create a public holiday (May 1st, which typically creates a bridge day opportunity)
    year = Date.utc_today().year

    {:ok, holiday} =
      %MehrSchulferien.Periods.Period{}
      |> MehrSchulferien.Periods.Period.changeset(%{
        starts_on: Date.new!(year, 5, 1),
        ends_on: Date.new!(year, 5, 1),
        location_id: state.id,
        holiday_or_vacation_type_id: holiday_type.id,
        is_public_holiday: true,
        is_school_vacation: false,
        is_valid_for_students: false,
        is_valid_for_everybody: true,
        display_priority: 5,
        created_by_email_address: "test@example.com"
      })
      |> Repo.insert()

    # Create a frame
    frame = Hermes.Server.Frame.new()

    frame = %{
      frame
      | private: %{
          server_module: MehrSchulferienWeb.MCP.Server,
          server_registry: Hermes.Server.Registry,
          __mcp_components__: []
        }
    }

    {:ok, frame: frame, country: country, state: state, holiday: holiday, year: year}
  end

  describe "get_bridge_days tool" do
    test "returns bridge days for valid federal state and year", %{state: state, year: year} do
      frame = Hermes.Server.Frame.new()

      {:reply, result, _frame} =
        Server.handle_tool(
          "get_bridge_days",
          %{federal_state_slug: state.slug, year: year},
          frame
        )

      # Result should be a list
      assert is_list(result)

      # If there are bridge days, check their structure
      if length(result) > 0 do
        bridge_day = hd(result)

        # Check required fields
        assert Map.has_key?(bridge_day, :starts_on)
        assert Map.has_key?(bridge_day, :ends_on)
        assert Map.has_key?(bridge_day, :vacation_days_needed)
        assert Map.has_key?(bridge_day, :total_consecutive_free_days)
        assert Map.has_key?(bridge_day, :efficiency_percentage)

        # Check new fields (improved in this PR)
        assert Map.has_key?(bridge_day, :category)
        assert bridge_day.category in ["normal", "super"]

        assert Map.has_key?(bridge_day, :related_holidays)
        assert is_list(bridge_day.related_holidays)

        assert Map.has_key?(bridge_day, :timeline)
        assert is_map(bridge_day.timeline)
        assert Map.has_key?(bridge_day.timeline, :actual_starts_on)
        assert Map.has_key?(bridge_day.timeline, :actual_ends_on)
        assert Map.has_key?(bridge_day.timeline, :includes_weekends)

        # Check that dates are ISO-8601 formatted strings
        assert is_binary(bridge_day.starts_on)
        assert {:ok, _} = Date.from_iso8601(bridge_day.starts_on)

        # Check that related holidays have proper structure
        if length(bridge_day.related_holidays) > 0 do
          holiday = hd(bridge_day.related_holidays)
          assert Map.has_key?(holiday, :name)
          assert Map.has_key?(holiday, :starts_on)
          assert Map.has_key?(holiday, :ends_on)
          assert Map.has_key?(holiday, :is_public_holiday)
        end
      end
    end

    test "returns error for invalid federal state", %{year: year} do
      frame = Hermes.Server.Frame.new()

      {:error, message, _frame} =
        Server.handle_tool(
          "get_bridge_days",
          %{federal_state_slug: "nonexistent", year: year},
          frame
        )

      assert message =~ "not found"
    end

    test "bridge days have correct efficiency calculation", %{state: state, year: year} do
      frame = Hermes.Server.Frame.new()

      {:reply, result, _frame} =
        Server.handle_tool(
          "get_bridge_days",
          %{federal_state_slug: state.slug, year: year},
          frame
        )

      # Check efficiency calculation for each bridge day
      Enum.each(result, fn bridge_day ->
        vacation_days = bridge_day.vacation_days_needed
        total_free_days = bridge_day.total_consecutive_free_days
        efficiency = bridge_day.efficiency_percentage

        # Efficiency should be (total - vacation) / vacation * 100
        expected_efficiency = round((total_free_days - vacation_days) / vacation_days * 100)
        assert efficiency == expected_efficiency

        # Only bridge days with >100% efficiency should be included
        assert efficiency > 100
      end)
    end

    test "bridge days are sorted by efficiency descending", %{state: state, year: year} do
      frame = Hermes.Server.Frame.new()

      {:reply, result, _frame} =
        Server.handle_tool(
          "get_bridge_days",
          %{federal_state_slug: state.slug, year: year},
          frame
        )

      if length(result) > 1 do
        efficiencies = Enum.map(result, & &1.efficiency_percentage)
        sorted_efficiencies = Enum.sort(efficiencies, :desc)
        assert efficiencies == sorted_efficiencies
      end
    end

    test "timeline includes adjacent weekends correctly", %{state: state, year: year} do
      frame = Hermes.Server.Frame.new()

      {:reply, result, _frame} =
        Server.handle_tool(
          "get_bridge_days",
          %{federal_state_slug: state.slug, year: year},
          frame
        )

      # Check that timeline correctly identifies when weekends are included
      Enum.each(result, fn bridge_day ->
        actual_start = Date.from_iso8601!(bridge_day.timeline.actual_starts_on)
        actual_end = Date.from_iso8601!(bridge_day.timeline.actual_ends_on)
        bridge_start = Date.from_iso8601!(bridge_day.starts_on)
        bridge_end = Date.from_iso8601!(bridge_day.ends_on)

        # If actual dates differ from bridge dates, includes_weekends should be true
        includes_weekends = actual_start != bridge_start or actual_end != bridge_end
        assert bridge_day.timeline.includes_weekends == includes_weekends

        # Actual period should always be >= bridge period
        assert Date.compare(actual_start, bridge_start) != :gt
        assert Date.compare(actual_end, bridge_end) != :lt
      end)
    end

    test "categories are correctly assigned", %{state: state, year: year} do
      frame = Hermes.Server.Frame.new()

      {:reply, result, _frame} =
        Server.handle_tool(
          "get_bridge_days",
          %{federal_state_slug: state.slug, year: year},
          frame
        )

      # Check category assignment
      # normal = 1 vacation day, super = 2+ vacation days
      Enum.each(result, fn bridge_day ->
        if bridge_day.vacation_days_needed == 1 do
          assert bridge_day.category == "normal"
        else
          assert bridge_day.category == "super"
        end
      end)
    end
  end
end
