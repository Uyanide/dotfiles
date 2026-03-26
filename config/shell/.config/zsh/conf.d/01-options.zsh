# History

HISTFILE="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/history"
HISTSIZE=100000
SAVEHIST=100000
setopt APPEND_HISTORY SHARE_HISTORY
setopt HIST_IGNORE_DUPS HIST_SAVE_NO_DUPS HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE HIST_REDUCE_BLANKS INC_APPEND_HISTORY
setopt HIST_VERIFY

# Shell options

setopt AUTO_CD EXTENDED_GLOB NOTIFY INTERACTIVE_COMMENTS
bindkey -e

# Allow word-based navigation and deletion to work on paths

WORDCHARS=${WORDCHARS//\//}

# Rookie keybindings :)
bindkey '^[[1;5D' backward-word      # C-Left
bindkey '^[[1;5C' forward-word       # C-Right
bindkey '^H'      backward-kill-word # C-Backspace
