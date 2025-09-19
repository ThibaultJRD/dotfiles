package ui

import (
	"fmt"
	"strings"
	"time"

	"github.com/charmbracelet/lipgloss"
	"cleanup-tool/pkg/scanner"
	"cleanup-tool/pkg/utils"
)

// ProgressBarStyle defines the styling for progress bars
type ProgressBarStyle struct {
	FilledChar   string
	EmptyChar    string
	ProgressColor lipgloss.Color
	BackgroundColor lipgloss.Color
	Width        int
}

// DefaultProgressBarStyle returns a default progress bar style
func DefaultProgressBarStyle() ProgressBarStyle {
	return ProgressBarStyle{
		FilledChar:      "█",
		EmptyChar:       "░",
		ProgressColor:   lipgloss.Color("86"),  // Green
		BackgroundColor: lipgloss.Color("240"), // Gray
		Width:           40,
	}
}

// RenderProgressBar creates a visual progress bar
func RenderProgressBar(progress float64, style ProgressBarStyle) string {
	if progress < 0 {
		progress = 0
	}
	if progress > 1 {
		progress = 1
	}
	
	filled := int(progress * float64(style.Width))
	empty := style.Width - filled
	
	filledStyle := lipgloss.NewStyle().Foreground(style.ProgressColor)
	emptyStyle := lipgloss.NewStyle().Foreground(style.BackgroundColor)
	
	bar := filledStyle.Render(strings.Repeat(style.FilledChar, filled)) +
		  emptyStyle.Render(strings.Repeat(style.EmptyChar, empty))
	
	return bar
}

// RenderScanProgress creates a comprehensive scan progress display
func RenderScanProgress(progress scanner.ScanProgress, width int) string {
	var s strings.Builder
	
	// Progress bar
	progressPercent := float64(0)
	if progress.EstimatedTotal > 0 {
		progressPercent = float64(progress.DirectoriesScanned) / float64(progress.EstimatedTotal)
	}
	
	progressBar := RenderProgressBar(progressPercent, DefaultProgressBarStyle())
	percentText := fmt.Sprintf("%.0f%%", progressPercent*100)
	
	// Calculate ETA
	eta := ""
	if progress.ScanSpeed > 0 && progress.EstimatedTotal > 0 {
		remaining := progress.EstimatedTotal - progress.DirectoriesScanned
		secondsLeft := float64(remaining) / progress.ScanSpeed
		etaDuration := time.Duration(secondsLeft) * time.Second
		eta = fmt.Sprintf("ETA: %s", formatDuration(etaDuration))
	}
	
	// Progress line
	progressLine := fmt.Sprintf("Progress: %s %s", progressBar, percentText)
	if eta != "" {
		progressLine += fmt.Sprintf(" (%s)", eta)
	}
	s.WriteString(progressLine)
	s.WriteString("\n")
	
	// Current path (truncated to fit)
	if progress.CurrentPath != "" {
		maxPathWidth := width - 12 // Reserve space for "Scanning: "
		truncatedPath := truncatePath(progress.CurrentPath, maxPathWidth)
		scanningLine := fmt.Sprintf("Scanning: %s", truncatedPath)
		s.WriteString(lipgloss.NewStyle().Foreground(lipgloss.Color("33")).Render(scanningLine))
		s.WriteString("\n")
	}
	
	// Speed info
	speedLine := ""
	if progress.ScanSpeed > 0 {
		speedLine = fmt.Sprintf("Speed: %.0f dirs/sec", progress.ScanSpeed)
	}
	if speedLine != "" {
		s.WriteString(lipgloss.NewStyle().Foreground(lipgloss.Color("241")).Render(speedLine))
		s.WriteString("\n")
	}
	
	s.WriteString("\n")
	
	// Statistics
	statsStyle := lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("86"))
	
	foundText := fmt.Sprintf("Found: %d items", progress.ItemsFound)
	if progress.TotalSize > 0 {
		foundText += fmt.Sprintf(" (%s total)", utils.FormatBytes(progress.TotalSize))
	}
	s.WriteString(statsStyle.Render(foundText))
	s.WriteString("\n")
	
	scannedText := fmt.Sprintf("Scanned: %s directories", formatNumber(progress.DirectoriesScanned))
	s.WriteString(lipgloss.NewStyle().Foreground(lipgloss.Color("241")).Render(scannedText))
	s.WriteString("\n")
	
	return s.String()
}

// RenderSpinner creates an animated spinner
func RenderSpinner(frame int) string {
	spinners := []string{"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"}
	return spinners[frame%len(spinners)]
}

// formatDuration formats a duration in a human-readable way
func formatDuration(d time.Duration) string {
	if d < time.Minute {
		return fmt.Sprintf("%.0fs", d.Seconds())
	}
	
	minutes := int(d.Minutes())
	seconds := int(d.Seconds()) % 60
	
	if minutes < 60 {
		if seconds > 0 {
			return fmt.Sprintf("%dm %ds", minutes, seconds)
		}
		return fmt.Sprintf("%dm", minutes)
	}
	
	hours := minutes / 60
	minutes = minutes % 60
	
	if hours < 24 {
		return fmt.Sprintf("%dh %dm", hours, minutes)
	}
	
	return "∞"
}

// formatNumber formats a number with thousand separators
func formatNumber(n int) string {
	str := fmt.Sprintf("%d", n)
	if len(str) <= 3 {
		return str
	}
	
	var result strings.Builder
	for i, digit := range str {
		if i > 0 && (len(str)-i)%3 == 0 {
			result.WriteRune(',')
		}
		result.WriteRune(digit)
	}
	
	return result.String()
}

// truncatePath truncates a path to fit in the given width, keeping the most relevant parts
func truncatePath(path string, maxWidth int) string {
	if len(path) <= maxWidth {
		return path
	}
	
	// Try to keep the end of the path which is usually more relevant
	if maxWidth > 10 {
		return "..." + path[len(path)-(maxWidth-3):]
	}
	
	return path[:maxWidth]
}