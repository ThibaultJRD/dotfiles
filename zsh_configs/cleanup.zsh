# ==============================================================================
# Cleanup Tool Configuration
# ==============================================================================
# This file provides aliases and functions for the modern Go-based cleanup tool

# Auto-detect the dotfiles repository path
_detect_dotfiles_path() {
    # Get the directory of this script file
    local script_path="${(%):-%N}"
    local script_dir="${script_path:A:h}"
    
    # Look for the cleanup-tool directory by going up the directory tree
    local current_dir="$script_dir"
    while [[ "$current_dir" != "/" ]]; do
        if [[ -d "$current_dir/cleanup-tool" ]]; then
            echo "$current_dir"
            return 0
        fi
        current_dir="${current_dir:h}"
    done
    
    # Fallback: return empty if not found
    return 1
}

# Detect dotfiles path and set cleanup tool path
_DOTFILES_ROOT="$(_detect_dotfiles_path)"
if [[ -n "$_DOTFILES_ROOT" ]]; then
    export CLEANUP_TOOL_PATH="$_DOTFILES_ROOT/cleanup-tool/cleanup-tool"
    
    # Main cleanup alias
    alias cleanup="$CLEANUP_TOOL_PATH"
    
    # Alternative aliases for convenience
    alias clean="$CLEANUP_TOOL_PATH"
    alias cleancache="$CLEANUP_TOOL_PATH"
fi

# Build the cleanup tool if it doesn't exist or source files are newer
_ensure_cleanup_tool() {
    if [[ -z "$_DOTFILES_ROOT" ]]; then
        echo "Warning: Could not detect dotfiles repository path" >&2
        return 1
    fi
    
    local tool_dir="$_DOTFILES_ROOT/cleanup-tool"
    local binary="$tool_dir/cleanup-tool"
    
    if [[ ! -f "$binary" ]] || [[ "$tool_dir" -nt "$binary" ]]; then
        echo "Building cleanup tool..."
        (builtin cd "$tool_dir" && go build ./cmd/cleanup-tool)
    fi
}

# Auto-build function that can be called manually
build-cleanup() {
    if [[ -z "$_DOTFILES_ROOT" ]]; then
        echo "Error: Could not detect dotfiles repository path" >&2
        return 1
    fi
    
    local tool_dir="$_DOTFILES_ROOT/cleanup-tool"
    echo "Building cleanup tool..."
    (builtin cd "$tool_dir" && go build ./cmd/cleanup-tool)
}

# Ensure tool is built when shell starts (only if Go is available)
if command -v go >/dev/null 2>&1; then
    _ensure_cleanup_tool
fi
