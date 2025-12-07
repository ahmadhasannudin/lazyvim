# SFTP Listener Performance Improvements

## Problem
Your original implementation was taking **2 minutes** to upload a folder while vscode-sftp took only **2.5 seconds** - approximately **48x slower**.

## Root Cause
The main performance bottleneck was creating a **new SSH/SFTP connection for every single file**:
- Each file upload/download opened a new TCP connection
- SSH handshake and authentication happened for every file
- No connection reuse whatsoever

## Solution Implemented

### 1. **Connection Pooling** (Biggest Impact)
- Added `ConnectionPool` that reuses SSH/SFTP connections
- Connections are identified by host/user/port combination
- Automatic health checks detect dead connections
- Idle connections are cleaned up after 5 minutes

### 2. **Parallel File Transfers**
- Changed from sequential to concurrent uploads/downloads
- Uses goroutines with a semaphore (10 concurrent transfers)
- All files in a folder are uploaded in parallel

### 3. **Optimized I/O**
- Added 32KB buffer for file transfers using `io.CopyBuffer`
- More efficient than the default `ReadFrom` method

### 4. **Better Error Handling**
- Folder uploads continue even if some files fail
- Reports which files succeeded/failed

## Performance Gains Expected
Based on vscode-sftp's approach, you should see:
- **10-50x faster** folder uploads (from 2 minutes → 3-10 seconds)
- Single file uploads remain fast
- Reduced network overhead
- Lower CPU usage from fewer SSH handshakes

## Key Changes in Code

**Before**: Every `uploadFile()` call created new connection:
```go
conn, err := ssh.Dial("tcp", ...)  // NEW CONNECTION EVERY TIME
client, err := sftp.NewClient(conn)
// ... upload ...
conn.Close()
```

**After**: Reuse connections from pool:
```go
client, err := connectionPool.getConnection(config)  // REUSED
// ... upload ...
// Connection stays open for next file
```

**Before**: Sequential folder upload:
```go
filepath.Walk(folder, func(path string, ...) {
    uploadFile(path)  // ONE AT A TIME
})
```

**After**: Parallel folder upload:
```go
// Collect files first
for _, path := range filesToUpload {
    go func(p string) {  // PARALLEL
        uploadFile(p)
    }(path)
}
wg.Wait()
```

## Testing
Restart your sftp-listener service and test with the same folder that took 2 minutes before.

## Configuration
The concurrency level is set to 10 parallel transfers. You can adjust this in:
- `handleUploadFolder()`: `const maxConcurrency = 10`
- `downloadFolder()`: `const maxConcurrency = 10`

Increase for faster uploads (more network/CPU), decrease for slower connections.
