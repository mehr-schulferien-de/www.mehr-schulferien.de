defmodule MehrSchulferien.MixProject do
  use Mix.Project

  def project do
    [
      app: :mehr_schulferien,
      version: "4.2.9",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
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
      {:phoenix, "~> 1.7.21"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_reload, "~> 1.4", only: :dev},
      {:phoenix_live_view, "~> 0.20.5"},
      {:phoenix_view, "~> 2.0"},
      {:floki, ">= 0.30.0", only: :test},
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2.2"},
      {:swoosh, "~> 1.15"},
      {:gen_smtp, "~> 1.2"},
      {:finch, "~> 0.18"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.24"},
      {:jason, "~> 1.4.0"},
      {:plug_cowboy, "~> 2.6"},
      {:ex_machina, "~> 2.7.0", only: :test},
      {:faker, "~> 0.17", only: :test},
      {:timex, "~> 3.7.11"},
      {:ex_ical, "~> 0.2.0"},
      {:sitemap, "~> 1.0"},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:ecto_autoslug_field, "~> 3.0"},
      {:icalendar, "~> 1.1.0"},
      {:slugger, "~> 0.3"},
      {:req, "~> 0.5.10"},
      {:tidewave, "~> 0.1.6", only: :dev},
      {:ex_phone_number, "~> 0.4.5"},
      {:paper_trail, "~> 1.0.0"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind default", "esbuild default"],
      "assets.deploy": ["tailwind default", "esbuild default --minify", "phx.digest"]
    ]
  end
end
