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
