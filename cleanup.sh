#!/bin/bash

# ==============================================================================
# macOS Development Environment Cleanup Script
# ==============================================================================
# This script helps free up disk space by cleaning various development caches
# and temporary files with a user-friendly interactive interface.
# ==============================================================================

set -e

# --- Debug Configuration ---
DEBUG_MODE=${DEBUG_MODE:-false}

# --- Color and UI Configuration ---
declare -r RED='\033[1;31m'
declare -r GREEN='\033[1;32m'
declare -r YELLOW='\033[1;33m'
declare -r BLUE='\033[1;34m'
declare -r MAGENTA='\033[1;35m'
declare -r CYAN='\033[1;36m'
declare -r WHITE='\033[1;37m'
declare -r RESET='\033[0m'
declare -r BOLD='\033[1m'

# --- Utility Functions ---
echo_header() {
    printf "\n${BLUE}${BOLD}%s${RESET}\n" "$1"
}

echo_info() {
    printf "${CYAN}ℹ %s${RESET}\n" "$1"
}

echo_success() {
    printf "${GREEN}✓ %s${RESET}\n" "$1"
}

echo_warning() {
    printf "${YELLOW}⚠ %s${RESET}\n" "$1"
}

echo_error() {
    printf "${RED}✗ %s${RESET}\n" "$1" >&2
}

echo_question() {
    printf "${MAGENTA}? %s${RESET}" "$1"
}

echo_debug() {
    if [[ "$DEBUG_MODE" == "true" ]]; then
        printf "${WHITE}[DEBUG] %s${RESET}\n" "$1" >&2
    fi
}

# Function to get human readable size
get_size() {
    local path="$1"
    if [[ -d "$path" ]] || [[ -f "$path" ]]; then
        du -sh "$path" 2>/dev/null | cut -f1 || echo "0B"
    else
        echo "0B"
    fi
}

# Function to get size in bytes for calculations
get_size_bytes() {
    local path="$1"
    if [[ -d "$path" ]] || [[ -f "$path" ]]; then
        du -sk "$path" 2>/dev/null | cut -f1 | awk '{print $1*1024}' || echo "0"
    else
        echo "0"
    fi
}

# Function to ask for confirmation
confirm() {
    local message="$1"
    local default="${2:-n}"
    local prompt="[y/N]"
    
    echo_debug "confirm() called with message: '$message', default: '$default'"
    
    if [[ "$default" == "y" ]]; then
        prompt="[Y/n]"
    fi
    
    echo_debug "Using prompt: '$prompt'"
    echo_question "$message $prompt "
    
    # Read from stdin
    echo_debug "Waiting for user input..."
    local response
    read -r response
    echo_debug "User responded: '$response'"
    
    if [[ "$default" == "y" ]]; then
        if [[ "$response" =~ ^[Nn]$ ]]; then
            echo_debug "User said no (default was yes)"
            return 1
        else
            echo_debug "User confirmed (default was yes)"
            return 0
        fi
    else
        if [[ "$response" =~ ^[Yy]$ ]]; then
            echo_debug "User said yes (default was no)"
            return 0
        else
            echo_debug "User declined (default was no)"
            return 1
        fi
    fi
}

# Global variables for spinner
SPINNER_PID=0
SPINNER_ACTIVE=false
SPINNER_PATH_FILE=""

# Function to ensure terminal is clean (only if spinner is active)
ensure_clean_terminal() {
    # Only clean if spinner is actually active
    if [[ $SPINNER_ACTIVE == true ]]; then
        SPINNER_ACTIVE=false
        if [[ $SPINNER_PID -ne 0 ]]; then
            kill $SPINNER_PID 2>/dev/null
            kill -9 $SPINNER_PID 2>/dev/null
            wait $SPINNER_PID 2>/dev/null
            SPINNER_PID=0
        fi
        # Clean terminal completely and restore cursor only if we had a spinner
        printf "\r\033[K\033[?25h"
    fi
    
    # Clean up path file if it exists
    if [[ -n "$SPINNER_PATH_FILE" && -f "$SPINNER_PATH_FILE" ]]; then
        rm -f "$SPINNER_PATH_FILE"
        SPINNER_PATH_FILE=""
    fi
}

# Function to handle script interruption (Ctrl+C)
cleanup_on_exit() {
    ensure_clean_terminal
    printf "\n"
    echo_warning "Script interrupted"
    exit 130
}

# Set trap for interruption signals
trap cleanup_on_exit INT TERM

# Set trap for normal exit to ensure spinner cleanup if needed
trap 'ensure_clean_terminal' EXIT

# Function to show animated spinner
show_spinner() {
    local message="$1"
    
    echo_debug "show_spinner() called with message: '$message'"
    
    # Skip spinner in debug mode for cleaner output
    if [[ "$DEBUG_MODE" == "true" ]]; then
        echo_debug "Debug mode active, skipping spinner - showing message instead"
        echo_info "$message"
        return 0
    fi
    
    # Stop any existing spinner first
    echo_debug "Stopping any existing spinner"
    stop_spinner
    
    # Simple spinner using a function instead of background process
    echo_debug "Setting SPINNER_ACTIVE=true"
    SPINNER_ACTIVE=true
    
    # Hide cursor
    echo_debug "Hiding cursor"
    printf "\033[?25l"
    
    # Start spinner in background
    echo_debug "Starting spinner background process"
    (
        local spin_chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
        local i=0
        while [[ $SPINNER_ACTIVE == true ]]; do
            printf "\r${CYAN} ${spin_chars:$i:1} %s${RESET}" "$message"
            sleep 0.1
            ((i++))
            if [[ $i -ge ${#spin_chars} ]]; then
                i=0
            fi
            # Check if parent wants us to stop
            if [[ ! $SPINNER_ACTIVE == true ]]; then
                break
            fi
        done
    ) &
    
    SPINNER_PID=$!
    echo_debug "Spinner started with PID: $SPINNER_PID"
}

# Function to stop spinner
stop_spinner() {
    echo_debug "stop_spinner() called"
    
    # Skip if debug mode (no spinner was started)
    if [[ "$DEBUG_MODE" == "true" ]]; then
        echo_debug "Debug mode active, no spinner to stop"
        return 0
    fi
    
    if [[ $SPINNER_ACTIVE == true ]]; then
        echo_debug "Stopping active spinner with PID: $SPINNER_PID"
        SPINNER_ACTIVE=false
        sleep 0.1  # Give spinner time to see the flag
        
        if [[ $SPINNER_PID -ne 0 ]]; then
            kill $SPINNER_PID 2>/dev/null
            wait $SPINNER_PID 2>/dev/null
            SPINNER_PID=0
        fi
    fi
    
    # Clean the line and restore cursor (simpler single-line approach)
    printf "\r\033[K\033[?25h"
    
    # Clean up path file if it exists
    if [[ -n "$SPINNER_PATH_FILE" && -f "$SPINNER_PATH_FILE" ]]; then
        rm -f "$SPINNER_PATH_FILE"
        SPINNER_PATH_FILE=""
    fi
    
    echo_debug "Spinner stopped"
}

# Function to show animated spinner with current path display
show_spinner_with_path() {
    local message="$1"
    
    # Stop any existing spinner first
    stop_spinner
    
    # Create temporary file for path communication
    SPINNER_PATH_FILE=$(mktemp)
    echo "" > "$SPINNER_PATH_FILE"
    
    # Simple spinner using a function instead of background process
    SPINNER_ACTIVE=true
    
    # Hide cursor
    printf "\033[?25l"
    
    # Start spinner in background with much simpler display
    (
        local spin_chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
        local i=0
        local last_path=""
        
        while [[ $SPINNER_ACTIVE == true ]]; do
            # Read current path from file
            local current_path=""
            if [[ -f "$SPINNER_PATH_FILE" ]]; then
                current_path=$(cat "$SPINNER_PATH_FILE" 2>/dev/null || echo "")
            fi
            
            # Only update display if path has changed or it's time for spinner animation
            if [[ "$current_path" != "$last_path" ]] || [[ $((i % 5)) -eq 0 ]]; then
                # Clear line and show spinner with message
                printf "\r\033[K${CYAN} ${spin_chars:$i:1} %s${RESET}" "$message"
                
                # Show current path on same line if available
                if [[ -n "$current_path" && "$current_path" != "" ]]; then
                    printf " ${YELLOW}(📁 %s)${RESET}" "$(basename "$current_path")"
                fi
                
                last_path="$current_path"
            fi
            
            sleep 0.1
            ((i++))
            if [[ $i -ge ${#spin_chars} ]]; then
                i=0
            fi
        done
    ) &
    
    SPINNER_PID=$!
}

# Function to update the current path being explored
update_spinner_path() {
    local path="$1"
    if [[ -n "$SPINNER_PATH_FILE" && -f "$SPINNER_PATH_FILE" ]]; then
        echo "$path" > "$SPINNER_PATH_FILE" 2>/dev/null
    fi
}

# Function to safely remove files/directories
# Sets global variable REMOVED_BYTES with the size freed
safe_remove() {
    local path="$1"
    local description="$2"
    REMOVED_BYTES=0
    
    echo_debug "safe_remove() called for path: '$path', description: '$description'"
    
    if [[ ! -e "$path" ]]; then
        echo_debug "Path does not exist: $path"
        echo_info "$description: Not found, skipping"
        return 0
    fi
    
    echo_debug "Getting size information for: $path"
    local size=$(get_size "$path")
    local size_bytes=$(get_size_bytes "$path")
    echo_debug "Size: $size, Size in bytes: $size_bytes"
    
    if [[ "$size_bytes" -eq 0 ]]; then
        echo_debug "Directory is empty, skipping"
        echo_info "$description: Empty, skipping"
        return 0
    fi
    
    echo_debug "Asking for confirmation to delete"
    if confirm "$description ($size) - Delete?"; then
        echo_debug "User confirmed deletion, attempting to remove: $path"
        if rm -rf "$path" 2>/dev/null; then
            echo_debug "Successfully deleted $path, freed $size_bytes bytes"
            echo_success "$description: Deleted ($size freed)"
            REMOVED_BYTES="$size_bytes"
            return 0
        else
            echo_debug "Failed to delete $path"
            echo_error "$description: Failed to delete"
            return 1
        fi
    else
        echo_debug "User declined deletion"
        echo_info "$description: Skipped"
        return 0
    fi
}

# --- Cleanup Functions ---

cleanup_node_modules() {
    echo_debug "Starting cleanup_node_modules function"
    echo_debug "Temporarily disabling set -e for find command"
    set +e  # Disable exit on error temporarily
    echo_header "🗂️  Cleaning node_modules directories"
    
    local total_freed=0
    echo_debug "Initialized total_freed=0"
    
    # Start spinner for the search
    echo_debug "Starting spinner for search"
    show_spinner "Searching for node_modules directories in $HOME..."
    
    # Simple and effective search: find all node_modules, exclude system dirs and nested node_modules
    echo_debug "Starting find command in $HOME with maxdepth 6"
    echo_debug "This may take 10-15 seconds depending on your filesystem..."
    local search_results
    echo_debug "About to execute find command..."
    search_results=$(find "$HOME" -maxdepth 6 -name "node_modules" -type d \
        -not -path "*/.*" \
        -not -path "*/Library/*" \
        -not -path "*/Applications/*" \
        -not -path "*/.Trash/*" \
        -not -path "*/System/*" \
        -not -path "*/usr/*" \
        -not -path "*/var/*" \
        -not -path "*/tmp/*" \
        -not -path "*/node_modules/*/node_modules" \
        2>/dev/null) 
    local find_exit_code=$?
    echo_debug "Find command completed with exit code: $find_exit_code"
    
    if [[ $find_exit_code -ne 0 ]]; then
        echo_debug "Find returned non-zero exit code (likely permission errors), but continuing with results found"
    fi
    echo_debug "Find command executed, checking results..."
    set -e  # Re-enable exit on error
    echo_debug "Re-enabled set -e"
    
    echo_debug "Find command completed successfully"
    local result_count=$(echo "$search_results" | wc -l | tr -d ' ')
    echo_debug "Found $result_count potential results"
    
    # Stop spinner after search completes
    echo_debug "Stopping spinner"
    stop_spinner
    
    # Check if any directories were found
    echo_debug "Checking if search results are empty"
    if [[ -z "$search_results" ]]; then
        echo_debug "No search results found"
        echo_info "No node_modules directories found to clean"
        return
    fi
    
    echo_debug "Search results found, processing..."
    
    # Show found directories with sizes
    echo_success "Search completed"
    echo_info "Found node_modules directories:"
    echo ""
    
    # Display results with sizes (simplified to avoid hanging)
    echo_debug "Starting size calculation with du command"
    echo_info "Calculating sizes..."
    local total_size=$(echo "$search_results" | xargs du -chs 2>/dev/null | tail -1 | cut -f1)
    echo_debug "Size calculation completed: $total_size"
    echo_success "Total size: $total_size"
    
    local found_count
    found_count=$(echo "$search_results" | wc -l)
    echo_debug "Found $found_count directories"
    echo_info "Total: $found_count directories"
    echo ""
    
    # Ask for confirmation to proceed
    echo_debug "Asking for confirmation to proceed"
    if ! confirm "Proceed with cleanup of these $found_count directories?" "y"; then
        echo_debug "User cancelled cleanup"
        echo_info "Cleanup cancelled"
        return
    fi
    
    echo_debug "User confirmed, proceeding with cleanup"
    
    # Process the results
    local processed=0
    echo_debug "Starting to process directories"
    
    # Convert search results to array to avoid pipeline subshell issues
    echo_debug "Converting search results to array"
    local -a dirs_array
    while IFS= read -r dir; do
        dirs_array+=("$dir")
    done <<< "$search_results"
    
    echo_debug "Array conversion completed, array size: ${#dirs_array[@]}"
    
    # Process each directory in the main shell to preserve variables
    echo_debug "Starting to process each directory"
    for dir in "${dirs_array[@]}"; do
        ((processed++))
        echo_debug "Processing directory $processed/$found_count: $dir"
        # dir is already an absolute path from find $HOME
        echo_info "Processing $processed/$found_count: $(basename "$dir")"
        echo_debug "Calling safe_remove for: $dir"
        safe_remove "$dir" "node_modules: $dir"
        echo_debug "safe_remove returned, REMOVED_BYTES=$REMOVED_BYTES"
        total_freed=$((total_freed + REMOVED_BYTES))
        echo_debug "Updated total_freed=$total_freed"
    done
    
    echo_debug "Finished processing all directories"
    echo_debug "Final total_freed=$total_freed"
    
    if [[ $total_freed -eq 0 ]]; then
        echo_debug "No bytes were freed"
        echo_info "No directories were actually deleted"
    else
        local total_freed_mb=$((total_freed / 1024 / 1024))
        echo_debug "Total freed: ${total_freed_mb}MB"
        echo_success "Total freed from node_modules: ${total_freed_mb}MB"
    fi
    
    echo_debug "cleanup_node_modules function completed"
}

cleanup_yarn_cache() {
    echo_header "🧶 Cleaning Yarn cache"
    
    local yarn_cache_v1="$HOME/.yarn/cache"
    local yarn_cache_v2="$HOME/.yarn/berry/cache"
    local yarn_cache_global="$HOME/Library/Caches/Yarn"
    
    safe_remove "$yarn_cache_v1" "Yarn v1 cache"
    safe_remove "$yarn_cache_v2" "Yarn Berry cache"
    safe_remove "$yarn_cache_global" "Yarn global cache"
    
    # Also clear yarn cache via command if yarn is available
    if command -v yarn >/dev/null 2>&1; then
        if confirm "Run 'yarn cache clean' command?"; then
            if yarn cache clean >/dev/null 2>&1; then
                echo_success "Yarn cache cleaned via command"
            else
                echo_warning "Failed to run yarn cache clean"
            fi
        fi
    fi
}

cleanup_npm_cache() {
    echo_header "📦 Cleaning npm cache"
    
    local npm_cache="$HOME/.npm"
    safe_remove "$npm_cache" "npm cache directory"
    
    # Also clear npm cache via command if npm is available
    if command -v npm >/dev/null 2>&1; then
        if confirm "Run 'npm cache clean --force' command?"; then
            if npm cache clean --force >/dev/null 2>&1; then
                echo_success "npm cache cleaned via command"
            else
                echo_warning "Failed to run npm cache clean"
            fi
        fi
    fi
}

cleanup_bun_cache() {
    echo_header "⚡ Cleaning Bun cache"
    
    local bun_cache="$HOME/.bun/cache"
    local bun_install_cache="$HOME/Library/Caches/bun"
    
    safe_remove "$bun_cache" "Bun cache directory"
    safe_remove "$bun_install_cache" "Bun install cache"
}

cleanup_pods() {
    echo_header "🍎 Cleaning CocoaPods"
    
    local pods_cache="$HOME/Library/Caches/CocoaPods"
    safe_remove "$pods_cache" "CocoaPods cache"
    
    # Create a temporary file to store search results
    local temp_file
    temp_file=$(mktemp)
    
    # Start spinner for the search with path display
    show_spinner_with_path "Searching for Pods directories in $HOME (max depth 8)..."
    
    # Store the path file variable for the subshell
    local path_file="$SPINNER_PATH_FILE"
    
    # Perform the search with path updates
    {
        # Initialize the path display
        echo "$HOME" > "$SPINNER_PATH_FILE" 2>/dev/null
        
        # Get a list of specific directories to search
        local search_paths=()
        
        # Add common iOS/macOS project directories that might contain Pods
        local common_dirs=(
            "$HOME/Documents"
            "$HOME/Desktop" 
            "$HOME/Projects"
            "$HOME/Development"
            "$HOME/dev"
            "$HOME/code"
            "$HOME/workspace"
            "$HOME/Downloads"
        )
        
        # Only add directories that actually exist
        for dir in "${common_dirs[@]}"; do
            if [[ -d "$dir" ]]; then
                search_paths+=("$dir")
            fi
        done
        
        # Also find any other directories in home (but exclude known large ones)
        while IFS= read -r -d '' dir; do
            # Skip if already in our list
            local already_added=false
            for existing in "${search_paths[@]}"; do
                if [[ "$dir" == "$existing" ]]; then
                    already_added=true
                    break
                fi
            done
            
            if [[ "$already_added" == false ]]; then
                search_paths+=("$dir")
            fi
        done < <(find "$HOME" -maxdepth 1 -type d \
            -not -path "$HOME" \
            -not -path "*/.*" \
            -not -path "*/Library" \
            -not -path "*/Applications" \
            -print0 2>/dev/null)
        
        # Process each path and update display
        for search_dir in "${search_paths[@]}"; do
            # Update the path display directly
            echo "$search_dir" > "$SPINNER_PATH_FILE" 2>/dev/null
            
            # Skip very large directories that would take too long
            if [[ "$search_dir" == *"/.Trash"* ]] || [[ "$search_dir" == *"/Library"* ]] || [[ "$search_dir" == *"/node_modules"* ]] || [[ "$search_dir" == "$HOME" ]]; then
                continue
            fi
            
            # Look for Pods in this directory and subdirectories
            find "$search_dir" -maxdepth 4 -name "Pods" -type d \
                -print0 2>/dev/null
            
            # Small delay to make the path updates visible
            sleep 0.1
        done
    } > "$temp_file"
    
    # Stop spinner after search completes
    stop_spinner
    echo_success "Search completed"
    
    # Process the results
    while IFS= read -r -d '' dir; do
        safe_remove "$dir" "Pods directory: $dir"
    done < "$temp_file"
    
    # Clean up temp file
    rm -f "$temp_file"
}

cleanup_docker() {
    echo_header "🐳 Cleaning Docker"
    
    if ! command -v docker >/dev/null 2>&1; then
        echo_info "Docker not found, skipping"
        return
    fi
    
    echo_warning "This will remove all stopped containers, unused networks, dangling images, and build cache"
    
    if confirm "Clean Docker system (docker system prune -a)?"; then
        if docker system prune -a --volumes -f >/dev/null 2>&1; then
            echo_success "Docker system cleaned"
        else
            echo_error "Failed to clean Docker system"
        fi
    fi
}

cleanup_xcode() {
    echo_header "🗄️  Cleaning Xcode caches"
    
    local derived_data="$HOME/Library/Developer/Xcode/DerivedData"
    local archives="$HOME/Library/Developer/Xcode/Archives"
    local device_support="$HOME/Library/Developer/Xcode/iOS DeviceSupport"
    local simulator_cache="$HOME/Library/Developer/CoreSimulator/Caches"
    
    safe_remove "$derived_data" "Xcode DerivedData"
    safe_remove "$simulator_cache" "iOS Simulator cache"
    
    if confirm "Also clean Xcode Archives? (This will remove your app archives)"; then
        safe_remove "$archives" "Xcode Archives"
    fi
    
    if confirm "Clean iOS Device Support files? (They will be re-downloaded when needed)"; then
        safe_remove "$device_support" "iOS Device Support"
    fi
}

cleanup_system_caches() {
    echo_header "🧹 Cleaning system caches"
    
    # Clean .DS_Store files
    echo_info "Searching for .DS_Store files..."
    local ds_store_count
    ds_store_count=$(find "$HOME" -name ".DS_Store" -type f 2>/dev/null | wc -l | tr -d ' ')
    
    if [[ "$ds_store_count" -gt 0 ]]; then
        if confirm "Remove $ds_store_count .DS_Store files?"; then
            find "$HOME" -name ".DS_Store" -type f -delete 2>/dev/null
            echo_success "Removed $ds_store_count .DS_Store files"
        fi
    else
        echo_info "No .DS_Store files found"
    fi
    
    # Clean Trash
    local trash="$HOME/.Trash"
    if [[ -d "$trash" ]] && [[ "$(ls -A "$trash" 2>/dev/null)" ]]; then
        safe_remove "$trash/*" "Trash contents"
    else
        echo_info "Trash is already empty"
    fi
    
    # Clean user cache directories
    local user_caches="$HOME/Library/Caches"
    if [[ -d "$user_caches" ]]; then
        echo_info "Found user cache directory: $(get_size "$user_caches")"
        if confirm "Clean user cache directory? (Some apps may run slower on first launch)"; then
            # Clean specific cache subdirectories instead of the whole thing
            local cleaned=0
            for cache_dir in "$user_caches"/*; do
                if [[ -d "$cache_dir" ]]; then
                    local dir_name
                    dir_name=$(basename "$cache_dir")
                    safe_remove "$cache_dir" "Cache: $dir_name"
                    cleaned=1
                fi
            done
            
            if [[ $cleaned -eq 1 ]]; then
                echo_success "User caches cleaned"
            fi
        fi
    fi
}

# --- Interactive Menu Functions ---

# Define cleanup options
declare -a CLEANUP_OPTIONS=(
    "🗂️ Clean node_modules directories"
    "🧶 Clean Yarn cache"
    "📦 Clean npm cache"
    "⚡ Clean Bun cache"
    "🍎 Clean CocoaPods cache & Pods directories"
    "🐳 Clean Docker containers & images"
    "🗄️ Clean Xcode caches"
    "🧹 Clean system caches (.DS_Store, Trash, etc.)"
)

# Define cleanup functions
declare -a CLEANUP_FUNCTIONS=(
    "cleanup_node_modules"
    "cleanup_yarn_cache"
    "cleanup_npm_cache"
    "cleanup_bun_cache"
    "cleanup_pods"
    "cleanup_docker"
    "cleanup_xcode"
    "cleanup_system_caches"
)

# Selection state array
declare -a SELECTED=()

# Current cursor position
CURRENT_OPTION=0

# Initialize selection array
init_selections() {
    for i in $(seq 0 $((${#CLEANUP_OPTIONS[@]} - 1))); do
        SELECTED[i]=false
    done
}

# Function to detect key presses - Robust method like yarn upgrade-interactive
detect_key() {
    local key
    
    # Save terminal state
    local old_tty_state
    old_tty_state=$(stty -g)
    
    # Set terminal to raw mode for proper key detection
    stty -echo -icanon min 0 time 1
    
    # Read single character with the most robust method
    IFS= read -d'' -s -n1 key 2>/dev/null || key=""
    
    # Restore terminal state immediately
    stty "$old_tty_state"
    
    # Detect the key based on ASCII value and special sequences
    case "$key" in
        # Space character (ASCII 32)
        ' ')
            echo "space"
            ;;
        # Enter/Return key (empty or newline)
        ''|$'\n'|$'\r')
            echo "enter"
            ;;
        # Escape sequence for arrows
        $'\x1b'|$'\033')
            # Read additional characters for arrow keys
            stty -echo -icanon min 0 time 1
            local seq
            IFS= read -d'' -s -n2 seq 2>/dev/null || seq=""
            stty "$old_tty_state"
            
            case "$seq" in
                '[A') echo "up" ;;
                '[B') echo "down" ;;
                '[C') echo "right" ;;
                '[D') echo "left" ;;
                *) echo "quit" ;;  # Just escape key
            esac
            ;;
        # Regular characters
        'k'|'K')
            echo "up"
            ;;
        'j'|'J')
            echo "down"
            ;;
        'q'|'Q')
            echo "quit"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Function to toggle selection
toggle_selection() {
    if [[ "${SELECTED[$CURRENT_OPTION]}" == "true" ]]; then
        SELECTED[$CURRENT_OPTION]=false
    else
        SELECTED[$CURRENT_OPTION]=true
    fi
}

# Function to count selected options
count_selected() {
    local count=0
    for selection in "${SELECTED[@]}"; do
        [[ "$selection" == "true" ]] && ((count++))
    done
    echo $count
}

# Function to draw the menu
draw_menu() {
    # Clear screen and move cursor to top
    printf "\033[2J\033[H"
    
    echo_header "🧹 macOS Development Cleanup Tool"
    echo
    
    # Draw each option
    for i in $(seq 0 $((${#CLEANUP_OPTIONS[@]} - 1))); do
        local prefix="  "
        local checkbox="○"
        local color="$RESET"
        
        # Set cursor indicator
        if [[ $i -eq $CURRENT_OPTION ]]; then
            prefix="▶ "
            color="$BOLD$CYAN"
        fi
        
        # Set checkbox state  
        if [[ "${SELECTED[$i]}" == "true" ]]; then
            checkbox="●"
            checkbox_color="$GREEN"
        else
            checkbox="○"
            checkbox_color="$WHITE"
        fi
        
        echo -e "${color}${prefix}${checkbox_color}${checkbox}${RESET} ${CLEANUP_OPTIONS[$i]}"
    done
    
    echo
    local selected_count
    selected_count=$(count_selected)
    echo -e "${YELLOW}(${selected_count} selected)${RESET} ${CYAN}↑/↓ j/k${RESET}: navigate, ${GREEN}space${RESET}: toggle, ${MAGENTA}enter${RESET}: confirm, ${RED}q${RESET}: quit"
}

# Main interactive menu function
interactive_menu() {
    init_selections
    
    while true; do
        draw_menu
        
        local key
        key=$(detect_key)
        
        case "$key" in
            "up")
                ((CURRENT_OPTION--))
                if [[ $CURRENT_OPTION -lt 0 ]]; then
                    CURRENT_OPTION=$((${#CLEANUP_OPTIONS[@]} - 1))
                fi
                ;;
            "down")
                ((CURRENT_OPTION++))
                if [[ $CURRENT_OPTION -ge ${#CLEANUP_OPTIONS[@]} ]]; then
                    CURRENT_OPTION=0
                fi
                ;;
            "space")
                toggle_selection
                ;;
            "enter")
                execute_selected
                break
                ;;
            "quit")
                echo
                echo_success "Cleanup cancelled"
                exit 0
                ;;
        esac
    done
}

# Function to execute selected cleanup operations
execute_selected() {
    local selected_count
    selected_count=$(count_selected)
    
    if [[ $selected_count -eq 0 ]]; then
        echo
        echo_warning "No options selected. Exiting."
        return
    fi
    
    echo
    echo_header "Executing $selected_count selected cleanup operations"
    
    for i in $(seq 0 $((${#CLEANUP_OPTIONS[@]} - 1))); do
        if [[ "${SELECTED[$i]}" == "true" ]]; then
            echo
            ${CLEANUP_FUNCTIONS[$i]}
        fi
    done
}

# --- Main Script ---

main() {
    echo_debug "Script started with arguments: $*"
    echo_debug "DEBUG_MODE is set to: $DEBUG_MODE"
    
    # Check if running on macOS
    echo_debug "Checking if running on macOS"
    if [[ "$(uname)" != "Darwin" ]]; then
        echo_debug "Not running on macOS, exiting"
        echo_error "This script is designed for macOS only"
        exit 1
    fi
    echo_debug "macOS check passed"
    
    # Check if we have arguments for non-interactive mode
    echo_debug "Checking command line arguments"
    if [[ "$1" == "--node-modules" ]] || [[ "$1" == "-n" ]]; then
        echo_debug "Non-interactive mode requested, running cleanup_node_modules"
        cleanup_node_modules
    else
        echo_debug "Starting interactive menu"
        # Start interactive menu
        interactive_menu
    fi
    
    echo_debug "Main cleanup operations completed"
    echo
    echo_success "Cleanup complete! 🎉"
    echo_info "Run 'df -h' to see updated disk usage"
    echo_debug "Script execution finished"
}

# Run the script
main "$@"