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

function __fish_gflow_all_local_branches
	command git for-each-ref --format='%(refname:short)' refs/heads/ 2>/dev/null
end

function __fish_gflow_remotes
	command git remote 2>/dev/null
end

complete -c gflow -e

complete -c gflow -f
complete -c gflow -n 'not __fish_seen_subcommand_from config new pr done help' -a config -d 'Show or set repo config'
complete -c gflow -n 'not __fish_seen_subcommand_from config new pr done help' -a new -d 'Create a prefixed feature branch'
complete -c gflow -n 'not __fish_seen_subcommand_from config new pr done help' -a pr -d 'Push a branch and open a PR'
complete -c gflow -n 'not __fish_seen_subcommand_from config new pr done help' -a done -d 'Finish and delete a local feature branch'
complete -c gflow -n 'not __fish_seen_subcommand_from config new pr done help' -a help -d 'Show usage'
complete -c gflow -n '__fish_seen_subcommand_from config; and not __fish_seen_subcommand_from prefix base remote' -f -a prefix -d 'Show or set branch prefix'
complete -c gflow -n '__fish_seen_subcommand_from config; and not __fish_seen_subcommand_from prefix base remote' -f -a base -d 'Show or set base branch'
complete -c gflow -n '__fish_seen_subcommand_from config; and not __fish_seen_subcommand_from prefix base remote' -f -a remote -d 'Show or set remote'
complete -c gflow -n '__fish_seen_subcommand_from config; and __fish_seen_subcommand_from prefix' -f -a 'team/' -d 'Branch prefix'
complete -c gflow -n '__fish_seen_subcommand_from config; and __fish_seen_subcommand_from base' -f -a '(__fish_gflow_all_local_branches)' -d 'Base branch'
complete -c gflow -n '__fish_seen_subcommand_from config; and __fish_seen_subcommand_from remote' -f -a '(__fish_gflow_remotes)' -d 'Remote'
complete -c gflow -n '__fish_seen_subcommand_from done' -f -a '(__fish_gflow_local_branches)' -d 'Local branch to delete after switching to main'
complete -c gflow -n '__fish_seen_subcommand_from pr' -f -a '(__fish_gflow_local_branches)' -d 'Local branch to push'
complete -c gflow -n '__fish_seen_subcommand_from new' -f
