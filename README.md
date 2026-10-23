
# CARE-O — Senior Citizen Care and Wellness App

CARE-O is a Flutter-based mobile application designed to support senior citizens through wellness activities, everyday assistance, entertainment, and family connectivity.

## Overview

CARE-O brings together care and wellness features in one mobile application, with an emphasis on making everyday activities more accessible and engaging for older adults.

## Features

The project includes modules for the following areas. Confirm each feature's implementation status in the current code before describing it as fully functional.

- **Health and Wellness:** Wellness activities and exercise-related content.
- **Meditation and Medication Reminders:** Meditation resources and reminder-related functionality.
- **Social Connection:** Features intended to encourage interaction and connection.
- **Music Player:** Devotional songs and audio playback.
- **Games and Entertainment:** Activities for recreation and engagement.
- **Guardian Control:** Features intended to support guardian and senior connectivity.
- **Helpline:** Access to help-related information or services.

## Technology Stack

| Technology | Purpose |
|---|---|
| Flutter | Mobile application framework |
| Dart | Application programming language |
| Firebase Authentication | Authentication services |
| Cloud Firestore | Cloud database |
| Flutter Local Notifications | Local notification functionality |
| Riverpod | State management |
| Audio and video packages | Media playback |

The repository also includes Firebase configuration and security-related files. The availability of each service depends on its configuration and implementation.

## Screenshots

Add screenshots of the actual application here.

| Home Screen | Wellness and Meditation |
|---|---|
| Add `screenshots/home-screen.png` | Add `screenshots/wellness-screen.png` |

| Music and Entertainment | Guardian Connectivity |
|---|---|
| Add `screenshots/music-screen.png` | Add `screenshots/guardian-screen.png` |

Replace these placeholders with genuine screenshots from the running application. Remove any screenshot entry for a screen that is not implemented.

## Getting Started

### Prerequisites

Before running CARE-O, install:

- Flutter SDK
- Dart SDK (included with Flutter)
- Android Studio or Visual Studio Code
- An Android emulator or compatible device
- A Firebase project, if required by the application configuration

### Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/anjanaav/CARE-O.git
   ```

2. Open the project directory:

   ```bash
   cd CARE-O
   ```

3. Install Flutter dependencies:

   ```bash
   flutter pub get
   ```

4. Check the Firebase configuration required by the project. Configure your own Firebase project if necessary.

5. Run the application:

   ```bash
   flutter run
   ```

### Run Tests

To run the available Flutter tests:

```bash
flutter test
```

To check the Dart code for common issues:

```bash
flutter analyze
```

Record the actual results after running these commands in your development environment.

## Firebase Configuration

CARE-O uses Firebase-related packages and configuration files.

Depending on the features being tested, you may need to configure Firebase Authentication, Cloud Firestore, and any other required services.

- Use your own Firebase project configuration.
- Verify that the required authentication methods are enabled.
- Review Firestore rules and indexes before deployment.
- Never commit service-account private keys or other secrets to GitHub.

## Project Structure

| Directory / File | Purpose |
|---|---|
| `lib/` | Flutter application source code |
| `android/` | Android-specific project files |
| `ios/` | iOS-specific project files |
| `web/` | Web platform files |
| `assets/icon/` | Application assets, icons, and media |
| `functions/` | Firebase-related functions |
| `dataconnect/` | Firebase Data Connect-related files |
| `test/` | Application tests |
| `firebase.json` | Firebase project configuration |
| `firestore.rules` | Firestore security rules |
| `firestore.indexes.json` | Firestore index configuration |
| `storage.rules` | Firebase Storage security rules |

## Project Status

CARE-O is an academic mini project developed to explore mobile application development for senior citizen care and wellness.

Feature availability, Firebase integration, and platform compatibility should be verified against the current implementation. Not all listed modules or integrations should be assumed to be production-ready.

## Future Improvements

- Improve accessibility and usability for senior citizens.
- Validate reminder and notification behavior across devices.
- Test Firebase authentication and database access.
- Improve error handling and application reliability.
- Test the complete application workflow on a physical device.
