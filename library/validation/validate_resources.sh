#!/usr/bin/env bash

# ### __validate_resources()
#
# TODO: Revise exit codes to not use reserved numbers
#
# Checks if files and folders exist and optionally are readable. writable and/or executable.
#
# You can pass multiple resources at a time but each will share the same attribute requirements, for different requirements call the function again.
#
# Options:
# - `-f` or `--fail` [arg]:  optional (default: `error`) - Set log level by name if validation fails.
# - `-p` or `--pass` [arg]:  optional (default: `debug`) - Set log level by name if validation succeeds.
# - `-R` or `--readable`:    optional (default: false)   - Validate that resource is readable.
# - `-r` or `--required`:    optional (default: false)   - If required `exit`, otherwise `return`
# - `-s` or `--silent`:      optional (default: false)   - Supress log, only return exit code.
# - `-w` or `--writable`:    optional (default: false)   - Validate that resource is writable.
# - `-x` or `--executable`:  optional (default: false)   - Validate that resource is executable.
#
# Parameters:
# - `$1...`: `$resource` - path (string) - required - Path to a resource. Accepts multiple resources.
#
# Returns:
# - `0`: If resource is found and if specified, is readable, writable and/or executable.
# - `1`: Unknown option in function call.
# - `2`: Resource is not found.
# - `3`: Resource is not readable.
# - `4`: Resource is not writable.
# - `5`: Resource is not executable.
#
# Returns the first failure in numerical order.
#
__validate_resources() {
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
			-R | --readable)
				local readable="readable"
				shift
				;;
			-r | --required)
				local required="required"
				shift
				;;
			-s | --silent)
				local silent="silent"
				shift
				;;
			-w | --writable)
				local writable="writable"
				shift
				;;
			-x | --executable)
				local executable="executable"
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

	# Make sure we have a path to validate.
	if [[ ! "${1:-}" ]]; then
		error "We need the path to at least one file or folder to validate."
		return 1
	fi

	local resource
	local resource_count=${#}
	local not_found="0" not_readable="0" not_writable="0" not_executable="0"

	# Validate files & folders
	for resource in "${@}"; do

		# Check if the path exists
		if ! [[ -a "${resource}" ]]; then
			[[ ! "${silent:-}" ]] \
				&& ${fail} "\"${resource}\" not found."
			((not_found++))
		fi

		# Check if path is readable
		if [[ "${readable:-}" ]] && ! [[ -r "${resource}" ]]; then
			[[ ! "${silent:-}" ]] \
				&& ${fail} "\"${resource}\" not readable."
			((not_readable++))
		fi

		# Check if path is writable
		if [[ "${writable:-}" ]] && ! [[ -w "$resource" ]]; then

			[[ ! "${silent:-}" ]] \
				&& ${fail} "\"${resource}\" not writable."
			((not_writable++))
		fi

		# Check if path is executable
		if [[ "${executable:-}" ]] && ! [[ -x "$resource" ]]; then
			[[ ! "${silent:-}" ]] \
				&& ${fail} "\"${resource}\" not executable."
			((not_executable++))
		fi
	done

	# Log results
	if [[ ! "${silent:-}" ]]; then
		# Log failures
		if ((not_found + not_readable + not_writable + not_executable > 0)); then
			if ((not_found == 1)); then
				${fail} "A resource was not found"
			elif ((not_found > 1)); then
				${fail} "${not_found} resources were not found"
			fi

			if ((not_readable == 1)); then
				${fail} "A resource was not readable"
			elif ((not_readable > 1)); then
				${fail} "${not_readable} resources were not readable"
			fi

			if ((not_writable == 1)); then
				${fail} "A resource was not writable"
			elif ((not_writable > 1)); then
				${fail} "${not_writable} resources were not writable"
			fi

			if ((not_executable == 1)); then
				${fail} "A resource was not executable"
			elif ((not_executable > 1)); then
				${fail} "${not_executable} resources were not executable"
			fi
		# Log success
		else
			if ((resource_count == 1)); then
				${pass} "Checking if a resource is valid. Done."
			else
				${pass} "Checking if ${resource_count} resources are valid. Done."
			fi
		fi
	fi

	# Return or exit failures
	if ((not_found > 0)); then
		if [[ "${required:-}" ]]; then
			exit 2
		else
			return 2
		fi
	elif ((not_readable > 0)); then
		if [[ "${required:-}" ]]; then
			exit 3
		else
			return 3
		fi
	elif ((not_writable > 0)); then
		if [[ "${required:-}" ]]; then
			exit 4
		else
			return 4
		fi
	elif ((not_executable > 0)); then
		if [[ "${required:-}" ]]; then
			exit 5
		else
			return 5
		fi
	else
		return 0
	fi
}
