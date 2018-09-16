#!/usr/bin/env bash

#
# # Formatting
# formatting.sh
#
# Set helpful global typography and color variables.
#
# Created by Chris White on 8/8/2018
# License: MIT License / https://opensource.org/licenses/MIT
#
# # Usage
#
# Execute:
# `Library::Import core/formatting`
#



# # Imports
Library::Import validation/validate_commands



# # Functions

# ## Formatting::Set_Variables()
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
#     - `__wrap_enable`:        write        - Enable wrapping output lines.
#     - `__wrap_disable`:       write        - Disable wrapping output lines.
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
Formatting::Set_Variables() {

	# Typography.
	__bold="$(tput bold)"
	__italic_start="$(tput sitm)"
	__italic_end="$(tput ritm)"
	__underline="$(tput smul)"
	__reverse="$(tput rev)"
	__formatting_reset="$(tput sgr0)"
	__wrap_enable="$(tput smam)"
	__wrap_disable="$(tput rmam)"

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


# ## Formatting::Validate_Italics()
#
# A very simple function that will make sure `tput sitm` is defined and if not will let the user know their terminal is not setup for italics at the lowest logging level.
#
Formatting::Validate_Italics() {

	# TODO: Uncomment when __validate_commands has been reviewed and refactored.
	# __validate_commands "infocmp"

	if ! infocmp "${TERM}" | grep --silent sitm; then
		local message
		read -r -d '' message <<-MESSAGE || true
		Your terminal is not setup to display italic text via "tput". This is a minor formatting issue with no effect on function.
		See: https://alexpearce.me/2014/05/italics-in-iterm2-vim-tmux/
		MESSAGE

		debug "${message}"
	fi
	return 0

}



# # Execute on Import
Formatting::Validate_Italics
Formatting::Set_Variables
