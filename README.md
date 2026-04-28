# gflow

Small Git branch workflow helpers:

```sh
gflow prefix team/
gflow new release-script
gflow done
gdone
```

`gflow new <feature>` creates a prefixed feature branch from an updated `main`.
`gflow done [branch]` switches back to `main`, pulls, deletes the local feature
branch, and prunes `origin`.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/<owner>/gflow/main/install.sh | sh
```

The installer detects `$SHELL` and installs the matching shell integration:

- Fish: `~/.config/fish/conf.d/gflow.fish` plus Fish completions
- Zsh: `~/.zshrc` setup plus Zsh completions
- Bash: `~/.bashrc` setup plus Bash completions, with `~/.bash_profile`
  sourcing `~/.bashrc` on macOS

The executable scripts are installed to `~/.local/bin` by default.
The installer carries an embedded copy of the runtime files, so the one-line
install does not depend on a hard-coded repository owner after it is downloaded.

## Options

Installer options are set while running `install.sh`:

```sh
GFLOW_INSTALL_DIR="$HOME/bin" sh install.sh
GFLOW_SHELL=zsh sh install.sh
GFLOW_BASE_URL="https://raw.githubusercontent.com/<owner>/gflow/main" sh install.sh
```

- `GFLOW_INSTALL_DIR` changes where `gflow` and `gdone` are installed. The
  default is `~/.local/bin`.
- `GFLOW_SHELL` overrides shell detection. Use this when `$SHELL` is missing,
  points at a parent shell, or you want to install integration for `fish`,
  `zsh`, or `bash` explicitly.
- `GFLOW_BASE_URL` makes the installer download live repo files instead of
  using the embedded copy. This is useful for forks, mirrors, or testing a
  branch before it is merged.

Runtime options are set when running `gflow`:

```sh
GFLOW_MAIN_BRANCH=trunk gflow new my-feature
GFLOW_REMOTE=upstream gflow done team/my-feature
```

- `GFLOW_MAIN_BRANCH` changes the base branch used by `gflow new` and
  `gflow done`. The default is `main`.
- `GFLOW_REMOTE` changes the Git remote used for pulls, remote-branch checks,
  and pruning. The default is `origin`.

## Commands

```sh
gflow prefix [prefix]  # show or set branch prefix
gflow new <feature>   # create <prefix><feature> from origin/main
gflow done [branch]   # switch to main, pull, delete branch, prune origin
gflow help            # show usage
gdone [branch]        # shortcut for gflow done [branch]
```
