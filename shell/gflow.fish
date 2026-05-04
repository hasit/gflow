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

function __fish_gflow_needs_command
	set -l tokens (commandline -opc)
	test (count $tokens) -eq 1
end

function __fish_gflow_using_command
	set -l tokens (commandline -opc)
	test (count $tokens) -ge 2
	and test "$tokens[2]" = "$argv[1]"
end

function __fish_gflow_needs_config_key
	set -l tokens (commandline -opc)
	test (count $tokens) -eq 2
	and test "$tokens[2]" = config
end

function __fish_gflow_config_value_for
	set -l tokens (commandline -opc)
	test (count $tokens) -eq 3
	and test "$tokens[2]" = config
	and test "$tokens[3]" = "$argv[1]"
end

function __fish_gflow_needs_branch
	set -l tokens (commandline -opc)
	test (count $tokens) -eq 2
	and contains -- "$tokens[2]" $argv
end

complete -c gflow -e

complete -c gflow -f
complete -c gflow -n '__fish_gflow_needs_command' -a config -d 'Show or set repo config'
complete -c gflow -n '__fish_gflow_needs_command' -a new -d 'Create a prefixed feature branch'
complete -c gflow -n '__fish_gflow_needs_command' -a pr -d 'Push a branch and open a PR'
complete -c gflow -n '__fish_gflow_needs_command' -a done -d 'Finish and delete a local feature branch'
complete -c gflow -n '__fish_gflow_needs_command' -a help -d 'Show usage'
complete -c gflow -n '__fish_gflow_needs_config_key' -f -a prefix -d 'Show or set branch prefix'
complete -c gflow -n '__fish_gflow_needs_config_key' -f -a base -d 'Show or set base branch'
complete -c gflow -n '__fish_gflow_needs_config_key' -f -a remote -d 'Show or set remote'
complete -c gflow -n '__fish_gflow_config_value_for prefix' -f -a 'team/' -d 'Branch prefix'
complete -c gflow -n '__fish_gflow_config_value_for base' -f -a '(__fish_gflow_all_local_branches)' -d 'Base branch'
complete -c gflow -n '__fish_gflow_config_value_for remote' -f -a '(__fish_gflow_remotes)' -d 'Remote'
complete -c gflow -n '__fish_gflow_needs_branch done pr' -f -a '(__fish_gflow_local_branches)' -d 'Local branch'
complete -c gflow -n '__fish_gflow_using_command new' -f
