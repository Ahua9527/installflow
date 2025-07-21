# 🔔 InstallFlow

> Make Mac app installation as simple as a "ding" - Batch processing tool for local macOS installation packages
<div align="center">

[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS-lightgrey.svg?style=flat-square)](https://www.apple.com/macos/)
[![Workers](https://img.shields.io/badge/Deployed%20on-Cloudflare%20Workers-F38020?style=flat-square&logo=cloudflare)](https://workers.cloudflare.com/)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/Ahua9527/installflow)

English · [简体中文](./README.md) · [Demo](https://ding.ahua.space)
</div>
## 📖 Project Overview


InstallFlow is a batch processing tool designed for macOS to help you quickly install locally downloaded application files. It eliminates the need to manually handle DMG, PKG, and other installation package formats one by one.

### 🎯 Core Value

- **Solves Pain Points**: Batch process local Mac app installation packages, avoiding repetitive mounting and dragging operations
- **Target Users**: Mac users, developers, and IT administrators who need to batch install local applications
- **Design Philosophy**: One script, interactive selection, intelligent processing, secure installation

## ✨ Key Features

### 🚀 Multi-Format Support
- **DMG Files**: Auto-mount, extract apps, intelligently handle nested structures
- **ISO Files**: Disk image mounting, app extraction, support for multi-level nested structures
- **PKG Files**: Invoke system installer for installation
- **ZIP Files**: Extract and retrieve applications within
- **APP Files**: Directly copy to Applications folder

### 🛡️ Security Mechanisms
- **Path Validation**: Strict path security checks to prevent command injection
- **Temporary File Cleanup**: Automatically clean up temporary files during installation
- **Permission Handling**: Auto-remove quarantine attributes to ensure apps run properly
- **Version Detection**: Intelligently detect app versions to avoid duplicate installations

### 💡 Interactive Experience
- **Terminal Interface**: Navigate with arrow keys, select with spacebar, confirm with enter
- **Real-time Feedback**: Colorized log output with detailed installation progress
- **Smart Notifications**: Apple Silicon compatibility detection and Rosetta installation reminders
- **Installation Reports**: Complete installation summary and results display

### 🎨 Web Interface
- **Cloudflare Workers**: Fast access based on edge computing
- **Modern Design**: Glassmorphism effects with responsive layout
- **Easy Sharing**: One-click copy installation command

## 🛠️ Tech Stack

### Frontend
- **Runtime**: Cloudflare Workers (Edge Computing)
- **Technology**: Vanilla JavaScript, HTML5, CSS3
- **Design**: Inline single-file architecture with glassmorphism UI

### Installation Script
- **Language**: Bash Script (1,377 lines of professional code)
- **Compatibility**: macOS 10.15+ (Catalina and above)
- **Architecture**: Apple Silicon native support with automatic Rosetta detection

### Deployment
- **CI/CD**: GitHub Actions automated deployment
- **Environments**: Separate development and production environments
- **Domains**: ding.ahua.space (homepage), gh.ahua.space (script proxy)

## 🚀 Quick Start

### System Requirements

- macOS 10.15 (Catalina) or higher
- Locally downloaded app installation packages (DMG/ISO/PKG/ZIP/APP)
- Terminal access permissions

### Usage

Run the following command in Terminal:

```bash
bash <(curl -fsSL https://ding.ahua.space/install)
```

### Usage Flow

1. **Run Installation Script**: Execute the command above
2. **Select Packages**: Script scans current directory and common download locations
3. **Interactive Selection**: Use arrow keys to browse, spacebar to select apps for installation
4. **Confirm Installation**: Press enter to start the batch installation process
5. **View Results**: Check detailed installation report after completion

### ⚠️ Important Notes

**Encrypted Disk Image Limitations**:
- Encrypted DMG or ISO files will interrupt the automated installation process
- It's recommended to decrypt or remove password protection before use
- The script will attempt to handle encrypted files, but may require manual intervention

**Other Usage Recommendations**:
- Ensure sufficient disk space for installation
- When installing many applications, consider closing other resource-intensive programs
- Do not manually operate Finder or mount/unmount disks during the installation process

## 📚 Project Architecture

### File Structure

```
/Frontend/
  worker.js          # Complete Cloudflare Worker application
  wrangler.toml      # Deployment configuration
  
/Scripts/
  install.sh         # Main installation script (1,377 lines)
  
/.github/
  workflows/deploy.yml    # GitHub Actions deployment configuration
```

### Core Components

#### Installation Script (`Scripts/install.sh`)
- **File Scanning**: Intelligently scan local directories for installation packages
- **Format Detection**: Automatically identify different installation file formats
- **Interactive Interface**: Graphical selection experience within terminal
- **Installation Processing**: Use appropriate installation methods based on file format
- **Error Handling**: Comprehensive error recovery and logging

#### Web Interface (`Frontend/worker.js`)
- **Static Service**: Provide project introduction and installation commands
- **Script Proxy**: Serve script downloads through `/install` path
- **Responsive Design**: Modern interface adapted for different devices

## 🔧 Local Development

### Prerequisites

- Node.js 22+
- Cloudflare account (for deployment)

### Development Steps

1. **Clone Repository**
   ```bash
   git clone https://github.com/yourusername/installflow.git
   cd installflow
   ```

2. **Install Wrangler CLI**
   ```bash
   npm install -g wrangler
   ```

3. **Local Development Server**
   ```bash
   cd Frontend
   wrangler dev
   ```

4. **Deploy to Development Environment**
   ```bash
   wrangler deploy --env development
   ```

5. **Test Installation Script**
   ```bash
   bash Scripts/install.sh
   ```

## 🤝 Contributing

Welcome to submit Pull Requests or Issues! For major changes, please open an Issue for discussion first.

### Contribution Process

1. Fork this repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

### Development Guidelines

- Follow existing code style and commenting conventions
- Ensure security checks and path validation pass
- Test your changes for compatibility across different macOS versions

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Cloudflare Workers for the edge computing platform
- GitHub Actions for CI/CD services
- macOS developer community for support and suggestions

## 📮 Contact

- Project Website: [https://ding.ahua.space](https://ding.ahua.space)
- Issue Reports: Submit via GitHub Issues

---

<p align="center">
  Made with ❤️ for the Mac Community
</p>