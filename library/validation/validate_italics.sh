#!/usr/bin/env bash

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
