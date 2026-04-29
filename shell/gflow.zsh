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

gdone() {
	command gflow done "$@"
}

_gflow_local_branches() {
	git for-each-ref --format='%(refname:short)' refs/heads/ 2>/dev/null |
		grep -v -E '^(main|master|develop)$'
}

_gflow() {
	local context state line
	typeset -A opt_args

	if [[ "${service:-}" == "gdone" ]]; then
		_arguments '1:branch:($(_gflow_local_branches))'
		return
	fi

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
	compdef _gflow gdone
fi
