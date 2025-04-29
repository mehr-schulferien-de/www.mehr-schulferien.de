defmodule MehrSchulferienWeb.FeatureCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Wallaby.Feature

      import MehrSchulferien.Factory
      import Wallaby.Query

      alias MehrSchulferienWeb.Router.Helpers, as: Routes

      @endpoint MehrSchulferienWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(MehrSchulferien.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(MehrSchulferien.Repo, {:shared, self()})
    end

    metadata = Phoenix.Ecto.SQL.Sandbox.metadata_for(MehrSchulferien.Repo, self())
    {:ok, session} = Wallaby.start_session(metadata: metadata)
    {:ok, session: session}
  end
end
