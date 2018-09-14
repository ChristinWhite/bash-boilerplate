#!/usr/bin/env bash

#
# # Bash Boiilerplate
# start.sh
#
# A basic template I use to start other Bash scripts.
#
# Created by Chris White on 8/8/2018
# License: MIT License / https://opensource.org/licenses/MIT
#
# # Usage
#
# Execute:
# `./start.sh -h`
#

# TODO: Add `calls` to function descriptions
# TODO: Spend some time thinking about modularization


# # Run Options
# NOTE: I've decided to omit `set -o errexit` and `set -o nounfail` and instead try to write error checking in code with an containable `trap ERR` fallback. More info:
# - http://mywiki.wooledge.org/BashFAQ/105?highlight=%28pipefail%29
# - http://mywiki.wooledge.org/BashFAQ/112?highlight=%28nounset%29
set -o pipefail         # Pipelines will return the value of the last command to exit non-zero.
set -o errtrace         # trace ERR through 'time command' and other functions
# set -o xtrace         # Trace execution, enable for more detailed debugging.
shopt -s failglob       # Patterns which fail to match filenames during filename expansion result in an expansion error.
IFS=$'\n\t'             # Set IFS to only separate by new lines and tabs.
# FIXME: Change to 6 by default:
[[ "${LOG_LEVEL:=7}" ]] # If a log level isn't specified set it to show info and above.
trap "__uncaught_exception \"\${?:-Unknown Exit}\" \"\${LINENO:-Unknown Line}\" \"\${BASH_LINENO[0]:-Unknown Function Line}\" \"\${BASH_SOURCE[0]:-Unknown Source}\" \"\${BASH_COMMAND:-Undefined Command}\"" ERR


# # User Variables

# Accent color is a tput color command that may be used in different places in the script like a header, if you print one. If you want to use an escape sequence see the description for `__formatting_variables()` below.
__accent_color="$(tput setaf 38)"

# Time zone will be used for printing logs, set it to `local` for system time, `env` if you've set $TZ in your environment variables or use a time zone string as defined in `tzset` command (see `man tzset`). Leave blank or undefined to use UTC.
__time_zone="America/Denver"

# # Header

read -r -d '' __header <<-HEADER
888o.    88     888 88  88    888o.  o88o  8888 88   8888 888o.  888o. 88      88   888888 8888
88  8   8  8   8.   88  88    88  8 88  88  88  88   88   88  8  88  8 88     8  8    88   88
8888'  o8oo8o   88  88oo88    8888' 88  88  88  88   88oo 8888'  888p' 88    o8oo8o   88   88oo
88  8 .8    8.   .8 88  88    88  8 88  88  88  88   88   88 88  88    88   .8    8.  88   88
888P' 88    88 888  88  88    888P'  8888  8888 8888 8888 88  88 88    8888 88    88  88   8888
HEADER


# # Functions

# ## Variable Functions

# ### __determine_script_variables()
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


# ### __determine_directory()
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


# ### __formatting_variables
#
# Set helpful global typography and color variables.
#
# This script uses `tput` commands, not escape sequences, for formatting, for more information on why see:
# - http://mywiki.wooledge.org/BashFAQ/037?highlight=%28tput%29
# - http://wiki.bash-hackers.org/scripting/terminalcodes
#
# If you decide to use escape sequences instead at a minimum `printf` commands will need to expand format variables as `%b` instead of `%s`
#
# Global Variables:
# - Typography
#     - `__bold`:               write        - Format text as bold.
#     - `__italic`:             write        - Format text as italic.
#     - `__underline`:          write        - Format text as underlined.
#     - `__reverse`:            write        - Reverse foreground and background colors.
#     - `__formatting_reset`:   write        - Remove formatting and colors from text.
# - Foreground text color
#     - `__red`:                write        - Red foreground color.
#     - `__green`:              write        - Green foreground color.
#     - `__yellow`:             write        - Yellow foreground color.
#     - `__blue`:               write        - Blue foreground color.
#     - `__magenta`:            write        - Magenta foreground color.
#     - `__cyan`:               write        - Cyan foreground color.
#     - `__white`:              write        - White foreground color.
#     - `__default`:            write        - Default foreground color.
# - Background color
#     - `__red_background`:     write        - Red background color.
#     - `__green_background`:   write        - Green background color.
#     - `__yellow_background`:  write        - Yellow background color.
#     - `__blue_background`:    write        - Blue background color.
#     - `__magenta_background`: write        - Magenta background color.
#     - `__cyan_background`:    write        - Cyan background color.
#     - `__white_background`:   write        - White background color.
#     - `__default_background`: write        - Default background color._
# - `__accent_color`:           read / write - Defaults to a light blue color if otherwise not set.
#
# shellcheck disable=SC2034
__formatting_variables () {
	# Typography.
	__bold="$(tput bold)"
	__italic_start="$(tput sitm)"
	__italic_end="$(tput ritm)"
	__underline="$(tput smul)"
	__reverse="$(tput rev)"
	__formatting_reset="$(tput sgr0)"

	# Foreground color.
	__red="$(tput setaf 1)"
	__green="$(tput setaf 2)"
	__yellow="$(tput setaf 3)"
	__blue="$(tput setaf 4)"
	__magenta="$(tput setaf 5)"
	__cyan="$(tput setaf 6)"
	__white="$(tput setaf 15)"
	__default="$(tput setaf 9)"

	# Background color.
	__red_background="$(tput setab 1)"
	__green_background="$(tput setab 2)"
	__yellow_background="$(tput setab 3)"
	__blue_background="$(tput setab 4)"
	__magenta_background="$(tput setab 5)"
	__cyan_background="$(tput setab 6)"
	__white_background="$(tput setab 7)"
	__default_background="$(tput setab 9)"

	# If __accent_color is not assigned give it a default light blue color.
	[[ "${__accent_color:=$(tput setaf 38)}" ]]
}


# ## Printing & Logging

# ### __log()
#
# TODO: This thing has become a monster, it should probably be refactored, simplified and modularized where possible.
#
# Log different levels of messages from general info to critical errors.
#
# Important Notes:
# 1. To use options you must call __log directly, do not use one of the helper functions like `info` or `warning`
# 2. If you need to pass formatting in with the message you must use the `--no-indent` option.
#
# Options:
# - `-i` or `--no-indent`:    optional (default: false) - Will not indent wrapped lines to the start of the log message.
#
# Paramaters:
# - `$1`: `$log_level` - log_level (string) - required - Log level to for setting the formatting and importance of the item. Important note: This is not a number, it's the string associated with the number used elsewhere in the script.
# - `$2`: `$log_lines` - message (string)   - required - Text of message to print and log. Supports multiple lines.
#
# Global Variables:
# - `__time_zone`         read - Use time zone defined in global variable.
# - `NO_COLOR`:           read - Don't print formatting & color if enabled.
# - `TERM`:               read - Don't print formatting & color for some terminals.
# - Formatting Variables: read - Standard text formatting variables like `__bold` and `__red` as defined in `__formatting_variables()`
#
# Calls:
# - `__validate_commands`: not required (fails silently)       - Looks for `fmt` and `sed`, will not call either if unavailable.
# - `fmt`:                 not required (not called)           - See previous. Wrapped lines will not be indented.
# - `sed`:                 not required (not called)           - See previous. Wrapped lines will not be indented.
# - `tput`:                not required (fails with debug log) - Used to check terminal width for wrapping, if check fails `80` characters is used.
#
# Returns:
# `1`: Did not provide log_level and message.
#
# shellcheck disable=SC2034
__log () {
	# Parse options
	while :; do
		case "${1:-}" in
			-i | --no-indent)
				local no_indent="Do not indent wrapped lines"
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

	# Ensure we have required parameters.
	if [[ "${1:-}" && "${2:-}" ]]; then
		local log_level="${1}"
		shift
		local log="${*}"
	else
		error "Logging requires a log_level (\$1) and message (\$2)."
		return 1
	fi

	# Set formatting
	local formatting_debug="${__magenta:-}"
	local formatting_info="${__green:-}"
	local formatting_notice="${__blue:-}"
	local formatting_warning="${__yellow:-}"
	local formatting_error="${__red:-}"
	local formatting_critical="${__red:-}${__bold:-}"
	local formatting_alert="${__red_background:-}${__white:-}"
	local formatting_emergency="${__reverse:-}"

	local formatting_bold="${__bold}"
	local formatting_reset="${__formatting_reset:-}"

	# Set correct formatting for `$log_level` and assign it to `$formatting`
	local formatting_variable="formatting_${log_level}"

	# If the `$formatting_variable` can't be resolved as a valid `log_level` as defined in "Set formatting" above then log a warning and use `formatting_error`.
	if [[ "${!formatting_variable}" ]]; then
		local formatting="${!formatting_variable}"
	else
		warning "\"${log_level}\" is not a valid log leval, formmatting like Error."
		local formatting="${formatting_error}"
	fi

	# Don't use formatting on pipes, non-recognized terminals or if $NO_COLOR has been specified.
	if [[ "${NO_COLOR:-}" = "true" ]] || { [[ "${TERM:-}" != "xterm"* ]] && [[ "${TERM:-}" != "screen"* ]] ; } || [[ ! -t 2 ]]; then
		if [[ "${NO_COLOR:-}" != "false" ]]; then
			formatting=""
			formatting_reset=""
		fi
	fi

	# Set Date & Time
	if [[ "${__time_zone}" == "local" ]]; then
		date=$(date +"%Y-%m-%d %H:%M %Z")
		time=$(date +"%H:%M:%S")
	elif [[ "${__time_zone}" ]]; then
		date=$(TZ="${__time_zone}" date +"%Y-%m-%d %H:%M %Z")
		time=$(TZ="${__time_zone}" date +"%H:%M:%S")
	else
		date=$(date -u +"%Y-%m-%d %H:%M %Z")
		time=$(date -u +"%H:%M:%S")
	fi

	# Print out date if date changed from previous log.
	if [[ ! "${__day}" ]]; then
		printf "%s%s%s\\n" "${formatting_bold}" "${date}" "${formatting_reset}" 1>&2
	elif [[ $(date -u +"%d") != "${__day}" ]]; then
		printf "\\n%s%s%s\\n" "${formatting_bold}" "${date}" "${formatting_reset}" 1>&2
	fi
	__day=$(date -u +"%d")

	# Log & print the date/time, the type of log and the log text.
	local log_line=""
	local line_number="1"
	local terminal_width

	if ! terminal_width=$(tput cols); then
		terminal_width="80"
		debug "Couldn't determine terminal width, using 80 characters."
	fi

	local indent_width=$(( terminal_width - 21 ))

	if __validate_commands --silent "fmt" "sed"; then
		commands_not_available="FMT is not available"
	fi

	while IFS= read -r log_line; do
		if (( line_number == 1 )); then

			# If the output will wrap then indent wrapped lines to match the start of the message collumn.
			if [[ ! "${no_indent}" ]] && (( ${#log_line} > indent_width )) && [[ ! "${commands_not_available}" ]]; then
				wrap_lines=$(fmt -w "${indent_width}" <(printf "%s" "${log_line}"))

				# Separate the first line and concatinate remaining lines into a single line string.
				local line=""
				local wrap_line_number="1"
				while IFS= read -r line; do
					if (( wrap_line_number == 1 )); then
						printf "%s %s[%9s]%s %s\\n" "${time}" "${formatting:-}" "${log_level}" "${formatting_reset:-}" "${line}" 1>&2
						(( wrap_line_number++ ))
					else
						printf "%s" "${line}" | sed 's/^/                     /' 1>&2
					fi
				done <<< "${wrap_lines}"
			else
				printf "%s %s[%9s]%s %s\\n" "${time}" "${formatting:-}" "${log_level}" "${formatting_reset:-}" "${log_line}" 1>&2
			fi

			(( line_number++ ))
		else
			# When you have multiple lines in one log instead of printing a whole bunch of [log_level] ... for each line instead replace the date & time with whitespace and the log_level name with `...` to show the continuation of a single item across lines.
			printf "%*s%s[%9s]%s %s\\n" 9 '' "${formatting:-}" "..." "${formatting_reset:-}" "${log_line}" 1>&2

			# If the output will wrap then indent wrapped lines to match the start of the message collumn.
			if [[ ! "${no_indent}" ]] && (( ${#log_line} > indent_width )) && [[ ! "${commands_not_available}" ]]; then
				wrap_lines=$(fmt -w "${indent_width}" <(printf "%s" "${log_line}"))

				# Separate the first line and concatinate remaining lines into a single line string.
				local line=""
				local wrap_line_number="1"
				while IFS= read -r line; do
					if (( wrap_line_number == 1 )); then
						printf "%*s%s[%9s]%s %s\\n" 9 '' "${formatting:-}" "..." "${formatting_reset:-}" "${line}" 1>&2
						(( wrap_line_number++ ))
					else
						printf "%s" "${line}" | sed 's/^/                     /' 1>&2
					fi
				done <<< "${wrap_lines}"
			else
				printf "%*s%s[%9s]%s %s\\n" 9 '' "${formatting:-}" "..." "${formatting_reset:-}" "${log_line}" 1>&2
			fi
		fi
	done <<< "${log}"
}


# ### Log Functions
# emergency(), alert(), critical(), error(), warning(), notice(), info(), debug()
#
# A group of nearly identical functions that only differ on the severity the message and, in the case of emergency(), the exit code (`1`). These are primarily helper functions that call `__log` to do the actual logging and printing but allow for simplier and more meaningful context inline.
#
# Each level tests against the `$LOG_LEVEL` for the script and only actually call `__log` if the severity equals or excedes the set level.
#
# Parameters:
# - `$@`: string - required - Message to log.
#
# Global Variables:
# - `LOG_LEVEL`: read - Tests current function against log level before logging. `$LOG_LEVEL` is `6` if not otherwise specified at runtime.
#
# Returns:
# - emergency(): `exit 1`: Called for critical errors that immediately exits script.
# - Others...:        `0`: All other functions explicitely return true.
#
emergency () {                                  __log emergency "${@}"; exit 1; } # Script is unusable. Execution stops.
alert ()     { [[ "${LOG_LEVEL:-0}" -ge 1 ]] && __log alert "${@}"; true; }       # Action should be taken but attempting to procead.
critical ()  { [[ "${LOG_LEVEL:-0}" -ge 2 ]] && __log critical "${@}"; true; }    # There is a significant problem that should be addressed.
error ()     { [[ "${LOG_LEVEL:-0}" -ge 3 ]] && __log error "${@}"; true; }       # There was a problem but it wasn't critical.
warning ()   { [[ "${LOG_LEVEL:-0}" -ge 4 ]] && __log warning "${@}"; true; }     # This isn't ideal but it's not a major issue.
notice ()    { [[ "${LOG_LEVEL:-0}" -ge 5 ]] && __log notice "${@}"; true; }      # This notice is important but not a problem.
info ()      { [[ "${LOG_LEVEL:-0}" -ge 6 ]] && __log info "${@}"; true; }        # Info is noteworthy but unimportant.
debug ()     { [[ "${LOG_LEVEL:-0}" -ge 7 ]] && __log debug "${@}"; true; }       # Information that is only relevant when debugging.


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
	while IFS= read -r header_line; do
		printf "%s%s%s\\n" "${formatting:-}" "${header_line}" "${formatting_reset:-}"
	done <<< "${header}"
	__print_blank_lines 1
}


# ### __print_blank_lines()
#
# Prints newlines, one, unless otherwise specified.
#
# Note that while `$1` is optional Shellcheck will complain because it thinks you're trying to use the script's parameter, since that's not what we're trying to do the function is valid without an argument *see Shellcheck's documentation). Rather than disabling sc2120 every time the function is called for one blank line I just pass `1` explicitely.
#
# Parameters:
# - `$1`: `$lines` - int - optional (default `1`) - Number of blank lines.
#
# shellcheck disable=2120
__print_blank_lines () {
	local lines="${1:-1}"

	# Validate paramater is a valid integer.
	if [[ "${lines}" != *[0-9]* ]]; then
		warning "Can't print \"${lines}\" blank lines, parameter is not an integer. Printing one line."
		lines="1"
	fi

	# Print blank lines the specified number of times
	for ((i=1;i<=lines;i++)); do
		printf "\\n"
	done
}


# ## Interaction

# ### __display_prompt()
#
# Print and log a formatted prompt message.
#
# Paramaters:
# - `$1`: `$message` - message (standard input) - Prompt message to print and log. Supports multiple lines.
#
# Global Variables:
# - `NO_COLOR`:           read - Don't print colors if enabled.
# - `TERM`:               read - Don't print colors for some terminals.
# - `__accent_color`:     read - Color to use in the prompt message.
# - `__formatting_reset`: read - Remove formatting and colors from text.
#
# Returns:
# - `1`: No parameter to print.
#
__display_prompt () {
	# Make sure we have a input to print.
	if [[ ! "${1:-}" ]]; then
		error "Prompt requires a message paramater"
		return 1
	fi

	local prompt="${*}"
	local formatting="${__accent_color:-}"
	local formatting_reset="${__formatting_reset:-}"

	# Don't use formatting on pipes, non-recognized terminals or if `$NO_COLOR`` has been specified.
	if [[ "${NO_COLOR:-}" = "true" ]] || { [[ "${TERM:-}" != "xterm"* ]] && [[ "${TERM:-}" != "screen"* ]] ; } || [[ ! -t 2 ]]; then
		if [[ "${NO_COLOR:-}" != "false" ]]; then
			formatting=""
			formatting_reset=""
		fi
	fi

	# Print and log the prompt message.
	local prompt_line=""
	local line_number="1"
	while IFS= read -r prompt_line; do
		if (( line_number == 1 )); then
			printf "\\n%b[prompt]%b %s\\n" "${formatting:-}" "${formatting_reset:-}" "${prompt_line}" 1>&2
			((line_number++))
		else
			# Identical to first line except instead of printing `[prompt]` it prints `[   ...]` to express a continuation across multiple lines.
			printf "%b[%6s]%b %s\\n" "${formatting:-}" "..." "${formatting_reset:-}" "${prompt_line}" 1>&2
		fi
	done <<< "${prompt}"
	echo -en '\n'
}


# ## Error Handling

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


# ## Validation Functions

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


# ### __validate_italics()
#
# A very simple function that will make sure `tput sitm` is defined and if not will let the user know their terminal is not setup for italics at the lowest logging level.
#
__validate_italics() {
	__validate_commands "infocmp"

	if ! infocmp "${TERM}" | grep --silent sitm; then
		local message
		read -r -d '' message <<-MESSAGE || true
		Your terminal is not setup to display italic text via "tput".
		This is a minor formatting issue with no effect on function.
		See: https://alexpearce.me/2014/05/italics-in-iterm2-vim-tmux/
		MESSAGE

		debug "${message}"
		return 0
	fi
}


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


# ## Runtime Information

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
	[[ "${__filename:-}" ]] \
		&& info "Script File: ${__filename}"

	[[ "${__determine_directory:-}" ]] \
		&& info "Directory: $__determine_directory"

	# FIXME: Remove pretend day change.
	__day="$(( __day - 1))"
	info "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam et tellus ipsum. Sed malesuada, massa nec pharetra lobortis, velit ex consequat nibh, ut tempus ex dolor ac diam. Proin faucibus lacus at pulvinar consectetur. Cras maximus dignissim arcu sit amet mollis."

	if [[ ${__is_main_script:-} ]]; then
		info "Script is being executed directly."
	else
		info "Script is not being executed directly or is undetermined."
	fi

	[[ "${__is_git_repo:-}" ]] \
		&& info "Script is in a git repository."
}


# # primary Function
primary() {

	# ## Traps
	# trap "__uncaught_exception \"\${?:-Unknown Exit}\" \"\${LINENO:-Unknown Line}\" \"\${BASH_LINENO[0]:-Unknown Function Line}\" \"\${BASH_SOURCE[0]:-Unknown Source}\" \"\${BASH_COMMAND:-Undefined Command}\"" ERR


	# ## Runtime

	# Get magic script variables.
	__determine_script_variables

	# Print script header and do not throw error.
	__print_header "${__header:-}" || true

	# Print runtime information
	__print_runtime_information


	# ## Validation
	# Validate basics and fail early.
	__validate_italics

	# ## Testing
	# TODO: Switch to proper testing and externalize the test option.
	# shellcheck disable=SC1090
	source "${__determine_directory}/test.sh" \
		|| warning "Could not source test.sh"
	temp_test


	# ## Completion
	info "Script completed."
}

# # Execute
primary

debug "Last line reached, exiting" && exit 0
