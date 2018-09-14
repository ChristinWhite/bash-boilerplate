#!/usr/bin/env bash

# trap "__uncaught_exception \"\${?:-Unknown Exit}\" \"\${LINENO:-Unknown Line}\" \"\${BASH_LINENO[0]:-Unknown Function Line}\" \"\${BASH_SOURCE[0]:-Unknown Source}\" \"\${BASH_COMMAND:-Undefined Command}\"" ERR

# ### __uncaught_exception()
#
#
#
# Parameters:
#
__uncaught_exception () {

	# Use default IFS.
	local IFS=$' \t\n'

	# Base Variables
	local exit_code="${1}"
	local line_number="${2}"
	local function_line_number="${3}"
	local source="${4}"
	local command="${5}"

	local file
	file=$(basename -- "${source}")

	# Printed variables
	local type="Unrecognized exception"
	local context="Exit: ${exit_code}"

	# Process Error

	# Unknown command
	if [[ "${exit_code}" == 127 ]]; then
		type="Undefined command"
		context="${command}"
	fi

	# Print Exception Info
	__log --no-indent error "${__bold}Uncaught Exception:${__formatting_reset} ${type} (${__accent_color:-__red}${__italic_start}${context}${__italic_end}${__formatting_reset})"

	# # Temporary Debugging
	# # FIXME: Delete when done
	{
		__print_blank_lines 2

		echo "*: ${*}"
		# echo "__exception: ${__exception}"

		__print_blank_lines 1

		echo "Exit Code: ${exit_code}"
		echo "Type: ${type}"
		echo "Line Number: ${line_number}"
		echo "Function Line Number: ${function_line_number}"

		echo "Command: ${command}"
		echo "Source: ${source}"
		echo "File: ${file}"

		__print_blank_lines 1
	}

	# If we're in an active terminal offer the option to continue or exit. If not, exit.
	__prompt_continue_or_break
}


# ### command_not_found_handle()
#
#
#
# Parameters:
# - `$@`: -
#
command_not_found_handle() {
	local IFS=$' \t\n'
	local exit_code="127"
	local line_number="${BASH_LINENO[0]:-Unknown Line}"
	local function_line_number="${BASH_LINENO[1]:-Unknown Line}"

	local source="${BASH_SOURCE[1]:-Unknown Source}"
	local command="${*:-Unknown Command}"

	__uncaught_exception "${exit_code}" "${line_number}" "${function_line_number}" "${source}" "${command}"
}


# ### __prompt_continue_or_break()
#
# Prompts whether to continue or stop execution after exception.
#
# Returns:
# - `0`:      Issued after user hits return after the prompt on the `read` command.
# - `1`:      Calls `emergency` which will `exit 1` if not being run in a terminal.
# - `SIGINT`: Also prompts user to [Ctrl-C] to exit script.
#
__prompt_continue_or_break () {
	# If we're on a Terminal prompt for interaction, otherwise log emergency and exit.
	if [[ -t 0 ]]; then
		# Prompt message
		__display_prompt "Press ${__bold}[Control-C]${__formatting_reset} to exit or ${__bold}[Return]${__formatting_reset} to continue."

		# Pause and wait for return. Ignore other input.
		read -rs
		info "Continuing..."
		return 0
	else
		emergency "Exception caught, exiting..."
	fi
}
