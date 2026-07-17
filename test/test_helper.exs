# Tests tagged :pdflatex need the pdflatex binary (LaTeX PDF generation).
# They are excluded automatically when it is not installed locally.
# CI always installs TeX Live, so these tests never skip there.
pdflatex_exclude = if System.find_executable("pdflatex"), do: [], else: [:pdflatex]

# Start ExUnit
ExUnit.start(exclude: [:skip] ++ pdflatex_exclude)

# Start Phoenix endpoint for system/browser tests
{:ok, _} = Application.ensure_all_started(:mehr_schulferien)

# Ecto sandbox for concurrent feature tests
Ecto.Adapters.SQL.Sandbox.mode(MehrSchulferien.Repo, :manual)
