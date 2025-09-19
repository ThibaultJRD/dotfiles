package cleanup

import (
	"fmt"
	"os"
	"path/filepath"

	tea "github.com/charmbracelet/bubbletea"
)

type Type struct {
	ID          string
	Name        string
	Description string
	Icon        string
	Handler     func() tea.Cmd
}

type Result struct {
	Type        string
	Description string
	Success     bool
	BytesFreed  int64
	Error       error
}

type ProgressMsg string
type CompleteMsg Result
type AllCompleteMsg bool

func GetAllTypes() []Type {
	return []Type{
		{
			ID:          "node_modules",
			Name:        "Clean node_modules directories",
			Description: "Find and remove node_modules directories",
			Icon:        "🗂️",
			Handler:     cleanNodeModules,
		},
		{
			ID:          "npm_cache",
			Name:        "Clean npm cache",
			Description: "Clear npm cache directory",
			Icon:        "📦",
			Handler:     cleanNpmCache,
		},
		{
			ID:          "yarn_cache",
			Name:        "Clean Yarn cache",
			Description: "Clear Yarn v1 and Berry cache directories",
			Icon:        "🧶",
			Handler:     cleanYarnCache,
		},
		{
			ID:          "bun_cache",
			Name:        "Clean Bun cache",
			Description: "Clear Bun cache directories",
			Icon:        "⚡",
			Handler:     cleanBunCache,
		},
		{
			ID:          "cocoapods",
			Name:        "Clean CocoaPods cache & Pods directories",
			Description: "Remove CocoaPods cache and Pods directories",
			Icon:        "🍎",
			Handler:     cleanCocoaPods,
		},
		{
			ID:          "docker",
			Name:        "Clean Docker containers & images",
			Description: "Prune Docker system (containers, images, networks)",
			Icon:        "🐳",
			Handler:     cleanDocker,
		},
		{
			ID:          "xcode",
			Name:        "Clean Xcode caches",
			Description: "Remove Xcode DerivedData and simulator caches",
			Icon:        "🗄️",
			Handler:     cleanXcode,
		},
		{
			ID:          "system",
			Name:        "Clean system caches",
			Description: "Remove .DS_Store files, Trash, and user caches",
			Icon:        "🧹",
			Handler:     cleanSystemCaches,
		},
	}
}

func RunCleanups(types []Type) tea.Cmd {
	return func() tea.Msg {
		results := make([]Result, 0, len(types))
		
		for _, cleanupType := range types {
			// Send progress message
			progressCmd := func() tea.Msg {
				return ProgressMsg(fmt.Sprintf("Running %s...", cleanupType.Name))
			}
			progressCmd()

			// Run the cleanup
			cmd := cleanupType.Handler()
			if cmd != nil {
				msg := cmd()
				if result, ok := msg.(CompleteMsg); ok {
					results = append(results, Result(result))
				}
			}
		}

		// Send completion message
		return AllCompleteMsg(true)
	}
}

func getDirSize(path string) (int64, error) {
	var size int64
	err := filepath.Walk(path, func(_ string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() {
			size += info.Size()
		}
		return err
	})
	return size, err
}