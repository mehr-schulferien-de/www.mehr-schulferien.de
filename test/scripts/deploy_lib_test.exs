defmodule MehrSchulferien.Scripts.DeployLibTest do
  use ExUnit.Case, async: true

  # scripts/deploy.sh decides between a hot upgrade and a restart by comparing
  # release_fingerprint of the new build with the one of the running release.
  # A hot upgrade ships nothing but this application's modules, so the
  # fingerprint has to move with everything else a release is made of.
  @lib Path.expand("../../scripts/deploy_lib.sh", __DIR__)

  setup do
    repo = Path.join(System.tmp_dir!(), "deploy-lib-test-#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf!(repo) end)

    write(repo, "mix.exs", """
    def project do
      [
        app: :mehr_schulferien,
        version: "1.2.3",
        deps: deps()
      ]
    end
    """)

    write(repo, "mix.lock", "%{phoenix: 1}")
    write(repo, ".tool-versions", "elixir 1.19.5")
    write(repo, "config/prod.exs", "import Config")
    write(repo, "priv/repo/migrations/20250101000000_first.exs", "first")
    write(repo, "priv/templates/letter.tex.eex", "letter")
    write(repo, "priv/static/assets/app-0123abcd.css", "body{}")
    write(repo, "priv/static/cache_manifest.json", ~s({"mtime": 1}))
    write(repo, "priv/static/assets/app-0123abcd.css.gz", "gz1")
    write(repo, "_build/prod/lib/mehr_schulferien/ebin/Elixir.Some.beam", "some")
    write(repo, "lib/mehr_schulferien/some.ex", "defmodule Some do end")
    write(repo, "env", "SECRET=1")

    {:ok, repo: repo, fingerprint: fingerprint(repo)}
  end

  describe "release_fingerprint" do
    test "is stable for an unchanged build", %{repo: repo, fingerprint: fingerprint} do
      assert fingerprint =~ ~r/^[0-9a-f]{64}$/
      assert fingerprint(repo) == fingerprint
    end

    test "ignores what a hot upgrade ships or what changes with every build", %{
      repo: repo,
      fingerprint: fingerprint
    } do
      write(repo, "lib/mehr_schulferien/some.ex", "defmodule Some do def new, do: 1 end")

      write(
        repo,
        "mix.exs",
        File.read!(Path.join(repo, "mix.exs")) |> String.replace("1.2.3", "1.2.4")
      )

      write(repo, "priv/static/cache_manifest.json", ~s({"mtime": 2}))
      write(repo, "priv/static/assets/app-0123abcd.css.gz", "gz2")
      write(repo, "priv/static/cache/images/1.2.3-card.webp", "runtime cache")
      write(repo, "_build/prod/lib/mehr_schulferien/ebin/Elixir.Some.beam", "some, recompiled")

      assert fingerprint(repo) == fingerprint
    end

    for {what, path, content} <- [
          {"a dependency", "mix.lock", "%{phoenix: 2}"},
          {"the runtime versions", ".tool-versions", "elixir 1.20.0"},
          {"the config", "config/prod.exs", "import Config\nconfig :logger, level: :info"},
          {"a new migration", "priv/repo/migrations/20260101000000_second.exs", "second"},
          {"a file read at runtime", "priv/templates/letter.tex.eex", "new letter"},
          {"a static asset", "priv/static/assets/app-4567cdef.css", "body{color:red}"},
          {"the environment file", "env", "SECRET=2"}
        ] do
      test "moves with #{what}", %{repo: repo, fingerprint: fingerprint} do
        write(repo, unquote(path), unquote(content))

        assert fingerprint(repo) != fingerprint
      end
    end

    test "moves with the project settings in mix.exs", %{repo: repo, fingerprint: fingerprint} do
      write(repo, "mix.exs", File.read!(Path.join(repo, "mix.exs")) <> "\ndefp deps, do: []\n")

      assert fingerprint(repo) != fingerprint
    end

    test "fails without a build instead of fingerprinting half of one", %{repo: repo} do
      File.rm_rf!(Path.join(repo, "_build"))

      assert {output, status} = run(~s(release_fingerprint "#{repo}" "#{repo}/env"))
      assert status != 0
      refute output =~ ~r/^[0-9a-f]{64}$/m
    end

    test "fails when a file it was told to cover is missing", %{repo: repo} do
      assert {output, status} = run(~s(release_fingerprint "#{repo}" "#{repo}/no-such-env"))
      assert status != 0
      refute output =~ ~r/^[0-9a-f]{64}$/m
    end
  end

  defp fingerprint(repo) do
    {output, 0} = run(~s(release_fingerprint "#{repo}" "#{repo}/env"))
    String.trim(output)
  end

  defp run(command) do
    System.cmd("bash", ["-c", ~s(set -e; source "#{@lib}"; #{command})], stderr_to_stdout: true)
  end

  defp write(repo, path, content) do
    file = Path.join(repo, path)
    File.mkdir_p!(Path.dirname(file))
    File.write!(file, content)
  end
end
