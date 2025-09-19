package app

import (
	"fmt"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"cleanup-tool/internal/cleanup"
)

const (
	stateMenu     = 0
	stateRunning  = 1
	stateComplete = 2
)

type Model struct {
	state           int
	cursor          int
	selected        map[int]bool
	cleanupTypes    []cleanup.Type
	currentTask     string
	totalFreed      int64
	results         []cleanup.Result
	width           int
	height          int
}

func NewModel() Model {
	return Model{
		state:        stateMenu,
		cursor:       0,
		selected:     make(map[int]bool),
		cleanupTypes: cleanup.GetAllTypes(),
		width:        80,
		height:       24,
	}
}

func (m Model) Init() tea.Cmd {
	return nil
}

func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		return m, nil

	case tea.KeyMsg:
		switch m.state {
		case stateMenu:
			return m.updateMenu(msg)
		case stateRunning:
			return m.updateRunning(msg)
		case stateComplete:
			return m.updateComplete(msg)
		}

	case cleanup.ProgressMsg:
		m.currentTask = string(msg)
		return m, nil

	case cleanup.CompleteMsg:
		m.results = append(m.results, cleanup.Result(msg))
		return m, nil

	case cleanup.AllCompleteMsg:
		m.state = stateComplete
		// Calculate total freed space
		m.totalFreed = 0
		for _, result := range m.results {
			m.totalFreed += result.BytesFreed
		}
		return m, nil
	}

	return m, nil
}

func (m Model) updateMenu(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "up", "k":
		if m.cursor > 0 {
			m.cursor--
		}
	case "down", "j":
		if m.cursor < len(m.cleanupTypes)-1 {
			m.cursor++
		}
	case " ":
		m.selected[m.cursor] = !m.selected[m.cursor]
	case "enter":
		// Start cleanup
		var selectedTypes []cleanup.Type
		for i, cleanupType := range m.cleanupTypes {
			if m.selected[i] {
				selectedTypes = append(selectedTypes, cleanupType)
			}
		}
		if len(selectedTypes) > 0 {
			m.state = stateRunning
			return m, cleanup.RunCleanups(selectedTypes)
		}
	case "q", "ctrl+c":
		return m, tea.Quit
	}
	return m, nil
}

func (m Model) updateRunning(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "q", "ctrl+c":
		return m, tea.Quit
	}
	return m, nil
}

func (m Model) updateComplete(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "q", "ctrl+c", "enter":
		return m, tea.Quit
	case "r":
		// Reset to menu
		m.state = stateMenu
		m.cursor = 0
		m.selected = make(map[int]bool)
		m.results = nil
		m.totalFreed = 0
		m.currentTask = ""
		return m, nil
	}
	return m, nil
}

func (m Model) View() string {
	switch m.state {
	case stateMenu:
		return m.viewMenu()
	case stateRunning:
		return m.viewRunning()
	case stateComplete:
		return m.viewComplete()
	}
	return ""
}

func (m Model) viewMenu() string {
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
	for i, cleanupType := range m.cleanupTypes {
		cursor := " "
		if m.cursor == i {
			cursor = "▶"
		}

		checkbox := "○"
		if m.selected[i] {
			checkbox = "●"
		}

		line := fmt.Sprintf("%s %s %s %s", cursor, checkbox, cleanupType.Icon, cleanupType.Name)
		
		if m.cursor == i {
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
	selectedCount := len(m.selected)
	footerStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("241"))
	s.WriteString(footerStyle.Render(fmt.Sprintf("(%d selected)", selectedCount)))

	return s.String()
}

func (m Model) viewRunning() string {
	var s strings.Builder

	headerStyle := lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("86")).
		Padding(1, 2)
	
	s.WriteString(headerStyle.Render("🧹 Running Cleanup..."))
	s.WriteString("\n\n")

	if m.currentTask != "" {
		taskStyle := lipgloss.NewStyle().
			Foreground(lipgloss.Color("33"))
		s.WriteString(taskStyle.Render("⚡ " + m.currentTask))
		s.WriteString("\n\n")
	}

	// Show completed results
	for _, result := range m.results {
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
				Render(fmt.Sprintf(" (%s freed)", formatBytes(result.BytesFreed)))
		}

		s.WriteString(line)
		s.WriteString("\n")
	}

	s.WriteString("\n")
	s.WriteString(lipgloss.NewStyle().
		Foreground(lipgloss.Color("241")).
		Render("Press q to quit"))

	return s.String()
}

func (m Model) viewComplete() string {
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
	
	s.WriteString(summaryStyle.Render(fmt.Sprintf("Total space freed: %s", formatBytes(m.totalFreed))))
	s.WriteString("\n\n")

	// Results
	successCount := 0
	for _, result := range m.results {
		status := "✓"
		color := lipgloss.Color("46")
		if !result.Success {
			status = "✗"
			color = lipgloss.Color("196")
		} else {
			successCount++
		}

		line := lipgloss.NewStyle().
			Foreground(color).
			Render(fmt.Sprintf("%s %s", status, result.Description))
		
		if result.BytesFreed > 0 {
			line += lipgloss.NewStyle().
				Foreground(lipgloss.Color("241")).
				Render(fmt.Sprintf(" (%s freed)", formatBytes(result.BytesFreed)))
		}

		s.WriteString(line)
		s.WriteString("\n")
	}

	s.WriteString("\n")
	instructionStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("241"))
	s.WriteString(instructionStyle.Render("Press q to quit, r to return to menu"))

	return s.String()
}

func formatBytes(bytes int64) string {
	const unit = 1024
	if bytes < unit {
		return fmt.Sprintf("%d B", bytes)
	}
	div, exp := int64(unit), 0
	for n := bytes / unit; n >= unit; n /= unit {
		div *= unit
		exp++
	}
	return fmt.Sprintf("%.1f %cB", float64(bytes)/float64(div), "KMGTPE"[exp])
}