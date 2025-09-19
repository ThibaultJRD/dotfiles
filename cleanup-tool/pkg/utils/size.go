package utils

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
)

// CalculateDirSize calculates the size of a directory with context support for cancellation
func CalculateDirSize(ctx context.Context, dirPath string) (int64, int64, error) {
	var totalSize int64
	var fileCount int64

	err := filepath.Walk(dirPath, func(path string, info os.FileInfo, err error) error {
		// Check for context cancellation
		select {
		case <-ctx.Done():
			return ctx.Err()
		default:
		}

		if err != nil {
			// Skip inaccessible files/directories but continue walking
			return nil
		}

		if !info.IsDir() {
			totalSize += info.Size()
			fileCount++
		}

		return nil
	})

	return totalSize, fileCount, err
}

// FormatBytes formats bytes into human readable format
func FormatBytes(bytes int64) string {
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

// SafeRemoveAll removes a directory safely with error handling
func SafeRemoveAll(path string) error {
	// Double-check the path exists and is accessible
	if _, err := os.Stat(path); err != nil {
		return err
	}
	
	return os.RemoveAll(path)
}