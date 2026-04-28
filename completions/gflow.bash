_gflow_local_branches() {
	git for-each-ref --format='%(refname:short)' refs/heads/ 2>/dev/null |
		grep -v -E '^(main|master|develop)$'
}

_gflow_complete() {
	local cur command

	cur=${COMP_WORDS[COMP_CWORD]}
	command=${COMP_WORDS[0]##*/}

	if [ "$command" = "gdone" ]; then
		COMPREPLY=($(compgen -W "$(_gflow_local_branches)" -- "$cur"))
		return 0
	fi

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

complete -F _gflow_complete gflow
complete -F _gflow_complete gdone
