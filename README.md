# 🛡️ ScAllergen Mobile Application

<div align="center">

**Your personal food safety guardian powered by AI**

Smart allergen detection through OCR scanning and graph-based allergen matching

[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

[🚀 Backend Repository](https://github.com/khangndct/ScAllergen-Backend) • [🏗️ Installation](#️-installation-options) • [✨ Features](#-key-features) • [📧 Contact](#-contact--support)

</div>

---

> **⚠️ IMPORTANT:** This is the **Frontend** of the application. The app requires the **Backend** to be running for allergen detection features to work. Please ensure you have completed the backend setup before using this app.
> 
> **Backend Repository:** [khangndct/ScAllergen-Backend](https://github.com/khangndct/ScAllergen-Backend)

---

## 📑 Table of Contents

- [About The Project](#-about-the-project)
- [Key Features](#-key-features)
- [Tech Stack](#-tech-stack)
- [Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [Backend Setup (Required)](#-backend-setup-required)
  - [Installation Options](#-installation-options)
- [Usage Guide](#-usage-guide)
- [Project Structure](#-project-structure)
- [Development Commands](#-development-commands)
- [Environment Configuration](#-environment-configuration)
- [Troubleshooting](#-troubleshooting)
- [License](#-license)
- [Contact & Support](#-contact--support)

---

## 📖 About The Project

**ScAllergen** is a Flutter-based mobile application designed to protect users from potentially harmful food allergens through intelligent OCR scanning and graph-based detection. The app directly addresses the critical challenge of identifying allergens in food products, especially when ingredient lists are in different languages or contain complex terminology.

### The Problem We Solve

- ⚠️ **Life-threatening allergies** require constant vigilance when shopping for food
- 🌍 **Language barriers** make it difficult to read foreign ingredient labels
- 🔍 **Complex ingredient names** are hard to identify and match to known allergens
- ⏱️ **Time-consuming** manual checking of every product label

### Our Solution

ScAllergen  reduces the risk of allergen exposure while making food shopping faster and safer. The app provides accurate allergen detection with multilingual support, empowering users to make informed decisions about their food choices and protecting them from potentially life-threatening allergic reactions.

### System Architecture

This mobile app is the **frontend client** that works in conjunction with the **ScAllergen Backend** (Neo4j graph database + FastAPI server). The workflow is:

1. 📸 **Mobile App** captures and OCR scans ingredient photos using Gemini AI
2. 📤 **Mobile App** sends extracted ingredients to the **Backend API**
3. 🔍 **Backend** performs fuzzy matching and graph traversal to detect allergens
4. ⚡ **Mobile App** displays results and warnings to the user

---

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| 📸 **AI-Powered OCR Scanning** | Capture ingredient lists from product labels using advanced Google Gemini AI technology |
| 🔍 **Graph-Based Allergen Detection** | Sends ingredients to backend for sophisticated fuzzy matching and Neo4j graph traversal |
| 👤 **User Health Profiles** | Manages personal allergen preferences and dietary restrictions |
| ⚡ **Fast Alerts** | Provides instant warnings about potential allergen matches with detailed safety information |
| 🌐 **Multi-language Support** | Automatically translates ingredients to English for accurate matching |
| 📰 **News Feed** | Stay updated with allergen-related health news and food safety alerts |

---

## 🏗️ Tech Stack

### Frontend & Mobile
- **[Flutter](https://flutter.dev/)** (v3.9.2+) - Cross-platform mobile framework
- **[Dart](https://dart.dev/)** (SDK) - Programming language for Flutter
- **[Firebase Auth](https://firebase.google.com/products/auth)** - User authentication and authorization
- **[Cloud Firestore](https://firebase.google.com/products/firestore)** - NoSQL cloud database for user data

### OCR
- **[Google Gemini AI](https://deepmind.google/models/gemini/)** (2.5 Flash) - Advanced AI for OCR and text extraction

### Backend Integration
- **[FastAPI](https://fastapi.tiangolo.com/)** - High-performance Python backend API
- **[Neo4j](https://neo4j.com/)** - Graph database for allergen relationship mapping
- **[FoodOn Ontology](https://foodon.org)** - Food ingredient classification system

### Tools
- **[Docker](https://www.docker.com/)** - Containerization for consistent builds
- **[Android Studio](https://developer.android.com/studio)** - Android development IDE
- **[VS Code](https://code.visualstudio.com/)** - Lightweight code editor with Flutter extensions

---

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following:

- ⚠️ **Backend Service** - ScAllergen Backend **must** be running ([Setup Guide](https://github.com/khangndct/ScAllergen-Backend))
- **Google Gemini API Key** - ([Get one here](https://aistudio.google.com/app/apikey))
- **Firebase Project** - ([Create here](https://console.firebase.google.com/))

**Choose one installation method:**
- **Docker** - Quick APK build without Flutter SDK
- **Flutter SDK** - For development and local testing

---

## 🛠️ Backend Setup (Required)

> **📖 Full Backend Documentation:** [khangndct/ScAllergen-Backend](https://github.com/khangndct/ScAllergen-Backend)

---

## 🏗️ Installation Options

**Before proceeding with installation, clone the frontend repository:**

```bash
git clone https://github.com/tothanhdat2006/ScAllergen.git
cd ScAllergen/src
```

Now choose your preferred installation method:
- **[Option A: Docker Build](#option-a-docker-build-🐳)** - Recommended for quick APK generation
- **[Option B: Manual Installation](#option-b-manual-installation-🖥️)** - For development and testing

### Option A: Docker Build 🐳

Build the application using Docker for consistent cross-platform compilation **without installing Flutter SDK locally**.

#### Requirements

| Requirement | Description |
|-------------|-------------|
| **[Docker Desktop](https://docs.docker.com/desktop/)** | Docker Engine for containerization |
| **Backend Service** | Must be running ⚠️ |
| **Firebase Config** | `google-services.json` file |
| **Gemini API Key** | For OCR functionality |

#### Configuration Before Building

Before building the Docker image, you must configure the required services:

**1. Configure Backend API Endpoint**

1. Open [lib/core/services/allergy_check_service.dart](lib/core/services/allergy_check_service.dart)
2. Replace the `_baseUrl` with your backend URL:
   ```dart
   static const String _baseUrl = 'YOUR_BACKEND_URL_HERE';
   ```
   - Use the Ngrok URL from backend setup when access http://localhost:4040 (e.g., `https://your-ngrok-subdomain.ngrok-free.dev`)
   
> **Note:** Docker builds create a standalone APK, so the backend URL must be hardcoded or configured before building.

**2. Configure Firebase**

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add an Android app to your Firebase project
3. Download `google-services.json` and place it in `android/app/`
4. Enable Firebase Authentication and Firestore Database + Storage (required billing information) in Test mode inside Firebase Console

**3. Configure Gemini API Key**

Edit [lib/core/services/gemini_ocr_service.dart](lib/core/services/gemini_ocr_service.dart) and replace the defaultValue key:
```dart
const String _apiKey = String.fromEnvironment('API_KEY',
    defaultValue: 'YOUR_API_KEY_HERE');
```

**Get your Gemini API Key:**
1. Visit [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Sign in to your Google account (or create one if needed)
3. Click "Create API key" → "Select a Cloud Project" → "+ Create Project"
4. Create and name your project
5. Generate an API key and copy it
6. Paste it in the `gemini_ocr_service.dart` file

#### Build Steps

> **⚠️ Important:** The Docker build process uses the configurations you set above. Make sure all settings are correct before building, as they will be compiled into the APK.

**Using Build Scripts (Recommended):**

<details>
<summary><b>Windows</b></summary>

```bash
# at root folder
.\build.bat
```
</details>

<details>
<summary><b>Linux/macOS</b></summary>

```bash
# at root folder
chmod +x build.sh
./build.sh
```
</details>

The script will:
1. ✅ Build a Docker image with Flutter SDK
2. ✅ Compile the Flutter app into a release APK
3. ✅ Extract the APK to your current directory

**Output:** The compiled `app-release.apk` will be available in the root folder.

**Manual Docker Build:**

```bash
# at root folder
docker build -t flutter-app .
docker create --name temp-container flutter-app
docker cp temp-container:/src/build/app/outputs/flutter-apk/app-release.apk .
docker rm temp-container
```

---

### Option B: Manual Installation 🖥️

For developers who want to run and debug the app locally with Flutter SDK.

#### Requirements

| Requirement | Description |
|-------------|-------------|
| **Backend Service** | Must be running ([Setup Guide](#-backend-setup-required)) |
| **Flutter SDK** | v3.9.2 or higher |
| **Dart SDK** | Bundled with Flutter |
| **IDE** | Android Studio or VS Code with Flutter extensions |
| **Firebase Account** | For authentication services |
| **Gemini API Key** | For OCR functionality |

#### Installation Steps

**1. Install Flutter SDK (Windows)**

Download the latest stable release from the [Flutter SDK archive](https://docs.flutter.dev/release/archive) or [stable version](https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.38.5-stable.zip).

**Create a folder to store the SDK:**
- **Recommended path:** `%USERPROFILE%\develop` (e.g., `C:\Users\{username}\develop`)
- Select a location that **does not** have special characters or spaces and **does not** require elevated privileges

**Extract the SDK:**
```powershell
Expand-Archive `
  -Path $env:USERPROFILE\Downloads\flutter_windows_3.29.3-stable.zip `
  -Destination $env:USERPROFILE\develop\
```

**Add Flutter to your PATH:**
1. Press `Windows` and search for '**environment variables**'
2. Choose **Edit the system environment variables** → **Environment Variables...**
3. Under **User variables**, find or create the **Path** entry
4. Add the path to your Flutter `bin` directory (e.g., `%USERPROFILE%\develop\flutter\bin`)
5. Click **OK** three times and restart your terminal

**Validate your setup:**
```bash
flutter --version
dart --version
```

If these commands return version information, your installation is successful! If not, refer to the [Flutter installation troubleshooting](https://docs.flutter.dev/get-started/install/windows#troubleshooting) guide.

**2. Install Dependencies**

```bash
flutter pub get
```

**3. Configure Backend API Endpoint**

**Update the backend URL in the app:**

1. Open [lib/core/services/allergy_check_service.dart](lib/core/services/allergy_check_service.dart)
2. Replace the `_baseUrl` with your backend URL:
   ```dart
   static const String _baseUrl = 'YOUR_BACKEND_URL_HERE';
   ```
   - Use the Ngrok URL from backend setup (e.g., `https://your-ngrok-subdomain.ngrok-free.dev`)
   - Or use `http://localhost:8000` if testing on the same machine

**4. Configure Firebase**

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add Android/iOS apps to your Firebase project
3. Download `google-services.json` (Android) and place it in `android/app/`
4. Enable Firebase Authentication and Cloud Firestore in Firebase Console

**5. Set Gemini API Key**

The app requires a Gemini API key for OCR functionality. You can configure it in two ways:

**Option 1: Build-time configuration (recommended):**
```bash
flutter run --dart-define=API_KEY=your_gemini_api_key_here
```

**Option 2: Update the default value:**
Edit `lib/core/services/gemini_ocr_service.dart` and replace the default API key (not recommended for production).

**Get your Gemini API Key:**
1. Visit [Google AI Studio](https://aistudio.google.com/app/apikey)

   +) 1.1 Sign in Google account and proceed the next step
   +) 1.2 If you don't have an account, sign up and proceed the next step

2. Click on "Create API key" -> Click on "Select a Cloud Project" and click on the "+ Create Project" in the dropdown
3. Create a project
4. Generate an API key by naming your key and choose the newly created project
5. Copy the key by clicking in the button next to "Set up billing" 
6. Paste to the .env file

**6. Run the Application**

**Ensure the backend is running before starting the app!**

**For Android:**
```bash
flutter run
```

**For Release Build:**
```bash
flutter build apk --release --dart-define=API_KEY=your_api_key
```

The APK will be located at `build/app/outputs/flutter-apk/app-release.apk`

---

## 📱 Usage Guide

> **⚠️ CRITICAL:** Ensure the **ScAllergen Backend is running** before using the app.

### Application Flow 🔄

1. **Welcome/Authentication**
   - First-time users see a welcome screen
   - Login with email/password or Google Sign-In
   - Register new accounts with email verification

2. **Health Profile Setup**
   - Configure personal allergen list
   - Save dietary preferences
   - View allergen statistics

3. **Scan Ingredients**
   - Open the scanner from the home screen
   - Capture a photo of the ingredient list
   - Wait for OCR processing (Gemini AI extracts text)
   - Ingredients are sent to the backend for allergen matching

4. **View Results**
   - See matched allergens highlighted
   - View detailed allergen information
   - Get safety recommendations

5. **Browse News**
   - Read health and allergen-related articles
   - Stay updated on food safety news


### Backend Integration 🔗

**The app requires an active connection to the ScAllergen backend for full functionality.**

#### Backend Communication

| Component | Details |
|-----------|---------|
| **API Endpoint** | Configured in [lib/core/services/allergy_check_service.dart](lib/core/services/allergy_check_service.dart) |
| **Primary Endpoint** | `POST /check` |
| **Request** | User's allergen list + scanned ingredients |
| **Response** | Detailed allergen match results from graph querying |

#### How to Verify Backend Connection

1. **Check containers are running**
   ```bash
   docker compose ps  # In backend directory
   ```

2. **Verify backend health**
   - Visit `http://localhost:8000` (should return a health check message)

3. **Check Ngrok tunnel**
   - Visit `http://localhost:4040` to see the public URL

4. **Test API**
   - Use the backend's Swagger UI at `http://localhost:8000/docs`

---

## 🗂️ Project Structure
```
src/
├── lib/
│   ├── main.dart                               # Application entry point
│   ├── app/
│   │   └── app.dart                            # App widget configuration
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_quotes.dart                 # Motivational quotes
│   │   │   └── colors.dart                     # App color scheme
│   │   ├── models/
│   │   │   └── allergy_match_result.dart       # Data models
│   │   └── services/
│   │       ├── allergy_check_service.dart      # Backend API communication
│   │       ├── gemini_ocr_service.dart         # Google Gemini OCR integration
│   │       ├── gemini_allergen_translator.dart # Allergen translation
│   │       ├── gemini_warning_information.dart # Warning generation
│   │       ├── chart_update_service.dart       # Chart data management
│   │       ├── news_service.dart               # News feed service
│   │       └── theme_service.dart              # Theme management
│   └── features/
│       ├── auth/                               # Authentication screens
│       │   ├── login_screen.dart
│       │   └── register_screen.dart
│       ├── home/                               # Home and news screens
│       │   ├── main_home_screen.dart
│       │   ├── home_content_screen.dart
│       │   ├── header_widget.dart
│       │   ├── news_section.dart
│       │   └── news_detail_screen.dart
│       ├── profile/                            # User profile management
│       │   ├── profile_screen.dart
│       │   └── health_profile_screen.dart
│       ├── scanner/                            # OCR scanner feature
│       │   └── ocr/
│       │       └── result_screen.dart
│       └── welcome/
│           └── welcome_screen.dart             # Onboarding screen
├── assets/                                     # Static data files
│   ├── Allergy_*.csv                           # Allergen reference data
├── android/                                    # Android-specific configuration
│   ├── app/
│   │   ├── build.gradle.kts
│   │   ├── google-services.json                # Firebase config
│   │   └── src/main/AndroidManifest.xml
│   └── build.gradle.kts
├── ios/                                        # iOS-specific configuration
├── Dockerfile                                  # Docker image for APK build
├── build.bat                                   # Windows build script
├── build.sh                                    # Linux/macOS build script
└── pubspec.yaml                                # Flutter dependencies
```

---

## 🔐 Environment Configuration

### Required Variables

| Variable | Description | How to Obtain |
|----------|-------------|---------------|
| `API_KEY` | Google Gemini API key for OCR | [Google AI Studio](https://aistudio.google.com/app/apikey) |
| `_baseUrl` | Backend API endpoint URL | Ngrok URL from backend setup |
| `google-services.json` | Firebase configuration file | [Firebase Console](https://console.firebase.google.com/) |

### Configuration Locations

```dart
// Backend API URL
// File: lib/core/services/allergy_check_service.dart
static const String _baseUrl = 'YOUR_BACKEND_URL_HERE';

// Gemini API Key
// File: lib/core/services/gemini_ocr_service.dart
const String _apiKey = String.fromEnvironment('API_KEY',
    defaultValue: 'YOUR_GEMINI_API_KEY_HERE');
```

---

## 🆘 Troubleshooting

### Common Issues

<details>
<summary><b>Issue: Backend connection fails</b></summary>

- ✅ Verify backend is running: `docker compose ps` in backend directory
- ✅ Check `_baseUrl` in [allergy_check_service.dart](lib/core/services/allergy_check_service.dart)
- ✅ Ensure Ngrok tunnel is active: visit `http://localhost:4040`
- ✅ Test API endpoint: `http://localhost:8000/docs`
</details>

<details>
<summary><b>Issue: Google Gemini API errors</b></summary>

- ✅ Confirm `API_KEY` is valid and correctly set
- ✅ Check API quota and billing in [Google Cloud Console](https://console.cloud.google.com/)
- ✅ Verify API is enabled in your Google Cloud project
- ✅ Ensure no rate limiting is occurring
</details>

<details>
<summary><b>Issue: Firebase authentication fails</b></summary>

- ✅ Verify `google-services.json` is in `android/app/` directory
- ✅ Check Firebase Authentication is enabled in Firebase Console
- ✅ Ensure Cloud Firestore is properly configured
- ✅ Verify SHA-1 fingerprint is added to Firebase project (for Google Sign-In)
</details>

<details>
<summary><b>Issue: Docker build fails</b></summary>

- ✅ Ensure Docker Desktop is running
- ✅ Check all configuration files are in place before building
- ✅ Verify disk space is sufficient
- ✅ Try cleaning Docker: `docker system prune -a`
</details>

<details>
<summary><b>Issue: Flutter doctor shows errors</b></summary>

- ✅ Run `flutter doctor -v` for detailed diagnosis
- ✅ Install missing dependencies as suggested
- ✅ Ensure Android SDK is properly installed
- ✅ Check Java/JDK version compatibility
</details>

---

## 🔗 Useful Resources

- 📖 [Flutter Documentation](https://docs.flutter.dev/)
- 🎯 [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- 🔥 [Firebase for Flutter](https://firebase.flutter.dev/)
- 🤖 [Google Gemini API Docs](https://ai.google.dev/docs)
- 🐳 [Docker Documentation](https://docs.docker.com/)
- 🌐 [Neo4j Graph Database](https://neo4j.com/docs/)
- 📊 [FoodOn Ontology](https://foodon.org/)

---

## Contributors

This project was developed by group "Nem Chua":

- **Ngo Tien Binh** - Led the mobile application design and development of the user interface.

- **To Thanh Dat** - Led the overall system pipeline design and was primarily responsible for the development and evaluation of the Fuzzy matching algorithms.

- **Phung Anh Khang** - Contributed to the construction and refinement of the food ontology and the Graph query module, and assisted with data preparation and experimental evaluation.

- **Nguyen Hoang Phuc Thinh** - Led the development of the OCR, including the implementation of the Gemini 2.5 Flash API, and also contributed to the development of the mobile application interface.

---

## 📧 Contact & Support

- **GitHub**: [@tothanhdat2006](https://github.com/tothanhdat2006)
- **Frontend Repository**: [ScAllergen](https://github.com/tothanhdat2006/ScAllergen)
- **Backend Repository**: [ScAllergen-Backend](https://github.com/khangndct/ScAllergen-Backend)
- **Report Issues**: [GitHub Issues](https://github.com/tothanhdat2006/ScAllergen/issues)

---

## 🙏 Acknowledgments

- [FoodOn](https://foodon.org/) for food ontology

---

<div align="center">

**Made with ❤️ to help job seekers succeed**

⭐ Star this repo if you find it helpful!

</div>