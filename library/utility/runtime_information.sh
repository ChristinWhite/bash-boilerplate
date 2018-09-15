#!/usr/bin/env bash

# ### __print_header()
#
# A simple function that will print out a string with formatting and color.
#
# For most scripts an FIGlet header is superfluous if not outright annoying but for a long script that produces plenty of output I find them a helpful tool for quickly determining where execution of the script began. I tend to favor Colossal or Roman generators as good starting points.
#
# Options:
# - `-f` or `--formatting` [arg]:  optional (default: `$__accent_color`) - A tput formatting string for the header.
#
# Parameters:
# - `$1`: `$header` - header (string) - required - Text to print, typically a multiline string.
#
# Global Variables:
# - `NO_COLOR`:           read - Don't print color or formatting.
# - `__accent_color`:     read - Accent color to use for formatting by default.
# - `__header`:           read - If a header isn't passed as a parameter try to use this global.
# - `__formatting_reset`: read - Remove formatting and colors from text.
#
# Returns:
# - `1`: Unable to print header.
#     - Unknown option in function call.
#     - No header is specified to print.
#
__print_header () {
	local formatting
	# Parse options
	while :; do
		case "${1:-}" in
			-f | --formatting)
				formatting="${2}"
				shift 2
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

	# If no formatting is specified use `$__accent_color`.
	[[ "${formatting:=$__accent_color}" ]]

	local formatting_reset="${__formatting_reset}"

	# Ensure we have a header to print. If one isn't passed try to use global `$__header` as a fallback.
	if [[ "${1:-}" ]]; then
		local header="$1"
	elif [[ "${__header:-}" ]]; then
		local header="${__header}"
	else
		warning "Can't print a header if no string is passed and \"__header\" is empty."
		return 1
	fi

	# Don't use formatting on pipes, non-recognized terminals or if $NO_COLOR has been specified.
	if [[ "${NO_COLOR:-}" = "true" ]] || { [[ "${TERM:-}" != "xterm"* ]] && [[ "${TERM:-}" != "screen"* ]] ; } || [[ ! -t 2 ]]; then
		if [[ "${NO_COLOR:-}" != "false" ]]; then
			formatting=""
		fi
	fi

	# Print out the header
	__print_blank_lines 1
	local header_line=""
	printf "%s" "${__wrap_disable}"
	while IFS= read -r header_line; do
		printf "%s%s%s\\n" "${formatting:-}" "${header_line}" "${formatting_reset:-}"
	done <<< "${header}"
	printf "%s" "${__wrap_enable}"
	__print_blank_lines 1
}



# ### __print_runtime_information()
#
# Prints out some information about the script being run.
#
# Global Variables:
# - `__filename`:            read - Script filename.
# - `__determine_directory`: raed - Script directory.
# - `__is_main_script`:      read - Is the script being run directly or sourced.
# - `__is_git_repo`:         read - Is the script in a Git repo.
#
__print_runtime_information() {
	if [[ "${__header}" ]]; then
		__print_header "${__header:-}" \
			|| true
	fi

	[[ "${__filename:-}" ]] \
		&& info "Script File: ${__filename}"

	[[ "${__determine_directory:-}" ]] \
		&& info "Directory: $__determine_directory"

	if [[ ${__is_main_script:-} ]]; then
		info "Script is being executed directly."
	else
		info "Script is not being executed directly or is undetermined."
	fi

	[[ "${__is_git_repo:-}" ]] \
		&& info "Script is in a git repository."
}
