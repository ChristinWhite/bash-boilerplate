#!/usr/bin/env bash

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
