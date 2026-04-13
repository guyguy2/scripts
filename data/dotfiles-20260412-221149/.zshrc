# Path to oh-my-zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Set theme
ZSH_THEME="robbyrussell"

# Plugins
plugins=(git docker)

# Load oh-my-zsh
source $ZSH/oh-my-zsh.sh

# ------------------------------------------------------------------------------
# Environment Variables
# ------------------------------------------------------------------------------

export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"

# PATH configuration
path=(
    "$HOME/.local/bin"
    "/opt/homebrew/bin"
    "$HOME/Library/Android/sdk/platform-tools"
    $path
)

# ------------------------------------------------------------------------------
# Completions
# ------------------------------------------------------------------------------

fpath=("$HOME/.docker/completions" $fpath)

# ------------------------------------------------------------------------------
# Aliases
# ------------------------------------------------------------------------------

# General
alias c='clear'
alias sqlite3='/usr/bin/sqlite3'

# Python
alias pip='pip3'
alias python='python3'
alias py='python3'

# npm
alias ni='npm install'
alias ns='npm start'

# Git
alias gacp='git add . && git commit -m "progress" && git push'

# Claude
alias cld='claude'
alias clda='cld --dangerously-skip-permissions'
alias clds='cld --dangerously-skip-permissions --model=sonnet'
alias cldo='cld --dangerously-skip-permissions --model=opus'
alias killClaudes='pkill -9 -f claude'

# Misc
alias fabric='fabric-ai'
alias gemini='gemini -y'
alias md='mkdir'
alias cpuIdle="top -l 1 | grep 'CPU usage' | awk '{print \$7}'"

# ------------------------------------------------------------------------------
# Functions
# ------------------------------------------------------------------------------

updateGitRepos() {
    local counter_file="$HOME/.update_git_repos_counter"
    local count=0
    if [[ -f "$counter_file" ]]; then
        count=$(cat "$counter_file")
    fi

    count=$((count + 1))

    if [[ $count -ge 5 ]]; then
        local agents_dir="/Users/guy/dev/ai/agents"
        local extra_repos=(
            "$HOME/dev/experiments/firecrawl"
        )
        echo "Updating git repos (run $count/5)..."
        if [[ -d "$agents_dir" ]]; then
            for agent_dir in "$agents_dir"/*/; do
                [[ -d "$agent_dir" ]] || continue
                if [[ -d "$agent_dir/.git" ]]; then
                    echo "\nUpdating git repo in $agent_dir..."
                    if ! (cd "$agent_dir" && git pull); then
                        _upd_failed_pulls+=("$agent_dir")
                    fi
                else
                    echo "Skipping $agent_dir (not a git repository)"
                fi
            done
        else
            echo "Skipping $agents_dir (directory not found)"
        fi
        for repo_dir in "${extra_repos[@]}"; do
            if [[ -d "$repo_dir/.git" ]]; then
                echo "\nUpdating git repo in $repo_dir..."
                if ! (cd "$repo_dir" && git pull); then
                    _upd_failed_pulls+=("$repo_dir")
                fi
            else
                echo "Skipping $repo_dir (not a git repository)"
            fi
        done
        count=0
    else
        echo "Skipping git repo updates (run $count/5)"
    fi

    echo "$count" >| "$counter_file"
}

upd() {
    local counter_file="$HOME/.upd_counter"
    typeset -g _upd_failed_pulls=()

    # Read counter early to gate brew update
    local count=0
    if [[ -f "$counter_file" ]]; then
        count=$(cat "$counter_file")
    fi
    count=$((count + 1))

    # Run brew update only every 5th run
    if [[ $count -ge 5 ]]; then
        brew update &>/dev/null
    fi
    brew upgrade

    # Update Todoist CLI
    if command -v td &>/dev/null; then
        td update
    fi

    # Update git repositories
    updateGitRepos

    # Update docker-compose if Docker is running
    if docker info &>/dev/null; then
        local compose_dirs=(
            "/Users/guy/dev/automation/n8n"
        )

        for compose_dir in "${compose_dirs[@]}"; do
            if [[ -f "$compose_dir/docker-compose.yml" ]] || [[ -f "$compose_dir/docker-compose.yaml" ]]; then
                echo "Updating docker-compose in $compose_dir..."
                (cd "$compose_dir" && docker-compose pull && docker-compose up -d)
            else
                echo "Skipping $compose_dir (no docker-compose.yml found)"
            fi
        done

        echo "Cleaning up old Docker images..."
        docker image prune -f
    else
        echo "Skipping docker-compose (Docker not running)"
    fi

    if [[ $count -ge 5 ]]; then
        echo "Running brew cleanup (run $count/5)..."
        brew cleanup
        count=0
    else
        echo "Skipping brew cleanup (run $count/5)"
    fi

    echo "$count" >| "$counter_file"

    # Report any failed git pulls
    if (( ${#_upd_failed_pulls[@]} > 0 )); then
        echo "\n--- Git Pull Failures ---"
        for repo in "${_upd_failed_pulls[@]}"; do
            echo "  FAILED: $repo"
        done
        echo "--- End of Report ---"
    fi
    unset _upd_failed_pulls
}

function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

# ------------------------------------------------------------------------------
# Tool Integrations
# ------------------------------------------------------------------------------

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# Initialize zoxide (smarter cd command)
eval "$(zoxide init zsh)"

# Added by Antigravity
export PATH="/Users/guy/.antigravity/antigravity/bin:$PATH"

eval $(thefuck --alias oops)
