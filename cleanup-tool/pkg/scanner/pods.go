package scanner

import (
	"context"
	"os"
	"path/filepath"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"cleanup-tool/pkg/utils"
)

// PodsScanner scans for CocoaPods Pods directories
type PodsScanner struct{}

// NewPodsScanner creates a new PodsScanner
func NewPodsScanner() *PodsScanner {
	return &PodsScanner{}
}

func (s *PodsScanner) Type() string {
	return "pods"
}

func (s *PodsScanner) Name() string {
	return "CocoaPods Pods directories"
}

func (s *PodsScanner) Icon() string {
	return "🍎"
}

func (s *PodsScanner) Description() string {
	return "Find and remove Pods directories from iOS/macOS projects"
}

func (s *PodsScanner) ShouldSkipDir(path string, dirName string) bool {
	// Skip ALL hidden directories completely
	if strings.HasPrefix(dirName, ".") && dirName != ".." {
		return true
	}
	
	// Skip system directories
	switch dirName {
	case "Library", "Applications", "System", "usr", "var", "tmp", "private", "opt":
		return true
	}
	
	// Skip nested Pods - if we're already inside a Pods directory, skip
	if strings.Contains(path, "/Pods/") {
		return true
	}
	
	// Skip common build directories
	switch dirName {
	case "build", "DerivedData", ".build", "dist", "coverage", ".git", ".svn", "target", "node_modules":
		return true
	}
	
	return false
}

func (s *PodsScanner) IsTargetItem(path string, dirName string) bool {
	// Must be a directory named "Pods"
	if dirName != "Pods" {
		return false
	}
	
	// Must not be nested inside another Pods directory
	if strings.Contains(path, "/Pods/") {
		return false
	}
	
	// Must not be inside any hidden directory
	pathParts := strings.Split(path, "/")
	for _, part := range pathParts {
		if strings.HasPrefix(part, ".") && part != ".." && part != "" {
			return false
		}
	}
	
	// Check if this looks like a CocoaPods directory by looking for Podfile
	projectDir := filepath.Dir(path)
	podfilePath := filepath.Join(projectDir, "Podfile")
	podfileLockPath := filepath.Join(projectDir, "Podfile.lock")
	
	// Must have either Podfile or Podfile.lock to be considered a valid Pods directory
	_, podfileExists := os.Stat(podfilePath)
	_, podfileLockExists := os.Stat(podfileLockPath)
	
	return podfileExists == nil || podfileLockExists == nil
}

func (s *PodsScanner) Scan(ctx context.Context, rootPath string) tea.Cmd {
	return func() tea.Msg {
		var items []Item
		var totalSize int64
		
		err := filepath.Walk(rootPath, func(path string, info os.FileInfo, err error) error {
			// Check for context cancellation
			select {
			case <-ctx.Done():
				return ctx.Err()
			default:
			}

			if err != nil {
				return nil // Skip errors, continue walking
			}

			// No need for progress updates during scan

			if !info.IsDir() {
				return nil
			}

			dirName := info.Name()
			
			// Check if we should skip this directory
			if s.ShouldSkipDir(path, dirName) {
				return filepath.SkipDir
			}

			// Check if this is a target item
			if s.IsTargetItem(path, dirName) {
				// Get the project root (directory containing Podfile)
				projectPath := filepath.Dir(path)
				
				item := Item{
					Path:         path,
					LastModified: info.ModTime(),
					Selected:     false, // Default to not selected for safety
					Type:         s.Type(),
					ProjectPath:  projectPath,
				}

				// Calculate actual size of the directory
				if size, fileCount, sizeErr := utils.CalculateDirSize(ctx, path); sizeErr == nil {
					item.Size = size
					item.ItemCount = fileCount
					totalSize += size
				}
				
				items = append(items, item)

				return filepath.SkipDir
			}

			return nil
		})

		// Send final progress
		return ScanCompleteMsg{
			ScannerType: s.Type(),
			Items:       items,
			TotalSize:   totalSize,
			Error:       err,
		}
	}
}

func (s *PodsScanner) CalculateSize(item *Item) tea.Cmd {
	return func() tea.Msg {
		ctx := context.Background()
		size, fileCount, err := utils.CalculateDirSize(ctx, item.Path)
		
		if err == nil {
			item.Size = size
			item.ItemCount = fileCount
		}
		
		return SizeCalculatedMsg{
			ItemPath: item.Path,
			Size:     size,
			Error:    err,
		}
	}
}