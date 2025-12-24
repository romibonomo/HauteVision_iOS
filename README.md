# HauteVision iOS

A comprehensive iOS application for tracking and managing eye health measurements and conditions.

## Features

- **Multiple Condition Tracking**: Support for various eye conditions including:
  - Glaucoma
  - Keratoconus
  - Fuchs' Dystrophy
  - Dry Eye Syndrome
  - Corneal Transplant
  - Retinal Injections

- **Data Visualization**: Interactive charts and graphs for tracking measurements over time
- **Multi-language Support**: English and French localization
- **Firebase Integration**: Secure cloud storage and authentication
- **Medication Reminders**: Set and manage medication reminders

## Setup Instructions

### Prerequisites

- Xcode 14.0 or later
- iOS 15.0 or later
- Swift 5.7 or later
- Firebase account

### Installation

1. Clone the repository:
```bash
git clone https://github.com/romibonomo/HauteVision.git
cd HauteVision
```

2. **Configure Firebase**:
   - Copy `GoogleService-Info.plist.example` to `GoogleService-Info.plist`
   - Replace all placeholder values with your Firebase project credentials
   - You can download your `GoogleService-Info.plist` from the Firebase Console:
     - Go to Project Settings → General
     - Download the iOS configuration file
     - Rename it to `GoogleService-Info.plist` and place it in the project root

3. Open the project in Xcode:
   - Open `HauteVision.xcodeproj` in Xcode
   - Or use: `open HauteVision.xcodeproj` in Terminal

4. Build and run the project (⌘R)

## Project Structure

```
HauteVision/
├── Views/              # SwiftUI view files
├── ViewModels/         # MVVM view models
├── Models/             # Data models
├── Shared/             # Shared components and utilities
│   ├── SharedComponents.swift
│   ├── SharedTypes.swift
│   ├── ErrorHandling.swift
│   └── PerformanceOptimizations.swift
├── Assets.xcassets/    # Images and assets
└── GoogleService-Info.plist  # Firebase configuration (not in repo)
```

## Configuration

### Firebase Setup

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add an iOS app to your project
3. Download the `GoogleService-Info.plist` file
4. Place it in the project root directory
5. The file is automatically ignored by git (see `.gitignore`)

### Localization

The app supports English and French. To add more languages:
1. Add language keys to `LocalizationManager.swift`
2. Add translations to the `strings` dictionary

## Security Notes

⚠️ **IMPORTANT**: Never commit `GoogleService-Info.plist` to version control. This file contains sensitive Firebase credentials.

If you accidentally committed it:
```bash
# Remove from git tracking (but keep local file)
git rm --cached GoogleService-Info.plist

# Commit the removal
git commit -m "Remove sensitive Firebase config"

# If already pushed, the file will be removed from future commits
# Note: The file will still exist in git history
```

## Development

### Architecture

The app follows the MVVM (Model-View-ViewModel) pattern:
- **Models**: Data structures and business logic
- **Views**: SwiftUI views for UI
- **ViewModels**: Observable objects that manage view state

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.



