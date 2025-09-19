# 🧹 Cleanup Tool - Interactive Development Environment Cleanup

A modern interactive tool for cleaning macOS development environments, similar to `npkill` but extensible for different types of directories.

## 🚀 Features

### Interactive Mode (Default)
- **Progressive scanning**: Real-time search with animated progress bars and ETA
- **Granular selection**: Choose individual directories to delete
- **Enhanced display**: Size color coding, project context, scroll indicators
- **Advanced sorting**: Sort by size, date, or path alphabetically  
- **Smart filtering**: Filter by minimum size (100MB+)
- **Real-time feedback**: Live counters, scan speed, spinner animations
- **Intuitive interface**: Navigate with arrows/vi keys, select with space
- **Safe confirmation**: Summary before deletion

### Available Scanners
- **📦 Node.js node_modules**: Find and remove node_modules directories
- **🍎 CocoaPods Pods**: Find and remove Pods directories

### Legacy Mode (Preserved)
- 🗂️ **Node.js node_modules**: Find and remove node_modules directories
- 📦 **npm cache**: Clear npm cache directory  
- 🧶 **Yarn cache**: Clear Yarn v1 and Berry cache directories
- ⚡ **Bun cache**: Clear Bun cache directories
- 🍎 **CocoaPods**: Remove CocoaPods cache and Pods directories
- 🐳 **Docker**: Prune Docker system (containers, images, networks)
- 🗄️ **Xcode**: Remove Xcode DerivedData and simulator caches
- 🧹 **System caches**: Remove .DS_Store files, Trash, and user caches

## 📦 Installation

```bash
# Build
go build -o cleanup-tool cmd/cleanup-tool/main.go

# Install to PATH (optional)
sudo cp cleanup-tool /usr/local/bin/
```

## 🎮 Usage

### Interactive Mode (recommended)
```bash
./cleanup-tool
# or explicitly
./cleanup-tool --interactive
```

### Legacy Mode
```bash
./cleanup-tool --legacy
```

### Help
```bash
./cleanup-tool --help
```

## 🕹️ Interactive Controls

### Scanner Selection
- `↑/↓` or `j/k`: Navigate
- `Enter`: Select scanner
- `q`: Quit

### Item Selection
- `↑/↓` or `j/k`: Navigate items
- `Space`: Toggle individual selection
- `a`: Select all items
- `n`: Select none
- `s`: Sort by size (largest first)
- `d`: Sort by date (newest first)
- `p`: Sort by path (alphabetical)
- `f`: Filter items >100MB
- `Enter`: Delete selected items
- `r`: Return to main menu
- `q`: Quit

## 🏗️ Architecture

### Modular Structure
```
├── pkg/
│   ├── scanner/           # Interfaces and scanners
│   │   ├── interface.go   # Common Scanner interface
│   │   ├── nodemodules.go # Scanner for node_modules
│   │   └── pods.go        # Scanner for Pods
│   └── utils/             # Shared utilities
│       └── size.go        # Size calculations
├── internal/
│   ├── ui/                # Interface components
│   │   └── scanner_view.go
│   └── app/               # Application logic
│       ├── model.go       # Legacy model
│       └── interactive_model.go # New model
└── cmd/
    └── cleanup-tool/
        └── main.go        # Entry point
```

### Scanner Interface
```go
type Scanner interface {
    Type() string
    Name() string  
    Icon() string
    Description() string
    Scan(ctx context.Context, rootPath string) tea.Cmd
    ShouldSkipDir(path string, dirName string) bool
    IsTargetItem(path string, dirName string) bool
    CalculateSize(item *Item) tea.Cmd
}
```

## 🔧 Adding New Scanners

1. Implement the `Scanner` interface in `pkg/scanner/`
2. Add your scanner to the list in `NewInteractiveModel()`
3. Test with `go build && ./cleanup-tool`

Minimal example:
```go
type MyScanner struct{}

func (s *MyScanner) Type() string { return "my_type" }
func (s *MyScanner) Name() string { return "My Custom Scanner" }
func (s *MyScanner) Icon() string { return "🔍" }
// ... other methods
```

## 🧪 Testing

```bash
# Test compilation and basic features
./test_interactive.sh

# Manual safe testing (scan only)
./cleanup-tool  # then navigate without confirming deletion
```

## 🔒 Security

- **No automatic deletion**: All items must be explicitly selected
- **Confirmation required**: Summary shown before any deletion
- **Path validation**: Existence verification before deletion
- **Preview mode**: Ability to scan without deleting

## 🆚 Comparison with npkill

| Feature | npkill | cleanup-tool |
|---|---|---|
| Interactive interface | ✅ | ✅ |
| Granular selection | ✅ | ✅ |
| Size calculation | ✅ | ✅ |
| Cleanup types | Node.js only | Extensible |
| Sort by size | ✅ | ✅ |
| Legacy mode | ❌ | ✅ |
| Modular scanners | ❌ | ✅ |
| CocoaPods support | ❌ | ✅ |

## 🤝 Contributing

1. Fork the project
2. Create a feature branch (`git checkout -b feature/amazing-scanner`)
3. Commit your changes (`git commit -m 'Add amazing scanner'`)
4. Push to the branch (`git push origin feature/amazing-scanner`)
5. Open a Pull Request

## 📄 License

This project is under MIT License. See `LICENSE` for more details.

## 🎯 Compatibility

- **System**: macOS (tested on macOS 15.0+)
- **Go**: 1.25+ required
- **Terminal**: Compatible with all modern terminals (iTerm2, Terminal.app, Kitty, etc.)

The cleanup tool is automatically built and configured as part of the dotfiles installation. The following aliases are available:

- `cleanup` - Main command
- `clean` - Shorter alias  
- `cleancache` - Descriptive alias

To manually rebuild the tool:

```bash
build-cleanup
```