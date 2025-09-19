package cleanup

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
)

func cleanNodeModules() tea.Cmd {
	return func() tea.Msg {
		homeDir, err := os.UserHomeDir()
		if err != nil {
			return CompleteMsg{
				Type:        "node_modules",
				Description: "node_modules cleanup",
				Success:     false,
				Error:       err,
			}
		}

		var totalSize int64
		var removedDirs []string

		// Find node_modules directories
		err = filepath.Walk(homeDir, func(path string, info os.FileInfo, err error) error {
			if err != nil {
				return nil // Skip errors, continue walking
			}

			// Skip certain directories to speed up search
			if info.IsDir() {
				name := info.Name()
				if strings.HasPrefix(name, ".") && name != ".." {
					return filepath.SkipDir
				}
				if name == "Library" || name == "Applications" || name == "System" {
					return filepath.SkipDir
				}
				if name == "node_modules" {
					// Don't traverse nested node_modules
					if strings.Contains(path, "node_modules/") {
						return filepath.SkipDir
					}
					
					// Calculate size before removal
					size, _ := getDirSize(path)
					
					// Remove the directory
					err := os.RemoveAll(path)
					if err == nil {
						totalSize += size
						removedDirs = append(removedDirs, path)
					}
					
					return filepath.SkipDir
				}
			}
			return nil
		})

		description := fmt.Sprintf("node_modules cleanup - removed %d directories", len(removedDirs))
		return CompleteMsg{
			Type:        "node_modules",
			Description: description,
			Success:     true,
			BytesFreed:  totalSize,
		}
	}
}

func cleanNpmCache() tea.Cmd {
	return func() tea.Msg {
		homeDir, err := os.UserHomeDir()
		if err != nil {
			return CompleteMsg{
				Type:        "npm_cache",
				Description: "npm cache cleanup",
				Success:     false,
				Error:       err,
			}
		}

		npmCacheDir := filepath.Join(homeDir, ".npm")
		var totalSize int64

		if _, err := os.Stat(npmCacheDir); err == nil {
			size, _ := getDirSize(npmCacheDir)
			err = os.RemoveAll(npmCacheDir)
			if err == nil {
				totalSize = size
			}
		}

		// Also try npm cache clean command if available
		if _, err := exec.LookPath("npm"); err == nil {
			exec.Command("npm", "cache", "clean", "--force").Run()
		}

		return CompleteMsg{
			Type:        "npm_cache",
			Description: "npm cache cleanup",
			Success:     true,
			BytesFreed:  totalSize,
		}
	}
}

func cleanYarnCache() tea.Cmd {
	return func() tea.Msg {
		homeDir, err := os.UserHomeDir()
		if err != nil {
			return CompleteMsg{
				Type:        "yarn_cache",
				Description: "Yarn cache cleanup",
				Success:     false,
				Error:       err,
			}
		}

		var totalSize int64
		
		// Yarn v1 cache
		yarnV1Cache := filepath.Join(homeDir, ".yarn", "cache")
		if _, err := os.Stat(yarnV1Cache); err == nil {
			size, _ := getDirSize(yarnV1Cache)
			err = os.RemoveAll(yarnV1Cache)
			if err == nil {
				totalSize += size
			}
		}

		// Yarn Berry cache
		yarnBerryCache := filepath.Join(homeDir, ".yarn", "berry", "cache")
		if _, err := os.Stat(yarnBerryCache); err == nil {
			size, _ := getDirSize(yarnBerryCache)
			err = os.RemoveAll(yarnBerryCache)
			if err == nil {
				totalSize += size
			}
		}

		// Global Yarn cache
		yarnGlobalCache := filepath.Join(homeDir, "Library", "Caches", "Yarn")
		if _, err := os.Stat(yarnGlobalCache); err == nil {
			size, _ := getDirSize(yarnGlobalCache)
			err = os.RemoveAll(yarnGlobalCache)
			if err == nil {
				totalSize += size
			}
		}

		// Try yarn cache clean command if available
		if _, err := exec.LookPath("yarn"); err == nil {
			exec.Command("yarn", "cache", "clean").Run()
		}

		return CompleteMsg{
			Type:        "yarn_cache",
			Description: "Yarn cache cleanup",
			Success:     true,
			BytesFreed:  totalSize,
		}
	}
}

func cleanBunCache() tea.Cmd {
	return func() tea.Msg {
		homeDir, err := os.UserHomeDir()
		if err != nil {
			return CompleteMsg{
				Type:        "bun_cache",
				Description: "Bun cache cleanup",
				Success:     false,
				Error:       err,
			}
		}

		var totalSize int64

		// Bun cache
		bunCache := filepath.Join(homeDir, ".bun", "cache")
		if _, err := os.Stat(bunCache); err == nil {
			size, _ := getDirSize(bunCache)
			err = os.RemoveAll(bunCache)
			if err == nil {
				totalSize += size
			}
		}

		// Bun install cache
		bunInstallCache := filepath.Join(homeDir, "Library", "Caches", "bun")
		if _, err := os.Stat(bunInstallCache); err == nil {
			size, _ := getDirSize(bunInstallCache)
			err = os.RemoveAll(bunInstallCache)
			if err == nil {
				totalSize += size
			}
		}

		return CompleteMsg{
			Type:        "bun_cache",
			Description: "Bun cache cleanup",
			Success:     true,
			BytesFreed:  totalSize,
		}
	}
}

func cleanCocoaPods() tea.Cmd {
	return func() tea.Msg {
		homeDir, err := os.UserHomeDir()
		if err != nil {
			return CompleteMsg{
				Type:        "cocoapods",
				Description: "CocoaPods cleanup",
				Success:     false,
				Error:       err,
			}
		}

		var totalSize int64

		// CocoaPods cache
		podsCache := filepath.Join(homeDir, "Library", "Caches", "CocoaPods")
		if _, err := os.Stat(podsCache); err == nil {
			size, _ := getDirSize(podsCache)
			err = os.RemoveAll(podsCache)
			if err == nil {
				totalSize += size
			}
		}

		// Find and remove Pods directories
		var removedPods int
		err = filepath.Walk(homeDir, func(path string, info os.FileInfo, err error) error {
			if err != nil {
				return nil
			}

			if info.IsDir() {
				name := info.Name()
				if strings.HasPrefix(name, ".") && name != ".." {
					return filepath.SkipDir
				}
				if name == "Library" || name == "Applications" || name == "System" {
					return filepath.SkipDir
				}
				if name == "Pods" {
					// Check if this looks like a CocoaPods directory
					podfilePath := filepath.Join(filepath.Dir(path), "Podfile")
					if _, err := os.Stat(podfilePath); err == nil {
						size, _ := getDirSize(path)
						err := os.RemoveAll(path)
						if err == nil {
							totalSize += size
							removedPods++
						}
					}
					return filepath.SkipDir
				}
			}
			return nil
		})

		description := fmt.Sprintf("CocoaPods cleanup - removed %d Pods directories", removedPods)
		return CompleteMsg{
			Type:        "cocoapods",
			Description: description,
			Success:     true,
			BytesFreed:  totalSize,
		}
	}
}

func cleanDocker() tea.Cmd {
	return func() tea.Msg {
		// Check if Docker is available
		if _, err := exec.LookPath("docker"); err != nil {
			return CompleteMsg{
				Type:        "docker",
				Description: "Docker cleanup - Docker not found",
				Success:     false,
				Error:       err,
			}
		}

		// Run docker system prune
		cmd := exec.Command("docker", "system", "prune", "-a", "--volumes", "-f")
		output, err := cmd.CombinedOutput()
		
		success := err == nil
		description := "Docker system cleanup"
		if !success {
			description += " - failed"
		}

		// Try to extract freed space from output if available
		var bytesFreed int64
		outputStr := string(output)
		if strings.Contains(outputStr, "Total reclaimed space:") {
			// Docker outputs something like "Total reclaimed space: 1.2GB"
			// We could parse this, but for now just mark as successful
		}

		return CompleteMsg{
			Type:        "docker",
			Description: description,
			Success:     success,
			BytesFreed:  bytesFreed,
			Error:       err,
		}
	}
}

func cleanXcode() tea.Cmd {
	return func() tea.Msg {
		homeDir, err := os.UserHomeDir()
		if err != nil {
			return CompleteMsg{
				Type:        "xcode",
				Description: "Xcode cleanup",
				Success:     false,
				Error:       err,
			}
		}

		var totalSize int64

		// Xcode DerivedData
		derivedData := filepath.Join(homeDir, "Library", "Developer", "Xcode", "DerivedData")
		if _, err := os.Stat(derivedData); err == nil {
			size, _ := getDirSize(derivedData)
			err = os.RemoveAll(derivedData)
			if err == nil {
				totalSize += size
			}
		}

		// iOS Simulator cache
		simulatorCache := filepath.Join(homeDir, "Library", "Developer", "CoreSimulator", "Caches")
		if _, err := os.Stat(simulatorCache); err == nil {
			size, _ := getDirSize(simulatorCache)
			err = os.RemoveAll(simulatorCache)
			if err == nil {
				totalSize += size
			}
		}

		return CompleteMsg{
			Type:        "xcode",
			Description: "Xcode caches cleanup",
			Success:     true,
			BytesFreed:  totalSize,
		}
	}
}

func cleanSystemCaches() tea.Cmd {
	return func() tea.Msg {
		homeDir, err := os.UserHomeDir()
		if err != nil {
			return CompleteMsg{
				Type:        "system",
				Description: "System caches cleanup",
				Success:     false,
				Error:       err,
			}
		}

		var totalSize int64
		var removedFiles int

		// Remove .DS_Store files
		err = filepath.Walk(homeDir, func(path string, info os.FileInfo, err error) error {
			if err != nil {
				return nil
			}

			if !info.IsDir() && info.Name() == ".DS_Store" {
				size := info.Size()
				err := os.Remove(path)
				if err == nil {
					totalSize += size
					removedFiles++
				}
			}

			// Skip certain directories
			if info.IsDir() {
				name := info.Name()
				if name == "Library" || name == "Applications" || name == "System" {
					return filepath.SkipDir
				}
			}
			return nil
		})

		// Clean Trash
		trashDir := filepath.Join(homeDir, ".Trash")
		if _, err := os.Stat(trashDir); err == nil {
			size, _ := getDirSize(trashDir)
			// Remove contents, not the trash directory itself
			entries, err := os.ReadDir(trashDir)
			if err == nil {
				for _, entry := range entries {
					entryPath := filepath.Join(trashDir, entry.Name())
					os.RemoveAll(entryPath)
				}
				totalSize += size
			}
		}

		description := fmt.Sprintf("System cleanup - removed %d .DS_Store files", removedFiles)
		return CompleteMsg{
			Type:        "system",
			Description: description,
			Success:     true,
			BytesFreed:  totalSize,
		}
	}
}