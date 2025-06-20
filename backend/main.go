package main

import (
	"encoding/base64"
	"fmt"
	"io/ioutil"
	"log"
	"mime"
	"net/http"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
)

type Image struct {
	Filename     string    `json:"filename"`
	Data         string    `json:"data"`
	MimeType     string    `json:"mime_type"`
	Size         int64     `json:"size"`
	Width        int       `json:"width,omitempty"`
	Height       int       `json:"height,omitempty"`
	ModifiedDate time.Time `json:"modified_date"`
}

type ImagesResponse struct {
	Images     []Image `json:"images"`
	TotalCount int     `json:"total_count"`
}

type ErrorResponse struct {
	Error string `json:"error"`
	Code  int    `json:"code"`
}

var (
	config *Config
	syncer *WebDAVSyncer
)

func isImageFile(filename string) bool {
	ext := strings.ToLower(filepath.Ext(filename))
	for _, supportedExt := range config.Images.SupportedFormats {
		if ext == supportedExt {
			return true
		}
	}
	return false
}

func loadImageFromFile(path string) (*Image, error) {
	info, err := os.Stat(path)
	if err != nil {
		return nil, err
	}

	data, err := ioutil.ReadFile(path)
	if err != nil {
		return nil, err
	}

	base64Data := base64.StdEncoding.EncodeToString(data)
	mimeType := mime.TypeByExtension(strings.ToLower(filepath.Ext(path)))
	if mimeType == "" {
		mimeType = "application/octet-stream"
	}

	return &Image{
		Filename:     filepath.Base(path),
		Data:         base64Data,
		MimeType:     mimeType,
		Size:         info.Size(),
		ModifiedDate: info.ModTime(),
	}, nil
}

func scanDirectoryForImages(dir string) ([]Image, error) {
	var images []Image

	err := filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if !info.IsDir() && isImageFile(info.Name()) {
			image, err := loadImageFromFile(path)
			if err != nil {
				log.Printf("Error loading image %s: %v", path, err)
				return nil // Continue walking, don't stop on individual file errors
			}
			images = append(images, *image)
		}
		return nil
	})

	return images, err
}

func sortImages(images []Image, ordering string) {
	switch ordering {
	case "name_asc":
		sort.Slice(images, func(i, j int) bool {
			return images[i].Filename < images[j].Filename
		})
	case "name_desc":
		sort.Slice(images, func(i, j int) bool {
			return images[i].Filename > images[j].Filename
		})
	case "date_asc":
		sort.Slice(images, func(i, j int) bool {
			return images[i].ModifiedDate.Before(images[j].ModifiedDate)
		})
	case "date_desc":
		sort.Slice(images, func(i, j int) bool {
			return images[i].ModifiedDate.After(images[j].ModifiedDate)
		})
	case "random":
		// For random, we'll just return as-is for now
		// TODO: Implement proper random shuffling
	}
}

func findStartIndex(images []Image, lastImage string) int {
	if lastImage == "" {
		return 0
	}

	for i, img := range images {
		if img.Filename == lastImage {
			return i + 1 // Start from the next image
		}
	}
	return 0 // If not found, start from beginning
}

func getImages(c *gin.Context) {
	countStr := c.Query("count")
	ordering := c.Query("ordering")
	lastImage := c.Query("last_image")

	// Validate required parameters
	if countStr == "" {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error: "count parameter is required",
			Code:  400,
		})
		return
	}

	if ordering == "" {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error: "ordering parameter is required",
			Code:  400,
		})
		return
	}

	count, err := strconv.Atoi(countStr)
	if err != nil || count < 1 || count > 100 {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error: "count must be a number between 1 and 100",
			Code:  400,
		})
		return
	}

	validOrderings := map[string]bool{
		"name_asc":  true,
		"name_desc": true,
		"date_asc":  true,
		"date_desc": true,
		"random":    true,
	}
	if !validOrderings[ordering] {
		c.JSON(http.StatusBadRequest, ErrorResponse{
			Error: "invalid ordering parameter",
			Code:  400,
		})
		return
	}

	// Scan all configured WebDAV directories for images
	var allImages []Image
	for _, dir := range config.WebDAV.Directories {
		if _, err := os.Stat(dir.LocalPath); os.IsNotExist(err) {
			log.Printf("Directory %s does not exist, skipping", dir.LocalPath)
			continue
		}

		dirImages, err := scanDirectoryForImages(dir.LocalPath)
		if err != nil {
			log.Printf("Error scanning directory %s: %v", dir.LocalPath, err)
			continue
		}
		allImages = append(allImages, dirImages...)
	}

	sortImages(allImages, ordering)
	startIndex := findStartIndex(allImages, lastImage)

	// Get the requested number of images starting from startIndex
	var selectedImages []Image
	for i := 0; i < count && (startIndex+i) < len(allImages); i++ {
		selectedImages = append(selectedImages, allImages[startIndex+i])
	}

	c.JSON(http.StatusOK, ImagesResponse{
		Images:     selectedImages,
		TotalCount: len(allImages),
	})
}

func main() {
	// Load configuration
	var err error
	config, err = loadConfig("config.yaml")
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// Initialize WebDAV syncer
	syncer = NewWebDAVSyncer(config)
	syncer.Start()

	r := gin.Default()

	// Add CORS middleware for frontend access
	r.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}

		c.Next()
	})

	r.GET("/images", getImages)

	serverAddr := fmt.Sprintf("%s:%s", config.Server.Host, config.Server.Port)
	log.Printf("Starting server on %s", serverAddr)
	r.Run(serverAddr)
}
