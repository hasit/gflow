# gflow

Small Git branch workflow helpers:

```sh
gflow config prefix team/
gflow config base trunk
gflow config remote upstream
gflow new api-cleanup
gflow pr
gflow done team/api-cleanup
```

`gflow new <feature>` creates a prefixed feature branch from an updated base branch.
`gflow pr [branch]` pushes a feature branch, sets its upstream, and opens a
pull request page when the remote URL format is recognized.
`gflow done [branch]` switches back to the base branch, pulls, deletes the local
feature branch, and prunes the configured remote.

## Install

```sh
curl -fsSL https://hasit.github.io/gflow/install.sh | sh
```

The installer detects `$SHELL` and installs the matching shell integration:

- Fish: one file at `~/.config/fish/conf.d/gflow.fish`
- Zsh: one file at `~/.config/gflow/gflow.zsh`, sourced from
  `${ZDOTDIR:-$HOME}/.zshrc`
- Bash: one file at `~/.config/gflow/gflow.bash`, sourced from `~/.bashrc`,
  with `~/.bash_profile` sourcing `~/.bashrc` on macOS
- Other shells: a generic PATH setup in `~/.profile`

The `gflow` executable is installed to `~/.local/bin` by default.
The installer carries an embedded copy of the runtime files, so the one-line
install does not depend on a hard-coded hosting account after it is downloaded.

## Options

Installer options are set while running `install.sh`:

```sh
GFLOW_INSTALL_DIR="$HOME/bin" sh install.sh
GFLOW_SHELL=zsh sh install.sh
GFLOW_BASE_URL="https://example.com/gflow" sh install.sh
```

- `GFLOW_INSTALL_DIR` changes where the `gflow` executable is installed. The
  default is `~/.local/bin`; shell integration points at this directory.
- `GFLOW_SHELL` overrides shell detection. Use this when `$SHELL` is missing,
  points at a parent shell, or you want to install integration for `fish`,
  `zsh`, `bash`, or a generic `sh` PATH setup explicitly.
- `GFLOW_BASE_URL` makes the installer download live repo files instead of
  using the embedded copy. This is useful for forks, mirrors, or testing a
  branch before it is merged.

Repo settings are saved in local Git config:

```sh
gflow config prefix team/
gflow config base trunk
gflow config remote upstream
```

- `gflow config prefix [prefix]` stores `gflow.branch-prefix`.
- `gflow config base [branch]` stores `gflow.main-branch`. The default is `main`.
- `gflow config remote [remote]` stores `gflow.remote`. The default is `origin`.
- `gflow config` shows the effective repo settings.

Runtime variables override the repo settings for the command invocation where
they are set:

```sh
GFLOW_MAIN_BRANCH=trunk gflow new my-feature
GFLOW_REMOTE=upstream gflow done team/my-feature
```

- `GFLOW_MAIN_BRANCH` overrides `gflow.main-branch`.
- `GFLOW_REMOTE` overrides `gflow.remote`.

## Commands

```sh
gflow config [name] [value]  # show or set repo config
gflow new <feature>   # create <prefix><feature> from the remote base branch
gflow pr [branch]     # push branch upstream and open a pull request page
gflow done [branch]   # switch to base, pull, delete branch, prune remote
gflow help            # show usage
```
