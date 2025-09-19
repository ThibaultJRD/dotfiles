package scanner

import (
	"context"
	"time"

	tea "github.com/charmbracelet/bubbletea"
)

// Item represents a discoverable item that can be cleaned up
type Item struct {
	Path         string
	Size         int64
	LastModified time.Time
	ItemCount    int64    // Number of files/subdirectories
	Selected     bool
	Type         string   // Type of item (node_modules, pods, etc.)
	ProjectPath  string   // Parent project path for context
	DeletionStatus string // Status during deletion: "", "pending", "deleting", "deleted", "error"
}

// ScanProgress represents the current scanning progress
type ScanProgress struct {
	CurrentPath      string
	ItemsFound       int
	DirectoriesScanned int
	TotalSize        int64
	IsComplete       bool
	Error            error
	ScanStartTime    time.Time
	EstimatedTotal   int     // Estimated total directories to scan
	ScanSpeed        float64 // Directories per second
}

// Scanner interface for different types of cleanup scanners
type Scanner interface {
	// Type returns the unique identifier for this scanner
	Type() string
	
	// Name returns the human-readable name
	Name() string
	
	// Icon returns the emoji/icon for display
	Icon() string
	
	// Description returns a description of what this scanner does
	Description() string
	
	// Scan performs the actual scanning and sends progress updates
	Scan(ctx context.Context, rootPath string) tea.Cmd
	
	// ShouldSkipDir determines if a directory should be skipped during scanning
	ShouldSkipDir(path string, dirName string) bool
	
	// IsTargetItem determines if the current path is a target for cleanup
	IsTargetItem(path string, dirName string) bool
	
	// CalculateSize calculates the size of an item (can be async)
	CalculateSize(item *Item) tea.Cmd
}

// ScanProgressMsg is sent during scanning to update progress
type ScanProgressMsg ScanProgress

// ItemFoundMsg is sent when a new item is discovered
type ItemFoundMsg Item

// ScanCompleteMsg is sent when scanning is complete
type ScanCompleteMsg struct {
	ScannerType string
	Items       []Item
	TotalSize   int64
	Error       error
}

// SizeCalculatedMsg is sent when an item's size calculation is complete
type SizeCalculatedMsg struct {
	ItemPath string
	Size     int64
	Error    error
}

// RealTimeProgressMsg is sent with actual scanning data
type RealTimeProgressMsg struct {
	CurrentPath        string
	DirectoriesScanned int
	ItemsFound        int
	ScanSpeed         float64
	EstimatedTotal    int
	Zone              string // "Projects", "Home", "System", etc.
}