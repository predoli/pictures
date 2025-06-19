package main

import (
	"io/ioutil"
	"time"

	"gopkg.in/yaml.v3"
)

type Config struct {
	Server struct {
		Port string `yaml:"port"`
		Host string `yaml:"host"`
	} `yaml:"server"`
	
	WebDAV struct {
		SyncInterval string `yaml:"sync_interval"`
		Directories  []struct {
			Name      string `yaml:"name"`
			BaseURL   string `yaml:"base_url"`
			Path      string `yaml:"path"`
			Username  string `yaml:"username"`
			Password  string `yaml:"password"`
			LocalPath string `yaml:"local_path"`
		} `yaml:"directories"`
	} `yaml:"webdav"`
	
	Images struct {
		SupportedFormats   []string `yaml:"supported_formats"`
		MaxFileSize        string   `yaml:"max_file_size"`
		QualityCompression int      `yaml:"quality_compression"`
	} `yaml:"images"`
	
	Logging struct {
		Level string `yaml:"level"`
		File  string `yaml:"file"`
	} `yaml:"logging"`
}

func loadConfig(filename string) (*Config, error) {
	data, err := ioutil.ReadFile(filename)
	if err != nil {
		return nil, err
	}

	var config Config
	err = yaml.Unmarshal(data, &config)
	if err != nil {
		return nil, err
	}

	return &config, nil
}

func (c *Config) GetSyncInterval() time.Duration {
	duration, err := time.ParseDuration(c.WebDAV.SyncInterval)
	if err != nil {
		return 5 * time.Minute // Default fallback
	}
	return duration
}