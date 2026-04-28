# gflow

Small Git branch workflow helpers:

```sh
gflow prefix hasit/
gflow new release-script
gflow done
gdone
```

`gflow new <feature>` creates a prefixed feature branch from an updated `main`.
`gflow done [branch]` switches back to `main`, pulls, deletes the local feature
branch, and prunes `origin`.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/hasit/gflow/main/install.sh | sh
```

The installer detects `$SHELL` and installs the matching shell integration:

- Fish: `~/.config/fish/conf.d/gflow.fish` plus Fish completions
- Zsh: `~/.zshrc` setup plus Zsh completions
- Bash: `~/.bashrc` setup plus Bash completions, with `~/.bash_profile`
  sourcing `~/.bashrc` on macOS

The executable scripts are installed to `~/.local/bin` by default.

## Options

```sh
GFLOW_INSTALL_DIR="$HOME/bin" sh install.sh
GFLOW_SHELL=fish sh install.sh
GFLOW_MAIN_BRANCH=trunk gflow new my-feature
GFLOW_REMOTE=upstream gflow done
```

## Commands

```sh
gflow prefix [prefix]  # show or set branch prefix
gflow new <feature>   # create <prefix><feature> from origin/main
gflow done [branch]   # switch to main, pull, delete branch, prune origin
gflow help            # show usage
gdone [branch]        # shortcut for gflow done [branch]
```
