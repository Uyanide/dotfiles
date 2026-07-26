# $fpath must be complete BEFORE compinit runs (03-compinit.zsh)

if [[ -d "$HOME/.zfunc" ]]; then
    fpath=("$HOME/.zfunc" $fpath)
fi

if [[ -d "$HOME/.zsh/completions" ]]; then
    fpath=("$HOME/.zsh/completions" $fpath)
fi

# Antidote: system package → user-local clone → auto-bootstrap.
# Sourced here because the first `antidote load` happens below.

_uy_antidote_dir="${XDG_DATA_HOME:-$HOME/.local/share}/antidote"

if [[ -f /usr/share/zsh-antidote/antidote.zsh ]]; then
    source /usr/share/zsh-antidote/antidote.zsh
elif [[ -f "$_uy_antidote_dir/antidote.zsh" ]]; then
    source "$_uy_antidote_dir/antidote.zsh"
elif (( $+commands[git] )); then
    _uy_antidote_stamp="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/antidote-bootstrap-failed"

    if [[ -z $_uy_antidote_stamp(#qN.mh-1) ]]; then
        if (( $+commands[timeout] )); then
            # -k: SIGKILL follows if git ignores the SIGTERM
            timeout -k 5 20 git clone -q --depth=1 https://github.com/mattmc3/antidote.git "$_uy_antidote_dir"
        else
            git clone -q --depth=1 https://github.com/mattmc3/antidote.git "$_uy_antidote_dir"
        fi

        if [[ -f "$_uy_antidote_dir/antidote.zsh" ]]; then
            command rm -f -- "$_uy_antidote_stamp"
            source "$_uy_antidote_dir/antidote.zsh"
        else
            # Drop the partial clone: `git clone` refuses to write into a
            # non-empty directory, so leaving it behind never recovers.
            [[ -d "$_uy_antidote_dir" ]] && command rm -rf -- "$_uy_antidote_dir"
            [[ -d "${_uy_antidote_stamp:h}" ]] || mkdir -p "${_uy_antidote_stamp:h}"
            : >| "$_uy_antidote_stamp"
            print -u2 "zsh: antidote bootstrap failed; plugins disabled, retrying in an hour"
        fi
    fi
fi

# Pre-compinit bundles — kind:fpath entries only, nothing is sourced.
if (( $+functions[antidote] )); then
    _uy_zsh_plugins_pre="${XDG_CONFIG_HOME:-$HOME/.config}/zsh/.zsh_plugins_pre.txt"
    if [[ -f "$_uy_zsh_plugins_pre" ]]; then
        antidote load "$_uy_zsh_plugins_pre"
    fi
fi

unset _uy_antidote_dir _uy_antidote_stamp _uy_zsh_plugins_pre
