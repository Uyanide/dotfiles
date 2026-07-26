# History

histdir="${XDG_DATA_HOME:-$HOME/.local/share}/zsh"
HISTFILE="${histdir}/history"
[[ -d $histdir ]] || mkdir -p "$histdir"
unset histdir

HISTSIZE=100000
SAVEHIST=100000

setopt SHARE_HISTORY EXTENDED_HISTORY
setopt HIST_IGNORE_DUPS HIST_SAVE_NO_DUPS HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE HIST_REDUCE_BLANKS
setopt HIST_VERIFY

# Shell options

setopt AUTO_CD EXTENDED_GLOB NOTIFY INTERACTIVE_COMMENTS
bindkey -e

WORDCHARS=${WORDCHARS//[\/=\*\.-]/}

# Rookie keybindings :)
bindkey '^[[1;5D' backward-word      # C-Left
bindkey '^[[1;5C' forward-word       # C-Right
bindkey '^H'      backward-kill-word # C-Backspace (also C-H)
bindkey '^Z'      undo               # C-z

# A-s to prepend sudo
uy_prepend_sudo() {
    if [[ $BUFFER == sudo\ * ]]; then
        BUFFER="${BUFFER#sudo }"
        (( CURSOR -= 5 ))
    else
        BUFFER="sudo $BUFFER"
        CURSOR+=5
    fi
}
zle -N uy_prepend_sudo
bindkey '^[s' uy_prepend_sudo

# Edit current command in editor
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# Magic space
# bindkey ' ' magic-space
# This is already handled by tab

# zmv
autoload -Uz zmv
