defmodule MehrSchulferien.MixProject do
  use Mix.Project

  def project do
    [
      app: :mehr_schulferien,
      version: "4.17.4",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      versioning: versioning(),
      listeners: [Phoenix.CodeReloader]
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
      {:claude, "~> 0.2", only: [:dev], runtime: false},
      {:usage_rules, "~> 0.1", only: [:dev]},
      {:phoenix, "~> 1.8.0"},
      {:phoenix_ecto, "~> 4.6.4"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.2"},
      {:phoenix_html_helpers, "~> 1.0"},
      {:phoenix_live_reload, "~> 1.4", only: :dev},
      {:phoenix_live_view, "~> 1.1.4"},
      {:phoenix_view, "~> 2.0"},
      {:floki, ">= 0.30.0", only: :test},
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.4.1"},
      {:gettext, "~> 1.0"},
      {:jason, "~> 1.4.0"},
      {:plug_cowboy, "~> 2.7"},
      {:ex_machina, "~> 2.8.0", only: :test},
      {:faker, "~> 0.17", only: :test},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:sitemap, "~> 1.0"},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false},
      {:ecto_autoslug_field, "~> 3.0"},
      {:req, "~> 0.5.10"},
      {:tidewave, "~> 0.5.0", only: :dev},
      {:ex_phone_number, "~> 0.4.8"},
      {:paper_trail, "~> 1.1.2"},
      {:swoosh, "~> 1.16"},
      {:gen_smtp, "~> 1.2"},
      {:hackney, "~> 1.9"},
      {:hermes_mcp, "~> 0.14.1"},
      {:tzdata, "~> 1.1"},
      {:mix_version, "~> 2.5.0"},
      {:mogrify, "~> 0.9.3"},
      {:resvg, "~> 0.5.0"},
      {:igniter, "~> 0.6", only: [:dev, :test]},
      {:csv, "~> 3.2"}
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
      "assets.deploy": [
        "tailwind production",
        "esbuild default --minify",
        "assets.copy",
        "phx.digest"
      ],
      "assets.copy": ["cmd cp -r assets/static/* priv/static/"]
    ]
  end

  defp versioning do
    [
      annotate: false
    ]
  end
end
