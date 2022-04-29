defmodule MehrSchulferien.MixProject do
  use Mix.Project

  def project do
    [
      app: :mehr_schulferien,
      version: "3.3.26",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  def application do
    [
      mod: {MehrSchulferien.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.5.1"},
      {:phoenix_ecto, "~> 4.1"},
      {:ecto_sql, "~> 3.4"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.14"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.1"},
      {:bamboo, "~> 1.4"},
      {:bamboo_smtp, "~> 3.1.3"},
      {:phauxth, "~> 2.3"},
      {:argon2_elixir, "~> 2.3"},
      {:plug_cowboy, "~> 2.1"},
      {:ex_machina, "~> 2.4", only: :test},
      {:faker, "~> 0.16.0", only: :test},
      {:ecto_autoslug_field, "~> 2.0"},
      {:csv, "~> 2.3"},
      {:tzdata, "~> 1.0.3"},
      {:icalendar, "~> 1.0"}
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
