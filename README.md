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
all my uptime
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

## 🧠 Conceptual Model: Namespaces as Grammar

AMH2W was born out of two personal needs:

1. **To organize the chaos** — Like many devs, I had a mess of random PowerShell scripts strewn across projects, downloads folders, and forgotten Notepad++ tabs. AMH2W gives them a home — a clean, reusable hierarchy that makes scripting feel good.
2. **To rebel** — Against the tyranny of `Get-Verbosity`, `Set-Tedium`, `Invoke-Overkill`. PowerShell's default grammar is a bureaucratic fever dream. AMH2W throws that out and replaces it with something human: `all my homies hate windows`. Minimal, memetic, memorable.

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

## 🎯 Features

- **Natural command chaining** via nested namespaces like `all my homies`
- **Result pattern** for `Ok`/`Err`-based error handling
- **Built-in logging system** with severity levels
- **Modular structure** for clean extensions
- **Pipeline-aware execution** like `result | map { it }`
---

## 📦 Installation

```powershell
git clone https://github.com/yourusername/AMH2W.git
cd AMH2W
./install.ps1
. $PROFILE
```

---

## 🚀 Example Usage

```powershell
all                                 # Root entrypoint. Has currency and weather functions. Has Math functions because math is 'all'.
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

## 🧑 Personal Tools

AMH2W provides personal productivity and system management tools:

### ⏱️ Time Management
```powershell
all my clock start               # Start a timer
all my clock stop                # Stop the timer and show elapsed time
all my clock status              # Check timer status
all my uptime                    # Show system uptime
```

### 🖥️ Terminal & Shell
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

## 💻 Hardware Management

AMH2W provides detailed hardware information and management tools:

### 🧠 CPU & Memory
```powershell
all my hardware cpu               # Show CPU information and temperature
all my hardware ram               # Display RAM information
all my hardware power             # Show power/battery status
```

### 💾 Storage & Devices
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

---


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
```

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

---



## 📦 Package & System Installation

AMH2W provides tools for managing software packages and system installations:

### 📦 Package Managers
```powershell
all my homies install chocolatey  # Install Chocolatey package manager
all my homies install scoop      # Install Scoop package manager
```

### 🐧 Linux & Development
```powershell
all my homies install linux      # Install WSL with Ubuntu
all my homies install distro     # Install specific WSL distro
all my homies install nvchad     # Install NvChad (Neovim config)
all my homies install jabba      # Install Java version manager
```

---

## 🔐 Cryptographic Tools

AMH2W provides cryptographic and security utilities:

### 🔒 Hashing & Encryption
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

### 🔐 AES Encryption
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

AMH2W gives you system utilities under the `hate` namespace; because some things are just too annoying to deal with sober.

### 📊 JSON Power Tools
```powershell
all my homies hate json view data.json
all my homies hate json tree "https://jsonplaceholder.typicode.com/users"
all my homies hate json table "https://jsonplaceholder.typicode.com/users"
all my homies hate json chart test.json month value
all my homies hate json highlight '{"name":"John"}'
```

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
return Err -Msg "optional warning" -Optional $true
```

---

## 🧾 License

GNU. Copy it, fork it, customize it.

