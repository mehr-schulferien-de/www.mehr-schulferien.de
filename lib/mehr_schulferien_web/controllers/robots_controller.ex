defmodule MehrSchulferienWeb.RobotsController do
  use MehrSchulferienWeb, :controller

  alias MehrSchulferien.Periods
  alias MehrSchulferien.Calendars.DateHelpers

  def index(conn, params) do
    # Get today's date, either from params or using the helper
    today =
      case params["today"] do
        nil ->
          DateHelpers.today_berlin()

        date_string ->
          # Try to parse the date in DD.MM.YYYY format
          case parse_date(date_string) do
            {:ok, date} -> date
            _ -> DateHelpers.today_berlin()
          end
      end

    # Get current year from the determined date
    current_year = today.year
    next_year = current_year + 1

    # Get list of all years that have data (periods)
    all_years = Periods.list_years_with_periods()

    # Generate robots.txt content
    robots_content = generate_robots_txt(all_years, current_year, next_year)

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, robots_content)
  end

  # Parse date string in DD.MM.YYYY format
  defp parse_date(date_string) do
    # Try ISO format first (YYYY-MM-DD)
    case Date.from_iso8601(date_string) do
      {:ok, date} ->
        {:ok, date}

      _ ->
        # Try DD.MM.YYYY format
        case String.split(date_string, ".") do
          [day, month, year] ->
            with {day, _} <- Integer.parse(day),
                 {month, _} <- Integer.parse(month),
                 {year, _} <- Integer.parse(year) do
              Date.new(year, month, day)
            else
              _ -> {:error, :invalid_date}
            end

          _ ->
            {:error, :invalid_format}
        end
    end
  end

  defp generate_robots_txt(all_years, current_year, next_year) do
    # Base robots.txt content
    base_content = """
    # Hello Robot Overlords,
    #
    # Do feel free to crawl as fast as you want! No need to be polite.
    # We can handle it. Otherwise it will take ages to crawl through everything.
    #
    # In case you are not a search engine: We offer a JSON RESTful API.
    # Have a look at https://www.mehr-schulferien.de/developers for
    # more information.

    User-agent: *
    Disallow: /api
    Disallow: /users
    Disallow: /sessions
    Disallow: /password_resets
    Disallow: /admin

    # Allow only current year (#{current_year}) and next year (#{next_year}) for city and school pages
    """

    # Generate Disallow rules for all years except current and next
    disallow_rules =
      all_years
      |> Enum.filter(fn year -> year != current_year && year != next_year end)
      |> Enum.flat_map(fn year ->
        [
          "Disallow: /land/*/stadt/*/#{year}$",
          "Disallow: /land/*/schule/*/#{year}$"
        ]
      end)
      |> Enum.join("\n")

    # Combine base content with disallow rules
    base_content <> "\n" <> disallow_rules <> "\n"
  end
end
