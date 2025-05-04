# Nerd Fonts Command Flow Diagram

```mermaid
graph TD
    A[all my homies install nerdfonts] --> B{Action?}
    
    B --> C[list]
    B --> D[search]
    B --> E[install]
    B --> F[info]
    
    C --> G{Cache Valid?}
    G -->|Yes| H[Load Cached Data]
    G -->|No| I[Fetch from GitHub API]
    I --> J[Cache Response]
    J --> H
    H --> K[Display All Fonts]
    
    D --> L{Search Term Provided?}
    L -->|No| M[Error: Search Term Required]
    L -->|Yes| G
    H --> N[Filter Fonts by Search Term]
    N --> O[Display Matching Fonts]
    
    E --> P{Font Name Provided?}
    P -->|No| Q[Error: Font Name Required]
    P -->|Yes| R{Is Admin?}
    R -->|No| S[Request Elevation]
    S --> T[Exit Current Process]
    R -->|Yes| U[Check if Font Already Installed]
    U -->|Yes| V[Display: Already Installed]
    U -->|No| W[Download Font ZIP]
    W --> X[Extract Files]
    X --> Y[Install TTF/OTF Files]
    Y --> Z[Cleanup Temporary Files]
    Z --> AA[Success Message]
    
    F --> AB{Font Name Provided?}
    AB -->|No| G
    AB -->|Yes| G
    H --> AC{Font Name?}
    AC -->|No| AD[Display Release Info]
    AC -->|Yes| AE[Display Specific Font Info]
```

## Cache System

The nerdfonts command implements a smart caching system:

1. **Cache Location**: `$env:LOCALAPPDATA\AMH2W\Cache\nerdfonts-release.json`
2. **Cache Duration**: 24 hours
3. **Force Refresh**: Use `-ForceRefresh` parameter to bypass cache
4. **Cache Contents**: Complete GitHub API release response including all font assets

## Installation Process

When installing a font, the system:

1. Checks for administrator privileges
2. Elevates if needed (keeping window open for feedback)
3. Searches for the font in release assets (case-insensitive)
4. Checks if font is already installed by looking for common display name patterns
5. Downloads the font using the `fetch` utility
6. Extracts TTF and OTF files
7. Installs each font file to `C:\Windows\Fonts`
8. Cleans up temporary files

## Error Handling

The command uses the Result pattern throughout:
- `Ok` results contain the requested data or success status
- `Err` results contain descriptive error messages
- All operations are wrapped in try/catch blocks
- Logging is used for diagnostic information

## Usage Examples

```powershell
# List all fonts with caching
all my homies install nerdfonts list

# Force fresh data from GitHub
all my homies install nerdfonts list -ForceRefresh

# Search for fonts
all my homies install nerdfonts search "Fira"

# Install a font (prompts for elevation)
all my homies install nerdfonts install FiraCode

# Get release information
all my homies install nerdfonts info

# Get specific font information
all my homies install nerdfonts info "JetBrainsMono"
```
