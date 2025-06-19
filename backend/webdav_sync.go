package main

import (
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/studio-b12/gowebdav"
)

type WebDAVSyncer struct {
	config *Config
}

func NewWebDAVSyncer(config *Config) *WebDAVSyncer {
	return &WebDAVSyncer{config: config}
}

func (w *WebDAVSyncer) Start() {
	log.Println("Starting WebDAV synchronization...")
	
	// Initial sync
	w.syncAll()
	
	// Set up periodic sync
	ticker := time.NewTicker(w.config.GetSyncInterval())
	go func() {
		for range ticker.C {
			w.syncAll()
		}
	}()
}

func (w *WebDAVSyncer) syncAll() {
	for _, dir := range w.config.WebDAV.Directories {
		if err := w.syncDirectory(dir); err != nil {
			log.Printf("Error syncing directory %s: %v", dir.Name, err)
		}
	}
}

func (w *WebDAVSyncer) syncDirectory(dirConfig struct {
	Name      string `yaml:"name"`
	BaseURL   string `yaml:"base_url"`
	Path      string `yaml:"path"`
	Username  string `yaml:"username"`
	Password  string `yaml:"password"`
	LocalPath string `yaml:"local_path"`
}) error {
	log.Printf("Syncing directory: %s", dirConfig.Name)
	
	// Create WebDAV client
	client := gowebdav.NewClient(dirConfig.BaseURL, dirConfig.Username, dirConfig.Password)
	
	// Ensure local directory exists
	if err := os.MkdirAll(dirConfig.LocalPath, 0755); err != nil {
		return fmt.Errorf("failed to create local directory: %v", err)
	}
	
	// Track all remote files (including nested ones)
	remoteFiles := make(map[string]bool)
	
	// Recursively sync directory
	if err := w.syncDirectoryRecursive(client, dirConfig.Path, dirConfig.LocalPath, dirConfig.Path, remoteFiles); err != nil {
		return err
	}
	
	// Remove local files that no longer exist remotely
	w.cleanupLocalFiles(dirConfig.LocalPath, remoteFiles)
	
	return nil
}

func (w *WebDAVSyncer) syncDirectoryRecursive(client *gowebdav.Client, remotePath, localPath, baseRemotePath string, remoteFiles map[string]bool) error {
	// List remote files/directories
	files, err := client.ReadDir(remotePath)
	if err != nil {
		return fmt.Errorf("failed to read remote directory %s: %v", remotePath, err)
	}
	
	for _, file := range files {
		if file.IsDir() {
			// Create local subdirectory
			subLocalPath := filepath.Join(localPath, file.Name())
			if err := os.MkdirAll(subLocalPath, 0755); err != nil {
				log.Printf("Error creating local directory %s: %v", subLocalPath, err)
				continue
			}
			
			// Recursively sync subdirectory
			subRemotePath := filepath.Join(remotePath, file.Name())
			if err := w.syncDirectoryRecursive(client, subRemotePath, subLocalPath, baseRemotePath, remoteFiles); err != nil {
				log.Printf("Error syncing subdirectory %s: %v", subRemotePath, err)
				continue
			}
		} else {
			// Check if it's an image file
			if !w.isImageFile(file.Name()) {
				continue
			}
			
			// Create relative path for tracking (relative to the base remote path)
			normalizedBasePath := strings.TrimPrefix(baseRemotePath, "/")
			normalizedCurrentPath := strings.TrimPrefix(remotePath, "/")
			
			var relativeFilePath string
			if normalizedBasePath != "" && strings.HasPrefix(normalizedCurrentPath, normalizedBasePath) {
				relativeDirFromBase := strings.TrimPrefix(normalizedCurrentPath, normalizedBasePath)
				relativeDirFromBase = strings.TrimPrefix(relativeDirFromBase, "/")
				if relativeDirFromBase != "" {
					relativeFilePath = filepath.ToSlash(filepath.Join(relativeDirFromBase, file.Name()))
				} else {
					relativeFilePath = file.Name()
				}
			} else {
				relativeFilePath = file.Name()
			}
			
			remoteFiles[relativeFilePath] = true
			
			// Local file path
			localFilePath := filepath.Join(localPath, file.Name())
			
			// Check if local file exists and is up to date
			if w.shouldDownloadFile(localFilePath, file.ModTime()) {
				remoteFilePath := filepath.Join(remotePath, file.Name())
				if err := w.downloadFile(client, remoteFilePath, localFilePath); err != nil {
					log.Printf("Error downloading %s: %v", file.Name(), err)
					continue
				}
				log.Printf("Downloaded: %s", remoteFilePath)
			}
		}
	}
	
	return nil
}

func (w *WebDAVSyncer) isImageFile(filename string) bool {
	ext := strings.ToLower(filepath.Ext(filename))
	for _, supportedExt := range w.config.Images.SupportedFormats {
		if ext == supportedExt {
			return true
		}
	}
	return false
}

func (w *WebDAVSyncer) shouldDownloadFile(localPath string, remoteModTime time.Time) bool {
	localInfo, err := os.Stat(localPath)
	if os.IsNotExist(err) {
		return true // File doesn't exist locally
	}
	if err != nil {
		log.Printf("Error checking local file %s: %v", localPath, err)
		return true // Download on error to be safe
	}
	
	// Download if remote file is newer
	return remoteModTime.After(localInfo.ModTime())
}

func (w *WebDAVSyncer) downloadFile(client *gowebdav.Client, remotePath, localPath string) error {
	reader, err := client.ReadStream(remotePath)
	if err != nil {
		return err
	}
	defer reader.Close()
	
	localFile, err := os.Create(localPath)
	if err != nil {
		return err
	}
	defer localFile.Close()
	
	_, err = io.Copy(localFile, reader)
	return err
}

func (w *WebDAVSyncer) cleanupLocalFiles(localDir string, remoteFiles map[string]bool) {
	filepath.Walk(localDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		
		if info.IsDir() {
			return nil
		}
		
		filename := info.Name()
		if !w.isImageFile(filename) {
			return nil
		}
		
		// Get relative path from base directory
		relativePath, err := filepath.Rel(localDir, path)
		if err != nil {
			log.Printf("Error getting relative path for %s: %v", path, err)
			return nil
		}
		
		// Normalize path separators for comparison
		relativePath = filepath.ToSlash(relativePath)
		
		// If file doesn't exist remotely, remove it locally
		if !remoteFiles[relativePath] {
			log.Printf("Removing local file (no longer exists remotely): %s", relativePath)
			os.Remove(path)
		}
		
		return nil
	})
}