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

_gflow_all_local_branches() {
	git for-each-ref --format='%(refname:short)' refs/heads/ 2>/dev/null
}

_gflow_remotes() {
	git remote 2>/dev/null
}

_gflow_complete() {
	local cur

	cur=${COMP_WORDS[COMP_CWORD]}

	if [ "$COMP_CWORD" -eq 1 ]; then
		COMPREPLY=($(compgen -W "config new pr done help" -- "$cur"))
		return 0
	fi

	case ${COMP_WORDS[1]} in
		config)
			if [ "$COMP_CWORD" -eq 2 ]; then
				COMPREPLY=($(compgen -W "prefix base remote" -- "$cur"))
				return 0
			fi

			case ${COMP_WORDS[2]} in
				base)
					COMPREPLY=($(compgen -W "$(_gflow_all_local_branches)" -- "$cur"))
					;;
				remote)
					COMPREPLY=($(compgen -W "$(_gflow_remotes)" -- "$cur"))
					;;
				prefix)
					COMPREPLY=()
					;;
				*)
					COMPREPLY=()
					;;
			esac
			;;
		done|pr)
			COMPREPLY=($(compgen -W "$(_gflow_local_branches)" -- "$cur"))
			;;
		new)
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
