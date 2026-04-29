#!/bin/sh

set -eu

home_dir=${HOME:-}
if [ -z "$home_dir" ]; then
	printf '%s\n' "gflow: HOME is required" >&2
	exit 1
fi

install_dir=${GFLOW_INSTALL_DIR:-"$home_dir/.local/bin"}
config_home=${XDG_CONFIG_HOME:-"$home_dir/.config"}
config_dir=$config_home/gflow
detected_shell=${GFLOW_SHELL:-}
if [ -z "$detected_shell" ] && [ -n "${SHELL:-}" ]; then
	detected_shell=${SHELL##*/}
fi

log() {
	printf '%s\n' "gflow: $*"
}

die() {
	printf '%s\n' "gflow: $*" >&2
	exit 1
}

write_embedded() {
	source_path=$1
	destination=$2

	case $source_path in
		bin/gflow)
			cat >"$destination" <<'GFLOW_BIN'
#!/bin/sh

set -u

main_branch=${GFLOW_MAIN_BRANCH:-main}
remote=${GFLOW_REMOTE:-origin}

usage() {
	cat <<'EOF'
Usage:
  gflow prefix [prefix]
  gflow new <feature>
  gflow done [branch]
  gflow help
EOF
}

die() {
	printf '%s\n' "gflow: $*" >&2
	exit 1
}

if [ -n "${XDG_CONFIG_HOME:-}" ]; then
	config_home=$XDG_CONFIG_HOME
elif [ -n "${HOME:-}" ]; then
	config_home=$HOME/.config
else
	die "HOME or XDG_CONFIG_HOME is required"
fi

config_dir=$config_home/gflow
config_file=$config_dir/config

normalize_prefix() {
	prefix=$1

	if [ -z "$prefix" ]; then
		printf '\n'
		return 0
	fi

	case $prefix in
		*/)
			printf '%s\n' "$prefix"
			;;
		*)
			printf '%s/\n' "$prefix"
			;;
	esac
}

is_protected_branch() {
	case $1 in
		main|master|develop)
			return 0
			;;
	esac

	return 1
}

require_git_repo() {
	command git rev-parse --is-inside-work-tree >/dev/null 2>&1 ||
		die "not inside a git repo"
}

require_clean_worktree() {
	if [ -n "$(command git status --porcelain)" ]; then
		die "working tree has uncommitted changes; commit or stash them first"
	fi
}

read_prefix() {
	if [ ! -r "$config_file" ]; then
		return 1
	fi

	while IFS='=' read -r key value; do
		if [ "$key" = "branch_prefix" ]; then
			printf '%s\n' "$value"
			return 0
		fi
	done <"$config_file"

	return 1
}

write_prefix() {
	prefix=$1

	mkdir -p "$config_dir" || die "could not create $config_dir"
	tmp_file=$config_file.tmp.$$

	if ! printf 'branch_prefix=%s\n' "$prefix" >"$tmp_file"; then
		rm -f "$tmp_file"
		die "could not write $config_file"
	fi

	mv "$tmp_file" "$config_file" || die "could not update $config_file"
}

prefix_command() {
	if [ "$#" -eq 0 ]; then
		prefix=$(read_prefix) || die "no branch prefix set; run: gflow prefix team/"
		printf '%s\n' "$prefix"
		return 0
	fi

	if [ "$#" -gt 1 ]; then
		die "prefix accepts at most one argument"
	fi

	prefix=$(normalize_prefix "$1")
	if [ -z "$prefix" ]; then
		die "prefix cannot be empty"
	fi

	command git check-ref-format --branch "${prefix}__gflow_test" >/dev/null 2>&1 ||
		die "invalid branch prefix '$prefix'"

	write_prefix "$prefix"
	printf '%s\n' "gflow: branch prefix set to $prefix"
}

target_branch() {
	feature=$1
	prefix=$(read_prefix) || die "no branch prefix set; run: gflow prefix team/"
	prefix=$(normalize_prefix "$prefix")

	case $feature in
		"$prefix"*)
			printf '%s\n' "$feature"
			;;
		*)
			printf '%s%s\n' "$prefix" "$feature"
			;;
	esac
}

new_command() {
	require_git_repo

	if [ "$#" -ne 1 ]; then
		die "usage: gflow new <feature>"
	fi

	target=$(target_branch "$1")

	if is_protected_branch "$target"; then
		die "refusing to create protected branch $target"
	fi

	command git check-ref-format --branch "$target" >/dev/null 2>&1 ||
		die "invalid branch name '$target'"

	require_clean_worktree

	if command git show-ref --verify --quiet "refs/heads/$target"; then
		die "local branch '$target' already exists"
	fi

	if command git show-ref --verify --quiet "refs/remotes/$remote/$target"; then
		die "remote branch '$remote/$target' already exists"
	fi

	printf '%s\n' "gflow: creating $target from $remote/$main_branch"

	command git switch "$main_branch" || exit $?
	command git pull --ff-only "$remote" "$main_branch" || exit $?
	command git switch -c "$target"
}

done_command() {
	require_git_repo

	if [ "$#" -gt 1 ]; then
		die "usage: gflow done [branch]"
	fi

	if [ "$#" -eq 1 ]; then
		branch=$1
	else
		branch=$(command git branch --show-current 2>/dev/null)
	fi

	if [ -z "$branch" ]; then
		die "could not determine current branch; pass one, e.g. gflow done team/my-feature"
	fi

	if is_protected_branch "$branch"; then
		die "refusing to delete protected branch $branch"
	fi

	require_clean_worktree

	printf '%s\n' "gflow: finishing $branch"

	command git switch "$main_branch" || exit $?
	command git pull --ff-only "$remote" "$main_branch" || exit $?

	if command git show-ref --verify --quiet "refs/heads/$branch"; then
		command git branch -D -- "$branch" || exit $?
	else
		printf '%s\n' "gflow: no local branch $branch to delete"
	fi

	command git fetch --prune "$remote"
}

subcommand=${1:-help}
if [ "$#" -gt 0 ]; then
	shift
fi

case $subcommand in
	prefix)
		prefix_command "$@"
		;;
	new)
		new_command "$@"
		;;
	done)
		done_command "$@"
		;;
	help|-h|--help)
		usage
		;;
	*)
		printf '%s\n' "gflow: unknown command '$subcommand'" >&2
		usage >&2
		exit 1
		;;
esac
GFLOW_BIN
			;;
		shell/gflow.bash)
			cat >"$destination" <<'GFLOW_BASH'
# gflow shell integration for Bash. Source from ~/.bashrc.

_gflow_install_dir="@GFLOW_INSTALL_DIR@"
case ":$PATH:" in
	*":$_gflow_install_dir:"*)
		;;
	*)
		PATH="$_gflow_install_dir:$PATH"
		export PATH
		;;
esac
unset _gflow_install_dir

_gflow_local_branches() {
	git for-each-ref --format='%(refname:short)' refs/heads/ 2>/dev/null |
		grep -v -E '^(main|master|develop)$'
}

_gflow_complete() {
	local cur

	cur=${COMP_WORDS[COMP_CWORD]}

	if [ "$COMP_CWORD" -eq 1 ]; then
		COMPREPLY=($(compgen -W "prefix new done help" -- "$cur"))
		return 0
	fi

	case ${COMP_WORDS[1]} in
		done)
			COMPREPLY=($(compgen -W "$(_gflow_local_branches)" -- "$cur"))
			;;
		new|prefix)
			COMPREPLY=()
			;;
		*)
			COMPREPLY=()
			;;
	esac
}

if command -v complete >/dev/null 2>&1; then
	complete -F _gflow_complete gflow
fi
GFLOW_BASH
			;;
		shell/gflow.fish)
			cat >"$destination" <<'GFLOW_FISH'
# gflow shell integration for Fish. Loaded from conf.d.

set -l gflow_install_dir "@GFLOW_INSTALL_DIR@"
if test -d "$gflow_install_dir"
	if type -q fish_add_path
		fish_add_path -g "$gflow_install_dir"
	else if not contains "$gflow_install_dir" $fish_user_paths
		set -U fish_user_paths "$gflow_install_dir" $fish_user_paths
	end
end

function __fish_gflow_local_branches
	command git for-each-ref --format='%(refname:short)' refs/heads/ 2>/dev/null | command grep -v -E '^(main|master|develop)$'
end

complete -c gflow -e

complete -c gflow -f
complete -c gflow -n 'not __fish_seen_subcommand_from prefix new done help' -a prefix -d 'Show or set branch prefix'
complete -c gflow -n 'not __fish_seen_subcommand_from prefix new done help' -a new -d 'Create a prefixed feature branch from main'
complete -c gflow -n 'not __fish_seen_subcommand_from prefix new done help' -a done -d 'Finish and delete a local feature branch'
complete -c gflow -n 'not __fish_seen_subcommand_from prefix new done help' -a help -d 'Show usage'
complete -c gflow -n '__fish_seen_subcommand_from prefix' -f -a 'team/' -d 'Branch prefix'
complete -c gflow -n '__fish_seen_subcommand_from done' -f -a '(__fish_gflow_local_branches)' -d 'Local branch to delete after switching to main'
complete -c gflow -n '__fish_seen_subcommand_from new' -f
GFLOW_FISH
			;;
		shell/gflow.zsh)
			cat >"$destination" <<'GFLOW_ZSH'
# gflow shell integration for Zsh. Source from ~/.zshrc or $ZDOTDIR/.zshrc.

_gflow_install_dir="@GFLOW_INSTALL_DIR@"
case ":$PATH:" in
	*":$_gflow_install_dir:"*)
		;;
	*)
		PATH="$_gflow_install_dir:$PATH"
		export PATH
		;;
esac
unset _gflow_install_dir

_gflow_local_branches() {
	git for-each-ref --format='%(refname:short)' refs/heads/ 2>/dev/null |
		grep -v -E '^(main|master|develop)$'
}

_gflow() {
	local context state line
	typeset -A opt_args

	_arguments -C \
		'1:command:((prefix\:Show\ or\ set\ branch\ prefix new\:Create\ a\ prefixed\ feature\ branch\ from\ main done\:Finish\ and\ delete\ a\ local\ feature\ branch help\:Show\ usage))' \
		'*::arg:->args'

	case $state in
		args)
			case ${line[1]} in
				done)
					_arguments '2:branch:($(_gflow_local_branches))'
					;;
				new)
					_message 'feature name'
					;;
				prefix)
					_message 'branch prefix'
					;;
			esac
			;;
	esac
}

autoload -Uz compinit
if ! whence -w compdef >/dev/null 2>&1; then
	compinit -i
fi

if whence -w compdef >/dev/null 2>&1; then
	compdef _gflow gflow
fi
GFLOW_ZSH
			;;
		*)
			die "no embedded source for $source_path"
			;;
	esac
}

fetch() {
	source_path=$1
	destination=$2

	if [ -n "${GFLOW_SOURCE_DIR:-}" ]; then
		cp "$GFLOW_SOURCE_DIR/$source_path" "$destination"
	elif [ -n "${GFLOW_BASE_URL:-}" ]; then
		command -v curl >/dev/null 2>&1 || die "curl is required"
		curl -fsSL "$GFLOW_BASE_URL/$source_path" -o "$destination"
	else
		write_embedded "$source_path" "$destination"
	fi
}

render_integration() {
	render_source_path=$1
	render_destination=$2
	render_source_file=$tmp_dir/$(basename "$render_source_path")
	render_escaped_install_dir=$(printf '%s' "$install_dir" | sed 's/[&|]/\\&/g')

	fetch "$render_source_path" "$render_source_file"
	sed "s|@GFLOW_INSTALL_DIR@|$render_escaped_install_dir|g" "$render_source_file" >"$render_destination"
}

append_block() {
	file=$1
	block=$2
	marker_start="# >>> gflow >>>"
	marker_end="# <<< gflow <<<"
	block_file=$tmp_dir/rc-block.$$

	mkdir -p "$(dirname "$file")"
	touch "$file"

	if grep -F "$marker_start" "$file" >/dev/null 2>&1; then
		awk -v start="$marker_start" -v end="$marker_end" -v block="$block" '
			$0 == start {
				print start
				line_count = split(block, lines, "\n")
				for (line = 1; line <= line_count; line++) {
					print lines[line]
				}
				print end
				in_block = 1
				next
			}
			$0 == end && in_block {
				in_block = 0
				next
			}
			!in_block {
				print
			}
		' "$file" >"$block_file" || die "could not update $file"
		cat "$block_file" >"$file" || die "could not replace $file"
		rm -f "$block_file"
		return 0
	fi

	{
		printf '\n%s\n' "$marker_start"
		printf '%s\n' "$block"
		printf '%s\n' "$marker_end"
	} >>"$file"
}

install_executable() {
	mkdir -p "$install_dir"

	fetch bin/gflow "$tmp_dir/gflow"
	chmod 0755 "$tmp_dir/gflow"

	cp "$tmp_dir/gflow" "$install_dir/gflow"
	chmod 0755 "$install_dir/gflow"
}

cleanup_legacy_files() {
	if [ ! -d "$install_dir/gdone" ]; then
		rm -f "$install_dir/gdone"
	fi

	rm -f \
		"$config_home/fish/completions/gflow.fish" \
		"$config_home/fish/completions/gdone.fish" \
		"$config_dir/completion.bash" \
		"$config_dir/completion.zsh"
}

install_fish() {
	fish_conf_dir=$config_home/fish/conf.d

	mkdir -p "$fish_conf_dir"
	render_integration shell/gflow.fish "$fish_conf_dir/gflow.fish"

	log "installed Fish integration to $fish_conf_dir/gflow.fish"
}

install_bash() {
	integration_file=$config_dir/gflow.bash

	mkdir -p "$config_dir"
	render_integration shell/gflow.bash "$integration_file"

	block="[ -r \"$integration_file\" ] && . \"$integration_file\""
	append_block "${GFLOW_BASH_RC:-"$home_dir/.bashrc"}" "$block"

	if [ "$(uname -s 2>/dev/null || printf unknown)" = "Darwin" ]; then
		profile=${GFLOW_BASH_PROFILE:-"$home_dir/.bash_profile"}
		profile_block="[ -r \"\$HOME/.bashrc\" ] && . \"\$HOME/.bashrc\""
		append_block "$profile" "$profile_block"
	fi

	log "installed Bash integration to $integration_file"
}

install_zsh() {
	integration_file=$config_dir/gflow.zsh
	zsh_dot_dir=${ZDOTDIR:-$home_dir}

	mkdir -p "$config_dir"
	render_integration shell/gflow.zsh "$integration_file"

	block="[ -r \"$integration_file\" ] && . \"$integration_file\""
	append_block "${GFLOW_ZSH_RC:-"$zsh_dot_dir/.zshrc"}" "$block"

	log "installed Zsh integration to $integration_file"
}

install_posix_profile() {
	block="export PATH=\"$install_dir:\$PATH\""
	append_block "${GFLOW_PROFILE:-"$home_dir/.profile"}" "$block"
	log "installed generic PATH setup in .profile"
}

tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/gflow-install.XXXXXX") || die "could not create temp directory"
trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM

install_executable
cleanup_legacy_files

case $detected_shell in
	fish)
		install_fish
		;;
	bash)
		install_bash
		;;
	zsh)
		install_zsh
		;;
	sh|dash|ksh|ash)
		install_posix_profile
		;;
	*)
		install_posix_profile
		log "unknown shell '${detected_shell:-unknown}', installed generic PATH setup"
		;;
esac

log "installed gflow to $install_dir/gflow"
log "restart your shell, then run: gflow help"
