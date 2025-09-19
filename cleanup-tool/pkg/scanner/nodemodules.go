package scanner

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"cleanup-tool/pkg/utils"
)

// NodeModulesScanner scans for node_modules directories
type NodeModulesScanner struct{}

// NewNodeModulesScanner creates a new NodeModulesScanner
func NewNodeModulesScanner() *NodeModulesScanner {
	return &NodeModulesScanner{}
}

func (s *NodeModulesScanner) Type() string {
	return "node_modules"
}

func (s *NodeModulesScanner) Name() string {
	return "Node.js node_modules directories"
}

func (s *NodeModulesScanner) Icon() string {
	return "📦"
}

func (s *NodeModulesScanner) Description() string {
	return "Find and remove node_modules directories from JavaScript projects"
}

func (s *NodeModulesScanner) ShouldSkipDir(path string, dirName string) bool {
	// Skip system directories that definitely won't have projects
	switch dirName {
	case "Library", "Applications", "System", "usr", "var", "tmp", "opt", "bin", "sbin", "etc":
		return true
	}
	
	// Skip system /private directory but allow user project directories named "private"
	if dirName == "private" && path == "/private" {
		return true
	}
	
	// Skip nested node_modules - count the depth to be more precise
	nodeModulesCount := strings.Count(path, "/node_modules/")
	if nodeModulesCount > 0 {
		return true // Already inside a node_modules, skip deeper nesting
	}
	
	// For hidden directories, be more selective - only skip definitely unneeded ones
	if strings.HasPrefix(dirName, ".") && dirName != ".." {
		switch dirName {
		case ".git", ".svn", ".hg", ".bzr": // VCS directories
			return true
		case ".DS_Store", ".localized", ".fseventsd", ".Spotlight-V100", ".Trashes", ".TemporaryItems":
			return true // macOS system files
		case ".npm", ".yarn", ".cache", ".temp", ".tmp":
			return true // Cache directories that won't have projects
		case ".Trash", ".trash":
			return true
		// Allow important development directories
		case ".vscode", ".idea", ".config", ".local", ".ssh", ".docker":
			return false // These might contain or lead to projects
		default:
			// For other hidden directories, check if they might be development-related
			if s.mightContainProjects(dirName) {
				return false
			}
			return true // Skip other hidden directories by default
		}
	}
	
	// Skip common build/cache directories but allow traversal
	switch dirName {
	case "build", "dist", "coverage", "target", "__pycache__", ".pytest_cache":
		return true
	}
	
	return false
}

// mightContainProjects checks if a hidden directory might contain development projects
func (s *NodeModulesScanner) mightContainProjects(dirName string) bool {
	developmentPatterns := []string{
		"workspace", "projects", "code", "dev", "development",
		"repos", "repositories", "src", "source",
	}
	
	lowerDir := strings.ToLower(dirName)
	for _, pattern := range developmentPatterns {
		if strings.Contains(lowerDir, pattern) {
			return true
		}
	}
	
	return false
}

func (s *NodeModulesScanner) IsTargetItem(path string, dirName string) bool {
	// Must be a directory named "node_modules"
	if dirName != "node_modules" {
		return false
	}
	
	// Must not be nested inside another node_modules
	// Check if the path contains "/node_modules/" which would indicate nesting
	if strings.Contains(path, "/node_modules/") {
		return false
	}
	
	// Additional check: make sure this is not inside any hidden directory
	pathParts := strings.Split(path, "/")
	for _, part := range pathParts {
		if strings.HasPrefix(part, ".") && part != ".." && part != "" {
			return false
		}
	}
	
	return true
}

func (s *NodeModulesScanner) Scan(ctx context.Context, rootPath string) tea.Cmd {
	return func() tea.Msg {
		var items []Item
		var totalSize int64
		directoriesScanned := 0
		scanStartTime := time.Now()
		lastProgressTime := time.Now()
		
		// Determine scan zone and get realistic estimate (for future use)
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

			// Count directories scanned
			if info.IsDir() {
				directoriesScanned++
				
				// Track progress updates every 100 directories or 200ms
				now := time.Now()
				if directoriesScanned%100 == 0 || now.Sub(lastProgressTime) > 200*time.Millisecond {
					// Progress tracking for future real-time updates
					lastProgressTime = now
				}
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
				// Find the project root (directory containing package.json)
				projectPath := s.findProjectRoot(path)
				
				item := Item{
					Path:         path,
					LastModified: info.ModTime(),
					Selected:     false, // Default to not selected
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

		// Calculate final statistics (for future use)
		_ = time.Since(scanStartTime).Seconds()

		return ScanCompleteMsg{
			ScannerType: s.Type(),
			Items:       items,
			TotalSize:   totalSize,
			Error:       err,
		}
	}
}

// GetProgress returns a command that calculates and sends current progress
// This method can be called periodically by the UI to get real-time updates
func (s *NodeModulesScanner) GetProgress(startTime time.Time, directoriesScanned int, itemsFound int, currentPath string, estimatedTotal int) tea.Cmd {
	return func() tea.Msg {
		elapsed := time.Since(startTime).Seconds()
		speed := float64(0)
		if elapsed > 0 {
			speed = float64(directoriesScanned) / elapsed
		}
		
		return RealTimeProgressMsg{
			CurrentPath:        currentPath,
			DirectoriesScanned: directoriesScanned,
			ItemsFound:        itemsFound,
			ScanSpeed:         speed,
			EstimatedTotal:    estimatedTotal,
			Zone:              s.determineScanZone(currentPath),
		}
	}
}

// determineScanZone identifies what type of area we're scanning for better estimation
func (s *NodeModulesScanner) determineScanZone(rootPath string) string {
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
func (s *NodeModulesScanner) getRealisticEstimate(rootPath string, zone string) int {
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
		return 15000 // Much more realistic than 50000
		
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

func (s *NodeModulesScanner) CalculateSize(item *Item) tea.Cmd {
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

// findProjectRoot finds the closest parent directory containing package.json
func (s *NodeModulesScanner) findProjectRoot(nodeModulesPath string) string {
	projectDir := filepath.Dir(nodeModulesPath)
	
	// Look for package.json in the parent directory
	packageJsonPath := filepath.Join(projectDir, "package.json")
	if _, err := os.Stat(packageJsonPath); err == nil {
		return projectDir
	}
	
	// If not found, return the parent directory anyway
	return projectDir
}