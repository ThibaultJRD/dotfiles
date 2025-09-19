# Cleanup Tool

A modern, interactive macOS development environment cleanup tool built with Go and [Bubble Tea](https://github.com/charmbracelet/bubbletea).

## Features

- **Interactive TUI**: Beautiful terminal user interface with keyboard navigation
- **Multiple Cleanup Types**: Supports various development caches and temporary files
- **Real-time Progress**: Shows progress and space freed during operations
- **Safe Operations**: Shows what will be deleted before executing
- **Modern Architecture**: Built with Go for performance and reliability

## Cleanup Types

- 🗂️ **Node.js node_modules**: Find and remove node_modules directories
- 📦 **npm cache**: Clear npm cache directory  
- 🧶 **Yarn cache**: Clear Yarn v1 and Berry cache directories
- ⚡ **Bun cache**: Clear Bun cache directories
- 🍎 **CocoaPods**: Remove CocoaPods cache and Pods directories
- 🐳 **Docker**: Prune Docker system (containers, images, networks)
- 🗄️ **Xcode**: Remove Xcode DerivedData and simulator caches
- 🧹 **System caches**: Remove .DS_Store files, Trash, and user caches

## Usage

### Interactive Mode (Default)

```bash
cleanup
```

Use arrow keys (or j/k) to navigate, space to select/deselect, enter to execute, and q to quit.

### Help

```bash
cleanup --help
```

## Installation

The cleanup tool is automatically built and configured as part of the dotfiles installation. The following aliases are available:

- `cleanup` - Main command
- `clean` - Shorter alias
- `cleancache` - Descriptive alias

To manually rebuild the tool:

```bash
build-cleanup
```

## Architecture

```
cleanup-tool/
├── cmd/cleanup-tool/     # Main application entry point
├── internal/
│   ├── app/              # Bubble Tea application model
│   ├── cleanup/          # Cleanup logic and handlers
│   └── ui/               # UI components (future)
└── pkg/
    ├── scanner/          # File system scanning utilities (future)
    └── utils/            # Utility functions (future)
```

## Dependencies

- [Bubble Tea](https://github.com/charmbracelet/bubbletea) - Terminal UI framework
- [Lipgloss](https://github.com/charmbracelet/lipgloss) - Styling and layout
- [Bubbles](https://github.com/charmbracelet/bubbles) - UI components

## Migration from Bash Script

This tool replaces the previous `cleanup.sh` bash script with:

- **Better UX**: Modern interactive interface vs text-based prompts
- **Performance**: Go performance vs bash script execution
- **Maintainability**: Structured code vs 950+ line bash script
- **Safety**: Better error handling and preview of actions
- **Extensibility**: Easy to add new cleanup types

## Development

### Building

```bash
go build ./cmd/cleanup-tool
```

### Running

```bash
./cleanup-tool
```

### Adding New Cleanup Types

1. Add a new `Type` in `internal/cleanup/types.go`
2. Implement the handler function in `internal/cleanup/handlers.go`
3. The new type will automatically appear in the interactive menu