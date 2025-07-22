defmodule MehrSchulferienWeb.WikiSchoolShowLive do
  use MehrSchulferienWeb, :live_view

  alias MehrSchulferien.{
    Locations,
    Periods,
    Wiki,
    Config
  }

  @impl true
  def mount(%{"slug" => school_slug}, _session, socket) do
    school = Locations.get_school_by_slug!(school_slug)

    # Get daily change count
    today = Date.utc_today()
    daily_changes = Wiki.get_daily_change_count(today)
    limit_reached = daily_changes >= Config.daily_change_limit()

    # Get bewegliche Ferientage count for the school
    bewegliche_ferientage_count = Periods.count_bewegliche_ferientage_for_school(school.id)

    {:ok,
     assign(socket,
       school: school,
       daily_changes: daily_changes,
       limit_reached: limit_reached,
       bewegliche_ferientage_count: bewegliche_ferientage_count
     )}
  end
end
