if not functions -q __fish_gflow_local_branches
	function __fish_gflow_local_branches
		command git for-each-ref --format='%(refname:short)' refs/heads/ 2>/dev/null | command grep -v -E '^(main|master|develop)$'
	end
end

complete -c gdone -e
complete -c gdone -f -a '(__fish_gflow_local_branches)' -d 'Local branch to delete after switching to main'
