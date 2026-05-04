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

_gflow_all_local_branches() {
	git for-each-ref --format='%(refname:short)' refs/heads/ 2>/dev/null
}

_gflow_remotes() {
	git remote 2>/dev/null
}

_gflow() {
	local context state line
	typeset -A opt_args

	_arguments -C \
		'1:command:((config\:Show\ or\ set\ repo\ config new\:Create\ a\ prefixed\ feature\ branch pr\:Push\ a\ branch\ and\ open\ a\ PR done\:Finish\ and\ delete\ a\ local\ feature\ branch help\:Show\ usage))' \
		'*::arg:->args'

	case $state in
		args)
			case ${line[1]} in
				config)
					case ${line[2]} in
						base)
							_arguments '3:branch:($(_gflow_all_local_branches))'
							;;
						remote)
							_arguments '3:remote:($(_gflow_remotes))'
							;;
						prefix)
							_message 'branch prefix'
							;;
						*)
							_arguments '2:setting:((prefix\:Show\ or\ set\ branch\ prefix base\:Show\ or\ set\ base\ branch remote\:Show\ or\ set\ remote))'
							;;
					esac
					;;
				done|pr)
					_arguments '2:branch:($(_gflow_local_branches))'
					;;
				new)
					_message 'feature name'
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
