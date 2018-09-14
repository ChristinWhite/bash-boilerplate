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
# Replace with an explicit path for maximum safety. You'll need it for the shellcheck directive anyway.
__library_directory="$( cd "${BASH_SOURCE[0]%/*}" && pwd )/library/"

# shellcheck source=/Users/cwhite/Source/open-source/bash-boilerplate/library/brewery.sh
source "${__library_directory}brewery.sh"



# # Source Modules



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
# Accent color is a `tput` color command that may be used in different places in the script like in a printed header or in some logging functions.
#
__accent_color="$(tput setaf 38)"


# ## Header
#
# If you define a text header it will be printed at the beginning of your script, if you do not want to use one delete this definition.
#
read -r -d '' __header <<-HEADER
888o.    88     888 88  88    888o. 888o.  8888 88            88 8888 888o. 88    88
88  8   8  8   8.   88  88    88  8 88  8  88    88    88    88  88   88  8  88..88
8888'  o8oo8o   88  88oo88    8888' 8888'  88oo   88  8888  88   88oo 8888'   '88'
88  8 .8    8.   .8 88  88    88  8 88 88  88      8888  8888    88   88 88    88
888P' 88    88 888  88  88    888P' 88  88 8888     88    88     8888 88  88   88
HEADER
