# ScAllergen Mobile Application
![License](https://img.shields.io/badge/license-MIT-blue)

The mobile application for the ScAllergen system - A smart allergen detection app for food safety.

> **⚠️ IMPORTANT:** This is the **Frontend** of the application. The app also requires the **Backend** to be set up and running for allergen detection features to work. Please ensure you have completed the backend setup before using this app.
> 
> **Backend Repository:** [khangndct/ScAllergen-Backend](https://github.com/khangndct/ScAllergen-Backend)

## Table of Contents
- [Introduction](#introduction)
- [Backend Setup (Required)](#backend-setup-required)
- [Clone Repository](#clone-repository)
- [Installation Options](#installation-options)
  - [Option A: Docker Build](#option-a-docker-build)
  - [Option B: Manual Installation](#option-b-manual-installation)
- [Usage](#usage)
- [Project Structure](#project-structure)

## 1. Introduction
NutriViet is a Flutter-based mobile application that helps users identify potential allergens in food products through intelligent OCR scanning. The app captures ingredient lists from product labels and communicates with a **backend service** for fuzzy matching and graph-based allergen detection.

### System Architecture
This mobile app is the **frontend client** that works in conjunction with the **ScAllergen Backend** (Neo4j graph database + FastAPI server). The workflow is:
1. **Mobile App** captures and OCR scans ingredient photos using Gemini AI
2. **Mobile App** sends extracted ingredients to the **Backend API**
3. **Backend** performs fuzzy matching and graph traversal to detect allergens
4. **Mobile App** displays results and warnings to the user

Key features include:
- **Camera OCR:** Uses Google Gemini AI to extract and translate ingredient lists from product photos
- **Allergen Detection:** Sends ingredients to backend for graph-based allergen matching (requires backend)
- **User Profiles:** Manages user allergen preferences and health profiles
- **Real-time Alerts:** Provides instant warnings about potential allergen matches
- **Multi-language Support:** Automatically translates Vietnamese ingredients to English
- **News Feed:** Displays allergen-related health news and updates

### Technologies
- **Framework:** Flutter 3.9.2+ (Dart SDK)
- **AI/ML:** Google Generative AI (Gemini 2.5 Flash)
- **Authentication:** Firebase Auth
- **Database:** Cloud Firestore
- **Containerization:** Docker

## 2. Backend Setup (Required)

**Before installing the mobile app, you MUST set up and run the backend service.**

The backend handles:
- Fuzzy matching of ingredient names to the FoodOn ontology
- Graph-based allergen detection via Neo4j
- API endpoints for allergen checking

### Backend Setup Steps:

1. **Clone the backend repository:**
   ```bash
   git clone https://github.com/khangndct/ScAllergen-Backend.git
   cd ScAllergen-Backend
   ```

2. **Follow the complete backend setup instructions** in the backend repository's README:
   - Configure environment variables (Neo4j password, Ngrok token)
   - Build and start Docker containers
   - Initialize the database with FoodOn ontology
   - Verify backend is running

3. **Obtain the backend API URL:**
   - After starting the backend, get the public URL from Ngrok dashboard at `http://localhost:4040`
   - Or use `localhost:8000` if testing locally on the same machine
   - You'll need this URL to configure the mobile app

4. **Keep the backend running** while using the mobile app

> **📖 Full Backend Documentation:** [khangndct/ScAllergen-Backend](https://github.com/khangndct/ScAllergen-Backend)

---

## 3. Clone Repository

**Before proceeding with installation, clone the frontend repository:**

```bash
git clone https://github.com/tothanhdat2006/ScAllergen.git
cd ScAllergen/src
```

Now you can choose your preferred installation method:
- **[Option A: Docker Build](#option-a-docker-build)** - Recommended for quick APK generation without installing Flutter SDK
- **[Option B: Manual Installation](#option-b-manual-installation)** - For development and testing with Flutter SDK

---

## 4. Installation Options

### Option A: Docker Build

The application can be built using Docker for consistent cross-platform compilation without installing Flutter SDK locally.

#### Requirements
- **[Docker Desktop](https://docs.docker.com/desktop/)** (or Docker Engine)
- **✅ Backend Service Running** (See [Backend Setup](#backend-setup-required))
- **Firebase Configuration** (google-services.json)
- **Gemini API Key**

#### Configuration Before Building

Before building the Docker image, you must configure the required services:

**1. Configure Backend API Endpoint**

1. Open [lib/core/services/allergy_check_service.dart](lib/core/services/allergy_check_service.dart)
2. Replace the `_baseUrl` with your backend URL:
   ```dart
   static const String _baseUrl = 'YOUR_BACKEND_URL_HERE';
   ```
   - Use the Ngrok URL from backend setup (e.g., `https://your-ngrok-subdomain.ngrok-free.dev`)
   - Or use `http://10.0.2.2:8000` for Android emulator to access host machine's localhost

> **Note:** Docker builds create a standalone APK, so the backend URL must be hardcoded or configured before building.

**2. Configure Firebase**

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add an Android app to your Firebase project
3. Download `google-services.json` and place it in `android/app/`
4. Enable Firebase Authentication and Cloud Firestore in Firebase Console

**3. Configure Gemini API Key**

Edit [lib/core/services/gemini_ocr_service.dart](lib/core/services/gemini_ocr_service.dart) and replace the default API key:
```dart
const String _apiKey = String.fromEnvironment('API_KEY',
    defaultValue: 'YOUR_GEMINI_API_KEY_HERE');
```

**Get your Gemini API Key:**
1. Visit [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Sign in to your Google account (or create one if needed)
3. Click "Create API key" → "Select a Cloud Project" → "+ Create Project"
4. Create and name your project
5. Generate an API key and copy it
6. Paste it in the `gemini_ocr_service.dart` file

#### Build Steps

**Using Build Scripts:**

**On Windows:**
```bash
cd src
.\build.bat
```

**On Linux/macOS:**
```bash
cd src
chmod +x build.sh
./build.sh
```

The script will:
1. Build a Docker image with Flutter SDK
2. Compile the Flutter app into a release APK
3. Extract the APK to your current directory

The compiled `app-release.apk` will be available in the `src/` folder.

**Manual Docker Build:**

> **⚠️ Important:** The Docker build process uses the configurations you set above. Make sure all settings are correct before building, as they will be compiled into the APK.

```bash
cd src
docker build -t flutter-app .
docker create --name temp-container flutter-app
docker cp temp-container:/src/build/app/outputs/flutter-apk/app-release.apk .
docker rm temp-container
```

---

### Option B: Manual Installation

For developers who want to run and debug the app locally with Flutter SDK.

#### Requirements
- **✅ Backend Service Running** (See [Backend Setup](#backend-setup-required))
- **Flutter SDK** 3.9.2 or higher
- **Dart SDK** (bundled with Flutter)
- **Android Studio** or **VS Code** with Flutter extensions
- **Firebase Account** (for authentication services)
- **Google Gemini API Key**

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
1.1 Sign in Google account and proceed the next step
1.2 If you don't have an account, sign up and proceed the next step
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

## 5. Usage

> **⚠️ CRITICAL:** Ensure the **ScAllergen Backend is running** before using the app.

### 5.1 Application Flow

1. **Welcome/Authentication:**
   - First-time users see a welcome screen
   - Login with email/password or Google Sign-In
   - Register new accounts with email verification

2. **Health Profile Setup:**
   - Configure personal allergen list
   - Save dietary preferences
   - View allergen statistics

3. **Scan Ingredients:**
   - Open the scanner from the home screen
   - Capture a photo of the ingredient list
   - Wait for OCR processing (Gemini AI extracts text)
   - Ingredients are sent to the backend for allergen matching

4. **View Results:**
   - See matched allergens highlighted
   - View detailed allergen information
   - Get safety recommendations

5. **Browse News:**
   - Read health and allergen-related articles
   - Stay updated on food safety news

### 5.2 Backend Integration

**The app requires an active connection to the ScAllergen backend for full functionality.**

#### Backend Communication:
- **API Endpoint:** Configured in [lib/core/services/allergy_check_service.dart](lib/core/services/allergy_check_service.dart)
- **Primary Endpoint:** `POST /check`
  - Sends: User's allergen list + scanned ingredients
  - Receives: Detailed allergen match results obtained after graph querying


#### How to Verify Backend Connection:
1. Ensure backend containers are running: `docker compose ps` (in backend directory)
2. Check backend health: Visit `http://localhost:8000` (should return a health check message)
3. Verify Ngrok tunnel: Visit `http://localhost:4040` to see the public URL
4. Test API: Use the backend's Swagger UI at `http://localhost:8000/docs`

## Project Structure
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

