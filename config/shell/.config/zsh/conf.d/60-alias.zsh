# fzf

if (( $+commands[fzf] )); then
	source <(fzf --zsh)

	# auto copy fzf's output
	if (( $+commands[wl-copy] )); then
		alias fzf="fzf --bind 'enter:execute-silent(echo {+} | wl-copy --trim-newline)+accept'"
	fi

	# fzh: history
	alias fzh="history -1 0 | fzf"

	# fz: fuzzy find a file and preview
	if (( $+commands[bat] )); then
		alias fz="fzf --preview 'bat --style=numbers --color=always {}'"
	else
		alias fz="fzf --preview 'cat -n {}'"
	fi

	# fe: fuzzy find a file and edit using $EDITOR
	fe() {
		local file
		file=$(fz "$@")
		[[ -n "$file" ]] && $EDITOR "$file"
	}

	# fkill: fuzzy find a process and kill with SIGKILL
	fkill() {
		local pids
		pids=$(ps -ef | sed 1d | fzf -m --preview 'pstree -p $(echo {} | awk "{print \$2}")' | awk '{print $2}')
		[[ -n "$pids" ]] && kill -9 ${=pids}
	}

	if (( $+commands[yay] )); then
		# fyq: fuzzy yay query
		alias fyq="yay -Qq | fzf --preview 'yay -Qi {}'"

		# fyi: fuzzy yay install
		fyi() {
			local pkg
			pkg=$(yay -Sl | awk '{print $1"/"$2}' | fzf -m --preview 'yay -Si {}' "$@")
			[[ -n "$pkg" ]] && yay -S ${=pkg}
		}

		# fyr: fuzzy yay remove
		fyr() {
			local pkg
			pkg=$(yay -Qq | fzf -m --preview 'yay -Qi {}' "$@")
			[[ -n "$pkg" ]] && yay -Rn ${=pkg}
		}
	fi
fi

# cd (zoxide)

if (( $+commands[zoxide] )); then
	eval "$(zoxide init zsh)"
	alias cd=z
fi

# ls

if (( $+commands[eza] )); then
	alias ll="eza -lh --group-directories-first --icons=auto"
	alias la="eza -lh --group-directories-first --icons=auto --all"
	alias lt="eza --tree --level=2 --long --icons --git"
else
	alias ls="ls --color=auto"
	alias ll="ls -lh --group-directories-first --color=auto"
	alias la="ls -lah --group-directories-first --color=auto"
fi

# directories

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# colorize

alias grep="grep --color=auto"
alias dir="dir --color=auto"
alias vdir="vdir --color=auto"
alias fgrep="fgrep --color=auto"
alias egrep="egrep --color=auto"

# copy

copy() {
	if [[ $# -eq 2 && -d "$1" ]]; then
		command cp -r "${1%/}" "$2"
	else
		command cp "$@"
	fi
}

# wget

if (( $+commands[wget] )); then
	alias wget="wget -c "
fi

# pacman

if (( $+commands[expac] )); then
	alias big="expac -H M '%m\t%n' | sort -h | nl"
fi

# clock

if (( $+commands[tty-clock] )); then
	alias clock="tty-clock -c -C 4"
fi

# journalctl

alias jctl="journalctl -p 3 -xb"

# nohup

nh() {
	nohup "$@" >/dev/null 2>&1 &
	disown
}

# ffmpeg

alias ffmpeg="ffmpeg -hide_banner -nostdin"
alias ffprobe="ffprobe -hide_banner"

# git

if (( $+commands[git] )); then
	gcp() {
		git add -A || return 1
		if [[ $# -eq 0 ]]; then
			git commit -m "👐 foo: too lazy to come up with a helpful commit message :)" || return 1
		else
			git commit -m "$*" || return 1
		fi
		git push
	}

	if (( $+commands[wl-paste] )); then
		# Get a git repo URL from clipboard, prompting if invalid
		uy_git_repo_from_clipboard() {
			local repo
			repo=$(wl-paste)
			if [[ ! "$repo" =~ '^(http|https|git|ssh)://|^git@' ]]; then
				echo "Error: Clipboard does not contain a valid git repository URL." >&2
				echo "Error: Clipboard content: $repo" >&2
				read "repo?Enter a valid git repository URL: "
				if [[ ! "$repo" =~ '^(http|https|git|ssh)://|^git@' ]]; then
					echo "Error: Invalid git repository URL." >&2
					return 1
				fi
			fi
			print -r -- "$repo"
		}

		gc() {
			local repo
			repo=$(uy_git_repo_from_clipboard) || return 1
			git clone "$repo"
		}

		pingo() {
			cd "$HOME/Repositories/PGdP" || return 1
			local repo
			repo=$(uy_git_repo_from_clipboard) || return 1
			local dir_name="${repo:t:r}"
			if [[ ! -d "$dir_name" ]]; then
				git clone "$repo" || return 1
			fi
			local app="$1"
			if [[ -n "$app" ]] && (( $+commands[$app] )); then
				echo "Opening project with $app"
				nohup "$app" "$dir_name" >/dev/null 2>&1 &
				disown
			else
				echo "Opening method missing or invalid"
				cd "$dir_name"
			fi
		}
	fi
fi
