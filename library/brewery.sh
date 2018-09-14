#!/usr/bin/env bash

# # Run Options
# NOTE: I've decided to omit `set -o errexit` and `set -o nounfail` and instead try to write error checking in code with an containable `trap ERR` fallback. More info:
# - http://mywiki.wooledge.org/BashFAQ/105
# - http://mywiki.wooledge.org/BashFAQ/112
set -o pipefail         # Pipelines will return the value of the last command to exit non-zero.
set -o errtrace         # trace ERR through 'time command' and other functions
shopt -s failglob       # Patterns which fail to match filenames during filename expansion result in an expansion error.
IFS=$'\n\t'             # Set IFS to only separate by new lines and tabs.
# FIXME: Change to 6 by default:
[[ "${LOG_LEVEL:=7}" ]] # If a log level isn't specified set it to show info and above.
