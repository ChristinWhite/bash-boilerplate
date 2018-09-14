#!/usr/bin/env bash

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
