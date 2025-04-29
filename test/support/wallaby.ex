defmodule MehrSchulferienWeb.Wallaby do
  use Wallaby.DSL

  def start_session do
    {:ok, session} = Wallaby.start_session()
    session
  end
end
