#!/usr/bin/env bash

#
# # Bash Brewery Library
# brewery.sh
#
# Initializes Bash Brewery, parses run paramaters, sets execution options and runs key functions.
#
# Created by Chris White on 8/8/2018
# License: MIT License / https://opensource.org/licenses/MIT
#
# # Usage
#
# Execute:
# `source ".../brewery.sh" && brew_library`
#



# # Run Options
# NOTE: I've decided to omit `set -o errexit` and `set -o nounfail` and instead try to write error checking in code with an containable `trap ERR` fallback. More info:
# - http://mywiki.wooledge.org/BashFAQ/105
# - http://mywiki.wooledge.org/BashFAQ/112
set -o pipefail         # Pipelines will return the value of the last command to exit non-zero.
set -o errtrace         # trace ERR through 'time command' and other functions
shopt -s failglob       # Patterns which fail to match filenames during filename expansion result in an expansion error.
IFS=$'\n\t'             # Set IFS to only separate by new lines and tabs.
[[ "${LOG_LEVEL:=6}" ]] # If a log level isn't specified set it to show info and above.



# # Parse Script Options
#
# Options:
# - `-d` or `--debug`:            optional                - Sets log-level to `7` and enables `xtrace`.
# - `-l` or `--log-level` [arg]:  optional (default: `6`) - Logging level severity to show, must be a number between 1-7. Seven shows all levels.
# - `-n` or `--no-color`:         optional                - Do not print any output with color or formatting.
#
# Global Variables:
# - `LOG_LEVEL`: write (optional) - Set the log level used throughout script.
# - `NO_COLOR`:  write (optional) - Disable color and formatting.
#
# Sets:
# - `set -o xtrace`: optional - Print a _lot_ of trace data during execution.
#
while :; do
	case "${1:-}" in
		-d | --debug)
			LOG_LEVEL="7"
			set -o xtrace
			shift
			;;
		-l | --log-level)
			if [[ "${2}" == *[1-7]* ]]; then
				LOG_LEVEL="$2"
				shift 2
			else
				emergency "The --log-level options requires a logging level between 1-7 to be passed with the option."
			fi
			;;
		-n | --no-color)
			# shellcheck disable=SC2034
			NO_COLOR="No color or formatting will be used."
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







# ## Library::Brew()
#
# Executes key functions to setup library, print important information and take care of any other core details.
#
# Global Variables:
# - `__brewed`: write - Set variable once brew_library() has completed.
#
# Calls:
# - `__determine_script_variables`: Automatically set as many magic variables as possible.
# - `__print_runtime_information`:  Prints out some information about the script being run.
# - `__validate_italics`:           Make sure we can format italics, if not print a debug message if log-level is sufficiently high enough.
#
Library::Brew() {

	# ## Runtime
	# Get magic script variables.
	__determine_script_variables

	# Print runtime information
	__print_runtime_information


	# ## Validation
	# Validate basics and fail early.
	__validate_italics


	# ## Completion
	# shellcheck disable=SC2034
	__brewed="Brewing complete."
	info "${__brewed}"

}
