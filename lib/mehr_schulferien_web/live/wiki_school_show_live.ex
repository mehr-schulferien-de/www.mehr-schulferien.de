defmodule MehrSchulferienWeb.WikiSchoolShowLive do
  use MehrSchulferienWeb, :live_view

  on_mount {MehrSchulferienWeb.WikiAuth, :require_auth}

  alias MehrSchulferien.{
    Blacklist,
    Config,
    Locations,
    Periods,
    Wiki
  }

  @impl true
  def mount(%{"slug" => school_slug}, _session, socket) do
    school = Locations.get_school_by_slug!(school_slug)

    # Filter blacklisted data from school address before display
    school = filter_blacklisted_address(school)

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
       bewegliche_ferientage_count: bewegliche_ferientage_count,
       school_contact_info_enabled: Config.school_contact_info_enabled?()
     )}
  end

  # Filters blacklisted fields from school's address
  defp filter_blacklisted_address(%{address: address} = school) when not is_nil(address) do
    filtered_address = Blacklist.filter_address(address)
    %{school | address: filtered_address}
  end

  defp filter_blacklisted_address(school), do: school
end
