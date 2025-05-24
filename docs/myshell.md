# MyShell - PowerShell Configuration Manager

A clean and simple PowerShell configuration manager that sets up PowerShell Core with enhanced PSReadLine features, a customizable profile, and beautiful Starship prompt configuration.

## Overview

MyShell provides an easy way to:
- Install PowerShell Core (pwsh) if not already installed
- Configure a feature-rich PowerShell profile with PSReadLine enhancements
- Install a beautiful Starship prompt configuration
- Manage PowerShell configuration through user-friendly prompts
- Maintain clean separation between setup and profile configuration

## Commands

### Available Actions

```powershell
# Display available commands and usage
all my config myshell

# Install PowerShell Core and required modules
all my config myshell setup

# Configure PowerShell profile with PSReadLine features
all my config myshell profile

# Install Starship prompt configuration
all my config myshell starship

# Show current configuration information
all my config myshell info
```

### Command Options

- **`-Force`**: Skip confirmation prompts
- **`-Yolo`**: Enable all features without asking (for profile configuration)

## Architecture

### Clean Configuration Approach

MyShell uses a simple, maintainable architecture:

1. **User Input** → **JSON Config File** → **Dynamic Profile Loading**
2. **Template-based** configuration for both PowerShell profile and Starship prompt
3. **No string manipulation** or complex code injection
4. **No commented-out code** in templates
5. **Clean separation** of concerns

### File Structure

```
all/my/config/
├── myshell.ps1              # Main script with configuration logic
└── dotfiles/
    ├── profile.ps1          # PowerShell profile template
    └── starship.toml        # Starship prompt configuration

Documents/PowerShell/
├── Microsoft.PowerShell_profile.ps1    # Your active profile
└── AMH2W-Profile-Config.json           # Feature configuration

%USERPROFILE%/.config/
└── starship.toml                       # Starship prompt configuration
```

## Usage Examples

### Complete Setup

```powershell
# 1. Install PowerShell Core and modules
all my config myshell setup

# 2. Configure profile with interactive feature selection
all my config myshell profile

# 3. Install beautiful Starship prompt
all my config myshell starship
```

### Quick Setup (Enable Everything)

```powershell
# Enable all features without prompts
all my config myshell profile -Yolo
all my config myshell starship -Force
```

### Check Current Configuration

```powershell
# See what's currently configured
all my config myshell info
```

## Starship Prompt Features

The Starship configuration provides a beautiful, informative prompt with:

### 🎨 **Visual Design**
- **Tokyo Night color scheme** with elegant styling
- **Powerline-style** segments with smooth transitions
- **Unicode icons** for visual appeal
- **Clean, readable** layout

### 📂 **Information Display**
- **Current directory** with home symbol and truncation
- **Git branch and status** with detailed indicators
- **Command execution time** for performance monitoring
- **Current time** display
- **Username** information

### 🔧 **Development Features**
- **Language/runtime detection**: Node.js, Python, Java, Go, Rust, C, Zig, Deno, Bun
- **Version display** for detected runtimes
- **Git status indicators**: modified, staged, untracked, conflicts, ahead/behind
- **Virtual environment** display for Python

### ⚡ **Performance**
- **Fast rendering** with conditional segments
- **Smart detection** only shows relevant information
- **Transient prompt** for clean history

## PSReadLine Features

The profile configuration offers these optional PSReadLine enhancements:

### 🔍 **History Search**
- **Up/Down arrows** search through command history
- Find commands that start with what you've typed

### 🤖 **Predictive IntelliSense**
- **AI-powered suggestions** based on command history
- **ListView mode** for better visibility

### ⌨️ **Enhanced Key Bindings**
- `Ctrl+D` - Delete character
- `Ctrl+W` - Delete word backward
- `Alt+D` - Delete word forward
- `Ctrl+←/→` - Move by word
- `Ctrl+Z/Y` - Undo/Redo

### 🎨 **Visual Enhancements**
- **Syntax highlighting** with custom colors
- Better readability for commands, parameters, strings, etc.

### 📝 **Smart Quotes**
- **Auto-paired quotes** and brackets
- Smart quote navigation

### 📚 **Advanced History**
- **Enhanced history search** behavior
- **Incremental saving** of command history
- **Larger history** buffer (4000 commands)

## Configuration System

### How It Works

1. **User Preferences**: MyShell asks which features you want
2. **JSON Storage**: Choices saved to `AMH2W-Profile-Config.json`
3. **Template Installation**: Copies configured templates to appropriate locations
4. **Dynamic Loading**: Profile reads config and applies features conditionally

### Configuration File Format

```json
{
  "HistorySearch": true,
  "PredictiveIntelliSense": false,
  "EnhancedKeybindings": true,
  "VisualEnhancements": true,
  "SmartQuotes": false,
  "AdvancedHistory": true
}
```

### Profile Template Features

The `profile.ps1` template includes:
- **Dynamic feature loading** based on config file
- **Module loading guards** to prevent conflicts
- **Error handling** for missing modules
- **Cross-platform compatibility**

## Built-in Integrations

### Always Enabled
- **Tab completion** with MenuComplete
- **Winget tab completion**
- **Terminal Icons** for file display
- **AMH2W module** loading

### Optional Integrations
- **Starship prompt** (if installed and configured)
- **Jabba Java manager** (if configured)

## Safety Features

### Backup System
- **Automatic backups** of existing profiles and configs with timestamps
- Format: `*.backup.YYYYMMDD-HHMMSS`
- Applies to both PowerShell profiles and Starship configurations

### Error Handling
- **Graceful fallbacks** for missing modules
- **Non-breaking** module import failures
- **Safe configuration** parsing with defaults

### Installation Protection
- **Directory creation** if config folders don't exist
- **Template validation** before copying
- **User confirmation** before overwriting (unless `-Force`)
- **Dependency checking** (e.g., Starship installation)

## Command Details

### `myshell setup`

**Purpose**: Install PowerShell Core and required modules

**What it does**:
1. Checks if PowerShell Core is installed
2. Installs PowerShell Core via winget (if needed)
3. Installs PSReadLine module
4. Installs Terminal-Icons module
5. Suggests switching to PowerShell Core if running Windows PowerShell

**Requirements**: 
- Administrator privileges (for PowerShell Core installation)
- Internet connection (for downloading)

### `myshell profile`

**Purpose**: Configure PowerShell profile with PSReadLine features

**What it does**:
1. Presents interactive feature selection (unless `-Yolo`)
2. Saves user preferences to JSON config file
3. Creates backup of existing profile
4. Copies and configures profile template
5. Updates date placeholder in profile

**Interactive Prompts**:
- Feature selection for each PSReadLine enhancement
- Confirmation before overwriting existing profile

### `myshell starship`

**Purpose**: Install Starship prompt configuration

**What it does**:
1. Checks if Starship is installed
2. Creates backup of existing Starship config (if exists)
3. Copies AMH2W Starship configuration to `~/.config/starship.toml`
4. Provides installation guidance if Starship is not installed

**Requirements**:
- Starship must be installed (`winget install starship`)

**Features Installed**:
- Tokyo Night color scheme
- Git integration with detailed status
- Language/runtime detection
- Command duration display
- Beautiful Unicode styling

### `myshell info`

**Purpose**: Display current configuration status

**Shows**:
- PowerShell Core installation status
- Current PowerShell edition
- Profile and config file paths
- Starship installation and config status
- File existence status
- Current feature configuration (if config exists)

## Troubleshooting

### Common Issues

**Profile not loading features**:
- Check if `AMH2W-Profile-Config.json` exists in profile directory
- Verify JSON format is valid
- Restart PowerShell session after configuration

**Starship not showing**:
- Ensure Starship is installed: `winget install starship`
- Check if `starship.toml` exists in `~/.config/`
- Verify PowerShell profile includes Starship initialization
- Restart PowerShell session after configuration

**Module nesting errors** (rare):
- Profile includes guards to prevent this
- If issues persist, restart PowerShell completely

**PSReadLine features not working**:
- Ensure PSReadLine module is installed: `Get-Module PSReadLine -ListAvailable`
- Check if running in PowerShell ISE (PSReadLine features are limited there)

### Manual Configuration

You can manually edit configuration files:

```powershell
# Edit PSReadLine configuration
notepad "$env:USERPROFILE\Documents\PowerShell\AMH2W-Profile-Config.json"

# Edit Starship configuration
notepad "$env:USERPROFILE\.config\starship.toml"

# Then restart PowerShell to apply changes
```

## Development Notes

### Design Principles

1. **Simplicity**: No complex string manipulation or code injection
2. **Maintainability**: Clear separation between config and templates
3. **Safety**: Always backup, graceful error handling
4. **User-friendly**: Interactive prompts with clear descriptions
5. **Modularity**: Each component (PowerShell, Starship) can be configured independently

### File Locations

- **Source**: `all/my/config/myshell.ps1`
- **PowerShell Template**: `all/my/config/dotfiles/profile.ps1`
- **Starship Template**: `all/my/config/dotfiles/starship.toml`
- **User Profile**: Dynamic based on `$PROFILE` variable
- **PSReadLine Config**: Same directory as user profile
- **Starship Config**: `%USERPROFILE%\.config\starship.toml`

### Future Enhancements

Potential improvements could include:
- Web-based configuration interface
- Profile themes and presets
- Integration with more PowerShell modules
- Cross-platform shell detection and setup
- Custom Starship theme builder
- Terminal emulator-specific optimizations

---

**Part of the AMH2W (All My Homies To Win) PowerShell module collection.** 