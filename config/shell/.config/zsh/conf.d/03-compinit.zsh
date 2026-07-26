# compinit
#
# Sits between 02-fpath.zsh (which finishes $fpath) and
# 95-plugins.zsh (which loads fzf-tab, and fzf-tab requires compinit first).

# Keep the dump next to the other zsh state (cf. $HISTFILE).
_uy_zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
[[ -d "${_uy_zcompdump:h}" ]] || mkdir -p "${_uy_zcompdump:h}"

# Cache compinit: only regenerate dump once daily
autoload -Uz compinit
if [[ -n $_uy_zcompdump(#qN.mh+24) ]]; then
    compinit -d "$_uy_zcompdump"
else
    compinit -C -d "$_uy_zcompdump"
fi

unset _uy_zcompdump

zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
# fzf-tab needs zsh's own menu off so it can capture the unambiguous prefix
zstyle ':completion:*' menu no
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '%F{cyan}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches --%f'
