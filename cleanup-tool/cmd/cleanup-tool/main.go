package main

import (
	"fmt"
	"log"
	"os"

	tea "github.com/charmbracelet/bubbletea"
	"cleanup-tool/internal/app"
)

func main() {
	if len(os.Args) > 1 {
		switch os.Args[1] {
		case "--help", "-h":
			printHelp()
			return
		case "--legacy":
			// Use legacy mode
			m := app.NewModel()
			p := tea.NewProgram(m, tea.WithAltScreen())
			if _, err := p.Run(); err != nil {
				log.Fatal(err)
			}
			return
		case "--interactive", "-i":
			// Use new interactive mode (explicit)
			m := app.NewInteractiveModel()
			p := tea.NewProgram(m, tea.WithAltScreen())
			if _, err := p.Run(); err != nil {
				log.Fatal(err)
			}
			return
		}
	}

	// Default to new interactive mode
	m := app.NewInteractiveModel()
	p := tea.NewProgram(m, tea.WithAltScreen())

	if _, err := p.Run(); err != nil {
		log.Fatal(err)
	}
}

func printHelp() {
	fmt.Println(`cleanup-tool - Modern macOS Development Environment Cleanup

USAGE:
    cleanup-tool [OPTIONS]

OPTIONS:
    -h, --help         Show this help message
    -i, --interactive  Use new interactive mode (default)
    --legacy          Use legacy cleanup mode

INTERACTIVE MODE (default):
    Unified menu with both interactive and direct cleanup options:
    
    INTERACTIVE CLEANUPS (individual selection):
    • Node.js node_modules directories - Find and selectively remove node_modules
    • CocoaPods Pods directories - Find and selectively remove Pods folders
    
    DIRECT CLEANUPS (immediate execution):
    • npm cache - Clear npm cache directory
    • Yarn cache - Clear Yarn v1 and Berry cache directories  
    • Bun cache - Clear Bun cache directories
    • CocoaPods cache - Remove CocoaPods cache directory
    • Docker containers & images - Prune Docker system
    • Xcode caches - Remove Xcode DerivedData and simulator caches
    • System caches - Remove .DS_Store files, Trash, and user caches

CONTROLS:
    Use arrow keys or j/k to navigate
    Press space to toggle selection (multi-select supported)
    Press enter to execute selected cleanups
    Press 'r' to return to main menu
    Press q to quit

INTERACTIVE SELECTION CONTROLS (for node_modules/Pods):
    Use arrow keys or j/k to navigate items
    Press space to toggle individual item selection
    Press 'a' to select all, 'n' to select none
    Press 's' to sort by size
    Press enter to delete selected items

LEGACY MODE (--legacy):
    Original interface with batch cleanup selection`)
}