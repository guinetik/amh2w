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
all my homies install choco
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

Yes, it’s ironic. Yes, it’s inspired by internet culture. But also — it works.


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

This isn’t just clever naming—it makes discoverability and chaining commands intuitive.

---

## 🎯 Features

- **Natural command chaining** via nested namespaces like `all my homies`
- **Result pattern** for `Ok`/`Err`-based error handling
- **Built-in logging system** with severity levels
- **Modular structure** for clean extensions
- **Pipeline-aware execution** like `result | map { it }`
- **UTF-8/BOM-safe** via tooling in `fix-encoding.ps1`

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
all                             # Root entrypoint
all my                         # User-level context
all my clock start             # Start tracking uptime
all my clock stop              # Stop tracking uptime
all my uptime                  # Show system uptime
all my files                   # List files in current directory
all my shell                   # Open an interactive shell prompt
all my browser google.com      # Launch the default browser to a URL

all my homies                  # Utilities namespace
all my homies fetch <url>      # Fetch JSON data from URL
all my homies install choco    # Install Chocolatey

all my homies hate windows     # Run Windows-related cleanup
all my homies hate windows version # Show Windows version info

# JSON Power Tools
all my homies hate json view data.json
all my homies hate json tree "https://jsonplaceholder.typicode.com/users"
all my homies hate json table "https://jsonplaceholder.typicode.com/users"
all my homies hate json chart test.json month value
all my homies hate json highlight '{"name":"John"}'
```

---

## 🧱 Architecture

- `core/`: Logging, result types, parser, pipeline support
- `all/`: All commands start here
- `all/my/`: User-centric tools (`clock`, `uptime`, `files`, `shell`, etc)
- `all/my/homies/`: Utilities, downloaders, nested namespaces
- `hate/`: Verbosity-simplifying adapter (e.g. `json`, `windows`)
- `install/`: Installers like `choco`

---

## 📁 Example Structure

```
all/
  my/
    clock.ps1
    uptime.ps1
    browser.ps1
    files.ps1
    shell.ps1
    homies/
      hate/
        json.ps1
        windows/
          version.ps1
      install/
        choco.ps1
core/
  result.ps1
  pipeline.ps1
  log.ps1
  command.ps1
  dispatch.ps1
  import.ps1
```

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

MIT. Copy it, fork it, customize it.

