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
# NOTE: I've decided to omit `set -o errexit` and `set -o nounset` and instead try to write error checking inline with an `trap ERR` fallback. More info:
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
			if [[ "${2:-}" == *[1-7]* ]]; then
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



# # Library Functions

# ## Library::Import()
#
# Takes a set of space deliniated paths relative to the Library directory and without a `.sh` extension and sources them.
#
# Usage:
# `Library::Import core/determine_variables core/formatting utility/exceptions`
#
# Paramaters:
# - `$1...`: `$path` - path - required - The relative path from /library/ to a file without `sh` to source. Accepts multiple paths.
#
# Calls:
# - `Library::Brew_Emergency`: - Checks if `emergency` is an available function and passes the message on to it, if not print a simplified version with the message.
#
# shellcheck disable=SC2154
Library::Import() {

	# Make sure we have at least one path in paramaters.
	if [[ "${1}" ]]; then
		local paths="${*}"
	else
		Library::Brew_Emergency "No paths specified to import." \
			|| printf "[emergency]: No paths specified to import. Exiting."
	fi

	# Double check that Library path is valid and readable.
	if ! [[ -a "${__library_path}" ]]; then
		Library::Brew_Emergency "Library path (${__library_path}) is not valid."
	elif ! [[ -r "${__library_path}" ]]; then
		Library::Brew_Emergency "Library path (${__library_path}) is not readable."
	fi

	local path
	for path in ${paths}; do
		local full_path="${__library_path}${path}.sh"
		if ! [[ -a "${full_path}" ]]; then
			Library::Brew_Emergency "Script path (${path}.sh) is not valid."
		elif ! [[ -r "${full_path}" ]]; then
			Library::Brew_Emergency "Script path (${path}.sh) is not readable."
		fi

		# shellcheck disable=SC1090
		source "${full_path}" \
			|| Library::Brew_Emergency "Unable to load /${path}"
	done

}


# ## Library::Brew_Emergency()
#
# Checks if `emergency` is an available function (logging was loaded) and passes the message on to it, if not print a simplified version with the message.
#
# Paramaters:
# - `$1`: `$message` - required - Text of message to print and log.
#
# Calls:
# - `Emergency`: optional - If `emergency` can be found pass the message onto it.
#
Library::Brew_Emergency() {

	if [[ "${1}" ]]; then
		local message="${1}"
	else
		Library::Brew_Emergency "Library::Brew_Emergency was called without a paramater."
	fi

	# If we can't call `emergency` then print a simplified version and exit.
	if hash "Emergency" >/dev/null 2>&1; then
		Emergency "${message}" \
			|| printf "[emergency] %s" "${message}"
	else
		local formatting_level
		formatting_level="$(tput rev)"

		local formatting_date
		formatting_date="$(tput bold)"

		local formatting_reset
		formatting_reset="$(tput sgr0)"

		printf "\\n%s%s%s\\n" "${formatting_date}" "$(date -u +"%Y-%m-%d %H:%M %Z")" "${formatting_reset}" 1>&2
		printf "%s %s[emergency]%s %s Exiting.\\n" "$(date -u +"%H:%M:%S")" "${formatting_level}" "${formatting_reset}" "${message}" 1>&2
		exit 1
	fi
}


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

	# ## Import Required Components
	Library::Import core/logging

	# TODO: Reduce this once you've added imports to functions
	Library::Import core/determine_variables core/formatting
	Library::Import utility/exceptions utility/interaction utility/runtime_information
	Library::Import validation/validate_commands validation/validate_italics validation/validate_repositories validation/validate_resources

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
