#!/usr/bin/env zsh
#
# Make a directory and cd into it after it's creation.
#
# Author:
#   Larry Gordon
#
# Usage:
#   $ mkcd foo
#   $ mkcd /tmp/img/photos/large
#
# License:
#   The MIT License (MIT) <http://psyrendust.mit-license.org/2014/license.html>
# ------------------------------------------------------------------------------
# Add bin to PATH
export PATH="$(cd -P "$(cd -P ${0:h} && pwd)/bin" && pwd):$PATH"
