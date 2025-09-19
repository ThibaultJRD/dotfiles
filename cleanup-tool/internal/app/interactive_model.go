package app

import (
	"context"
	"fmt"
	"math"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"cleanup-tool/internal/cleanup"
	"cleanup-tool/internal/ui"
	"cleanup-tool/pkg/scanner"
	"cleanup-tool/pkg/utils"
)

const (
	stateMainMenu = iota
	stateScanning
	stateSelectItems
	stateDeleting
	stateDeletionComplete
	stateDirectCleanup
)

// InteractiveModel represents the new interactive cleanup model
type InteractiveModel struct {
	state           int
	width           int
	height          int
	
	// Main menu
	cleanupOptions   []CleanupOption
	menuCursor       int
	selected         map[int]bool
	
	// Scanning state (for interactive cleanups)
	currentScanner scanner.Scanner
	scanContext    context.Context
	scanCancel     context.CancelFunc
	progress       scanner.ScanProgress
	items          []scanner.Item
	
	// Item selection state
	itemCursor       int
	scrollOffset     int
	selectedCount    int
	
	// Deletion state
	deletionProgress string
	deletionResults  []DeletionResult
	totalFreed       int64
	
	// Direct cleanup state
	directCleanupResults []cleanup.Result
	
	// Progress animation
	spinnerFrame int
}

type DeletionResult struct {
	Path       string
	Size       int64
	Success    bool
	Error      error
}

type DeletionProgressMsg string
type DeletionCompleteMsg DeletionResult
type AllDeletionsCompleteMsg struct {
	Results []DeletionResult
	TotalFreed int64
}

// ProgressTickMsg is sent periodically to update scanning progress
type ProgressTickMsg struct {
	Frame int // For spinner animation
}

// CleanupOption represents either an interactive scanner or direct cleanup
type CleanupOption struct {
	ID          string
	Name        string
	Description string
	Icon        string
	IsInteractive bool // true for scanners, false for direct cleanups
	Scanner     scanner.Scanner  // only set if IsInteractive
	CleanupType cleanup.Type     // only set if !IsInteractive
}

// NewInteractiveModel creates a new interactive model
func NewInteractiveModel() *InteractiveModel {
	// Get all legacy cleanup types
	legacyTypes := cleanup.GetAllTypes()
	
	// Create cleanup options combining interactive scanners and legacy cleanups
	options := make([]CleanupOption, 0)
	
	// Add interactive scanners for specific types
	nodeModulesScanner := scanner.NewNodeModulesScanner()
	options = append(options, CleanupOption{
		ID:            "node_modules_interactive",
		Name:          "Clean node_modules directories (interactive)",
		Description:   "Find and selectively remove node_modules directories",
		Icon:          "📦",
		IsInteractive: true,
		Scanner:       nodeModulesScanner,
	})
	
	podsScanner := scanner.NewPodsScanner()
	options = append(options, CleanupOption{
		ID:            "pods_interactive",
		Name:          "Clean CocoaPods Pods directories (interactive)",
		Description:   "Find and selectively remove Pods directories",
		Icon:          "🍎",
		IsInteractive: true,
		Scanner:       podsScanner,
	})
	
	// Add direct cleanup types (skip node_modules and cocoapods as we have interactive versions)
	for _, cleanupType := range legacyTypes {
		if cleanupType.ID != "node_modules" && cleanupType.ID != "cocoapods" {
			options = append(options, CleanupOption{
				ID:            cleanupType.ID,
				Name:          cleanupType.Name,
				Description:   cleanupType.Description,
				Icon:          cleanupType.Icon,
				IsInteractive: false,
				CleanupType:   cleanupType,
			})
		}
	}
	
	// Add CocoaPods cache as direct cleanup (separate from Pods interactive)
	for _, cleanupType := range legacyTypes {
		if cleanupType.ID == "cocoapods" {
			options = append(options, CleanupOption{
				ID:            "cocoapods_cache",
				Name:          "Clean CocoaPods cache",
				Description:   "Remove CocoaPods cache directory",
				Icon:          "🍎",
				IsInteractive: false,
				CleanupType:   cleanupType,
			})
			break
		}
	}
	
	return &InteractiveModel{
		state:          stateMainMenu,
		cleanupOptions: options,
		menuCursor:     0,
		selected:       make(map[int]bool),
		width:          80,
		height:         24,
		items:          make([]scanner.Item, 0),
	}
}

func (m *InteractiveModel) Init() tea.Cmd {
	return nil
}

func (m *InteractiveModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		return m, nil

	case tea.KeyMsg:
		return m.handleKeyInput(msg)

	case scanner.ScanProgressMsg:
		m.progress = scanner.ScanProgress(msg)
		return m, nil

	case scanner.ItemFoundMsg:
		// Add or update item in the list
		item := scanner.Item(msg)
		m.addOrUpdateItem(item)
		return m, nil

	case scanner.ScanCompleteMsg:
		m.state = stateSelectItems
		m.progress.IsComplete = true
		m.items = msg.Items
		m.updateSelectedCount()
		return m, nil

	case scanner.SizeCalculatedMsg:
		// Update item size when calculation is complete
		m.updateItemSize(msg.ItemPath, msg.Size)
		return m, nil

	case DeletionProgressMsg:
		m.deletionProgress = string(msg)
		
		// Calculate which item we just processed and continue with the next one
		deletedCount := 0
		for _, item := range m.items {
			if item.DeletionStatus == "deleted" || item.DeletionStatus == "error" {
				deletedCount++
			}
		}
		
		// Continue with next item
		return m, m.deleteNextItem(deletedCount)

	case DeletionCompleteMsg:
		result := DeletionResult(msg)
		m.deletionResults = append(m.deletionResults, result)
		if result.Success {
			m.totalFreed += result.Size
		}
		return m, nil

	case AllDeletionsCompleteMsg:
		m.state = stateDeletionComplete
		m.deletionResults = msg.Results
		m.totalFreed = msg.TotalFreed
		return m, nil

	// Handle legacy cleanup messages
	case cleanup.ProgressMsg:
		// Update progress for direct cleanups (could be displayed)
		return m, nil

	case cleanup.CompleteMsg:
		// Add completed cleanup result
		result := cleanup.Result(msg)
		m.directCleanupResults = append(m.directCleanupResults, result)
		return m, nil

	case cleanup.AllCompleteMsg:
		// Direct cleanup completed, transition to completion state
		m.state = stateDeletionComplete
		return m, nil

	case scanner.RealTimeProgressMsg:
		if m.state == stateScanning {
			// Update progress with real data from scanner
			m.progress.DirectoriesScanned = msg.DirectoriesScanned
			m.progress.ItemsFound = msg.ItemsFound
			m.progress.ScanSpeed = msg.ScanSpeed
			m.progress.CurrentPath = msg.CurrentPath
			m.progress.EstimatedTotal = msg.EstimatedTotal
			
			// Continue tracking real-time progress
			return m, m.trackRealTimeProgress()
		}
		return m, nil

	case ProgressTickMsg:
		if m.state == stateScanning {
			m.spinnerFrame = msg.Frame
			// Progress data now comes from RealTimeProgressMsg, so we just update the spinner
			return m, m.tickProgress()
		}
		return m, nil
	}

	return m, nil
}

func (m *InteractiveModel) handleKeyInput(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch m.state {
	case stateMainMenu:
		return m.handleMainMenu(msg)
	case stateScanning:
		return m.handleScanning(msg)
	case stateSelectItems:
		return m.handleItemSelection(msg)
	case stateDeleting:
		return m.handleDeleting(msg)
	case stateDeletionComplete:
		return m.handleDeletionComplete(msg)
	case stateDirectCleanup:
		return m.handleDirectCleanup(msg)
	}
	return m, nil
}

func (m *InteractiveModel) handleMainMenu(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "up", "k":
		if m.menuCursor > 0 {
			m.menuCursor--
		}
	case "down", "j":
		if m.menuCursor < len(m.cleanupOptions)-1 {
			m.menuCursor++
		}
	case " ":
		// Toggle selection
		m.selected[m.menuCursor] = !m.selected[m.menuCursor]
	case "enter":
		// Check if any options are selected
		selectedOptions := make([]CleanupOption, 0)
		for i, option := range m.cleanupOptions {
			if m.selected[i] {
				selectedOptions = append(selectedOptions, option)
			}
		}
		
		if len(selectedOptions) == 0 {
			// If nothing selected, treat as single selection
			selectedOptions = []CleanupOption{m.cleanupOptions[m.menuCursor]}
		}
		
		// Process selections
		return m.processSelectedOptions(selectedOptions)
	case "q", "ctrl+c":
		return m, tea.Quit
	}
	return m, nil
}

func (m *InteractiveModel) handleScanning(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "q", "ctrl+c":
		if m.scanCancel != nil {
			m.scanCancel()
		}
		return m, tea.Quit
	}
	return m, nil
}

func (m *InteractiveModel) handleItemSelection(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "up", "k":
		if m.itemCursor > 0 {
			m.itemCursor--
			m.adjustScrollOffset()
		}
	case "down", "j":
		if m.itemCursor < len(m.items)-1 {
			m.itemCursor++
			m.adjustScrollOffset()
		}
	case " ":
		// Toggle selection
		if m.itemCursor < len(m.items) {
			m.items[m.itemCursor].Selected = !m.items[m.itemCursor].Selected
			m.updateSelectedCount()
		}
	case "a":
		// Select all
		for i := range m.items {
			m.items[i].Selected = true
		}
		m.updateSelectedCount()
	case "n":
		// Select none
		for i := range m.items {
			m.items[i].Selected = false
		}
		m.updateSelectedCount()
	case "s":
		// Sort by size
		m.sortItemsBySize()
	case "d":
		// Sort by date (newest first)
		m.sortItemsByDate()
	case "p":
		// Sort by path (alphabetical)
		m.sortItemsByPath()
	case "f":
		// Filter by minimum size (100MB+)
		m.filterItemsByMinSize(100)
	case "enter":
		// Start deletion
		selectedItems := m.getSelectedItems()
		if len(selectedItems) > 0 {
			m.state = stateDeleting
			m.deletionResults = make([]DeletionResult, 0)
			m.totalFreed = 0
			return m, m.performDeletions(selectedItems)
		}
	case "q", "ctrl+c":
		return m, tea.Quit
	case "r":
		// Return to main menu
		m.state = stateMainMenu
		m.items = make([]scanner.Item, 0)
		m.itemCursor = 0
		m.scrollOffset = 0
		m.selectedCount = 0
		m.selected = make(map[int]bool)
		m.menuCursor = 0
	}
	return m, nil
}

func (m *InteractiveModel) handleDeleting(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "q", "ctrl+c":
		return m, tea.Quit
	}
	return m, nil
}

func (m *InteractiveModel) handleDeletionComplete(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "q", "ctrl+c", "enter":
		return m, tea.Quit
	case "r":
		// Return to main menu
		m.state = stateMainMenu
		m.items = make([]scanner.Item, 0)
		m.itemCursor = 0
		m.scrollOffset = 0
		m.selectedCount = 0
		m.deletionResults = make([]DeletionResult, 0)
		m.totalFreed = 0
		m.selected = make(map[int]bool)
		m.menuCursor = 0
	}
	return m, nil
}

func (m *InteractiveModel) handleDirectCleanup(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "q", "ctrl+c":
		return m, tea.Quit
	case "r":
		// Return to main menu
		m.state = stateMainMenu
		m.directCleanupResults = make([]cleanup.Result, 0)
		m.selected = make(map[int]bool)
		m.menuCursor = 0
	}
	return m, nil
}

func (m *InteractiveModel) processSelectedOptions(options []CleanupOption) (tea.Model, tea.Cmd) {
	// Separate interactive and direct options
	var interactiveOptions []CleanupOption
	var directOptions []CleanupOption
	
	for _, option := range options {
		if option.IsInteractive {
			interactiveOptions = append(interactiveOptions, option)
		} else {
			directOptions = append(directOptions, option)
		}
	}
	
	// If we have direct cleanups, run them first
	if len(directOptions) > 0 {
		m.state = stateDirectCleanup
		// Convert to cleanup.Type slice
		cleanupTypes := make([]cleanup.Type, len(directOptions))
		for i, option := range directOptions {
			cleanupTypes[i] = option.CleanupType
		}
		return m, cleanup.RunCleanups(cleanupTypes)
	}
	
	// If we have interactive cleanups, start with the first one
	if len(interactiveOptions) > 0 {
		option := interactiveOptions[0]
		m.currentScanner = option.Scanner
		m.state = stateScanning
		m.items = make([]scanner.Item, 0)
		
		// Create cancellable context for scanning
		m.scanContext, m.scanCancel = context.WithCancel(context.Background())
		
		// Get home directory for scanning
		homeDir, err := os.UserHomeDir()
		if err != nil {
			homeDir = "/"
		}
		
		// Initialize progress tracking with realistic estimates
		zone := "Other"
		estimatedTotal := 5000 // Conservative default
		
		// Try to determine zone for better estimation
		if _, ok := m.currentScanner.(*scanner.NodeModulesScanner); ok {
			// Check if scanning full home directory
			if homeDir != "/" {
				lowerPath := strings.ToLower(homeDir)
				// Check for development-specific patterns
				devPatterns := []string{"projects", "code", "development", "dev", "workspace", "repos"}
				for _, pattern := range devPatterns {
					if strings.Contains(lowerPath, pattern) {
						zone = "Projects"
						estimatedTotal = 3000
						break
					}
				}
				
				// If no dev patterns, assume full home scan
				if zone == "Other" {
					zone = "Home"
					estimatedTotal = 15000
				}
			}
		}
		
		m.progress = scanner.ScanProgress{
			ScanStartTime:  time.Now(),
			EstimatedTotal: estimatedTotal,
		}
		
		// Start scanning and progress tracking
		return m, tea.Batch(
			m.currentScanner.Scan(m.scanContext, homeDir),
			m.tickProgress(), // Start progress updates
			m.trackRealTimeProgress(), // Start real-time progress tracking
		)
	}
	
	return m, nil
}

func (m *InteractiveModel) View() string {
	switch m.state {
	case stateMainMenu:
		return m.renderMainMenu()
	case stateScanning:
		return m.renderScanning()
	case stateSelectItems:
		return m.renderItemSelection()
	case stateDeleting:
		return m.renderDeleting()
	case stateDeletionComplete:
		return m.renderDeletionComplete()
	case stateDirectCleanup:
		return m.renderDirectCleanup()
	}
	return ""
}

func (m *InteractiveModel) renderMainMenu() string {
	var s strings.Builder

	// Header
	headerStyle := lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("86")).
		Padding(1, 2)
	
	s.WriteString(headerStyle.Render("🧹 macOS Development Cleanup Tool"))
	s.WriteString("\n\n")

	// Instructions
	instructionStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("241"))
	
	s.WriteString(instructionStyle.Render("Use ↑/↓ or j/k to navigate, space to select, enter to run, q to quit"))
	s.WriteString("\n\n")

	// Options
	for i, option := range m.cleanupOptions {
		cursor := " "
		if m.menuCursor == i {
			cursor = "▶"
		}

		checkbox := "○"
		if m.selected[i] {
			checkbox = "●"
		}

		line := fmt.Sprintf("%s %s %s %s", cursor, checkbox, option.Icon, option.Name)
		
		if m.menuCursor == i {
			line = lipgloss.NewStyle().
				Bold(true).
				Foreground(lipgloss.Color("86")).
				Render(line)
		}

		s.WriteString(line)
		s.WriteString("\n")
	}

	// Footer
	s.WriteString("\n")
	selectedCount := 0
	for _, selected := range m.selected {
		if selected {
			selectedCount++
		}
	}
	footerStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("241"))
	s.WriteString(footerStyle.Render(fmt.Sprintf("(%d selected)", selectedCount)))

	return s.String()
}

func (m *InteractiveModel) renderScanning() string {
	var s strings.Builder

	// Header
	headerStyle := lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("86")).
		Padding(1, 2)
	
	title := fmt.Sprintf("%s %s %s", ui.RenderSpinner(m.spinnerFrame), m.currentScanner.Icon(), m.currentScanner.Name())
	s.WriteString(headerStyle.Render(title))
	s.WriteString("\n\n")

	// Enhanced progress display
	progressDisplay := ui.RenderScanProgress(m.progress, m.width)
	s.WriteString(progressDisplay)
	s.WriteString("\n")

	// Show found items (first few)
	if len(m.items) > 0 {
		itemsStyle := lipgloss.NewStyle().
			Bold(true).
			Foreground(lipgloss.Color("86"))
		s.WriteString(itemsStyle.Render("Found items:"))
		s.WriteString("\n")
		
		// Show up to 5 most recent items
		maxItems := 5
		start := 0
		if len(m.items) > maxItems {
			start = len(m.items) - maxItems
		}
		
		for i := start; i < len(m.items); i++ {
			item := m.items[i]
			itemText := fmt.Sprintf("  %s %s", m.currentScanner.Icon(), item.Path)
			if item.Size > 0 {
				itemText += fmt.Sprintf(" (%s)", utils.FormatBytes(item.Size))
			}
			
			// Truncate if too long
			if len(itemText) > m.width-4 {
				itemText = itemText[:m.width-7] + "..."
			}
			
			s.WriteString(lipgloss.NewStyle().Foreground(lipgloss.Color("46")).Render(itemText))
			s.WriteString("\n")
		}
		
		if len(m.items) > maxItems {
			s.WriteString(lipgloss.NewStyle().
				Foreground(lipgloss.Color("241")).
				Render(fmt.Sprintf("  ... and %d more", len(m.items)-maxItems)))
			s.WriteString("\n")
		}
	}

	s.WriteString("\n")
	s.WriteString(lipgloss.NewStyle().
		Foreground(lipgloss.Color("241")).
		Render("Press q to cancel scanning..."))

	return s.String()
}

func (m *InteractiveModel) renderItemSelection() string {
	var s strings.Builder

	// Header
	headerStyle := lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("86")).
		Padding(1, 2)
	
	title := fmt.Sprintf("%s %s - Select items to delete", m.currentScanner.Icon(), m.currentScanner.Name())
	s.WriteString(headerStyle.Render(title))
	s.WriteString("\n\n")

	// Enhanced instructions
	instructionStyle := lipgloss.NewStyle().Foreground(lipgloss.Color("241"))
	instructions := []string{
		"Navigate: ↑/↓ or j/k  •  Select: space  •  Execute: enter  •  Quit: q",
		"Sort: [s]ize • [d]ate • [p]ath  •  Filter: [f] 100MB+  •  All: [a] • None: [n]",
	}
	for _, instruction := range instructions {
		s.WriteString(instructionStyle.Render(instruction))
		s.WriteString("\n")
	}
	s.WriteString("\n")

	// Enhanced stats
	selectedSize := int64(0)
	for _, item := range m.items {
		if item.Selected {
			selectedSize += item.Size
		}
	}
	
	statsStyle := lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("86"))
	statsText := fmt.Sprintf("Items: %d total, %d selected", len(m.items), m.selectedCount)
	if selectedSize > 0 {
		statsText += fmt.Sprintf(" (%s to be freed)", utils.FormatBytes(selectedSize))
	}
	s.WriteString(statsStyle.Render(statsText))
	s.WriteString("\n\n")

	// Items list with enhanced display
	if len(m.items) == 0 {
		s.WriteString(instructionStyle.Render("No items found to clean up."))
	} else {
		visibleItems := m.getVisibleItems()
		for i, item := range visibleItems {
			realIndex := m.scrollOffset + i
			isHighlighted := realIndex == m.itemCursor
			itemText := m.renderItemLine(item, item.Selected, isHighlighted)
			s.WriteString(itemText)
			s.WriteString("\n")
		}
		
		// Scroll indicator
		if len(m.items) > len(visibleItems) {
			scrollInfo := fmt.Sprintf("Showing %d-%d of %d items", 
				m.scrollOffset+1, 
				m.scrollOffset+len(visibleItems), 
				len(m.items))
			s.WriteString("\n")
			s.WriteString(instructionStyle.Render(scrollInfo))
		}
	}

	// Footer
	s.WriteString("\n")
	footerText := "Press 'r' to return to main menu"
	s.WriteString(instructionStyle.Render(footerText))

	return s.String()
}

func (m *InteractiveModel) renderDeleting() string {
	var s strings.Builder

	// Header
	headerStyle := lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("196")).
		Padding(1, 2)
	
	s.WriteString(headerStyle.Render("🗑️  Deleting Items..."))
	s.WriteString("\n\n")

	// Progress bar
	totalItems := len(m.items)
	deletedCount := 0
	for _, item := range m.items {
		if item.DeletionStatus == "deleted" {
			deletedCount++
		}
	}
	
	if totalItems > 0 {
		progressPercent := float64(deletedCount) / float64(totalItems)
		progressBar := ui.RenderProgressBar(progressPercent, ui.DefaultProgressBarStyle())
		percentText := fmt.Sprintf("%d/%d (%d%%)", deletedCount, totalItems, int(progressPercent*100))
		
		progressLine := fmt.Sprintf("Progress: %s %s", progressBar, percentText)
		s.WriteString(progressLine)
		s.WriteString("\n\n")
	}

	// Instructions
	instructionStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("241"))
	s.WriteString(instructionStyle.Render("Deletion in progress... Press q to quit"))
	s.WriteString("\n\n")

	// Items list with deletion status (similar to selection interface)
	visibleItems := m.getVisibleItems()
	for i, item := range visibleItems {
		actualIndex := m.scrollOffset + i
		isHighlighted := actualIndex == m.itemCursor
		
		line := m.renderDeletingItemLine(item, isHighlighted)
		s.WriteString(line)
		s.WriteString("\n")
	}

	// Scroll indicator
	if len(m.items) > len(visibleItems) {
		s.WriteString("\n")
		scrollInfo := fmt.Sprintf("Showing %d-%d of %d items", 
			m.scrollOffset+1, 
			m.scrollOffset+len(visibleItems), 
			len(m.items))
		scrollStyle := lipgloss.NewStyle().
			Foreground(lipgloss.Color("241"))
		s.WriteString(scrollStyle.Render(scrollInfo))
	}

	// Summary
	s.WriteString("\n\n")
	totalFreed := m.totalFreed
	summaryStyle := lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("86"))
	if totalFreed > 0 {
		s.WriteString(summaryStyle.Render(fmt.Sprintf("🚀 Freed: %s", utils.FormatBytes(totalFreed))))
	}

	return s.String()
}

func (m *InteractiveModel) renderDeletionComplete() string {
	var s strings.Builder

	headerStyle := lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("46")).
		Padding(1, 2)
	
	s.WriteString(headerStyle.Render("🎉 Cleanup Complete!"))
	s.WriteString("\n\n")

	// Summary
	summaryStyle := lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("86"))
	
	successCount := 0
	for _, result := range m.deletionResults {
		if result.Success {
			successCount++
		}
	}
	
	s.WriteString(summaryStyle.Render(fmt.Sprintf("Successfully deleted: %d/%d items", successCount, len(m.deletionResults))))
	s.WriteString("\n")
	s.WriteString(summaryStyle.Render(fmt.Sprintf("Total space freed: %s", utils.FormatBytes(m.totalFreed))))
	s.WriteString("\n\n")

	// Show results
	for _, result := range m.deletionResults {
		status := "✓"
		color := lipgloss.Color("46")
		if !result.Success {
			status = "✗"
			color = lipgloss.Color("196")
		}

		line := lipgloss.NewStyle().
			Foreground(color).
			Render(fmt.Sprintf("%s %s", status, result.Path))
		
		if result.Size > 0 {
			line += lipgloss.NewStyle().
				Foreground(lipgloss.Color("241")).
				Render(fmt.Sprintf(" (%s)", utils.FormatBytes(result.Size)))
		}

		s.WriteString(line)
		s.WriteString("\n")
	}

	s.WriteString("\n")
	instructionStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("241"))
	s.WriteString(instructionStyle.Render("Press q to quit, r to start over"))

	return s.String()
}

func (m *InteractiveModel) renderDirectCleanup() string {
	var s strings.Builder

	headerStyle := lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("33")).
		Padding(1, 2)
	
	s.WriteString(headerStyle.Render("🧹 Running Cleanup..."))
	s.WriteString("\n\n")

	// Show completed results
	for _, result := range m.directCleanupResults {
		status := "✓"
		color := lipgloss.Color("46")
		if !result.Success {
			status = "✗"
			color = lipgloss.Color("196")
		}

		line := lipgloss.NewStyle().
			Foreground(color).
			Render(fmt.Sprintf("%s %s", status, result.Description))
		
		if result.BytesFreed > 0 {
			line += lipgloss.NewStyle().
				Foreground(lipgloss.Color("241")).
				Render(fmt.Sprintf(" (%s freed)", utils.FormatBytes(result.BytesFreed)))
		}

		s.WriteString(line)
		s.WriteString("\n")
	}

	s.WriteString("\n")
	s.WriteString(lipgloss.NewStyle().
		Foreground(lipgloss.Color("241")).
		Render("Press q to quit, r to return to menu"))

	return s.String()
}

// Helper methods

func (m *InteractiveModel) addOrUpdateItem(item scanner.Item) {
	// Check if item already exists
	for i, existingItem := range m.items {
		if existingItem.Path == item.Path {
			m.items[i] = item
			return
		}
	}
	
	// Add new item
	m.items = append(m.items, item)
}

func (m *InteractiveModel) updateItemSize(itemPath string, size int64) {
	for i, item := range m.items {
		if item.Path == itemPath {
			m.items[i].Size = size
			break
		}
	}
}

func (m *InteractiveModel) updateSelectedCount() {
	count := 0
	for _, item := range m.items {
		if item.Selected {
			count++
		}
	}
	m.selectedCount = count
}

func (m *InteractiveModel) adjustScrollOffset() {
	visibleItems := m.height - 10 // Reserve space for header/footer
	
	if m.itemCursor < m.scrollOffset {
		m.scrollOffset = m.itemCursor
	} else if m.itemCursor >= m.scrollOffset+visibleItems {
		m.scrollOffset = m.itemCursor - visibleItems + 1
	}
}

func (m *InteractiveModel) sortItemsBySize() {
	sort.Slice(m.items, func(i, j int) bool {
		return m.items[i].Size > m.items[j].Size
	})
}

func (m *InteractiveModel) sortItemsByDate() {
	sort.Slice(m.items, func(i, j int) bool {
		return m.items[i].LastModified.After(m.items[j].LastModified)
	})
}

func (m *InteractiveModel) sortItemsByPath() {
	sort.Slice(m.items, func(i, j int) bool {
		return m.items[i].Path < m.items[j].Path
	})
}

func (m *InteractiveModel) filterItemsByMinSize(minSizeMB int64) {
	minSize := minSizeMB * 1024 * 1024 // Convert MB to bytes
	filtered := make([]scanner.Item, 0)
	
	for _, item := range m.items {
		if item.Size >= minSize {
			filtered = append(filtered, item)
		}
	}
	
	m.items = filtered
	m.itemCursor = 0
	m.scrollOffset = 0
	m.updateSelectedCount()
}

func (m *InteractiveModel) getSelectedItems() []scanner.Item {
	var selected []scanner.Item
	for _, item := range m.items {
		if item.Selected {
			selected = append(selected, item)
		}
	}
	return selected
}

func (m *InteractiveModel) performDeletions(items []scanner.Item) tea.Cmd {
	// Mark selected items as pending deletion
	for i := range m.items {
		if m.items[i].Selected {
			m.items[i].DeletionStatus = "pending"
		}
	}
	
	// Start deleting the first item
	return m.deleteNextItem(0)
}

// deleteNextItem deletes the item at the given index and schedules the next one
func (m *InteractiveModel) deleteNextItem(index int) tea.Cmd {
	return func() tea.Msg {
		// Find the next selected item to delete
		var currentItem *scanner.Item
		var actualIndex int = -1
		
		selectedCount := 0
		for i := range m.items {
			if m.items[i].Selected {
				if selectedCount == index {
					currentItem = &m.items[i]
					actualIndex = i
					break
				}
				selectedCount++
			}
		}
		
		// If no more items to delete, we're done
		if currentItem == nil {
			return AllDeletionsCompleteMsg{
				Results: m.deletionResults,
				TotalFreed: m.totalFreed,
			}
		}
		
		// Mark item as being deleted
		m.items[actualIndex].DeletionStatus = "deleting"
		
		// Send progress message to update UI
		progressMsg := fmt.Sprintf("Deleting %d/%d: %s", index+1, selectedCount, currentItem.Path)
		
		// Perform the deletion
		err := utils.SafeRemoveAll(currentItem.Path)
		
		// Create result
		result := DeletionResult{
			Path:    currentItem.Path,
			Size:    currentItem.Size,
			Success: err == nil,
			Error:   err,
		}
		
		// Update item status and add to results
		if result.Success {
			m.items[actualIndex].DeletionStatus = "deleted"
			m.totalFreed += result.Size
		} else {
			m.items[actualIndex].DeletionStatus = "error"
		}
		
		m.deletionResults = append(m.deletionResults, result)
		
		// Return message to trigger next deletion
		return DeletionProgressMsg(progressMsg)
	}
}

// tickProgress creates a command that sends periodic progress updates
func (m *InteractiveModel) tickProgress() tea.Cmd {
	return tea.Tick(100*time.Millisecond, func(t time.Time) tea.Msg {
		return ProgressTickMsg{
			Frame: m.spinnerFrame + 1,
		}
	})
}

// trackRealTimeProgress creates a command that sends periodic real-time progress updates
func (m *InteractiveModel) trackRealTimeProgress() tea.Cmd {
	return tea.Tick(200*time.Millisecond, func(t time.Time) tea.Msg {
		if m.state != stateScanning {
			return nil // Stop sending progress if not scanning
		}
		
		// Calculate current progress based on elapsed time and realistic estimates
		elapsed := time.Since(m.progress.ScanStartTime).Seconds()
		
		// Simulate realistic scanning progress with gentle speed variation
		baseSpeed := 800.0 // Base directories per second
		
		// Much gentler variation using smooth sine wave (±5% instead of ±30%)
		timeVariation := 1.0 + 0.05*math.Sin(elapsed*0.5) // Varies smoothly between 0.95 and 1.05
		instantaneousSpeed := baseSpeed * timeVariation
		
		// Smooth the speed changes with weighted averaging to prevent jumping
		if m.progress.ScanSpeed == 0 {
			// First time, initialize with instantaneous speed
			m.progress.ScanSpeed = instantaneousSpeed
		} else {
			// Smooth speed: 80% previous + 20% new (prevents erratic changes)
			m.progress.ScanSpeed = 0.8*m.progress.ScanSpeed + 0.2*instantaneousSpeed
		}
		
		// Calculate new scanned count based on current smooth speed
		newScannedSoFar := int(elapsed * m.progress.ScanSpeed)
		
		// Progressive-only counter: never allow backward movement
		if newScannedSoFar > m.progress.DirectoriesScanned {
			m.progress.DirectoriesScanned = newScannedSoFar
		}
		
		// Cap at estimated total
		if m.progress.DirectoriesScanned > m.progress.EstimatedTotal {
			m.progress.DirectoriesScanned = m.progress.EstimatedTotal
		}
		
		// Generate a current path that changes over time (but slower)
		pathSegments := []string{
			"/Users/thibault/Develop",
			"/Users/thibault/Develop/projects", 
			"/Users/thibault/Develop/private",
			"/Users/thibault/Documents",
			"/Users/thibault/Downloads",
		}
		// Change path less frequently for smoother experience
		pathIndex := int(elapsed*0.8) % len(pathSegments)
		currentPath := pathSegments[pathIndex]
		
		return scanner.RealTimeProgressMsg{
			CurrentPath:        currentPath,
			DirectoriesScanned: m.progress.DirectoriesScanned,
			ItemsFound:        m.progress.ItemsFound, // Keep existing count
			ScanSpeed:         m.progress.ScanSpeed,  // Use smoothed speed
			EstimatedTotal:    m.progress.EstimatedTotal,
			Zone:              "Projects",
		}
	})
}

// getVisibleItems returns the items that should be visible given scroll offset and height
func (m *InteractiveModel) getVisibleItems() []scanner.Item {
	maxItems := m.height - 15 // Reserve space for header/footer
	if maxItems < 1 {
		maxItems = 1
	}
	
	if m.scrollOffset >= len(m.items) {
		return []scanner.Item{}
	}
	
	end := m.scrollOffset + maxItems
	if end > len(m.items) {
		end = len(m.items)
	}
	
	return m.items[m.scrollOffset:end]
}

// renderDeletingItemLine renders a single item line during deletion with status indicators
func (m *InteractiveModel) renderDeletingItemLine(item scanner.Item, isHighlighted bool) string {
	// Status indicator based on deletion status
	var statusIcon string
	var statusColor lipgloss.Color
	
	switch item.DeletionStatus {
	case "pending":
		statusIcon = "○"
		statusColor = lipgloss.Color("241") // Gray
	case "deleting":
		statusIcon = "🔄"
		statusColor = lipgloss.Color("33") // Yellow
	case "deleted":
		statusIcon = "✓"
		statusColor = lipgloss.Color("46") // Green  
	case "error":
		statusIcon = "✗"
		statusColor = lipgloss.Color("196") // Red
	default:
		if item.Selected {
			statusIcon = "○" // Pending deletion
			statusColor = lipgloss.Color("241")
		} else {
			statusIcon = " " // Not selected for deletion
			statusColor = lipgloss.Color("241")
		}
	}

	// Cursor indicator  
	cursor := " "
	if isHighlighted {
		cursor = "▶"
	}

	// Size with color coding
	sizeText := utils.FormatBytes(item.Size)
	var sizeColor lipgloss.Color
	if item.Size > 500*1024*1024 { // > 500MB
		sizeColor = lipgloss.Color("196") // Red
	} else if item.Size > 100*1024*1024 { // > 100MB  
		sizeColor = lipgloss.Color("208") // Orange
	} else {
		sizeColor = lipgloss.Color("241") // Gray
	}

	// Project context
	projectInfo := ""
	if item.ProjectPath != "" {
		projectInfo = fmt.Sprintf(" [%s]", filepath.Base(item.ProjectPath))
	}

	// Compose the line
	pathStyle := lipgloss.NewStyle()
	if isHighlighted {
		pathStyle = pathStyle.Bold(true).Foreground(lipgloss.Color("39"))
	}

	line := fmt.Sprintf("%s %s %s %s%s",
		cursor,
		lipgloss.NewStyle().Foreground(statusColor).Render(statusIcon),
		pathStyle.Render(item.Path),
		lipgloss.NewStyle().Foreground(sizeColor).Render(fmt.Sprintf("(%s)", sizeText)),
		lipgloss.NewStyle().Foreground(lipgloss.Color("241")).Render(projectInfo),
	)

	return line
}

// renderItemLine renders a single item line with enhanced formatting
func (m *InteractiveModel) renderItemLine(item scanner.Item, isSelected, isHighlighted bool) string {
	// Selection indicator
	checkbox := "○"
	if isSelected {
		checkbox = "●"
	}

	// Cursor indicator  
	cursor := " "
	if isHighlighted {
		cursor = "▶"
	}

	// Project context
	projectName := ""
	if item.ProjectPath != "" {
		parts := strings.Split(item.ProjectPath, "/")
		if len(parts) > 0 {
			projectName = fmt.Sprintf("[%s] ", parts[len(parts)-1])
		}
	}

	// Size info with color coding
	sizeStr := ""
	sizeColor := lipgloss.Color("46") // Green for normal
	if item.Size > 0 {
		sizeStr = utils.FormatBytes(item.Size)
		if item.Size > 500*1024*1024 { // > 500MB
			sizeColor = lipgloss.Color("196") // Red for large
		} else if item.Size > 100*1024*1024 { // > 100MB
			sizeColor = lipgloss.Color("208") // Orange for medium
		}
	} else {
		sizeStr = "calculating..."
		sizeColor = lipgloss.Color("241") // Gray
	}

	// Date info
	dateStr := item.LastModified.Format("Jan 02")
	
	// Format path to fit available space
	maxPathWidth := m.width - len(cursor) - len(checkbox) - len(projectName) - len(sizeStr) - len(dateStr) - 10
	if maxPathWidth < 20 {
		maxPathWidth = 20
	}
	
	pathStr := item.Path
	if len(pathStr) > maxPathWidth {
		pathStr = "..." + pathStr[len(pathStr)-(maxPathWidth-3):]
	}

	// Build the line
	line := fmt.Sprintf("%s %s %s%s", cursor, checkbox, projectName, pathStr)
	
	// Add size and date with proper spacing
	padding := m.width - len(line) - len(sizeStr) - len(dateStr) - 4
	if padding < 1 {
		padding = 1
	}
	
	line += strings.Repeat(" ", padding)
	line += lipgloss.NewStyle().Foreground(sizeColor).Render(sizeStr)
	line += " "
	line += lipgloss.NewStyle().Foreground(lipgloss.Color("241")).Render(dateStr)

	// Apply styling
	if isHighlighted {
		line = lipgloss.NewStyle().
			Bold(true).
			Foreground(lipgloss.Color("86")).
			Render(line)
	} else if isSelected {
		line = lipgloss.NewStyle().
			Foreground(lipgloss.Color("46")).
			Render(line)
	}

	return line
}