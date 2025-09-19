package main

import (
	"fmt"
	"log"
	"os"

	tea "github.com/charmbracelet/bubbletea"
	"cleanup-tool/internal/app"
)

func main() {
	if len(os.Args) > 1 && (os.Args[1] == "--help" || os.Args[1] == "-h") {
		printHelp()
		return
	}

	m := app.NewModel()
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
    -h, --help    Show this help message

INTERACTIVE MODE:
    Use arrow keys to navigate
    Press space to toggle selection
    Press enter to execute selected cleanups
    Press q to quit

CLEANUP TYPES:
    • Node.js node_modules directories
    • npm cache
    • Yarn cache
    • Bun cache
    • CocoaPods cache & Pods directories
    • Docker containers & images
    • Xcode DerivedData & caches
    • System caches (.DS_Store, Trash, etc.)`)
}