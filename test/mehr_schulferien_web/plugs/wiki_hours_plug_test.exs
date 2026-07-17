defmodule MehrSchulferienWeb.Plugs.WikiHoursPlugTest do
  # Not async: the tests flip global application env.
  use MehrSchulferienWeb.ConnCase

  alias MehrSchulferienWeb.Plugs.WikiHoursPlug

  setup do
    on_exit(fn -> Application.put_env(:mehr_schulferien, :wiki_hours_override, :open) end)
  end

  test "override :open keeps the wiki open regardless of the clock" do
    Application.put_env(:mehr_schulferien, :wiki_hours_override, :open)
    refute WikiHoursPlug.wiki_closed?()
  end

  test "override :closed closes the wiki" do
    Application.put_env(:mehr_schulferien, :wiki_hours_override, :closed)
    assert WikiHoursPlug.wiki_closed?()
  end

  test "the plug halts wiki requests with 403 while closed", %{conn: conn} do
    Application.put_env(:mehr_schulferien, :wiki_hours_override, :closed)

    conn = WikiHoursPlug.call(conn, [])

    assert conn.halted
    assert conn.status == 403
  end

  test "without an override the clock decides" do
    Application.delete_env(:mehr_schulferien, :wiki_hours_override)

    expected =
      WikiHoursPlug.current_berlin_time().hour >= 22 or
        WikiHoursPlug.current_berlin_time().hour < 6

    assert WikiHoursPlug.wiki_closed?() == expected
  end
end
