#!/bin/bash

# ==============================================================================
# Dotfiles Installation Test Script
# ==============================================================================
# This script validates that the dotfiles installation was successful
# ==============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# --- Utility Functions ---
test_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

test_info() {
    echo -e "${BLUE}Testing: $1${NC}"
}

test_pass() {
    echo -e "${GREEN}✓ PASS: $1${NC}"
    ((TESTS_PASSED++))
}

test_fail() {
    echo -e "${RED}✗ FAIL: $1${NC}"
    ((TESTS_FAILED++))
}

test_warn() {
    echo -e "${YELLOW}⚠ WARNING: $1${NC}"
}

run_test() {
    ((TESTS_RUN++))
    test_info "$1"
    if eval "$2"; then
        test_pass "$1"
    else
        test_fail "$1"
    fi
}

# --- Test Functions ---
test_homebrew() {
    test_header "Homebrew Installation"
    run_test "Homebrew is installed" "command -v brew >/dev/null 2>&1"
    run_test "Homebrew PATH is configured" "echo \$PATH | grep -q brew"
}

test_shell_config() {
    test_header "Shell Configuration"
    run_test "Zsh is the default shell" "[ \"\$SHELL\" = '/bin/zsh' ] || [ \"\$SHELL\" = '/opt/homebrew/bin/zsh' ] || [ \"\$SHELL\" = '/usr/local/bin/zsh' ]"
    run_test ".zshrc exists" "[ -f \"\$HOME/.zshrc\" ]"
    run_test "Oh My Zsh is installed" "[ -d \"\$HOME/.oh-my-zsh\" ]"
    run_test "Starship is installed" "command -v starship >/dev/null 2>&1"
}

test_core_tools() {
    test_header "Core Tools Installation"
    
    # Essential CLI tools
    local tools=(
        "git"
        "nvim"
        "bat"
        "eza"
        "fzf"
        "yazi"
        "tmux"
        "lazygit"
        "zoxide"
        "gh"
        "jq"
        "fd"
        "ripgrep:rg"
    )
    
    for tool_spec in "${tools[@]}"; do
        if [[ "$tool_spec" == *":"* ]]; then
            tool_name="${tool_spec%%:*}"
            command_name="${tool_spec##*:}"
        else
            tool_name="$tool_spec"
            command_name="$tool_spec"
        fi
        run_test "$tool_name is installed" "command -v \"$command_name\" >/dev/null 2>&1"
    done
}

test_config_files() {
    test_header "Configuration Files"
    
    local configs=(
        "$HOME/.config/kitty/kitty.conf"
        "$HOME/.config/starship.toml"
        "$HOME/.config/tmux/tmux.conf"
        "$HOME/.config/nvim/init.lua"
        "$HOME/.config/yazi/yazi.toml"
        "$HOME/.config/bat/config"
    )
    
    for config in "${configs[@]}"; do
        config_name=$(basename "$config")
        run_test "$config_name exists" "[ -f \"$config\" ]"
    done
}

test_symlinks() {
    test_header "Symbolic Links"
    
    # These are the actual symlinks created by the install script
    local symlinks=(
        "$HOME/.config/kitty"
        "$HOME/.config/starship.toml"
        "$HOME/.config/tmux"
        "$HOME/.config/nvim"
        "$HOME/.config/yazi"
        "$HOME/.config/bat"
    )
    
    for symlink in "${symlinks[@]}"; do
        symlink_name=$(basename "$symlink")
        run_test "$symlink_name is a symlink" "[ -L \"$symlink\" ]"
    done
}

test_environment() {
    test_header "Environment Variables"
    
    # Test environment variables by sourcing .zshrc
    if source "$HOME/.zshrc" 2>/dev/null; then
        run_test "EDITOR is set to nvim" "[ \"\$EDITOR\" = 'nvim' ]"
        run_test "PATH includes Homebrew" "echo \$PATH | grep -q brew"
        if [ -d "$HOME/.n" ]; then
            run_test "PATH includes Node.js" "echo \$PATH | grep -q '\\.n/bin'"
        else
            ((TESTS_RUN++))
            test_warn "Node.js not installed via n, skipping PATH test"
        fi
    else
        ((TESTS_RUN+=3))
        test_fail "Could not source .zshrc"
        test_fail "EDITOR is set to nvim"
        test_fail "PATH includes Homebrew"
    fi
}

test_aliases() {
    test_header "Shell Aliases"
    
    # Test aliases by sourcing .zshrc
    if source "$HOME/.zshrc" 2>/dev/null; then
        run_test "cat alias points to bat" "alias cat 2>/dev/null | grep -q bat"
        run_test "lg alias points to lazygit" "alias lg 2>/dev/null | grep -q lazygit"
        run_test "v alias points to nvim" "alias v 2>/dev/null | grep -q nvim"
        run_test "ls alias points to eza" "alias ls 2>/dev/null | grep -q eza"
    else
        ((TESTS_RUN+=4))
        test_fail "Could not source .zshrc for alias testing"
    fi
}

test_nodejs() {
    test_header "Node.js Environment"
    
    if [ -d "$HOME/.n" ]; then
        run_test "Node.js version manager (n) is installed" "command -v n >/dev/null 2>&1"
        run_test "Node.js is installed" "command -v node >/dev/null 2>&1"
        run_test "npm is installed" "command -v npm >/dev/null 2>&1"
    else
        test_warn "Node.js not installed via n"
    fi
}

test_fonts() {
    test_header "Fonts"
    
    # Check if fonts are installed (macOS specific)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        local font_dirs=("$HOME/Library/Fonts" "/Library/Fonts" "/System/Library/Fonts")
        local nerd_fonts_found=false
        
        for font_dir in "${font_dirs[@]}"; do
            if find "$font_dir" -name "*Nerd*" -type f 2>/dev/null | head -1 | grep -q .; then
                nerd_fonts_found=true
                break
            fi
        done
        
        if [ "$nerd_fonts_found" = true ]; then
            test_pass "Nerd Fonts are installed"
            ((TESTS_PASSED++))
        else
            test_fail "Nerd Fonts not found"
            ((TESTS_FAILED++))
        fi
        ((TESTS_RUN++))
    fi
}

test_plugins() {
    test_header "Zsh Plugins"
    
    local plugins=(
        "zsh-syntax-highlighting"
        "zsh-autosuggestions"
        "zsh-completions"
        "zsh-history-substring-search"
    )
    
    for plugin in "${plugins[@]}"; do
        run_test "$plugin is installed" "[ -d \"\$HOME/.oh-my-zsh/custom/plugins/$plugin\" ]"
    done
}

# --- Main Test Execution ---
main() {
    echo -e "${BLUE}===================================================${NC}"
    echo -e "${BLUE}    Dotfiles Installation Test Suite${NC}"
    echo -e "${BLUE}===================================================${NC}"
    
    # Run all tests
    test_homebrew
    test_shell_config
    test_core_tools
    test_config_files
    test_symlinks
    test_environment
    test_aliases
    test_nodejs
    test_fonts
    test_plugins
    
    # Print results
    echo -e "\n${BLUE}===================================================${NC}"
    echo -e "${BLUE}                  Test Results${NC}"
    echo -e "${BLUE}===================================================${NC}"
    echo -e "Tests run: ${TESTS_RUN}"
    echo -e "Tests passed: ${GREEN}${TESTS_PASSED}${NC}"
    echo -e "Tests failed: ${RED}${TESTS_FAILED}${NC}"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "\n${GREEN}🎉 All tests passed! Your dotfiles installation is working correctly.${NC}"
        exit 0
    else
        echo -e "\n${RED}❌ Some tests failed. Please check the output above for details.${NC}"
        exit 1
    fi
}

# Run the main function
main "$@"