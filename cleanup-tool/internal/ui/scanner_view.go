package ui

import (
	"fmt"
	"strings"

	"github.com/charmbracelet/lipgloss"
	"cleanup-tool/pkg/scanner"
	"cleanup-tool/pkg/utils"
)

var (
	// Styles for scanner view
	titleStyle = lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("86")).
		Padding(1, 2)

	progressStyle = lipgloss.NewStyle().
		Foreground(lipgloss.Color("33"))

	itemStyle = lipgloss.NewStyle().
		Padding(0, 1)

	selectedItemStyle = lipgloss.NewStyle().
		Padding(0, 1).
		Background(lipgloss.Color("240"))

	highlightedItemStyle = lipgloss.NewStyle().
		Padding(0, 1).
		Bold(true).
		Foreground(lipgloss.Color("86"))

	infoStyle = lipgloss.NewStyle().
		Foreground(lipgloss.Color("241"))

	errorStyle = lipgloss.NewStyle().
		Foreground(lipgloss.Color("196"))
)

// ScannerViewState represents the state of the scanner view
type ScannerViewState struct {
	Scanner       scanner.Scanner
	Progress      scanner.ScanProgress
	Items         []scanner.Item
	Cursor        int
	SelectedCount int
	TotalSize     int64
	IsScanning    bool
	Width         int
	Height        int
	ScrollOffset  int
}

// RenderScanningView renders the view while scanning is in progress
func RenderScanningView(state *ScannerViewState) string {
	var s strings.Builder

	// Header
	title := fmt.Sprintf("%s %s - Scanning...", state.Scanner.Icon(), state.Scanner.Name())
	s.WriteString(titleStyle.Render(title))
	s.WriteString("\n\n")

	// Progress info
	if state.Progress.CurrentPath != "" {
		progressText := fmt.Sprintf("🔍 Scanning: %s", truncatePath(state.Progress.CurrentPath, state.Width-20))
		s.WriteString(progressStyle.Render(progressText))
		s.WriteString("\n")
	}

	// Stats
	statsText := fmt.Sprintf("Found: %d items", len(state.Items))
	if state.TotalSize > 0 {
		statsText += fmt.Sprintf(" (%s total)", utils.FormatBytes(state.TotalSize))
	}
	s.WriteString(infoStyle.Render(statsText))
	s.WriteString("\n\n")

	// Show found items (limited to visible area)
	visibleItems := getVisibleItems(state.Items, state.ScrollOffset, state.Height-8)
	for _, item := range visibleItems {
		itemText := renderItem(item, false, false, state.Width)
		s.WriteString(itemText)
		s.WriteString("\n")
	}

	s.WriteString("\n")
	s.WriteString(infoStyle.Render("Press q to cancel, scanning in progress..."))

	return s.String()
}

// RenderSelectionView renders the view for selecting items to delete
func RenderSelectionView(state *ScannerViewState) string {
	var s strings.Builder

	// Header
	title := fmt.Sprintf("%s %s - Select items to delete", state.Scanner.Icon(), state.Scanner.Name())
	s.WriteString(titleStyle.Render(title))
	s.WriteString("\n\n")

	// Instructions
	instructions := "Use ↑/↓ to navigate, space to toggle selection, enter to delete selected, q to quit"
	s.WriteString(infoStyle.Render(instructions))
	s.WriteString("\n\n")

	// Stats
	selectedSize := int64(0)
	for _, item := range state.Items {
		if item.Selected {
			selectedSize += item.Size
		}
	}
	
	statsText := fmt.Sprintf("Items: %d total, %d selected", len(state.Items), state.SelectedCount)
	if selectedSize > 0 {
		statsText += fmt.Sprintf(" (%s to be freed)", utils.FormatBytes(selectedSize))
	}
	s.WriteString(infoStyle.Render(statsText))
	s.WriteString("\n\n")

	// Items list
	if len(state.Items) == 0 {
		s.WriteString(infoStyle.Render("No items found to clean up."))
	} else {
		visibleItems := getVisibleItems(state.Items, state.ScrollOffset, state.Height-10)
		for i, item := range visibleItems {
			realIndex := state.ScrollOffset + i
			isHighlighted := realIndex == state.Cursor
			itemText := renderItem(item, item.Selected, isHighlighted, state.Width)
			s.WriteString(itemText)
			s.WriteString("\n")
		}
	}

	// Footer
	s.WriteString("\n")
	footerText := "Press 'a' to select all, 'n' to select none, 's' to sort by size"
	s.WriteString(infoStyle.Render(footerText))

	return s.String()
}

// renderItem renders a single item in the list
func renderItem(item scanner.Item, isSelected, isHighlighted bool, maxWidth int) string {
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

	// Size info
	sizeStr := ""
	if item.Size > 0 {
		sizeStr = utils.FormatBytes(item.Size)
	} else {
		sizeStr = "calculating..."
	}

	// Project context
	projectName := ""
	if item.ProjectPath != "" {
		projectName = fmt.Sprintf("[%s] ", getProjectName(item.ProjectPath))
	}

	// Format the path to fit in available space
	pathStr := truncatePath(item.Path, maxWidth-40) // Reserve space for other elements
	
	// Build the line
	line := fmt.Sprintf("%s %s %s%s (%s)", cursor, checkbox, projectName, pathStr, sizeStr)

	// Apply styling
	style := itemStyle
	if isSelected {
		style = selectedItemStyle
	}
	if isHighlighted {
		style = highlightedItemStyle
	}

	return style.Render(line)
}

// truncatePath is now defined in progress.go

// getProjectName extracts a meaningful project name from the project path
func getProjectName(projectPath string) string {
	parts := strings.Split(projectPath, "/")
	if len(parts) > 0 {
		return parts[len(parts)-1]
	}
	return "unknown"
}

// getVisibleItems returns the items that should be visible given the scroll offset and height
func getVisibleItems(items []scanner.Item, scrollOffset, maxItems int) []scanner.Item {
	if scrollOffset >= len(items) {
		return []scanner.Item{}
	}
	
	end := scrollOffset + maxItems
	if end > len(items) {
		end = len(items)
	}
	
	return items[scrollOffset:end]
}