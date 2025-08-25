# Changelog

## App & Module Updates

### ✨ New Features
- **Refresh Rate Spoofing**: Added experimental refresh rate spoofing functionality with dedicated configuration tab
- **Backup & Restore**: Added backup and restore functionality allowing users to save and load their saved configurations

### 🐛 Bug Fixes & Improvements
- **Enhanced Installation Reliability**: Implemented fallback extraction paths for critical installation files (`installer.sh` and `bin/$ARCH.xz`) to improve module deployment success rate in Emulators
- **Android 11 & 15+ Compatibility**: Resolved connection timeout issues where the retry mechanism failed to generate authentication tokens for reconnection, which affected some devices running Android 11 and later versions.
- **System Optimizations**: Various performance improvements and code optimizations

