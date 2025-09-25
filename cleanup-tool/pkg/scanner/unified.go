package scanner

import (
	"context"
	"os"
	"path/filepath"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"cleanup-tool/pkg/utils"
)

// UnifiedScanner scans for both node_modules and Pods directories in a single pass
type UnifiedScanner struct {
	nodeScanner *NodeModulesScanner
	podsScanner *PodsScanner
}

// NewUnifiedScanner creates a new UnifiedScanner
func NewUnifiedScanner() *UnifiedScanner {
	return &UnifiedScanner{
		nodeScanner: NewNodeModulesScanner(),
		podsScanner: NewPodsScanner(),
	}
}

func (s *UnifiedScanner) Type() string {
	return "unified"
}

func (s *UnifiedScanner) Name() string {
	return "Node.js & CocoaPods directories (unified)"
}

func (s *UnifiedScanner) Icon() string {
	return "🧹"
}

func (s *UnifiedScanner) Description() string {
	return "Find and remove both node_modules and Pods directories in one scan"
}

func (s *UnifiedScanner) ShouldSkipDir(path string, dirName string) bool {
	// A directory should be skipped if BOTH scanners want to skip it
	// This is more permissive to ensure we don't miss any targets
	nodeSkip := s.nodeScanner.ShouldSkipDir(path, dirName)
	podsSkip := s.podsScanner.ShouldSkipDir(path, dirName)
	
	// Skip if both scanners agree to skip, OR if it's definitely a system directory
	switch dirName {
	case "Library", "Applications", "System", "usr", "var", "tmp", "opt", "bin", "sbin", "etc":
		return true
	}
	
	// Skip system /private directory
	if dirName == "private" && path == "/private" {
		return true
	}
	
	// Skip if already inside node_modules or Pods to avoid deep nesting
	if strings.Contains(path, "/node_modules/") || strings.Contains(path, "/Pods/") {
		return true
	}
	
	// For other cases, be conservative - only skip if both scanners agree
	return nodeSkip && podsSkip
}

func (s *UnifiedScanner) IsTargetItem(path string, dirName string) bool {
	// Target if either scanner considers it a target
	return s.nodeScanner.IsTargetItem(path, dirName) || s.podsScanner.IsTargetItem(path, dirName)
}

func (s *UnifiedScanner) Scan(ctx context.Context, rootPath string) tea.Cmd {
	// Start the asynchronous scanning process
	return s.startAsyncScan(ctx, rootPath)
}

// startAsyncScan initiates the scanning process and returns the first command
func (s *UnifiedScanner) startAsyncScan(ctx context.Context, rootPath string) tea.Cmd {
	// Create a channel to communicate found items
	itemChan := make(chan Item, 10) // Buffered channel
	doneChan := make(chan ScanCompleteMsg, 1)
	
	// Start the scanning goroutine
	go s.performAsyncScan(ctx, rootPath, itemChan, doneChan)
	
	// Return command to start listening for items
	return s.listenForItems(itemChan, doneChan)
}

// performAsyncScan does the actual scanning work in a goroutine
func (s *UnifiedScanner) performAsyncScan(ctx context.Context, rootPath string, itemChan chan<- Item, doneChan chan<- ScanCompleteMsg) {
	defer close(itemChan)
	defer close(doneChan)
	
	var items []Item
	var totalSize int64
	
	// Determine scan zone  
	zone := s.determineScanZone(rootPath)
	_ = s.getRealisticEstimate(rootPath, zone)
	
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
			var itemType string
			var projectPath string
			
			// Determine which type of item this is
			if s.nodeScanner.IsTargetItem(path, dirName) {
				itemType = s.nodeScanner.Type()
				projectPath = s.findNodeProjectRoot(path)
			} else if s.podsScanner.IsTargetItem(path, dirName) {
				itemType = s.podsScanner.Type()
				projectPath = filepath.Dir(path)
			}
			
			item := Item{
				Path:         path,
				LastModified: info.ModTime(),
				Selected:     false, // Default to not selected
				Type:         itemType,
				ProjectPath:  projectPath,
			}

			// Calculate actual size of the directory
			if size, fileCount, sizeErr := utils.CalculateDirSize(ctx, path); sizeErr == nil {
				item.Size = size
				item.ItemCount = fileCount
				totalSize += size
			}
			
			items = append(items, item)
			
			// Send item immediately for real-time updates
			select {
			case itemChan <- item:
				// Item sent successfully
			case <-ctx.Done():
				return ctx.Err()
			}

			return filepath.SkipDir
		}

		return nil
	})
	
	// Send completion message
	doneChan <- ScanCompleteMsg{
		ScannerType: s.Type(),
		Items:       items,
		TotalSize:   totalSize,
		Error:       err,
	}
}

// listenForItems creates a command that listens for items and scan completion
func (s *UnifiedScanner) listenForItems(itemChan <-chan Item, doneChan <-chan ScanCompleteMsg) tea.Cmd {
	return func() tea.Msg {
		select {
		case item, ok := <-itemChan:
			if !ok {
				// Channel closed, wait for completion
				return <-doneChan
			}
			// Return a message that includes both the item and continuation info
			return ItemFoundWithContinuationMsg{
				Item:     item,
				ItemChan: itemChan,
				DoneChan: doneChan,
			}
			
		case completion := <-doneChan:
			// Scan completed
			return completion
		}
	}
}

// ItemFoundWithContinuationMsg contains an item and the channels to continue listening
type ItemFoundWithContinuationMsg struct {
	Item     Item
	ItemChan <-chan Item
	DoneChan <-chan ScanCompleteMsg
}

// ContinueListening creates a new command to continue listening for items
func (s *UnifiedScanner) ContinueListeningWithChannels(itemChan <-chan Item, doneChan <-chan ScanCompleteMsg) tea.Cmd {
	return s.listenForItems(itemChan, doneChan)
}

func (s *UnifiedScanner) CalculateSize(item *Item) tea.Cmd {
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

// Helper methods borrowed from individual scanners

// findNodeProjectRoot finds the closest parent directory containing package.json
func (s *UnifiedScanner) findNodeProjectRoot(nodeModulesPath string) string {
	projectDir := filepath.Dir(nodeModulesPath)
	
	// Look for package.json in the parent directory
	packageJsonPath := filepath.Join(projectDir, "package.json")
	if _, err := os.Stat(packageJsonPath); err == nil {
		return projectDir
	}
	
	// If not found, return the parent directory anyway
	return projectDir
}

// determineScanZone identifies what type of area we're scanning for better estimation
func (s *UnifiedScanner) determineScanZone(rootPath string) string {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return "Unknown"
	}
	
	lowerPath := strings.ToLower(rootPath)
	
	// Check if scanning full home directory
	if rootPath == homeDir {
		return "Home"
	}
	
	// Check for development-specific directories
	devPatterns := []string{
		"projects", "code", "development", "dev", "workspace", "repos", "repositories", 
		"src", "source", "github", "gitlab", "bitbucket",
	}
	
	for _, pattern := range devPatterns {
		if strings.Contains(lowerPath, pattern) {
			return "Projects"
		}
	}
	
	// Check for Documents/Desktop which might have projects
	if strings.Contains(lowerPath, "documents") || strings.Contains(lowerPath, "desktop") {
		return "Documents"
	}
	
	// Check for Downloads which might have downloaded projects
	if strings.Contains(lowerPath, "downloads") {
		return "Downloads"
	}
	
	return "Other"
}

// getRealisticEstimate provides realistic directory count estimates based on zone
func (s *UnifiedScanner) getRealisticEstimate(rootPath string, zone string) int {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return 5000 // Safe default
	}
	
	// Get the relative depth from home
	relPath := strings.TrimPrefix(rootPath, homeDir)
	depth := strings.Count(relPath, string(os.PathSeparator))
	
	switch zone {
	case "Projects":
		// Development areas are usually more organized, fewer total dirs but more projects
		switch {
		case depth <= 2:
			return 3000  // Project root level
		case depth <= 4:
			return 1500  // Within project categories
		default:
			return 500   // Deep in specific projects
		}
		
	case "Documents":
		// Documents might have some projects mixed with other files
		switch {
		case depth <= 2:
			return 5000
		case depth <= 4:
			return 2000
		default:
			return 800
		}
		
	case "Downloads":
		// Downloads often have compressed projects, but varies wildly
		return 2000
		
	case "Home":
		// Full home directory scan - conservative estimate
		return 15000
		
	case "Other":
		// Unknown areas, be conservative
		switch {
		case depth <= 2:
			return 3000
		case depth <= 4:
			return 1500
		default:
			return 500
		}
		
	default:
		return 2000
	}
}