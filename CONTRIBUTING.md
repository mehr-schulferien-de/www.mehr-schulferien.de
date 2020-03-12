# Contributing to mehr-schulferien.de

The aim of this document is to help developers contribute to this project.

This document is a work-in-progress. If you feel that you can improve it,
please open an issue and let us know.

## Setup

1. Make sure you have the following programs installed:

    * Erlang > 21.1
    * Elixir > 1.8
    * nodejs > 6.8.0
    * postgresql

1. [Fork](https://help.github.com/articles/fork-a-repo/) the project, clone your fork,
and configure the remotes.

1. Create and migrate your database with `priv/repo/reset-db.sh` (this might take some time).

1. Install [pre-commit](https://pre-commit.com/) and run `pre-commit install`
in the root directory of the project.

## Tooling

We use the following tools in our development process.

### Pre-commit

After running `pre-commit install`, several pre-commit git hooks will be
added. These hooks perform certain checks when making a commit, and the
commit will not be made if any of these checks fail.

The configured checks are:

* tests check using `mix test`
* format check using `mix format --check-formatted`
* compilation using `mix compile --warnings-as-errors`
* trailing whitespace check
* merge conflict check
* yaml file check
* end of each file ends in a newline check
* a check that you are not committing to the v5, master, staging or production branch

If the end-of-file-fixer fails, run the commit again and it should pass
the second time.

## Pull requests

We recommend that you follow this guide, which is based on the
[Phoenix contributing guide](https://github.com/phoenixframework/phoenix/blob/master/CONTRIBUTING.md).

1. Choose an issue you want to work on and assign yourself to it.
(If a relevant issue does not exist yet, open the issue first and then assign
yourself to it).

1. Create a new topic branch (off of `v5`, which is the main branch for the 2020 version)
to work on the issue.

    **IMPORTANT**: making changes in `v5` is discouraged. You should always
    keep your local `v5` in sync with upstream `v5` and make your
    changes in topic branches.

    ```bash
    git checkout -b <topic-branch-name>
    ```

1. As you work on the issue, commit your changes in logical chunks.

1. Push your topic branch up to your fork:

    ```bash
    git push origin <topic-branch-name>
    ```

1. [Open a Pull Request](https://help.github.com/articles/about-pull-requests/)
with the following information (this should help the reviewer understand the
pull request better):

    * a clear, and informative, title
    * a description that references the issue(s) you have been working on
      * do not leave the description blank

1. Make sure that your topic branch is up-to-date. If necessary, rebase
on v5 and resolve any conflicts.

    **IMPORTANT**: _Never ever_ merge upstream `v5` into your branches. You
    should always `git rebase` on `v5` to bring your changes up to date when
    necessary.

    ```bash
    git checkout v5
    git pull upstream v5
    git checkout <your-topic-branch>
    git rebase v5
    ```
