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

### 📊 JSON Power Tools
```powershell
all my homies hate json view data.json
all my homies hate json tree "https://jsonplaceholder.typicode.com/users"
all my homies hate json table "https://jsonplaceholder.typicode.com/users"
all my homies hate json chart test.json month value
all my homies hate json highlight '{"name":"John"}'
```

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

