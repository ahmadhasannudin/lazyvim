package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/pkg/sftp"
	"golang.org/x/crypto/ssh"
)

type ProjectConfig struct {
	LocalBasePath string `json:"local_base_path"`
	SFTPHost      string `json:"sftp_host"`
	SFTPPort      string `json:"sftp_port"`
	SFTPUser      string `json:"sftp_user"`
	SFTPPassword  string `json:"sftp_password"`
	SFTPBasePath  string `json:"sftp_base_path"`
}

type Config struct {
	ServerPort         string                   `json:"server_port"`
	RegisteredProjects map[string]ProjectConfig `json:"registered_projects"`
}

type UploadRequest struct {
	BaseRoot string `json:"base_root"`
	FilePath string `json:"file_path"`
}

type FolderRequest struct {
	BaseRoot   string `json:"base_root"`
	FolderPath string `json:"folder_path"`
}

type DownloadRequest struct {
	BaseRoot string `json:"base_root"`
	FilePath string `json:"file_path"`
}

type UploadResponse struct {
	Success bool   `json:"success"`
	Message string `json:"message"`
	File    string `json:"file"`
}

type ConnectionPool struct {
	connections map[string]*PooledConnection
	mu          sync.RWMutex
}

type PooledConnection struct {
	sshConn    *ssh.Client
	sftpClient *sftp.Client
	lastUsed   time.Time
	mu         sync.Mutex
}

var (
	appConfig      Config
	configMutex    sync.RWMutex
	configPath     string
	connectionPool = &ConnectionPool{
		connections: make(map[string]*PooledConnection),
	}
)

func (p *ConnectionPool) getConnection(config ProjectConfig) (*sftp.Client, error) {
	key := fmt.Sprintf("%s:%s@%s:%s", config.SFTPUser, config.SFTPHost, config.SFTPPort, config.SFTPBasePath)

	p.mu.Lock()
	defer p.mu.Unlock()

	// Check if we have a valid connection
	if conn, exists := p.connections[key]; exists {
		conn.mu.Lock()
		defer conn.mu.Unlock()

		// Test if connection is still alive
		if _, err := conn.sftpClient.Getwd(); err == nil {
			conn.lastUsed = time.Now()
			return conn.sftpClient, nil
		}

		// Connection is dead, clean it up
		conn.sftpClient.Close()
		conn.sshConn.Close()
		delete(p.connections, key)
	}

	// Create new connection
	sshConfig := &ssh.ClientConfig{
		User: config.SFTPUser,
		Auth: []ssh.AuthMethod{
			ssh.Password(config.SFTPPassword),
		},
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
		Timeout:         10 * time.Second,
	}

	sshConn, err := ssh.Dial("tcp", fmt.Sprintf("%s:%s", config.SFTPHost, config.SFTPPort), sshConfig)
	if err != nil {
		return nil, fmt.Errorf("failed to dial: %w", err)
	}

	sftpClient, err := sftp.NewClient(sshConn)
	if err != nil {
		sshConn.Close()
		return nil, fmt.Errorf("failed to create SFTP client: %w", err)
	}

	pooledConn := &PooledConnection{
		sshConn:    sshConn,
		sftpClient: sftpClient,
		lastUsed:   time.Now(),
	}

	p.connections[key] = pooledConn
	return sftpClient, nil
}

func (p *ConnectionPool) cleanup() {
	p.mu.Lock()
	defer p.mu.Unlock()

	now := time.Now()
	for key, conn := range p.connections {
		if now.Sub(conn.lastUsed) > 5*time.Minute {
			conn.mu.Lock()
			conn.sftpClient.Close()
			conn.sshConn.Close()
			conn.mu.Unlock()
			delete(p.connections, key)
			log.Printf("Cleaned up idle connection: %s", key)
		}
	}
}

func startConnectionCleanup() {
	ticker := time.NewTicker(1 * time.Minute)
	go func() {
		for range ticker.C {
			connectionPool.cleanup()
		}
	}()
}

func main() {
	configPath = os.Getenv("CONFIG_PATH")
	if configPath == "" {
		configPath = "sftp-listener.json"
	}

	if err := loadConfig(); err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// Start connection cleanup goroutine
	startConnectionCleanup()

	configMutex.RLock()
	serverPort := appConfig.ServerPort
	projectCount := len(appConfig.RegisteredProjects)
	projects := make([]string, 0, projectCount)
	for key := range appConfig.RegisteredProjects {
		projects = append(projects, key)
	}
	configMutex.RUnlock()

	log.Printf("Starting HTTP server on port %s", serverPort)
	log.Printf("Registered %d projects", projectCount)
	for _, key := range projects {
		log.Printf("  - %s", key)
	}

	http.HandleFunc("/upload", handleUpload)
	http.HandleFunc("/upload-folder", handleUploadFolder)
	http.HandleFunc("/download", handleDownload)
	http.HandleFunc("/download-folder", handleDownloadFolder)
	http.HandleFunc("/health", handleHealth)
	http.HandleFunc("/projects", handleListProjects)
	http.HandleFunc("/reload", handleReload)

	log.Fatal(http.ListenAndServe(":"+serverPort, nil))
}

func loadConfig() error {
	data, err := os.ReadFile(configPath)
	if err != nil {
		return fmt.Errorf("failed to read config file: %w", err)
	}

	var newConfig Config
	if err := json.Unmarshal(data, &newConfig); err != nil {
		return fmt.Errorf("failed to parse config file: %w", err)
	}

	if newConfig.ServerPort == "" {
		newConfig.ServerPort = "8765"
	}

	configMutex.Lock()
	appConfig = newConfig
	configMutex.Unlock()

	return nil
}

func getConfig() Config {
	configMutex.RLock()
	defer configMutex.RUnlock()
	return appConfig
}

func handleReload(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if err := loadConfig(); err != nil {
		log.Printf("Failed to reload config: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]string{
			"status":  "error",
			"message": fmt.Sprintf("Failed to reload config: %v", err),
		})
		return
	}

	config := getConfig()
	log.Printf("Config reloaded successfully. Registered %d projects", len(config.RegisteredProjects))
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status":        "ok",
		"message":       "Config reloaded successfully",
		"project_count": len(config.RegisteredProjects),
	})
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}

func handleListProjects(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	config := getConfig()
	projects := make([]string, 0, len(config.RegisteredProjects))
	for key := range config.RegisteredProjects {
		projects = append(projects, key)
	}

	json.NewEncoder(w).Encode(map[string]interface{}{
		"projects": projects,
		"count":    len(projects),
	})
}

func handleUpload(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: "Only POST method is allowed",
		})
		return
	}

	var req UploadRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: fmt.Sprintf("Invalid JSON: %v", err),
		})
		return
	}

	if req.BaseRoot == "" || req.FilePath == "" {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: "base_root and file_path are required",
		})
		return
	}

	config := getConfig()
	projectConfig, exists := config.RegisteredProjects[req.BaseRoot]
	if !exists {
		log.Printf("Project not registered: %s", req.BaseRoot)
		w.WriteHeader(http.StatusForbidden)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: fmt.Sprintf("Project not registered: %s", req.BaseRoot),
		})
		return
	}

	if !strings.HasPrefix(req.FilePath, projectConfig.LocalBasePath) {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: "File path must be within the project base path",
		})
		return
	}

	if _, err := os.Stat(req.FilePath); os.IsNotExist(err) {
		w.WriteHeader(http.StatusNotFound)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: "File does not exist",
		})
		return
	}

	log.Printf("[%s] Uploading: %s", req.BaseRoot, req.FilePath)

	if err := uploadFile(projectConfig, req.FilePath); err != nil {
		log.Printf("[%s] Upload failed: %v", req.BaseRoot, err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: fmt.Sprintf("Upload failed: %v", err),
			File:    req.FilePath,
		})
		return
	}

	log.Printf("[%s] Successfully uploaded: %s", req.BaseRoot, req.FilePath)
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(UploadResponse{
		Success: true,
		Message: "File uploaded successfully",
		File:    req.FilePath,
	})
}

func uploadFile(config ProjectConfig, localPath string) error {
	client, err := connectionPool.getConnection(config)
	if err != nil {
		return err
	}

	srcFile, err := os.Open(localPath)
	if err != nil {
		return fmt.Errorf("failed to open source file: %w", err)
	}
	defer srcFile.Close()

	relativePath := strings.TrimPrefix(localPath, config.LocalBasePath)
	relativePath = strings.TrimPrefix(relativePath, "/")
	remotePath := filepath.Join(config.SFTPBasePath, relativePath)
	remoteDir := filepath.Dir(remotePath)

	if err := client.MkdirAll(remoteDir); err != nil {
		return fmt.Errorf("failed to create remote directory: %w", err)
	}

	dstFile, err := client.Create(remotePath)
	if err != nil {
		return fmt.Errorf("failed to create remote file: %w", err)
	}
	defer dstFile.Close()

	// Use buffered copy for better performance
	buf := make([]byte, 32*1024) // 32KB buffer
	if _, err := io.CopyBuffer(dstFile, srcFile, buf); err != nil {
		return fmt.Errorf("failed to upload file: %w", err)
	}

	return nil
}

func handleUploadFolder(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: "Only POST method is allowed",
		})
		return
	}

	var req FolderRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: fmt.Sprintf("Invalid JSON: %v", err),
		})
		return
	}

	if req.BaseRoot == "" || req.FolderPath == "" {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: "base_root and folder_path are required",
		})
		return
	}

	config := getConfig()
	projectConfig, exists := config.RegisteredProjects[req.BaseRoot]
	if !exists {
		log.Printf("Project not registered: %s", req.BaseRoot)
		w.WriteHeader(http.StatusForbidden)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: fmt.Sprintf("Project not registered: %s", req.BaseRoot),
		})
		return
	}

	log.Printf("[%s] Uploading folder: %s", req.BaseRoot, req.FolderPath)

	// Collect all files first
	var filesToUpload []string
	err := filepath.Walk(req.FolderPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() {
			filesToUpload = append(filesToUpload, path)
		}
		return nil
	})

	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: fmt.Sprintf("Folder scan failed: %v", err),
		})
		return
	}

	// Upload files in parallel with limited concurrency
	const maxConcurrency = 10
	sem := make(chan struct{}, maxConcurrency)
	var wg sync.WaitGroup
	var uploadMutex sync.Mutex
	fileCount := 0
	var uploadErrors []string

	for _, path := range filesToUpload {
		wg.Add(1)
		go func(p string) {
			defer wg.Done()
			sem <- struct{}{}        // acquire
			defer func() { <-sem }() // release

			if err := uploadFile(projectConfig, p); err != nil {
				uploadMutex.Lock()
				uploadErrors = append(uploadErrors, fmt.Sprintf("%s: %v", p, err))
				uploadMutex.Unlock()
				log.Printf("[%s] Failed to upload %s: %v", req.BaseRoot, p, err)
			} else {
				uploadMutex.Lock()
				fileCount++
				uploadMutex.Unlock()
			}
		}(path)
	}

	wg.Wait()

	if len(uploadErrors) > 0 {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: fmt.Sprintf("Folder upload completed with errors (%d/%d succeeded): %s", fileCount, len(filesToUpload), strings.Join(uploadErrors, "; ")),
		})
		return
	}

	log.Printf("[%s] Successfully uploaded folder with %d files", req.BaseRoot, fileCount)
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(UploadResponse{
		Success: true,
		Message: fmt.Sprintf("Folder uploaded successfully (%d files)", fileCount),
		File:    req.FolderPath,
	})
}

func handleDownload(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: "Only POST method is allowed",
		})
		return
	}

	var req DownloadRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: fmt.Sprintf("Invalid JSON: %v", err),
		})
		return
	}

	if req.BaseRoot == "" || req.FilePath == "" {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: "base_root and file_path are required",
		})
		return
	}

	projectConfig, exists := appConfig.RegisteredProjects[req.BaseRoot]
	if !exists {
		log.Printf("Project not registered: %s", req.BaseRoot)
		w.WriteHeader(http.StatusForbidden)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: fmt.Sprintf("Project not registered: %s", req.BaseRoot),
		})
		return
	}

	log.Printf("[%s] Downloading: %s", req.BaseRoot, req.FilePath)

	if err := downloadFile(projectConfig, req.FilePath); err != nil {
		log.Printf("[%s] Download failed: %v", req.BaseRoot, err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: fmt.Sprintf("Download failed: %v", err),
			File:    req.FilePath,
		})
		return
	}

	log.Printf("[%s] Successfully downloaded: %s", req.BaseRoot, req.FilePath)
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(UploadResponse{
		Success: true,
		Message: "File downloaded successfully",
		File:    req.FilePath,
	})
}

func handleDownloadFolder(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: "Only POST method is allowed",
		})
		return
	}

	var req FolderRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: fmt.Sprintf("Invalid JSON: %v", err),
		})
		return
	}

	if req.BaseRoot == "" || req.FolderPath == "" {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: "base_root and folder_path are required",
		})
		return
	}

	config := getConfig()
	projectConfig, exists := config.RegisteredProjects[req.BaseRoot]
	if !exists {
		log.Printf("Project not registered: %s", req.BaseRoot)
		w.WriteHeader(http.StatusForbidden)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: fmt.Sprintf("Project not registered: %s", req.BaseRoot),
		})
		return
	}

	log.Printf("[%s] Downloading folder: %s", req.BaseRoot, req.FolderPath)

	if err := downloadFolder(projectConfig, req.FolderPath); err != nil {
		log.Printf("[%s] Folder download failed: %v", req.BaseRoot, err)
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(UploadResponse{
			Success: false,
			Message: fmt.Sprintf("Folder download failed: %v", err),
		})
		return
	}

	log.Printf("[%s] Successfully downloaded folder: %s", req.BaseRoot, req.FolderPath)
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(UploadResponse{
		Success: true,
		Message: "Folder downloaded successfully",
		File:    req.FolderPath,
	})
}

func downloadFile(config ProjectConfig, localPath string) error {
	client, err := connectionPool.getConnection(config)
	if err != nil {
		return err
	}

	relativePath := strings.TrimPrefix(localPath, config.LocalBasePath)
	relativePath = strings.TrimPrefix(relativePath, "/")
	remotePath := filepath.Join(config.SFTPBasePath, relativePath)

	srcFile, err := client.Open(remotePath)
	if err != nil {
		return fmt.Errorf("failed to open remote file: %w", err)
	}
	defer srcFile.Close()

	localDir := filepath.Dir(localPath)
	if err := os.MkdirAll(localDir, 0755); err != nil {
		return fmt.Errorf("failed to create local directory: %w", err)
	}

	dstFile, err := os.Create(localPath)
	if err != nil {
		return fmt.Errorf("failed to create local file: %w", err)
	}
	defer dstFile.Close()

	// Use buffered copy for better performance
	buf := make([]byte, 32*1024) // 32KB buffer
	if _, err := io.CopyBuffer(dstFile, srcFile, buf); err != nil {
		return fmt.Errorf("failed to download file: %w", err)
	}

	return nil
}

func downloadFolder(config ProjectConfig, localFolderPath string) error {
	client, err := connectionPool.getConnection(config)
	if err != nil {
		return err
	}

	relativePath := strings.TrimPrefix(localFolderPath, config.LocalBasePath)
	relativePath = strings.TrimPrefix(relativePath, "/")
	remoteFolderPath := filepath.Join(config.SFTPBasePath, relativePath)

	// Collect all files first
	var filesToDownload []string
	walker := client.Walk(remoteFolderPath)
	for walker.Step() {
		if err := walker.Err(); err != nil {
			log.Printf("Error walking remote folder: %v", err)
			continue
		}

		remotePath := walker.Path()
		relPath := strings.TrimPrefix(remotePath, config.SFTPBasePath)
		relPath = strings.TrimPrefix(relPath, "/")
		localPath := filepath.Join(config.LocalBasePath, relPath)

		if walker.Stat().IsDir() {
			if err := os.MkdirAll(localPath, 0755); err != nil {
				log.Printf("Failed to create directory %s: %v", localPath, err)
			}
		} else {
			filesToDownload = append(filesToDownload, localPath)
		}
	}

	// Download files in parallel with limited concurrency
	const maxConcurrency = 10
	sem := make(chan struct{}, maxConcurrency)
	var wg sync.WaitGroup

	for _, localPath := range filesToDownload {
		wg.Add(1)
		go func(lp string) {
			defer wg.Done()
			sem <- struct{}{}        // acquire
			defer func() { <-sem }() // release

			if err := downloadFile(config, lp); err != nil {
				log.Printf("Failed to download %s: %v", lp, err)
			}
		}(localPath)
	}

	wg.Wait()
	return nil
}
