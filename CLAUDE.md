# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

InstallFlow (叮当装) is a Mac batch application installer tool with a Cloudflare Workers-based web frontend and a comprehensive bash installation script. The project is designed to make software installation as simple as "叮当" (dingdang - like a bell chime).

## Development Commands

### Frontend Development (Cloudflare Workers)

```bash
cd Frontend

# Install Wrangler CLI globally
npm install -g wrangler

# Deploy to development environment
wrangler deploy --env development

# Deploy to production environment  
wrangler deploy --env production

# Start local development server
wrangler dev
```

### Testing the Installation Script

```bash
# Test the install script locally
bash Scripts/install.sh

# Test via curl (requires deployment)
bash <(curl -fsSL https://ding.ahua.space/install)
```

### Deployment

The project uses GitHub Actions for automatic deployment:
- **Pull Requests**: Deploy to development environment (`installflow-dev`)
- **Main branch pushes**: Deploy to production environment (`installflow-prod`)
- **Manual**: Use `workflow_dispatch` trigger

## Architecture

### Frontend (`/Frontend/`)
- **Single-file Cloudflare Worker**: `worker.js` contains the complete web application
- **Self-contained design**: HTML, CSS, and JavaScript are inlined for optimal edge performance
- **No build process**: Direct deployment of `worker.js` to Cloudflare Workers
- **Configuration**: `wrangler.toml` defines deployment environments and settings

### Installation Script (`/Scripts/install.sh`)
- **Comprehensive installer**: 1,377 lines handling multiple Mac app formats (DMG, ISO, PKG, ZIP, APP)
- **Security-first approach**: Input validation, path security, temporary file cleanup
- **Interactive terminal UI**: Arrow key navigation and space selection
- **Advanced features**: Version comparison, nested DMG handling, Apple Silicon support

## Key Components

### Worker Architecture
The Cloudflare Worker serves:
- Static HTML with inlined CSS and modern gradient design
- JavaScript for interactive features (copy-to-clipboard, animations)
- URL routing and redirects
- Installation command distribution

### Installation Script Features
- **Multi-format support**: Handles DMG/ISO (including nested structures), PKG, ZIP, APP files
- **Security mechanisms**: Path validation, quarantine removal, Gatekeeper integration
- **Smart installation logic**: Duplicate detection, version comparison, automatic updates
- **Error handling**: Comprehensive logging and rollback capabilities
- **Apple Silicon support**: Automatic Rosetta detection and installation

## Environment Configuration

### Cloudflare Workers Environments
- **Development**: `installflow-dev` - Used for PR testing
- **Production**: `installflow-prod` - Main deployment target

### Required Secrets
- `CLOUDFLARE_API_TOKEN`: Required for GitHub Actions deployment

## File Structure

```
/Frontend/
  worker.js          # Complete Cloudflare Worker application
  wrangler.toml      # Deployment configuration
  
/Scripts/
  install.sh         # Main installation script
  
/.github/
  workflows/deploy.yml    # GitHub Actions deployment workflow
  ACTIONS_SETUP.md       # Deployment setup instructions
```

## Development Notes

### Frontend Changes
- Edit `worker.js` directly - no build step required
- Test locally with `wrangler dev`
- Deploy changes trigger automatic GitHub Actions

### Script Changes
- Test `install.sh` locally before committing
- Script is distributed via GitHub raw content with Cloudflare proxy
- Changes are immediately available after commit to main branch

### Security Considerations
- The installation script includes extensive security validations
- Path injection prevention and temporary file cleanup are implemented
- All external downloads are verified and handled securely