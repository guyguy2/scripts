#!/bin/zsh

# Mac Setup Script
# Author: Auto-generated improvement
# Version: 2.0.0
# Description: Installs Homebrew and various tools/apps on a new Mac with enhanced features

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Exit codes
EXIT_SUCCESS=0
EXIT_GENERAL_ERROR=1
EXIT_MISSING_DEPENDENCY=2
EXIT_NETWORK_ERROR=3
EXIT_INSTALL_FAILED=4
EXIT_DISK_SPACE_ERROR=5

# Global options
VERBOSE=false
DRY_RUN=false
SKIP_HOMEBREW=false
SKIP_TERMINAL=false
SKIP_CLI_TOOLS=false
SKIP_GUI_APPS=false
CONFIG_FILE=""

# Package arrays organized by theme/group

# Development Tools - Core
DEV_CORE_TOOLS=("git" "gh" "node" "python" "uv" "bun")

# Development Tools - CLI Utilities
DEV_CLI_UTILS=("eza" "ripgrep" "tree" "ffmpeg")

# Development Tools - Containers
CONTAINER_TOOLS=("docker")

# Network Tools
NETWORK_TOOLS=("telnet")

# Terminal Applications
TERMINAL_APPS=("warp")

# GUI Applications - Development
DEV_GUI_APPS=("visual-studio-code" "docker-desktop")

# GUI Applications - Productivity
PRODUCTIVITY_APPS=("rectangle" "todoist" "dropbox" "macwhisper")

# GUI Applications - Communication
COMMUNICATION_APPS=("whatsapp" "zoom" "google-chrome")

# Legacy arrays for backward compatibility (combined from groups)
CLI_TOOLS=("${DEV_CORE_TOOLS[@]}" "${DEV_CLI_UTILS[@]}" "${CONTAINER_TOOLS[@]}" "${NETWORK_TOOLS[@]}")
GUI_APPS=("${DEV_GUI_APPS[@]}" "${PRODUCTIVITY_APPS[@]}" "${COMMUNICATION_APPS[@]}")

# Minimum disk space required (in GB)
MIN_DISK_SPACE_GB=5

# Logging functions
log_info() {
    echo "[INFO] $*"
}

log_verbose() {
    if [[ "$VERBOSE" == true ]]; then
        echo "[VERBOSE] $*"
    fi
}

log_error() {
    echo "[ERROR] $*" >&2
}

log_warning() {
    echo "[WARNING] $*" >&2
}

log_success() {
    echo "[SUCCESS] $*"
}

# Progress indicator
show_progress() {
    local current=$1
    local total=$2
    local desc=$3
    local percent=$((current * 100 / total))
    echo "[PROGRESS] ($current/$total - $percent%) $desc"
}

# Help function
show_help() {
    cat << EOF
Mac Setup Script v2.0.0

Usage: $0 [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -v, --verbose           Enable verbose output
    -d, --dry-run           Show what would be installed without executing
    -c, --config FILE       Load configuration from file
    --skip-homebrew         Skip Homebrew installation
    --skip-terminal         Skip terminal applications (Warp)
    --skip-cli-tools        Skip command line tools
    --skip-gui-apps         Skip GUI applications

EXAMPLES:
    $0                              # Install everything
    $0 --dry-run                    # Show what would be installed
    $0 --skip-gui-apps --verbose    # Skip GUI apps with verbose output
    $0 --config ./setup.conf        # Use custom configuration file

CONFIGURATION FILE FORMAT:
    DEV_CORE_TOOLS="git gh node python"
    DEV_CLI_UTILS="eza ripgrep tree"
    DEV_GUI_APPS="visual-studio-code docker-desktop"
    PRODUCTIVITY_APPS="rectangle todoist"
    COMMUNICATION_APPS="google-chrome zoom"
    SKIP_TERMINAL=true

EXIT CODES:
    0  Success
    1  General error
    2  Missing dependency
    3  Network error
    4  Installation failed
    5  Insufficient disk space
EOF
}

# Check system requirements
check_system_requirements() {
    log_verbose "Checking system requirements..."

    # Check if running on macOS
    if [[ $(uname) != "Darwin" ]]; then
        log_error "This script is designed for macOS only"
        exit $EXIT_GENERAL_ERROR
    fi

    # Check available disk space
    local available_space_kb
    available_space_kb=$(df -k / | awk 'NR==2 {print $4}')
    local available_space_gb=$((available_space_kb / 1024 / 1024))

    log_verbose "Available disk space: ${available_space_gb}GB"

    if [[ $available_space_gb -lt $MIN_DISK_SPACE_GB ]]; then
        log_error "Insufficient disk space. Required: ${MIN_DISK_SPACE_GB}GB, Available: ${available_space_gb}GB"
        exit $EXIT_DISK_SPACE_ERROR
    fi

    # Check for curl
    if ! command -v curl &> /dev/null; then
        log_error "curl is required but not installed"
        exit $EXIT_MISSING_DEPENDENCY
    fi

    log_verbose "System requirements check passed"
}

# Check network connectivity
check_network() {
    log_verbose "Checking network connectivity..."

    if ! curl -s --connect-timeout 5 https://github.com > /dev/null; then
        log_error "Cannot connect to GitHub. Please check your internet connection."
        exit $EXIT_NETWORK_ERROR
    fi

    log_verbose "Network connectivity confirmed"
}

# Load configuration file
load_config() {
    local config_file=$1

    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        exit $EXIT_GENERAL_ERROR
    fi

    log_verbose "Loading configuration from $config_file"

    # Source the config file safely
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue

        # Validate and source the line
        if [[ "$line" =~ ^[A-Z_]+= ]]; then
            eval "$line"
        fi
    done < "$config_file"

    log_verbose "Configuration loaded successfully"
}

# Install Homebrew
install_homebrew() {
    if [[ "$SKIP_HOMEBREW" == true ]]; then
        log_verbose "Skipping Homebrew installation"
        return
    fi

    log_info "🍺 Installing Homebrew..."

    # Check if Homebrew is already installed
    if command -v brew &> /dev/null; then
        log_success "Homebrew is already installed"
        return
    fi

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would install Homebrew"
        return
    fi

    # Install Homebrew
    log_verbose "Downloading and installing Homebrew..."
    if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
        log_error "Failed to install Homebrew"
        exit $EXIT_INSTALL_FAILED
    fi

    # Add Homebrew to PATH
    local brew_path
    if [[ $(uname -m) == "arm64" ]]; then
        brew_path="/opt/homebrew/bin/brew"
    else
        brew_path="/usr/local/bin/brew"
    fi

    if [[ -x "$brew_path" ]]; then
        echo "eval \"\$($brew_path shellenv)\"" >> ~/.zprofile
        eval "$($brew_path shellenv)"
        log_success "Homebrew installed and configured successfully"
    else
        log_error "Homebrew installation failed - executable not found"
        exit $EXIT_INSTALL_FAILED
    fi
}

# Install terminal applications
install_terminal_apps() {
    if [[ "$SKIP_TERMINAL" == true ]]; then
        log_verbose "Skipping terminal applications"
        return
    fi

    log_info "🚀 Installing terminal applications..."

    local total=${#TERMINAL_APPS[@]}
    local current=0

    for app in "${TERMINAL_APPS[@]}"; do
        current=$((current + 1))
        show_progress $current $total "Installing $app"

        if [[ "$DRY_RUN" == true ]]; then
            log_info "[DRY RUN] Would install terminal app: $app"
            continue
        fi

        log_verbose "Installing $app..."
        if ! brew install --cask "$app"; then
            log_warning "Failed to install $app, continuing..."
            continue
        fi

        # Verify installation
        if brew list --cask | grep -q "^$app$"; then
            log_verbose "$app installed successfully"
        else
            log_warning "$app installation could not be verified"
        fi
    done

    log_success "Terminal applications installation completed"
}

# Install command line tools
# Note: Homebrew installs the latest stable version by default
install_cli_tools() {
    if [[ "$SKIP_CLI_TOOLS" == true ]]; then
        log_verbose "Skipping command line tools"
        return
    fi

    log_info "🛠️ Installing command line tools (latest versions)..."
    log_verbose "Package groups: Development Core, CLI Utilities, Containers, Network Tools"

    local total=${#CLI_TOOLS[@]}
    local current=0

    for tool in "${CLI_TOOLS[@]}"; do
        current=$((current + 1))
        show_progress $current $total "Installing $tool"

        if [[ "$DRY_RUN" == true ]]; then
            log_info "[DRY RUN] Would install CLI tool: $tool"
            continue
        fi

        log_verbose "Installing latest version of $tool..."
        if ! brew install "$tool"; then
            log_warning "Failed to install $tool, continuing..."
            continue
        fi

        # Verify installation
        if brew list | grep -q "^$tool$"; then
            log_verbose "$tool installed successfully"
        else
            log_warning "$tool installation could not be verified"
        fi
    done

    log_success "Command line tools installation completed"
}

# Install GUI applications
# Note: Homebrew Cask installs the latest stable version by default
install_gui_apps() {
    if [[ "$SKIP_GUI_APPS" == true ]]; then
        log_verbose "Skipping GUI applications"
        return
    fi

    log_info "📱 Installing GUI applications (latest versions)..."
    log_verbose "Package groups: Development, Productivity, Communication"

    local total=${#GUI_APPS[@]}
    local current=0

    for app in "${GUI_APPS[@]}"; do
        current=$((current + 1))
        show_progress $current $total "Installing $app"

        if [[ "$DRY_RUN" == true ]]; then
            log_info "[DRY RUN] Would install GUI app: $app"
            continue
        fi

        log_verbose "Installing latest version of $app..."
        if ! brew install --cask "$app"; then
            log_warning "Failed to install $app, continuing..."
            continue
        fi

        # Verify installation
        if brew list --cask | grep -q "^$app$"; then
            log_verbose "$app installed successfully"
        else
            log_warning "$app installation could not be verified"
        fi
    done

    log_success "GUI applications installation completed"
}

# Run cleanup and final steps
cleanup_and_finalize() {
    log_info "🧹 Running cleanup and finalization..."

    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would run brew cleanup"
        return
    fi

    # Clean up Homebrew caches
    log_verbose "Cleaning up Homebrew caches..."
    brew cleanup || log_warning "Homebrew cleanup failed"

    # Update Homebrew
    log_verbose "Updating Homebrew..."
    brew update || log_warning "Homebrew update failed"

    log_success "Cleanup and finalization completed"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit $EXIT_SUCCESS
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -c|--config)
                if [[ -n "$2" ]]; then
                    CONFIG_FILE="$2"
                    shift 2
                else
                    log_error "Config file path required"
                    exit $EXIT_GENERAL_ERROR
                fi
                ;;
            --skip-homebrew)
                SKIP_HOMEBREW=true
                shift
                ;;
            --skip-terminal)
                SKIP_TERMINAL=true
                shift
                ;;
            --skip-cli-tools)
                SKIP_CLI_TOOLS=true
                shift
                ;;
            --skip-gui-apps)
                SKIP_GUI_APPS=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit $EXIT_GENERAL_ERROR
                ;;
        esac
    done
}

# Main function
main() {
    log_info "Mac Setup Script v2.0.0"

    # Load configuration if specified
    if [[ -n "$CONFIG_FILE" ]]; then
        load_config "$CONFIG_FILE"
    fi

    # System checks
    check_system_requirements
    check_network

    if [[ "$DRY_RUN" == true ]]; then
        log_info "🔍 DRY RUN MODE - No actual installations will be performed"
    fi

    # Installation phases
    install_homebrew
    install_terminal_apps
    install_cli_tools
    install_gui_apps
    cleanup_and_finalize

    # Final summary
    log_info ""
    log_success "🎉 Installation complete!"

    if [[ "$DRY_RUN" != true ]]; then
        log_info "You can now launch applications from your Applications folder."
        log_info "Command line tools are available in your terminal."
        log_info "You may need to restart your terminal for PATH changes to take effect."
    fi
}

# Parse arguments and run main function
parse_args "$@"
main