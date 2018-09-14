#!/usr/bin/env bash

# # __determine_script_variables()
#
# Automatically set magic variables as much as possible.
#
# There are circumstances where most, if not all, of these can fail and should not be depended upon.
#
# Reference: http://mywiki.wooledge.org/BashFAQ/028
#
# Global Variables:
# - `$0`:                    read  - filename (string)   - Name of shell script as set by the shell itself.
# - `$BASH_SOURCE[0]`:       read  - filename ([string]) - Source filenames corresponding to the elements in the FUNCNAME array variable.
# - `__is_main_script`:      write - if true (string)    - Determine if the script is running directly or sourced by another.
# - `__filename`:            write - filename (string)   - Script filename.
# - `__determine_directory`: write - path (string)       - Directory script is run from. Failable and potentially inaccurate in some cases.
# - `__full_path`:           write - path (string)       - Full path to script, is not set if `__determine_directory` is not set.
# - `__is_git_repo`:         write - if true (string)    - Is the script directory in a Git repository.
#
# shellcheck disable=SC2034
__determine_script_variables() {

	# Set __is_main_script.
	[[ "${BASH_SOURCE[0]:-}" != "${0:-}" ]] \
		|| __is_main_script="is_main_script"

	# Set __filename
	__filename="$(basename "${BASH_SOURCE[0]:-}")"

	# Set __determine_directory & __full_path if possible.
	if __determine_directory=$( __determine_directory ) && [[ "${__filename:-}" ]]; then
		__full_path="${__determine_directory}/${__filename}"
	else
		warning "Failed to determine script directory"
	fi

	# Set __is_git_repo if this is in a Git repo. Return true either way.
	if [[ $(git rev-parse --is-inside-work-tree)$? ]]; then
		__is_git_repo="is_git"
	else
		true
	fi

	# Set formatting variables
	__formatting_variables \
		|| Warning "Unable to generate text color & formatting variables."

}


# # __determine_directory()
#
# Tries to determine the script's directory and prints it if successful.
#
# Because this is not accurate in 100% of situations you should not depend on it, just use it contextually.
#
# Based on Dave Eddy's function:
# https://www.daveeddy.com/2015/04/13/dirname-case-study-for-bash-and-node/
#
# Global Variables:
# - `$BASH_SOURCE[0]`: read - filename ([string]) - Source filenames corresponding to the elements in the FUNCNAME array variable.
#
# Returns:
# - `0`: Function was able to determine directory, prints path for interpolating subshell.
# - `1`: `$BASH_SOURCE[0]` is empthy or doesn't exist.
# - `2`: `readlink` fails or returns empty.
#
__determine_directory() {
	local source=${BASH_SOURCE[0]}
	[[ ${source:-} ]] || return 1

	# resolve symlinks (of script)
	while [[ -L $source ]]; do
		local readlink

		# Check if readlink is available.
		__validate_commands --fail "warning" "readlink"

		# If readlink doesn't return a non-zero string return 1.
		if readlink=$(readlink "$source") || [[ "$readlink" ]]; then
			return 2
		fi

		# Since symlinks can be relative we need to check if the first character in the path is `/` (root) vs `../` (relative). If the symlink is relative we need set the path relative to the original bash source.
		if [[ ${readlink:0:1} = '/' ]]; then
				source=$readlink
		else
				source=$(dirname "$source")/$readlink
		fi
	done

	# Resolve the directory and output the path.
	( cd "$(dirname "$source")" && pwd )
}
