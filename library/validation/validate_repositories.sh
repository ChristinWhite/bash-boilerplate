#!/usr/bin/env bash

# ### __validate_repositories()
#
# Validates that the repository URLs exists and can be cloned.
#
# Options:
# - `-f` or `--fail` [arg]: optional (default: `error`) - Set log level by name if validation fails.
# - `-p` or `--pass` [arg]: optional (default: `debug`) - Set log level by name if validation succeeds.
# - `-r` or `--required`:   optional (default: false)   - If required `exit`, otherwise `return`
# - `-s` or `--silent`:     optional (default: false)   - Supress log, only return exit code.
#
# Parameters:
# - `$1`: `$repository` - url (string) - required - HTTPS or SSH URL to clone.
#
# Returns:
# - `0`: Repository URL was found and is able to be cloned.
# - `1`: Repository URL was not found or could not be cloned.
# - `2`: `git` command not available. If --required `exit`.
#
__validate_repositories() {
	# Parse options
	local pass fail
	while :; do
		case "${1:-}" in
			-f | --fail)
				local fail="${2}"
				shift 2
				;;
			-p | --pass)
				local pass="${2}"
				shift 2
				;;
			-r | --required)
				local required="required"
				shift
				;;
			-s | --silent)
				local silent="silent"
				shift
				;;
			--) # End of options
				shift
				break;
				;;
			-*) # Unknown option
				error "\"${1}\" is an unknown option."
				return 1
				;;
			*) # No more options
				break
				;;
		esac
	done

	# Set defaults
	[[ "${fail:=error}" ]]
	[[ "${pass:=debug}" ]]

	# Make sure we have a repository URL to validate.
	if [[ ! "${1:-}" ]]; then
		error "We need the URL to at least one repository in order to validate that it can be cloned."
		return 1
	fi

	local repository
	local repository_count="${#}"
	local not_repository="0"

	# Make sure git command is available. If `--silent`` and it's not avaliable exit/return `2`
	if ! [[ "${silent:-}" ]]; then
		__validate_commands --fail "warning" "git"
	else
		if ! __validate_commands --silent "git"; then
			if [[ "${required:-}" ]]; then
				exit 2
			else
				return 2
			fi
		fi
	fi

	# Check if repository is accessible
	for repository in "${@}"; do
		if ! git ls-remote "${repository}" &> /dev/null; then
			[[ ! "${silent:-}" ]] \
				&& ${fail} "No repository accessible at ${repository}."
			((not_repository++))
		fi
	done

	# Log success or failure and return or exit.
	if ((not_repository == 1)); then
		if [[ "${required:-}" ]]; then
			[[ ! "${silent:-}" ]] \
				&& ${fail} "Required repository was inaccessible."
			exit 1
		else
			[[ ! "${silent:-}" ]] \
				&& ${fail} "Non-essential repository was inaccessible."
			return 1
		fi
	elif ((not_repository > 1)); then
		if [[ "${required:-}" ]]; then
			[[ ! "${silent:-}" ]] \
				&& ${fail} "${not_repository} required repositories were inaccessible."
			exit 1
		else
			[[ ! "${silent:-}" ]] \
				&& ${fail} "${not_repository} non-essential repositories were inaccessible."
			return 1
		fi
	else
		if ((repository_count == 1)); then
			[[ ! "${silent:-}" ]] \
				&& ${pass} "Checking if repository can be cloned. Done."
		else
			[[ ! "${silent:-}" ]] \
				&& ${pass} "Checking if repositories can be cloned. Done."
		fi
		return 0
	fi
}
