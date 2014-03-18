#!/usr/bin/env zsh
#
# Executes file/folder creation, login message, and should not change the shell.
#
# Author:
#   Larry Gordon
#
# Execution Order
#   https://github.com/psyrendust/alf/templates/home
#
# License:
#   The MIT License (MIT) <http://psyrendust.mit-license.org/2014/license.html>
# ------------------------------------------------------------------------------


# Load Custom aliases and key bindings (useful if you want to override Alf's defaults)
source "$ALF_CUSTOM_ALIASES" 2>/dev/null
source "$ALF_CUSTOM_KEY_BINDINGS" 2>/dev/null

# Last run helper functions
source "$ALF_SRC_TOOLS/last-run.zsh" 2>/dev/null



# ------------------------------------------------------------------------------
# RUN A FEW THINGS AFTER OH MY ZSH HAS FINISHED INITIALIZING
# ------------------------------------------------------------------------------
if [[ -n $PLATFORM_IS_CYGWIN ]]; then
  # Install gem helper aliases in the background
  {
    if [[ -n "$(which ruby 2>/dev/null)" ]]; then
      _gem-alias "install"
    fi
  } &!

  # If we are using Cygwin and ZSH_THEME is Pure, then replace the prompt
  # character to something that works in Windows
  if [[ $ZSH_THEME == "pure" ]]; then
    PROMPT=$(echo $PROMPT | tr "❯" "›")
  fi
fi


# Settings for zsh-syntax-highlighting plugin
if [[ -n $PLATFORM_IS_MAC ]] && [[ -n "${ZSH_HIGHLIGHT_STYLES+x}" ]]; then
  # Set highlighters.
  zstyle -a ':alf:module:syntax-highlighting' highlighters 'ZSH_HIGHLIGHT_HIGHLIGHTERS'
  if (( ${#ZSH_HIGHLIGHT_HIGHLIGHTERS[@]} == 0 )); then
    ZSH_HIGHLIGHT_HIGHLIGHTERS=(main)
  fi

  # Set highlighting styles.
  typeset -A syntax_highlighting_styles
  zstyle -a ':alf:module:syntax-highlighting' styles 'syntax_highlighting_styles'
  for syntax_highlighting_style in "${(k)syntax_highlighting_styles[@]}"; do
    ZSH_HIGHLIGHT_STYLES[$syntax_highlighting_style]="$syntax_highlighting_styles[$syntax_highlighting_style]"
  done
  unset syntax_highlighting_style{s,}
fi



# Don't run auto update if it's been disabled
# ------------------------------------------------------------------------------
if [[ ! -n $ALF_DISABLE_AUTO_UPDATE ]]; then

  # Load up the last run for auto-update
  # ----------------------------------------------------------------------------
  alf epoch --set
  alf_au_last_epoch_diff=$(( $(alf epoch --get "auto-update") - $(alf epoch --get) ))

  # See if we ran this today already
  # ----------------------------------------------------------------------------
  if [[ ${alf_au_last_epoch_diff} -gt $ALF_UPDATE_DAYS ]]; then
    # Run antigen self-update then update all bundles
    # --------------------------------------------------------------------------
    printf '\n\033[0;32m%s\033[0m' "Executing antigen updates: "; \
    typeset -a _repos; \
    antigen selfupdate | while read -r line; do printf '\033[0;32m▍\033[0m'; done; \
    antigen update | while read -r line; do printf '\033[0;32m▍\033[0m'; done;


    # Update last epoch
    # --------------------------------------------------------------------------
    alf epoch --set "auto-update"
  fi
  # Run any post-update scripts if they exist
  # ----------------------------------------------------------------------------
  run-once
  unset alf_au_last_epoch_diff

fi


unalias run-help
autoload run-help
HELPDIR=/usr/local/share/zsh/helpfiles


# Output Alf's current version number
_alf_startup_time_end=$(/usr/local/bin/gdate +%s%N)
_alf_startup_time_diff=" \033[1;35m$(( ($_alf_startup_time_end - $_alf_startup_time_begin) / 1000000 ))ms\033[0m"
alf --version


{
  # Compile the completion dump to increase startup speed in the background.
  zcompdump="$HOME/.zcompdump"
  if [[ -s "$zcompdump" && (! -s "${zcompdump}.zwc" || "$zcompdump" -nt "${zcompdump}.zwc") ]]; then
    zcompile "$zcompdump"
  fi
  # Figure out the SHORT hostname
  if [ -n "$commands[scutil]" ]; then
    # OS X
    SHORT_HOST=$(scutil --get ComputerName)
  else
    SHORT_HOST=${HOST/.*/}
  fi
  ZSH_COMPDUMP="${ZDOTDIR:-${HOME}}/.zcompdump-${SHORT_HOST}-${ZSH_VERSION}"
  # Also compile the completion dump that is generated by oh-my-zsh.
  if [[ -s "$ZSH_COMPDUMP" && (! -s "${ZSH_COMPDUMP}.zwc" || "$ZSH_COMPDUMP" -nt "${ZSH_COMPDUMP}.zwc") ]]; then
    zcompile "$ZSH_COMPDUMP"
  fi
} &!
