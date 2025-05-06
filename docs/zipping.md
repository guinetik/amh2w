# Zipping Module Documentation

The `zipping` module provides a unified interface for file compression and decompression operations, supporting multiple formats and compression tools.

## Features

- Supports multiple compression formats: ZIP, GZIP, TAR.GZ, and RAR
- Auto-detects available compression tools (7-Zip, WinRAR, Microsoft Tar)
- Falls back to Windows built-in commands when third-party tools are unavailable
- Handles both file and directory compression
- Automatic format detection based on file extensions

## Usage

### Basic Commands

```powershell
# Compress a file or directory (default to ZIP)
all my homies hate zipping zip "C:\path\to\source"

# Compress with specific format
all my homies hate zipping zip "C:\path\to\source" "output.tar.gz" "tar.gz"

# Extract an archive
all my homies hate zipping unzip "archive.zip"

# Extract to specific directory
all my homies hate zipping unzip "archive.zip" "C:\destination"
```

### Examples

```powershell
# Compress a folder to ZIP
all my homies hate zipping zip "C:\myproject"
# Creates: C:\myproject.zip

# Compress a file with GZIP
all my homies hate zipping zip "data.json" "data.json.gz" "gzip"

# Create a TAR.GZ archive
all my homies hate zipping zip "C:\myproject" "backup.tar.gz" "tar.gz"

# Extract a RAR file
all my homies hate zipping unzip "archive.rar" "C:\extracted"
```

## Supported Formats

1. **ZIP**
   - Uses 7-Zip if available
   - Falls back to PowerShell's `Compress-Archive` cmdlet
   - Supports both files and directories

2. **GZIP**
   - Uses 7-Zip or Microsoft's tar command
   - Only supports single file compression
   - Commonly used for log files and data compression

3. **TAR.GZ**
   - Uses 7-Zip or Microsoft's tar command  
   - Supports directory compression
   - Creates a TAR archive first, then compresses with GZIP

4. **RAR**
   - Requires WinRAR for creation
   - 7-Zip can extract RAR files
   - Supports both files and directories

## Tool Priority

The module automatically detects and prioritizes compression tools:

1. **7-Zip**: Preferred for most operations
2. **WinRAR**: Required for creating RAR archives
3. **Microsoft Tar**: Used as fallback for TAR.GZ and GZIP
4. **PowerShell Built-ins**: Last resort for ZIP operations

## Error Handling

The module follows AMH2W's Result pattern:
- Returns `Ok` objects on success with operation details
- Returns `Err` objects on failure with descriptive error messages
- All errors are logged with proper context

## Installation Requirements

- PowerShell 5.1 or later
- Optional: 7-Zip for enhanced functionality
- Optional: WinRAR for RAR creation
- Windows 10/11 includes the tar command by default

## Technical Details

### File Detection
- Automatically detects if the source is a file or directory
- Determines compression format from file extensions
- Allows format override via parameter

### Default Destinations
- If no destination is specified, creates archive in the same directory as source
- Automatically adds appropriate file extensions
- Preserves original filename as base for archive name

### Performance Considerations
- 7-Zip generally offers better compression ratios;
- PowerShell's built-in compression is slow and less efficient but works on all systems;
- TAR.GZ operations may be slower due to two-step process.

## Limitations

1. GZIP cannot compress directories directly (use TAR.GZ instead)
2. RAR creation requires WinRAR installation
3. Some advanced compression options are not exposed (compression levels, etc.)
4. Password protection not currently supported

## Future Enhancements

Potential improvements for future versions:
- Password protection support
- Compression level selection
- Multi-part archive support
- Progress reporting for large files
- Support for additional formats (7z, bz2, xz)