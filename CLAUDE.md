# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**InstallFlow (叮当装)** is a macOS batch application installer tool with a web frontend and sophisticated bash installation script. The project serves installation scripts via Cloudflare Workers and provides an interactive terminal interface for batch installing macOS applications (DMG, ISO, PKG, ZIP, APP files).

## Common Development Commands

### Frontend Development
```bash
cd Frontend
wrangler dev                           # Start local development server (localhost:8787)
wrangler deploy --env development      # Deploy to development environment
wrangler deploy --env production       # Deploy to production environment
```

### Script Testing
```bash
bash Scripts/install.sh                # Test installation script locally
bash Scripts/install.sh /path/to/apps  # Test with specific directory
```

### Prerequisites
- **Node.js 22+** for Wrangler CLI
- **Cloudflare account** with API token configured
- **macOS 10.15+** for script testing

### Deployment
- Deployment is automated via GitHub Actions on push to main branch
- Manual deployment can be triggered through GitHub Actions workflow dispatch

## Architecture Overview

### Frontend (`Frontend/worker.js`)
- **Single-file Cloudflare Worker** containing inline HTML, CSS, and JavaScript
- **Route Structure**:
  - `/` - Main landing page with installation instructions
  - `/install` - Serves the bash installation script
  - `/assets/css/style.css` - Embedded CSS styles  
  - `/assets/js/script.js` - Embedded JavaScript functionality
- **Key Features**: Copy-to-clipboard functionality, modern glassmorphism UI, GitHub integration

### Installation Script (`Scripts/install.sh`)
- **1,335-line professional bash script** for macOS application installation with comprehensive Chinese documentation
- **Multi-format support**: DMG, ISO, PKG, ZIP, APP files
- **Interactive terminal interface** with arrow key navigation and multi-select
- **Security features**: Path validation, sudo management, quarantine removal
- **Smart processing**: Nested structure handling, version detection, Apple Silicon compatibility
- **Documentation**: Complete Chinese comments explaining all functions and logic

### CI/CD Pipeline (`.github/workflows/deploy.yml`)
- **Automated deployment** to both development and production environments
- **Node.js 22** with Wrangler CLI for Cloudflare Workers deployment
- **Environment-specific deployments**: PR → development, main push → production
- **Path-based triggers**: Only deploys when Frontend/, Scripts/, or workflow files change
- **PR comments**: Automatic deployment status updates with preview URLs

## Key Technical Details

### Installation Script Architecture
- **Entry point**: `Scripts/install.sh:main()` function
- **Core functions**:
  - `analyze_local_packages()` - Package analysis and file scanning with hidden file filtering
  - `interactive_package_selector()` - Terminal UI with arrow keys, space bar, pagination (30 items/page)
  - `install_dmg_file()` - DMG file installation with nested structure support
  - `install_pkg_file()` - PKG file installation handler
  - `check_app_installation()` - Version comparison with semantic versioning
  - `mount_and_process_nested_dmg()` - Recursive processing up to 5 levels deep
  - `show_install_summary()` - Installation result reporting with statistics
- **Utility functions**:
  - `start_sudo_keepalive()` - Background sudo permission refresh every 240 seconds
  - `get_app_version()` - Extract version from CFBundleShortVersionString or CFBundleVersion
  - `compare_versions()` - Semantic version comparison using `sort -V`
  - `check_rosetta_status()` - Apple Silicon compatibility check with installation guidance

### Web Frontend Structure
- **Single file architecture** with all resources embedded in `Frontend/worker.js`
- **Design rationale**: Zero build step for instant deployment to Cloudflare Workers edge network
- **Route structure**:
  - `/` serves HTML page with embedded CSS and JavaScript
  - `/install` proxies to GitHub raw script URL
  - `/assets/*` serves embedded static resources
- **Zero dependencies**: Pure JavaScript with no npm packages required

### Critical Implementation Details

#### Hidden File Filtering (macOS Specific)
- **Problem**: macOS creates `._*` resource fork files on non-HFS+ filesystems (FAT32, exFAT)
- **Solution**: `analyze_local_packages()` filters out:
  - Resource fork files: `._*` (AppleDouble format)
  - System metadata: `.DS_Store`
- **Implementation**: Checks file content for `AppleDouble` magic bytes to distinguish from legitimate files

#### Version Management Strategy
- **Detection**: Extracts version from app bundle Info.plist
- **Comparison**: Uses `sort -V` for semantic versioning (handles 1.2.3, 2.0.0-beta, etc.)
- **Decision logic**:
  - Not installed → Install
  - Package version > installed version → Update
  - Package version ≤ installed version → Skip

#### Nested Structure Processing
- **Supported scenarios**:
  - DMG containing DMG (up to 5 levels)
  - DMG containing PKG and APP files
  - ISO containing nested DMG structures
  - ZIP containing DMG or APP files
- **Processing order**: PKG files processed first, then DMG, then APP
- **Mount management**: Automatic mounting and cleanup to prevent resource leaks

### Security Implementation
- **Path validation** prevents command injection attacks
- **Sudo privilege management** with automatic keepalive and cleanup on exit
- **Temporary file cleanup** on script exit or interruption (SIGINT, SIGTERM)
- **Quarantine attribute removal** via `xattr -d -r com.apple.quarantine`
- **Signal handling**: Comprehensive cleanup for all exit scenarios

## Development Notes

### Testing the Installation Script
- Test on macOS 10.15+ (Catalina and above)
- Requires administrator privileges for application installation
- Test with various file formats (DMG, PKG, ZIP, APP)
- Verify Apple Silicon compatibility detection
- Test nested DMG/ISO structures and version comparison logic
- Validate interactive package selector keyboard navigation
- Check sudo keepalive mechanism and cleanup functions

### Frontend Development
- Uses Cloudflare Workers runtime environment with Node.js compatibility
- No build step required - deploy directly from source
- Environment variables configured in `wrangler.toml`
- Custom domains: ding.ahua.space (main), gh.ahua.space (script proxy)
- **Development workflow**: Edit `worker.js` → `wrangler dev` → test → deploy

### Code Conventions
- **Bash script**:
  - Professional error handling with comprehensive cleanup functions
  - All functions documented in Chinese with detailed explanations
  - Chinese comments explain functionality, implementation details, and technical concepts
  - Colored logging with timestamps: `log()`, `warn()`, `error()`, `info()`
- **JavaScript**:
  - Vanilla JS with no external dependencies
  - Embedded inline for zero build step
  - Modern async/await patterns where needed
- **Error handling**: Comprehensive error recovery and cleanup for all exit scenarios

## Project Configuration

### Wrangler Configuration (`Frontend/wrangler.toml`)
- Supports both development and production environments
- Node.js compatibility flags enabled (`nodejs_compat`)
- Custom route configurations for domain mapping

### GitHub Actions
- **Triggers**: Push to main (production), PR (development), manual workflow dispatch
- **Path filtering**: Only triggers on Frontend/, Scripts/, or workflow changes
- **Environment separation**: `installflow-prod` (production), `installflow-dev` (development)
- **Security**: Cloudflare API token validation before deployment
- **Notifications**: Automatic PR comments with deployment status and preview URLs

## Important Notes

### macOS-Specific Considerations
- **Encrypted DMG/ISO files**: Cannot be processed automatically - user intervention required
- **Resource fork files**: Automatically filtered out to prevent installation errors
- **Rosetta detection**: Script automatically detects Apple Silicon and prompts for Rosetta if needed
- **Quarantine attributes**: Automatically removed to ensure apps can launch without warnings

### Interactive Package Selector Controls
- **Arrow keys**: Navigate up/down, left/right for pagination
- **Space**: Toggle selection
- **Enter**: Confirm and proceed with installation
- **Ctrl+A**: Select all packages
- **Ctrl+N**: Deselect all packages
- **q / ESC**: Quit without installing