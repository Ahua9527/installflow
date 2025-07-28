# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**InstallFlow (叮当装)** is a macOS batch application installer tool with a web frontend and sophisticated bash installation script. The project serves installation scripts via Cloudflare Workers and provides an interactive terminal interface for batch installing macOS applications (DMG, ISO, PKG, ZIP, APP files).

## Common Development Commands

### Frontend Development
```bash
cd Frontend
wrangler dev                           # Start local development server
wrangler deploy --env development      # Deploy to development environment
wrangler deploy --env production       # Deploy to production environment
```

### Script Testing
```bash
bash Scripts/install.sh                # Test installation script locally
```

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
- **Environment-specific deployments** based on branch and manual triggers

## Key Technical Details

### Installation Script Architecture
- **Entry point**: `Scripts/install.sh:main()` function at line 1314
- **Core functions**:
  - `analyze_local_packages()` - Package analysis and file scanning (line 554)
  - `interactive_package_selector()` - Terminal UI for package selection (line 362)
  - `install_dmg_file()` - DMG file installation handler (line 934)
  - `install_pkg_file()` - PKG file installation handler (line 1090)
  - `check_app_installation()` - Version comparison and app checking (line 834)
  - `mount_and_process_nested_dmg()` - Nested DMG processing (line 599)
  - `show_install_summary()` - Installation result reporting (line 1232)
- **Utility functions**:
  - `start_sudo_keepalive()` - Background sudo permission management (line 74)
  - `get_app_version()` - Extract version from app bundles (line 784)
  - `compare_versions()` - Semantic version comparison (line 807)
  - `check_rosetta_status()` - Apple Silicon compatibility check (line 250)

### Web Frontend Structure
- **Single file architecture** with embedded resources in `Frontend/worker.js`
- **Fetch event handler** manages all routing (line ~1)
- **HTML template** embedded as template literals (line ~100)
- **CSS styles** inlined for performance (line ~200)

### Security Implementation
- **Path validation** prevents command injection attacks
- **Sudo privilege management** with automatic keepalive
- **Temporary file cleanup** on script exit or interruption
- **Quarantine attribute removal** for downloaded applications

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
- Uses Cloudflare Workers runtime environment
- No build step required - deploy directly from source
- Environment variables configured in `wrangler.toml`
- Custom domains: ding.ahua.space (main), gh.ahua.space (script proxy)

### Code Conventions
- **Bash script**: Professional error handling with comprehensive cleanup
- **JavaScript**: Vanilla JS with async/await patterns
- **Logging**: Colored terminal output with timestamps for user feedback
- **Error handling**: Comprehensive error recovery and cleanup
- **Documentation**: All bash functions documented in Chinese with detailed explanations
- **Comments**: Chinese comments explain functionality, implementation details, and technical concepts

## Project Configuration

### Wrangler Configuration (`Frontend/wrangler.toml`)
- Supports both development and production environments
- Node.js compatibility flags enabled
- Custom route configurations for domain mapping

### GitHub Actions
- Automatic deployment on main branch push
- PR environment deployments for testing
- Cloudflare API token validation before deployment

## Recent Updates

### Chinese Documentation (Latest)
- **Complete Chinese documentation** added to `Scripts/install.sh`
- **All functions documented** with detailed explanations of functionality and implementation
- **Technical concepts explained** including macOS-specific features like Rosetta, DMG mounting, and quarantine attributes
- **Code structure clarified** with organized sections and clear function purposes
- **Maintenance improved** with comprehensive comments for future development

### Key Documented Features
- **Interactive package selector**: Full keyboard navigation with arrow keys, space bar selection, and pagination
- **Version management**: Intelligent version comparison and automatic updates
- **Nested structure handling**: Recursive processing of DMG-in-DMG and complex installation packages
- **System compatibility**: Apple Silicon detection and Rosetta installation guidance
- **Security features**: Sudo permission management, quarantine removal, and path validation
- **Installation reporting**: Comprehensive result tracking and user-friendly summary display