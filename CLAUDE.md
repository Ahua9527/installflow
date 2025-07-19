# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

叮当装 (InstallFlow) is a macOS automation tool for batch installing applications from local packages. It consists of a bash script for installation and a web-based frontend for folder selection. The project name combines Chinese "叮当装" (DingDang Zhuang - meaning "install with a ding-dong/bell sound") and English "InstallFlow".

## Architecture

### Components
1. **Scripts/install.sh** - Main installation script that handles .dmg, .pkg, .zip, and .app files
   - Interactive package selector with keyboard navigation
   - Gatekeeper management for smooth third-party app installation
   - Support for nested/special package structures and complex DMG files
   - Automatic quarantine attribute removal

2. **Frontend/** - Web-based folder selector
   - HTML5 drag-and-drop interface
   - Generates shell commands for the install script
   - Uses Marked.js for command formatting

## Commands

### Running the Installation Script
```bash
# Run with a folder containing installation packages
bash Scripts/install.sh /path/to/installers

# Show help
bash Scripts/install.sh --help
```

### Testing the Web Interface
```bash
# Open the web interface (macOS)
open Frontend/index.html

# Or serve it with a local server
python3 -m http.server -d Frontend 8000
```

## Development Notes

### Key Script Features
- **Interactive Selection**: Uses terminal-based UI with arrow keys, space for selection, Ctrl+A/N for select all/none
- **Gatekeeper Handling**: Prompts to temporarily disable Gatekeeper for easier installation, with reminders to re-enable
- **Package Detection**: Recursively finds packages in subdirectories, handles various packaging formats including nested structures
- **Error Handling**: Comprehensive error checking with fallback options for different package structures

### Web Frontend
- Pure JavaScript with no build process required
- Uses Web File API and drag-drop events
- Generates commands that reference the bootstrap.sh script (though the actual script is install.sh)