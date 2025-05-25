# AMH2W - All My Homies ~~Hate~~ Handle Windows

A minimal but expressive PowerShell utility library that lets you write commands like a sentence and treat errors like data.

---

## ⚡ What It Does

AMH2W is not just a meme—it's a shell DSL where every word maps to a namespace or action:

```powershell
all my homies hate json tree "https://api.example.com/data"
```
That line? It parses JSON from a URL and prints it as a tree.

Need system info?

```powershell
all my homies hate windows wineofetch
```

Install a CLI tool?

```powershell
all my homies install chocolatey
```

Launch a browser?

```powershell
all my browser google.com
```

It's declarative, it's composable, it's readable, and it's built for scripting and debugging real-world Windows environments.

---


## 🎯 Features

- **Natural command chaining** via nested namespaces like `all my homies`
- **Result pattern** for `Ok`/`Err`-based error handling
- **Unwrapping** of results for easy use
- **Built in pipeline** for easy chaining of commands in a safe way
- **Built-in logging system** with severity levels
- **Modular structure** for clean extensions
- **Pipeline-aware execution** like `result | map { it }`
---

## 📦 Installation

### Pre-requisites

- PowerShell 5.1+
- Works better with PowerShell Core (pwsh)
- .NET 4.0+
- Windows 7+
- Administrator privileges

Before installing make sure you have the appropriate execution policy set:

```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
```

### Download and install the latest release:
```powershell
iex ((New-Object System.Net.WebClient).DownloadString('https://github.com/guinetik/amh2w/releases/latest/download/amh2w.ps1'))
```

Or if you want a single command:
```powershell
pwsh -NoProfile -Command "Set-ExecutionPolicy Bypass -Scope CurrentUser -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://github.com/guinetik/amh2w/releases/latest/download/amh2w.ps1'))"
```

(Replace `pwsh` with `powershell` if you are using Windows PowerShell)

### Locally Install:

```powershell
git clone https://github.com/guinetik/amh2w.git
cd amh2w
./install.ps1
. $PROFILE
```
---

## 🚀 Example Usage

```powershell
all                                 # Root entrypoint. `all` is Math and Everything in between.
all my                              # User-level context
all my clock start                  # Start a clock
all my clock stop                   # Stop a clock
all my uptime                       # Show system uptime
all my files                        # Open file explorer
all my shell                        # Open an interactive shell prompt
all my browser google.com           # Launch the default browser to a URL

all my homies                       # Utilities namespace
all my homies fetch <url>           # Fetch JSON data from URL
all my homies install chocolat      # Install Chocolatey

all my homies hate windows          # Run Windows-related cleanup
all my homies hate windows version  # Show Windows version info
```
---

## 🧮 Mathematical & Programming Utilities

AMH2W includes various mathematical and programming utilities in the root `all` namespace:

### 🔢 Number Theory & Sequences
```powershell
all factor 123456                   # Prime factorization of a number
all fibo 10                         # Generate first 10 Fibonacci numbers
all primes 100                      # Generate prime numbers up to 100
all pi 1000                         # Calculate π to specified precision
all numbers                         # Number conversion utilities
```

### 🎯 Programming Challenges
```powershell
all fizbuss 100                     # Classic FizzBuzz implementation (1-100)
all anagrams "hello"                # Generate all anagrams of a word
```

### 📊 Visual & Animation
```powershell
all sine                            # Animated sine wave in terminal
all fractals                        # Animated Julia set fractal display
```

### 📰 News & Information
```powershell
all news brazil                     # Latest news from Brazil (G1)
all news world                      # World news from Yahoo
all weather                         # Current weather information
all time                            # Time utilities and world clocks
```

Features:
- **Mathematical Functions**: Prime factorization, Fibonacci sequences, prime generation
- **Programming Exercises**: FizzBuzz, anagram generation, number theory
- **Visual Effects**: Animated sine waves and fractal displays
- **Information Services**: News feeds, weather, and time utilities

---

## 🧑 Personal Tools

AMH2W provides personal productivity and system management tools:

### 📎 Clipboard Management

```powershell
# Copy text to clipboard
all my clip copi "Hello World"
# Paste from clipboard
all my clip paste       # This will return a value
# To output the value to the console, do:
(all my clip paste).value
# View clipboard history
all my clip clipboard
# Clear clipboard history
all my clip clipboard clear
# Get specific item from history (index 2)
# This will move the item to your current window's clipboard
all my clip clipboard get 2
# Count items in history
all my clip clipboard count
# Pipeline example
"Text to copy" | all my clip copy
```

#### Features:
- Copy text to clipboard
- Paste from clipboard
- Manage clipboard history

### ⏱️ Time Management
```powershell
all my clock start               # Start a timer
all my clock stop                # Stop the timer and show elapsed time
all my clock status              # Check timer status
all my uptime                    # Show system uptime
```

### 💻 Terminal & Shell
```powershell
all my terminal "ls"             # Open command in new terminal
all my terminal "ls" -Admin      # Open command as admin
all my terminal "ls" "My Title"  # Open with custom title
all my shell                     # Open interactive shell
```

### 📍 Location & System
```powershell
all my location                  # Show current location from IP
all my files                     # Open file explorer
all my browser google.com        # Open URL in default browser
all my npp file.txt              # Open file in Notepad++
all my edit file.txt             # Open file in default editor
```

### 📊 System Information
```powershell
all my psconfig                 # Show PowerShell configuration
all my historyexport            # Export command history
all my apps                     # List installed applications
```

### 📂 Folder Navigation
```powershell
all my folders downloads        # Navigate to Downloads folder
all my folders docs             # Navigate to Documents folder
all my folders desktop          # Navigate to Desktop folder
all my folders ssh              # Navigate to SSH config folder
```

---

## 🖥️ Computer Tools

### ⚙️ Hardware Management

AMH2W provides detailed hardware information and management tools:

#### 🔍 System Information
```powershell
all my hardware scanpc            # Show system information
all my hardware bluetooth         # Configure Bluetooth devices
all my hardware usbs              # Configure USB devices

```


#### 🧠 CPU & Memory
```powershell
all my hardware cpu               # Show CPU information and temperature
all my hardware ram               # Display RAM information
all my hardware power             # Show power/battery status
```

#### 🎮 Hardware Profiling & Stress Testing
```powershell
all my hardware profiler         # Run comprehensive hardware stress tests
```

Features:
- **RAM Test**:
  - Uses TestLimit for memory stress testing
  - Runs configurable test cycles
  - Measures memory usage and cleanup
  - Provides detailed metrics per cycle

- **CPU Test**:
  - Multi-core stress testing
  - Matrix multiplication and prime number calculations
  - Temperature monitoring
  - Performance scoring and thermal analysis

- **GPU Test**:
  - FurMark-based stress testing
  - VRAM stress test (configurable size)
  - Full benchmark with FPS analysis
  - Temperature and stability monitoring
  - Detailed performance metrics and recommendations

#### 💾 Storage & Devices
```powershell
all my hardware power             # Display power report
all my hardware storage           # List storage devices
all my hardware smart             # Display SMART status
all my hardware gpu               # Display GPU information
all my hardware motherboard       # Display motherboard details
all my hardware bios              # Display BIOS information
all my hardware bluetooth         # Display Bluetooth devices
```

---

## 🌐 Network Management

AMH2W provides comprehensive network diagnostic and management tools:

### 🔍 Network Diagnostics
```powershell
all my network ip all              # Show all network information
all my network ip interfaces       # List network interfaces
all my network ip neighbors        # Show network neighbors
all my network ip routes           # Display routing table
all my network ip shares           # List shared folders
```

### 📡 Network Tools
```powershell
all my network ping google.com     # Ping a host
all my network portscan 80         # Scan a port
all my network wifip               # Show saved WiFi passwords
all my network dns                 # Show DNS configuration
all my network firewall            # Manage Windows Firewall
all my network internet            # Check internet connectivity
```

### 🔧 Network Configuration
```powershell
all my network dns flush          # Flush DNS cache
all my network dns set 1.1.1.1    # Set DNS server
```

## ✂️🔎🔨🔮🔫🔥🔪 Everyday utilities

### 📦 Package & System Installation

AMH2W provides tools for installing and configuring package managers and system installations:

```powershell
all my homies install chocolatey    # Install Chocolatey package manager
all my homies install scoop         # Install Scoop package manager
all my config updatepackages        # Update all installed packages
```

### 🐧 Linux & Development

```powershell
all my config myshell            # Install PowerShell Core + Plugins from the Gallery. Configure Profile.
all my config gitconfig          # Configure Git username and email, sets up aliases and default configs.
all my config hyperv             # Enable Hyper-V
all my config wslconfig          # Configure WSL
all my homies install linux      # Install WSL with Ubuntu
all my homies install distro     # Install specific WSL distro
all my homies install nvchad     # Install NvChad (Neovim config)
all my homies install jabba      # Install Java version manager
```

#### 🐧 WSL Management

AMH2W provides comprehensive tools for managing Windows Subsystem for Linux (WSL) distros:

```powershell
all my config wslconfig location [Distro]           # Show the VHDX path for a distro
all my config wslconfig install [Distro]            # Install a WSL distro (default: Ubuntu)
all my config wslconfig backup [Distro] <Path>      # Backup a distro to a .tar file
all my config wslconfig resize [Distro] <Size>      # Resize a distro's virtual disk (e.g., 50GB)
all my config wslconfig export [Distro] <Path>      # Export a distro to a .tar file
all my config wslconfig import <Name> <Path> <Tar>  # Import a new distro from a .tar file
all my config wslconfig list                        # List installed and available distros
all my config wslconfig enable                      # Enable WSL and required features
```

Features:
- Install, backup, export, import, and resize WSL distros
- List installed and available distros
- Enable WSL and VirtualMachinePlatform features
- Friendly error handling and status messages
- Very useful for backup and restore of WSL distros for when you format your system for example.

### 🔤 Nerd Fonts
```powershell
# List all available Nerd Fonts
all my homies install nerdfonts list

# Search for specific fonts
all my homies install nerdfonts search "Cascadia"

# Install a specific font (requires admin privileges)
all my homies install nerdfonts install CascadiaCode

# Set installed Nerd Font in Windows Terminal
all my homies install nerdfonts use CascadiaCode

# View release information
all my homies install nerdfonts info

# Get info about a specific font
all my homies install nerdfonts info "CascadiaCode"

# Force refresh cached data
all my homies install nerdfonts list -ForceRefresh
```

Features:
- List all available Nerd Fonts from the latest release
- Search for fonts by name
- Install fonts with automatic elevation prompt
- Set installed fonts in Windows Terminal (automatically backs up settings)
- View detailed information about fonts and releases
- 24-hour caching of release data for performance
- Automatic cleanup of temporary files after installation

---

### 🛠️ Additional Utilities

AMH2W provides additional utility tools for everyday tasks:

#### 📱 QR Code Generator
```powershell
# Generate QR code for text
all my homies qrcode "Hello World"

# Generate QR code with custom settings
all my homies qrcode "https://example.com" "800x800" "my_qr" "png"
```

Features:
- Generates QR codes from any text or URL
- Customizable image size and format
- Saves to Pictures folder automatically
- Shows ASCII preview in terminal
- Supports multiple output formats (JPG, PNG, etc.)

#### 🌍 Translation Service
```powershell
# Translate to all supported languages
all my homies translate "Hello World"

# Translate to specific language
all my homies translate "Hello World" "es"  # Spanish
all my homies translate "Hello World" "fr"  # French
all my homies translate "Hello World" "pt"  # Portuguese
```

Features:
- Supports 12+ languages with flag emojis
- Uses Google Translate API
- Batch translation to multiple languages
- Interactive table display of results
- Automatic language detection

#### 📦 Bootstrap Installer
```powershell
# Install packages from JSON configuration
all my homies bootstrap

# Install packages without prompts
all my homies bootstrap -Yolo

# Use custom package file
all my homies bootstrap "custom-packages.json"
```

Features:
- Installs software packages from JSON configuration
- Interactive or automated installation modes
- Requires Chocolatey package manager
- Categorized package organization
- Progress tracking and error handling

### 🖼️ Image Conversion

Convert images between formats and resize them with ease.

#### Usage

```powershell
# Basic conversion: input.png to jpg format
all my homies convert img input.png jpg

# Resize image to specific width (maintaining aspect ratio)
all my homies convert img photo.jpg png 800 auto

# Resize image to specific dimensions
all my homies convert img input.bmp png output.png 1024 768

# Convert with quality setting (for jpg/jpeg)
all my homies convert img input.tiff jpg -Quality 90

# Convert all png files in a folder to jpg
all my homies convert img *.png jpg

# Convert all images in a folder recursively
all my homies convert img folder/ jpg -Recursive
```

#### Parameters

- `InputFile` - Source image or pattern (required)
- `Format` - Target format (jpg, png, etc.) (required)
- `Output` - Output filename (optional)
- `Width` - Target width in pixels or "auto" (default: "auto")
- `Height` - Target height in pixels or "auto" (default: "auto")
- `-Quality` - JPEG quality (1-100)
- `-PreserveMetadata` - Keep image metadata during conversion
- `-Recursive` - Process all subfolders when converting directories

#### Features

- Auto-detects and uses ImageMagick, FFmpeg or System.Drawing
- Batch conversion with wildcards and directory processing
- Auto-generated output filenames
- Preserves aspect ratio with "auto" dimension
- Preserves or strips metadata
- Supports all common image formats

#### Technical Notes

- Uses .NET System.Drawing for image processing
- Automatically calculates height to maintain aspect ratio
- Converts to grayscale by averaging RGB values
- Maps brightness values to ASCII characters

### 🔐 Cryptographic Tools

AMH2W provides cryptographic and security utilities:

### 🗝️ Hashing & Encryption
```powershell
all my homies crypto hash "text" md5      # Generate MD5 hash
all my homies crypto hash "text" sha256   # Generate SHA-256 hash
all my homies crypto rot13 in "text"      # ROT13 encode text
all my homies crypto rot13 out "text"     # ROT13 decode text
all my homies crypto sshkeygen            # Generate SSH key pair
```

### 💰 Crypto Rates
```powershell
all my homies crypto rates               # Show cryptocurrency rates
```

Features:
- Supports multiple hash algorithms (MD5, SHA1, SHA256, SHA512)
- ROT13 encoding/decoding for text
- Real-time cryptocurrency price tracking
- SSH key pair generation

### 🔏 AES Encryption
```powershell
# Text encryption/decryption
all my homies crypto aes encrypt "text" -Password (Read-Host -AsSecureString)  # Encrypt text
all my homies crypto aes decrypt "encrypted" -Password (Read-Host -AsSecureString)  # Decrypt text

# File encryption/decryption
all my homies crypto aes encryptfile "file.txt" -Password (Read-Host -AsSecureString)  # Encrypt file
all my homies crypto aes decryptfile "file.txt_encrypted" -Password (Read-Host -AsSecureString)  # Decrypt file
```

Features:
- AES-256 encryption with CBC mode
- Secure password handling using SecureString
- File encryption with progress tracking
- Automatic IV generation and management
- Base64 encoding for text encryption
- Preserves file extensions and metadata

---

## 🔧 System Utilities

AMH2W gives you system utilities to unpleasant stuff under the `hate` namespace; because some things are just too annoying to deal with sober.

### 🌐 HTTP Client
```powershell
# Basic requests
all my homies hate fetch "https://api.example.com"           # GET request
all my homies hate fetch "https://api.example.com" -Method POST -Body '{"data":"value"}'  # POST with JSON
all my homies hate fetch "https://example.com/file.zip" -OutFile "download.zip"  # Download file

# Advanced options
all my homies hate fetch "https://api.example.com" -Headers "api-key=1234"  # Custom headers
all my homies hate fetch "https://api.example.com" -Params "page=1,limit=10"  # Query parameters
all my homies hate fetch "https://api.example.com" -Timeout 60  # Custom timeout
all my homies hate fetch "https://example.com/file.zip" -OutFile "download.zip" -UseBits  # Use BITS for download
```

### 📥 File Download Utility
```powershell
# Basic download
all my homies download "https://example.com/file.zip"

# Download with a custom filename
all my homies download "https://example.com/file.zip" -OutFile "myfile.zip"

# Use BITS for better performance (recommended for large files)
all my homies download "https://example.com/largefile.iso" -UseBits

# Show progress while downloading
all my homies download "https://example.com/file.zip" -ShowProgress

# Resume interrupted downloads (with BITS)
all my homies download "https://example.com/largefile.iso" -UseBits -Resume
```

Features:
- Optimized file downloads with BITS support
- Automatic filename detection from URL
- Progress display during downloads
- Resume capability for interrupted downloads
- Fallback to standard download if BITS fails
- Detailed download statistics and speed reporting

### 📁 FTP Client
```powershell
# Connect to an FTP server (prompts for password if not provided)
all my homies hate iftp connect ftp.example.com username

# List remote directory (defaults to root)
all my homies hate iftp ls /path/to/dir

# Download remote file to local path
all my homies hate iftp download /remote/file.txt local.txt

# Upload local file to remote path
all my homies hate iftp upload local.txt /remote/target.txt

# Disconnect from active session
all my homies hate iftp disconnect

# Test connection to the current FTP server
all my homies hate iftp test
```

### 📁 Path & Environment
```powershell
# PATH management
all my homies hate path addpath     # Add directory to PATH
all my homies hate path removepath  # Remove directory from PATH
all my homies hate path printpath   # Show current PATH entries

# Environment variables
all my homies hate path addenv      # Add environment variable
all my homies hate path removeenv   # Remove environment variable
all my homies hate path printenv    # Show environment variables
```

Features:
- Full HTTP client with support for all methods
- JSON request/response handling
- File download with progress tracking
- PATH management for both user and system
- Environment variable management
- Interactive prompts for sensitive operations

---

### 📊 JSON Power Tools
```powershell
all my homies hate json view data.json
all my homies hate json tree "https://jsonplaceholder.typicode.com/users"
all my homies hate json table "https://jsonplaceholder.typicode.com/users"
all my homies hate json chart test.json month value
all my homies hate json highlight '{"name":"John"}'
```

### 📦 File Compression & Extraction
```powershell
# Compress files and folders
all my homies hate zipping zip "source.txt" "archive.zip"  # Compress to ZIP
all my homies hate zipping zip "folder" "archive.zip"      # Compress folder to ZIP
all my homies hate zipping zip "file.txt" "archive.gz"     # Compress to GZIP
all my homies hate zipping zip "folder" "archive.tar.gz"   # Compress to TAR.GZ
all my homies hate zipping zip "folder" "archive.rar"      # Compress to RAR (requires WinRAR)

# Extract archives
all my homies hate zipping unzip "archive.zip" "output"    # Extract ZIP
all my homies hate zipping unzip "archive.gz" "output"     # Extract GZIP
all my homies hate zipping unzip "archive.tar.gz" "output" # Extract TAR.GZ
all my homies hate zipping unzip "archive.rar" "output"    # Extract RAR
```

Features:
- Supports multiple formats: ZIP, GZIP, TAR.GZ, RAR
- Automatically detects and uses available tools (7-Zip, WinRAR, tar)
- Handles both files and directories
- Smart destination path generation
- Progress tracking and error handling
- Fallback to built-in PowerShell commands when needed


## 🪟 Windows Management Features

AMH2W provides powerful tools for managing and optimizing Windows systems:

### 🔧 System Optimization
```powershell
all my homies hate windows optimize dev         # Apply all optimizations for development
all my homies hate windows optimize performance # Optimize power and visual settings
all my homies hate windows optimize services    # Optimize Windows services
all my homies hate windows optimize memory      # Optimize memory and page file
all my homies hate windows optimize startup     # Manage startup programs
all my homies hate windows optimize cleanup     # Clean temporary files
all my homies hate windows optimize cache       # Clean cache, temporary files and logs
```

### Windows General Utilities
```powershell
all my homies hate windows telnetc enable      # Enable Telnet Client
all my homies hate windows telnetc disable     # Disable Telnet Client
all my homies hate windows hibernation         # Trigger hibernation
all my homies hate windows godmode             # Create God Mode folder on desktop
```

#### 🛰️ Telnet Client Management

Easily enable, disable, or check the status of the Windows Telnet Client feature:

```powershell
all my homies hate windows telnetc enable   # Enables the Windows Telnet Client
all my homies hate windows telnetc disable  # Disables the Windows Telnet Client
all my homies hate windows telnetc status   # Shows if the Telnet Client is enabled or disabled
```

Features:
- Elevates automatically if not run as administrator
- Enables or disables the Windows Telnet Client feature
- Checks and displays the current status
- Friendly output and error handling

### 🔒 Privacy & Security
```powershell
all my homies hate windows privacy              # Apply privacy hardening
all my homies hate windows telemetry            # Disable telemetry and tracking
all my homies hate windows debloater            # Install debloater from https://github.com/Raphire/Win11Debloat
```

Other stuff like disabling Cortana, disabling one drive and etc, you can use the debloater command to do it because the code for that is too much for this library to handle so we delegate that to the master powershell coders that maintain the debloater project.

### 💾 System Configuration
```powershell
all my homies hate windows pagefile             # Configure virtual memory/pagefile
all my homies hate windows version              # Show Windows version info neofetch style
```

Key features include:
- **Performance Optimization**: Power plans, visual effects, and system services
- **Privacy Hardening**: Disable telemetry, advertising ID, and data collection
- **System Cleanup**: Temporary files, disk cleanup, and startup management
- **Memory Management**: Pagefile configuration and memory optimization
- **Service Control**: Manage Windows services for optimal performance


## 😹 Fun Stuff

### 🖼️ ASCII Art Converter

Convert any image into ASCII art that displays in your terminal!

#### Usage

```powershell
# Basic usage
all my homies luv ascii "path/to/image.jpg"

# Custom width
all my homies luv ascii "./logo.png" -Width 120

# Inverted colors (dark background)
all my homies luv ascii "./photo.jpg" -Invert

# Get help
all my homies luv ascii -Help
```

#### Parameters

- `ImagePath` - Path to the image file (supports jpg, png, gif, bmp)
- `-Width` - Width of ASCII output in characters (default: 80)
- `-Invert` - Invert the brightness mapping (useful for dark terminals)
- `-Help` - Show help information

#### Features

- Supports common image formats (JPG, PNG, GIF, BMP)
- Maintains aspect ratio automatically
- Adjustable output width
- Invertible brightness mapping
- Uses 10 levels of ASCII characters for detail

#### Character Palette

The converter uses these characters from dark to light:
```
' ', '.', ':', '-', '=', '+', '*', '#', '%', '@'
```

When using `-Invert`, this order is reversed.

#### Examples

```powershell
# Convert a photo to ASCII art
all my homies luv ascii "C:\Users\You\Pictures\photo.jpg"

# Create a large ASCII version for a presentation
all my homies luv ascii "./company-logo.png" -Width 150

# Invert for dark terminal backgrounds
all my homies luv ascii "./icon.gif" -Width 60 -Invert
```

#### Technical Notes

- Uses .NET System.Drawing for image processing
- Automatically calculates height to maintain aspect ratio
- Converts to grayscale by averaging RGB values
- Maps brightness values to ASCII characters

### 🎬 Terminal Animations

#### The Matrix Effect
```powershell
# Start the classic Matrix digital rain animation
all my homies luv thematrix
```

Features:
- Full-screen Matrix-style digital rain effect
- Green text on black background
- Infinite loop animation (press Ctrl+C to stop)
- Uses the word "MATRIX" as the falling characters
- Adapts to your terminal window size

### 🛰️ International Space Station Tracker

Track the ISS in real-time with detailed information and crew data:

#### Usage
```powershell
# Get current ISS position
all my homies luv iss position

# Track ISS in real-time with updates every 5 seconds
all my homies luv iss track

# Get current crew information
all my homies luv iss crew

# Get upcoming ISS passes over your location
all my homies luv iss pass

# Show ISS on a world map
all my homies luv iss map

# Get help
all my homies luv iss help
```

#### Features
- **Real-time Position**: Live latitude/longitude coordinates
- **Location Names**: Reverse geocoding to show what country/region the ISS is over
- **Crew Information**: Current astronauts aboard the ISS
- **Pass Predictions**: When the ISS will be visible from your location
- **Visual Tracking**: ASCII world map showing ISS position relative to your location
- **Caching**: Smart caching for offline functionality
- **Auto-location**: Uses your IP to determine your location automatically

#### Examples
```powershell
# Basic position check
all my homies luv iss position

# Track with custom update interval (10 seconds)
all my homies luv iss track -UpdateInterval 10

# Use specific location coordinates
all my homies luv iss track -Location "40.7128,-74.0060"  # New York City
```

--- 

## 🧠 Conceptual Model: Commands as Grammar

AMH2W was born out of two personal needs:

1. **To organize the chaos** — Like many devs, I had a mess of random PowerShell scripts strewn across projects, downloads folders, and forgotten Notepad++ tabs. AMH2W gives them a home — a clean, reusable hierarchy that makes scripting feel good.
2. **To rebel** — Against the **tyranny** of `Get-Verbosity`, `Set-Tedium`, `Invoke-Overkill`. PowerShell's default grammar is a bureaucratic *Orwellian* nightmare. AMH2W throws that out and replaces it with something human: `all my homies hate windows`. Minimal, memetic, memorable.

Yes, it's ironic. Yes, it's inspired by internet culture. But also — it works.


Commands are structured like sentences. Each word is a layer of meaning:

- **`all`** — The root of everything. This bootstraps the command grammar and resolves modules.
- **`my`** — User-focused commands: uptime, shell access, browser launching.
- **`homies`** — Extended utility layer. These are your tools, integrations, and contacts.
- **`hate`** — The "adapter" that simplifies complexity: it makes things like JSON parsing or Windows telemetry easy to talk to.
- **`windows`** — Everything Windows-related: telemetry, cleanup, versioning.
- **`json`** — A power-tool for working with structured data interactively.

You get a grammar tree like:

```powershell
all my homies hate json tree
```
Which breaks down into:
- `all` — core
- `my` — personal context
- `homies` — utility toolkit
- `hate` — adapter for simplified interaction
- `json` — specific module (with `view`, `tree`, `table`, etc.)

This isn't just clever naming—it makes discoverability and chaining commands intuitive.
The point is to create a grammar-like syntax that is easy to remember and easy to use.

---

## 🧱 Architecture

- `core/`: Logging, result types, parser, pipeline support
- `all/`: All commands start here. Math and weather functions.
- `all/my/`: User-centric tools (`clock`, `uptime`, `files`, `shell`, etc)
- `all/my/homies/`: Utilities, downloaders, nested namespaces
- `hate/`: Verbosity-simplifying adapter (e.g. `json`, `windows`)
- `install/`: Installers like `choco`

---

## 🧠 Writing Your Own Commands

You define a `.ps1` in the appropriate namespace folder (like `all/my/homies/hello.ps1`) and export a function matching its path. Your function should:

- Return `Ok` or `Err` objects
- Use `Log-Info`, `Log-Warning`, or `Log-Error`
- Respect pipeline input if possible

> 🚧 Work-in-progress CLI scaffolder:

```powershell
all -Create "say hello" "echo 'Hello World'"
```

---

## ❌ Exception-Free Zone

No `throw`. Only structured `Result` objects.

```powershell
return Ok -Value "done"
return Err "failed"
return Err -Message "optional warning" -Optional $true
```

---

## 🧾 License

GNU. Copy it, fork it, customize it.

