#!/bin/sh

set -eu

default_base_url=https://raw.githubusercontent.com/hasit/gflow/main
base_url=${GFLOW_BASE_URL:-$default_base_url}
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

fetch() {
	source_path=$1
	destination=$2

	if [ -n "${GFLOW_SOURCE_DIR:-}" ]; then
		cp "$GFLOW_SOURCE_DIR/$source_path" "$destination"
	else
		command -v curl >/dev/null 2>&1 || die "curl is required"
		curl -fsSL "$base_url/$source_path" -o "$destination"
	fi
}

append_block() {
	file=$1
	block=$2
	marker_start="# >>> gflow >>>"
	marker_end="# <<< gflow <<<"

	mkdir -p "$(dirname "$file")"
	touch "$file"

	if grep -F "$marker_start" "$file" >/dev/null 2>&1; then
		return 0
	fi

	{
		printf '\n%s\n' "$marker_start"
		printf '%s\n' "$block"
		printf '%s\n' "$marker_end"
	} >>"$file"
}

install_executables() {
	mkdir -p "$install_dir"

	fetch bin/gflow "$tmp_dir/gflow"
	fetch bin/gdone "$tmp_dir/gdone"
	chmod 0755 "$tmp_dir/gflow"
	chmod 0755 "$tmp_dir/gdone"

	cp "$tmp_dir/gflow" "$install_dir/gflow"
	cp "$tmp_dir/gdone" "$install_dir/gdone"
	chmod 0755 "$install_dir/gflow" "$install_dir/gdone"
}

install_fish() {
	fish_config_dir=$config_home/fish

	mkdir -p "$fish_config_dir/conf.d" "$fish_config_dir/completions"
	fetch completions/gflow.fish "$fish_config_dir/completions/gflow.fish"
	fetch completions/gdone.fish "$fish_config_dir/completions/gdone.fish"

	cat >"$fish_config_dir/conf.d/gflow.fish" <<EOF
set -l gflow_install_dir "$install_dir"
if test -d "\$gflow_install_dir"
	if type -q fish_add_path
		fish_add_path -g "\$gflow_install_dir"
	else if not contains "\$gflow_install_dir" \$fish_user_paths
		set -U fish_user_paths "\$gflow_install_dir" \$fish_user_paths
	end
end
EOF

	log "installed Fish integration"
}

install_bash() {
	mkdir -p "$config_dir"
	fetch completions/gflow.bash "$config_dir/completion.bash"

	block="export PATH=\"$install_dir:\$PATH\"
[ -r \"$config_dir/completion.bash\" ] && . \"$config_dir/completion.bash\""

	append_block "${GFLOW_BASH_RC:-"$home_dir/.bashrc"}" "$block"

	if [ "$(uname -s 2>/dev/null || printf unknown)" = "Darwin" ]; then
		profile=${GFLOW_BASH_PROFILE:-"$home_dir/.bash_profile"}
		profile_block="[ -r \"\$HOME/.bashrc\" ] && . \"\$HOME/.bashrc\""
		append_block "$profile" "$profile_block"
	fi

	log "installed Bash integration"
}

install_zsh() {
	mkdir -p "$config_dir"
	fetch completions/gflow.zsh "$config_dir/completion.zsh"

	block="export PATH=\"$install_dir:\$PATH\"
autoload -Uz compinit
if ! whence -w compdef >/dev/null 2>&1; then
	compinit -i
fi
[ -r \"$config_dir/completion.zsh\" ] && . \"$config_dir/completion.zsh\""

	append_block "${GFLOW_ZSH_RC:-"$home_dir/.zshrc"}" "$block"

	log "installed Zsh integration"
}

install_posix_profile() {
	block="export PATH=\"$install_dir:\$PATH\""
	append_block "${GFLOW_PROFILE:-"$home_dir/.profile"}" "$block"
	log "installed PATH setup in .profile"
}

tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/gflow-install.XXXXXX") || die "could not create temp directory"
trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM

install_executables

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
	*)
		install_posix_profile
		log "unknown shell '${detected_shell:-unknown}', installed generic PATH setup"
		;;
esac

log "installed gflow to $install_dir"
log "restart your shell, then run: gflow help"
