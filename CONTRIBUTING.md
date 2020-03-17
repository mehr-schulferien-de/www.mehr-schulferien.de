# Contributing to mehr-schulferien.de

This document aims to help developers contribute to this project.

This document is a work-in-progress. If you feel that you can improve it,
please open an issue and let us know.

## Setup

1. Make sure you have the following programs installed:

    * Erlang > 22
    * Elixir > 1.9
    * nodejs > 6.8.0
    * postgresql

1. Clone this repository (do not create a fork, as pull requests from forks
are not being handled properly by Github actions).

1. Create and migrate your database with `priv/repo/reset-db.sh` (this might take some time).

1. Install [pre-commit](https://pre-commit.com/) and run `pre-commit install`
in the root directory of the project.

## Tooling

We use the following tool in our development process.

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
* a check that you are not committing to the master, staging or production branch

If the end-of-file-fixer fails, run the commit again and it should pass
the second time.

## Pull requests

We recommend that you follow this guide, which has been adapted from the
[Phoenix contributing guide](https://github.com/phoenixframework/phoenix/blob/master/CONTRIBUTING.md).

1. Choose an issue you want to work on and assign yourself to it.
(If a relevant issue does not exist yet, open the issue first and then assign
yourself to it).

1. Create a new topic branch (off of `master`) to work on the issue.
Give the topic branch a meaningful name and prefix the name with your Github username
and a forward slash (for example, `riverrun/update_readme`).

    **IMPORTANT**: do not make changes in `master`.

    ```bash
    git checkout -b <topic-branch-name>
    ```

1. As you work on the issue, commit your changes in logical chunks.

1. Push your topic branch:

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
on master and resolve any conflicts.

    **IMPORTANT**: Do not merge `master` into your branches. You should
    always `git rebase` on `master` to bring your changes up to date when necessary.

    ```bash
    git checkout master
    git pull origin master
    git checkout <your-topic-branch>
    git rebase master
    ```
