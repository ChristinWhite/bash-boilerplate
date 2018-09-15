#!/usr/bin/env bash

#
# # Bash Brewery Library
# start.sh
#
# A little larger than boilerplate but hopefully still light enough to be quick and useful.
#
# Created by Chris White on 8/8/2018
# License: MIT License / https://opensource.org/licenses/MIT
#
# # Usage
#
# Execute:
# `./start.sh -h`
#



# # Source Bash Brewery
# TODO: Consider other solutions
# Replace with an explicit path for maximum safety. You'll need it for the shellcheck directive anyway.
__library_directory="$( cd "${BASH_SOURCE[0]%/*}" && pwd )/library/"

# shellcheck source=/Users/cwhite/Source/open-source/bash-boilerplate/library/brewery.sh
source "${__library_directory}brewery.sh"


# ## Source Modules


# TODO: This needs to be replaced by something better.
# shellcheck source=/Users/cwhite/Source/open-source/bash-boilerplate/library/core/determine_variables.sh
source "${__library_directory}/core/determine_variables.sh"
# shellcheck source=/Users/cwhite/Source/open-source/bash-boilerplate/library/core/formatting.sh
source "${__library_directory}/core/formatting.sh"
# shellcheck source=/Users/cwhite/Source/open-source/bash-boilerplate/library/core/logging.sh
source "${__library_directory}/core/logging.sh"

# shellcheck source=/Users/cwhite/Source/open-source/bash-boilerplate/library/utility/exceptions.sh
source "${__library_directory}/utility/exceptions.sh"
# shellcheck source=/Users/cwhite/Source/open-source/bash-boilerplate/library/utility/interaction.sh
source "${__library_directory}/utility/interaction.sh"
# shellcheck source=/Users/cwhite/Source/open-source/bash-boilerplate/library/utility/runtime_information.sh
source "${__library_directory}/utility/runtime_information.sh"

# shellcheck source=/Users/cwhite/Source/open-source/bash-boilerplate/library/validation/validate_commands.sh
source "${__library_directory}/validation/validate_commands.sh"
# shellcheck source=/Users/cwhite/Source/open-source/bash-boilerplate/library/validation/validate_italics.sh
source "${__library_directory}/validation/validate_italics.sh"
# shellcheck source=/Users/cwhite/Source/open-source/bash-boilerplate/library/validation/validate_repositories.sh
source "${__library_directory}/validation/validate_repositories.sh"
# shellcheck source=/Users/cwhite/Source/open-source/bash-boilerplate/library/validation/validate_resources.sh
source "${__library_directory}/validation/validate_resources.sh"



# # User Variables

# ## Time Zone
#
# Set the time zone to be used for dates and times in logging functions. You have three options:
# 1. Leave undefined and UTC times will be used.
# 2. Use local time by setting the value to `local`, this will use the default option used with the date command, if your `$TZ` environment variable is set it will be used.
# 3. Set a specific time zone in the same format you would use to set `$TZ`. See https://www.cyberciti.biz/faq/linux-unix-set-tz-environment-variable/
#
__time_zone="America/Denver"


# ## Accent Color
#
# Accent color is a `tput` color command that may be used in different places in the script like in a printed header or in some logging functions. This variable can be deleted.
#
__accent_color="$(tput setaf 130)"


# ## Header
#
# If you define a text header it will be printed at the beginning of your script, if you do not want to use one delete this definition.
#
read -r -d '' __header <<-HEADER
888o.    88     888 88  88    888o. 888o.  8888 88            88 8888 888o. 88    88 \\\\-----//
88  8   8  8   8.   88  88    88  8 88  8  88    88    88    88  88   88  8  88..88   \\\\___//
8888'  o8oo8o   88  88oo88    8888' 8888'  88oo   88  8888  88   88oo 8888'   '88'     ))=((
88  8 .8    8.   .8 88  88    88  8 88 88  88      8888  8888    88   88 88    88     //---\\\\
888P' 88    88 888  88  88    888P' 88  88 8888     88    88     8888 88  88   88    ((_____))
HEADER



# # Brew (Initialize) Library
Library::Brew



# # Your Code

	# ## Testing
	# TODO: Switch to proper testing and externalize the test option.
	# shellcheck disable=SC1090
	# source "$( cd "${BASH_SOURCE[0]%/*}" && pwd )/test/test.sh" \
	# 	|| warning "Could not source test.sh"
	# temp_test

debug "Final line of script"
