#!/usr/bin/env bash

# ### __validate_commands()
#
# Validates that external commands exist in PATH before we try to use them.
#
# Based on Bash Hackers Wiki's best practices:
# http://wiki.bash-hackers.org/scripting/style
#
# Options:
# - `-f` or `--fail` [arg]:  optional (default: `error`) - Set log level by name if validation fails.
# - `-p` or `--pass` [arg]:  optional (default: `debug`) - Set log level by name if validation succeeds.
# - `-r` or `--required`:    optional (default: false)   - If required `exit 1`, otherwise `return 1`
# - `-s` or `--silent`:      optional (default: false)   - Supress log, only return exit code.
#
# Paramaters:
# - `$1...`: `$command` - command (string) - required - Name of the command you use to call it. Accepts multiple commands.
#
# Returns:
# - `0`: All commands found.
# - `1`: Unable to complete validation.
#     - Unknown option in function call.
#     - One or more commands were not found. If --required `exit`.
#
__validate_commands() {
	# Parse options
	local pass fail
	while :; do
		case "${1:-}" in
			-f | --fail)
				fail="${2}"
				shift 2
				;;
			-p | --pass)
				pass="${2}"
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

	# Make sure we have a command to validate.
	if [[ ! "${1:-}" ]]; then
		error "We need at least one command in order to validate."
		return 1
	fi

	local command
	local command_count="${#}"
	local missing_commands="0"

	# Check for commands and log missing commands
	for command in "${@}"; do
		if ! hash "${command}" >/dev/null 2>&1; then
			[[ ! "${silent:-}" ]] \
				&& ${fail} "Command not found in PATH: $command"
			((missing_commands++))
		fi
	done

	# Check if commands were missing, log them and return.
	if ((missing_commands > 0)); then
		if [[ "${required:-}" ]]; then
			if [[ ! "${silent:-}" ]]; then
				if ((missing_commands == 1)); then
					${fail} "A required command is missing in PATH."
				else
					${fail} "${missing_commands} required commands missing in PATH."
				fi
			fi
			exit 1
		else
			if [[ ! "${silent:-}" ]]; then
				if ((missing_commands == 1)); then
					${fail} "A non-essential command is missing in PATH."
				else
					${fail} "${missing_commands} non-essential commands missing in PATH."
				fi
			fi
			return 1
		fi
	elif ((command_count == 1)); then
		[[ ! "${silent:-}" ]] \
			&& ${pass} "Checking availability of a command. Done."
	else
		[[ ! "${silent:-}" ]] \
			&& ${pass} "Checking availability of ${command_count} commands. Done."
	fi
}
