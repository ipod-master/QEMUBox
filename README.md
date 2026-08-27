# QEMUBox - iOS Virtualization with OS Downloader

**QEMUBox** is a full-featured QEMU virtualization environment for iOS devices (iPhone, iPad) with an integrated OS downloader, JIT acceleration, and Sileo package support.

## 🎯 Features

- ✅ **QEMU Virtualization** - Run Linux, macOS, Windows on iOS
- ✅ **30+ CPU Architectures** - x86_64, ARM64, RISC-V, PowerPC, and more
- ✅ **OS Downloader** - Browse and download Ubuntu, Fedora, Debian, Alpine, CentOS ISOs
- ✅ **One-Click VM Creation** - Select OS → Auto downloads → Creates pre-configured VM
- ✅ **JIT Acceleration** - Fast emulation (requires jailbreak)
- ✅ **Multiple VM Management** - Create, configure, run multiple VMs
- ✅ **Sileo Integration** - Install as .deb package on jailbroken iOS
- ✅ **Download Manager** - Pause, resume, queue OS downloads
- ✅ **VM Configuration** - Adjust CPU cores, RAM, storage per VM
- ✅ **Terminal/Console Access** - Serial console and display output

## 📋 Requirements

- iOS 16+ device (iPhone 8+, iPad)
- Jailbroken device with Sileo
- 500MB+ free storage per OS
- JIT support (via AltJIT, TrollStore, or similar)

## 🏗️ Project Structure

```
QEMUBox/
├── QEMUBoxApp/              # Main iOS Swift application
│   ├── App/                 # App entry point
│   │   └── QEMUBoxApp.swift
│   ├── Views/               # SwiftUI UI screens
│   │   ├── ContentView.swift
│   │   ├── VMListView.swift
│   │   ├── OSDownloadView.swift
│   │   ├── VMConfigView.swift
│   │   ├── VMConsoleView.swift
│   │   └── DownloadProgressView.swift
│   ├── ViewModels/          # State management
│   │   ├── VMListViewModel.swift
│   │   ├── OSDownloadViewModel.swift
│   │   └── DownloadProgressViewModel.swift
│   ├── Models/              # Data structures
│   │   ├── VirtualMachine.swift
│   │   ├── OSImage.swift
│   │   ├── DownloadTask.swift
│   │   └── QEMUConfig.swift
│   ├── Services/            # Core logic
│   │   ├── VMManager.swift
│   │   ├── OSRepository.swift
│   │   ├── DownloadManager.swift
│   │   ├── QEMUWrapper.swift
│   │   └── StorageManager.swift
│   ├── Utils/               # Helper utilities
│   │   ├── FileUtils.swift
│   │   └── NetworkUtils.swift
│   └── Resources/           # Assets and configs
│       ├── OSConfigs/
│       │   ├── ubuntu.json
│       │   ├── fedora.json
│       │   ├── debian.json
│       │   └── alpine.json
│       └── Icons/
│
├── QEMU/                    # QEMU compilation for iOS
│   ├── build-qemu-ios.sh
│   ├── qemu-patches/
│   └── ios-config
│
├── Packaging/               # Sileo/Cydia .deb package
│   ├── control
│   ├── preinst
│   ├── postinst
│   ├── prerm
│   └── postrm
│
├── Scripts/                 # Build and deployment
│   ├── build.sh
│   ├── package.sh
│   └── deploy.sh
│
├── Documentation/
│   ├── INSTALLATION.md
│   ├── USAGE.md
│   ├── DEVELOPMENT.md
│   └── API.md
│
└── LICENSE (Apache 2.0)
```

## 🚀 Quick Start

### Installation (Jailbroken iOS)
1. Add QEMUBox repo to Sileo
2. Install QEMUBox
3. Open app → Select OS → Download → Create VM → Run

### Building from Source
```bash
git clone https://github.com/ipod-master/QEMUBox.git
cd QEMUBox
./scripts/build.sh
./scripts/package.sh
```

## 📖 Documentation

- [Installation Guide](Documentation/INSTALLATION.md)
- [Usage Guide](Documentation/USAGE.md)
- [Development Setup](Documentation/DEVELOPMENT.md)
- [API Reference](Documentation/API.md)

## 🔧 Supported Operating Systems

- **Linux Distributions:**
  - Ubuntu (20.04 LTS, 22.04 LTS, 24.04 LTS)
  - Fedora (39, 40)
  - Debian (11, 12)
  - Alpine Linux (3.18, 3.19)
  - CentOS Stream (9)
  
- **Other:**
  - macOS (Monterey, Ventura, Sonoma) - Limited
  - Windows (limited ARM64 support)

## 📝 License

QEMUBox is distributed under the Apache License 2.0. See LICENSE file for details.

It uses QEMU (GPLv2) and other open-source components.

## 🤝 Contributing

Contributions are welcome! Please see CONTRIBUTING.md for guidelines.

## ⚠️ Disclaimer

- QEMUBox requires a jailbroken device
- Performance depends on device hardware
- Not affiliated with Apple or QEMU project
- Use at your own risk

---

**Repository:** https://github.com/ipod-master/QEMUBox  
**Status:** In Development 🔨
