# GazProf - Professional Gas Delivery Management System

<div align="center">

![GazProf Logo](assets/logo_gazprof.png)

**A comprehensive Flutter application for managing gas bottle deliveries with real-time tracking, role-based access control, and push notifications.**

[![Flutter](https://img.shields.io/badge/Flutter-3.11.5+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11.5+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore%20%7C%20FCM-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![License: CC BY-NC-SA 4.0](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg?style=for-the-badge)](https://creativecommons.org/licenses/by-nc-sa/4.0/)

</div>

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Firebase Configuration](#firebase-configuration)
- [EmailJS Configuration](#emailjs-configuration)
- [Environment Variables](#environment-variables)
- [Running the App](#running-the-app)
- [User Manual](#user-manual)
  - [Authentication](#authentication)
  - [User Roles](#user-roles)
  - [Driver (Șofer) Features](#driver-șofer-features)
  - [Dispatcher (Dispecer) Features](#dispatcher-dispecer-features)
  - [Admin Features](#admin-features)
  - [Payment Types](#payment-types)
  - [Loyalty Card System](#loyalty-card-system)
- [Troubleshooting](#troubleshooting)
- [Project Structure](#project-structure)
- [Technologies Used](#technologies-used)
- [License](#license)

---

## Overview

GazProf is a professional gas delivery management system built with Flutter and Firebase. It provides a complete solution for gas distribution companies to manage orders, drivers, dispatchers, and customers in real-time.

The application supports multiple user roles with different permissions and features, ensuring secure and efficient workflow management.

**Key Capabilities:**
- Real-time order tracking and management
- Role-based access control (Admin, Dispatcher, Driver, Unassigned)
- Push notifications for new orders
- GPS navigation integration (Google Maps/Waze)
- Dark/Light theme support
- Multi-language support (Romanian)
- Secure authentication with email/password and Google Sign-In
- Password reset via OTP email verification

---

## Features

### Core Features
- **Secure Authentication** - Email/Password + Google Sign-In
- **Role-Based Access** - Admin, Dispatcher, Driver, Unassigned roles
- **Order Management** - Create, track, and manage delivery orders
- **Push Notifications** - Real-time FCM notifications for drivers
- **Navigation Integration** - Google Maps and Waze support
- **Theme Support** - Dark and Light mode
- **Statistics & Analytics** - Track deliveries, revenue, and performance
- **Multiple Payment Types** - Cash, Card, Invoice
- **Loyalty Card System** - Automatic discounts for loyal customers
- **Cross-Platform** - Android and iOS support

### Admin Features
- User management and role assignment
- Product catalog management
- Global order monitoring
- Financial statistics and reporting
- Order editing and cancellation

### Dispatcher Features
- Order creation and assignment
- Real-time order monitoring
- Driver notification system
- Order history with advanced filters

### Driver Features
- Order acceptance and delivery tracking
- Quick order creation for on-the-spot sales
- Navigation to customer addresses
- Customer contact integration
- Personal delivery statistics

---

## Requirements

### Development Environment
- **Flutter SDK**: 3.11.5 or higher
- **Dart SDK**: 3.11.5 or higher
- **Android Studio**: Latest version (for Android development)
- **Xcode**: Latest version (for iOS development - macOS only)
- **Git**: For version control

### System Requirements
- **Operating System**: Windows, macOS, or Linux
- **RAM**: 8GB minimum (16GB recommended)
- **Storage**: 10GB free space
- **Internet Connection**: Required for Firebase services

### Firebase Requirements
- Firebase account (free tier is sufficient for development)
- Firebase project with:
  - Authentication enabled
  - Firestore Database enabled
  - Cloud Messaging enabled

### EmailJS Requirements
- EmailJS account (free tier available)
- Email service configured (Outlook, Gmail, etc.)

---

## Installation

### Step 1: Clone the Repository

```bash
git clone https://github.com/dastian23/GazProf.git
cd GazProf
```

### Step 2: Install Dependencies

```bash
flutter pub get
```

This command downloads all required packages defined in `pubspec.yaml`.

### Step 3: Verify Installation

```bash
flutter doctor
```

This command checks your Flutter installation and reports any missing dependencies.

**Expected Output:**
```
[✓] Flutter (Channel stable, 3.11.5, on macOS)
[✓] Android toolchain
[✓] Xcode (if on macOS)
[✓] Android Studio
[✓] Connected device
```

Fix any issues reported by `flutter doctor` before proceeding.

---

## Firebase Configuration

Firebase is the backend service used for authentication, database, and push notifications.

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"** or **"Create a project"**
3. Enter project name: `GazProf` (or your preferred name)
4. Accept terms and click **"Continue"**
5. Disable Google Analytics (optional) or configure as needed
6. Click **"Create project"**
7. Wait for project creation to complete
8. Click **"Continue"**

### Step 2: Enable Authentication

1. In Firebase Console, go to **Build** → **Authentication**
2. Click **"Get started"**
3. Go to **Sign-in method** tab
4. Enable the following providers:

#### Email/Password Provider
- Click **"Email/Password"**
- Toggle **"Enable"** to ON
- Click **"Save"**

#### Google Sign-In Provider
- Click **"Google"**
- Toggle **"Enable"** to ON
- Enter support email (your email)
- Click **"Save"**

### Step 3: Enable Firestore Database

1. Go to **Build** → **Firestore Database**
2. Click **"Create database"**
3. Choose **"Start in test mode"** (for development)
   - **Production**: Choose "Start in locked mode" and configure security rules
4. Select server location (closest to your users)
5. Click **"Enable"**

**Important:** Test mode allows anyone to read/write to your database. Configure proper security rules before production deployment.

### Step 4: Enable Cloud Messaging

1. Go to **Build** → **Messaging**
2. Click **"Get started"** if prompted
3. Cloud Messaging is now enabled for your project

### Step 5: Add Android App

1. In Firebase Console, go to **Project Settings** (gear icon)
2. Scroll down to **"Your apps"** section
3. Click the **Android icon** (</>) to add Android app
4. Fill in the details:
   - **Android package name**: `com.example.gazprof`
   - **App nickname**: `GazProf` (optional)
   - **Debug signing certificate SHA-1**: (optional for now)
5. Click **"Register app"**
6. Download `google-services.json` file
7. Move the file to your Flutter project:
   ```bash
   mv ~/Downloads/google-services.json android/app/
   ```
8. Click **"Next"** → **"Next"** → **"Continue to console"**

### Step 6: Add iOS App (Optional)

1. In Firebase Console, go to **Project Settings**
2. Click the **iOS icon** to add iOS app
3. Fill in the details:
   - **iOS bundle ID**: `com.example.gazprof`
   - **App nickname**: `GazProf` (optional)
4. Click **"Register app"**
5. Download `GoogleService-Info.plist` file
6. Move the file to your Flutter project:
   ```bash
   mv ~/Downloads/GoogleService-Info.plist ios/Runner/
   ```
7. Open `ios/Runner.xcworkspace` in Xcode
8. Drag `GoogleService-Info.plist` into the Runner group
9. Click **"Next"** → **"Next"** → **"Continue to console"**

### Step 7: Generate Firebase Options

FlutterFire CLI automatically generates the `firebase_options.dart` file with your project configuration.

1. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. Run the configuration command:
   ```bash
   flutterfire configure
   ```

3. Follow the prompts:
   - Select your Firebase project
   - Select platforms (Android, iOS)
   - The CLI will generate `lib/firebase_options.dart`

**Note:** The `firebase_options.dart` file is excluded from Git for security reasons. Each developer must generate their own file.

### Step 8: Configure FCM for Push Notifications

Push notifications require a service account key encoded in base64.

1. In Firebase Console, go to **Project Settings** → **Service accounts** tab
2. Click **"Generate new private key"**
3. A JSON file will be downloaded (e.g., `gazprof-firebase-adminsdk-xxxxx.json`)
4. Encode the file to base64:

   **Linux/macOS:**
   ```bash
   base64 -i gazprof-firebase-adminsdk-xxxxx.json | tr -d '\n' > fcm_key_base64.txt
   ```

   **Windows (PowerShell):**
   ```powershell
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("gazprof-firebase-adminsdk-xxxxx.json")) | Out-File -Encoding ASCII fcm_key_base64.txt
   ```

5. Open `fcm_key_base64.txt` and copy the entire content
6. Paste it into your `.env` file as `FCM_SERVICE_ACCOUNT_BASE64`

---

## EmailJS Configuration

EmailJS is used to send password reset OTP (One-Time Password) emails to users.

### Step 1: Create EmailJS Account

1. Go to [EmailJS Sign Up](https://dashboard.emailjs.com/sign_up)
2. Create an account (free tier available)
3. Verify your email address

### Step 2: Add Email Service

1. Go to **Email Services** → **"Add New Service"**
2. Choose your email provider (Outlook, Gmail, etc.)
3. Connect your email account
4. Note the **Service ID** (you'll find this in your EmailJS dashboard)

### Step 3: Create Email Template

1. Go to **Email Templates** → **"Create New Template"**
2. Configure the template:

   **Subject:**
   ```
   Cod de resetare parolă GazProf: {{otp_code}}
   ```

   **Content:**
   ```html
   <h2>Cod de resetare parolă</h2>
   <p>Codul tău OTP este: <strong>{{otp_code}}</strong></p>
   <p>Acest cod expiră în 10 minute.</p>
   <p>Dacă nu ai solicitat resetarea parolei, ignoră acest email.</p>
   ```

   **To Email:** `{{to_email}}`
   **From Name:** `GazProf`
   **Reply To:** `{{to_email}}`

3. Save the template
4. Note the **Template ID** (you'll find this in your EmailJS dashboard)

### Step 4: Get User ID

1. Go to **Account** → **General**
2. Copy the **User ID** (Public Key) from your EmailJS dashboard

---

## Environment Variables

Environment variables store sensitive configuration data. They are loaded from the `.env` file at runtime.

### Step 1: Create .env File

Copy the example file:

```bash
cp .env.example .env
```

### Step 2: Configure Variables

Open `.env` in your text editor and fill in all required values.

**For detailed instructions on each variable, see `.env.example`**

The `.env.example` file contains:
- Complete list of all required environment variables
- Step-by-step instructions for obtaining each value
- Links to relevant dashboards and configuration pages
- Security notes and best practices

**Important:** Never commit `.env` to version control. It contains sensitive credentials.

### Step 3: Verify .env is Excluded

The `.env` file is already excluded from Git via `.gitignore`. Verify:

```bash
git status
```

The `.env` file should NOT appear in the list of tracked files.

**Security Note:** Never commit `.env` to version control. It contains sensitive credentials.

---

## Running the App

### Android

1. Start an Android emulator or connect a physical device:
   ```bash
   flutter emulators
   flutter emulators --launch <emulator_id>
   ```

2. Run the app:
   ```bash
   flutter run
   ```

3. Or specify a device:
   ```bash
   flutter run -d <device_id>
   ```

### iOS (macOS only)

1. Install CocoaPods dependencies:
   ```bash
   cd ios
   pod install
   cd ..
   ```

2. Start an iOS simulator or connect a physical device

3. Run the app:
   ```bash
   flutter run
   ```

### Build Release APK (Android)

```bash
flutter build apk --release
```

The APK will be located at `build/app/outputs/flutter-apk/app-release.apk`

### Build Release IPA (iOS)

```bash
flutter build ipa --release
```

The IPA will be located at `build/ios/archive/Runner.xcarchive`

---

## User Manual

### Authentication

#### Login

Users can log in using:
- **Email and Password**: Enter registered email and password
- **Google Sign-In**: One-tap authentication with Google account

**Login Screen Features:**
- Email validation
- Password visibility toggle
- "Forgot password?" link
- "Don't have an account? Register" link
- Rate limiting protection (5 failed attempts = 30 second lockout)

#### Registration

New users can create an account:
1. Enter full name
2. Enter email address
3. Enter phone number
4. Create password (minimum 6 characters)
5. Confirm password
6. Click "Register"

**After Registration:**
- Account is created with role: `neatribuit` (unassigned)
- User must wait for admin to assign a role
- User can edit personal data and change password while unassigned

#### Password Reset

If you forgot your password:
1. Click "Forgot password?" on login screen
2. Enter your registered email
3. Check your email for a 4-digit OTP code
4. Enter the OTP code in the app
5. Create a new password

**OTP Details:**
- Valid for 10 minutes
- Maximum 5 attempts
- 30-second lockout after failed attempts

---

### User Roles

The application has 4 user roles with different permissions:

| Role | Romanian | Permissions | Working Hours |
|------|----------|-------------|---------------|
| **Unassigned** | Neatribuit | View profile, edit personal data, change password | 24/7 |
| **Driver** | Șofer | Accept orders, deliver, create quick orders, view history | 07:00 - 01:00 |
| **Dispatcher** | Dispecer | Create orders, monitor all orders, edit orders, view history | 07:00 - 01:00 |
| **Admin** | Administrator | Full system access, user management, product management | 24/7 |

**Role Assignment:**
- New users start as `Unassigned`
- Only Admin can assign or change roles
- Role determines which screens and features are accessible

---

### Driver (Șofer) Features

#### Home Screen

The driver's home screen displays:
- **Statistics**: Available orders, accepted orders, delivered orders
- **Filters**: Filter by city (Oraș) or routes (Rute)
- **Quick Order Button**: Create a completed order instantly (for on-the-spot sales)
- **Available Orders List**: Orders waiting to be accepted

**Working Hours Restriction:**
- Orders can only be viewed and accepted between 07:00 - 01:00
- Outside these hours, a message "In afara programului" is displayed
- Drivers can still view profile and settings

#### Accepting an Order

1. Browse available orders on home screen
2. Tap on an order to view details
3. Tap "Acceptă comanda" (Accept order)
4. Order status changes to "Alocată" (Allocated)
5. Order appears in "Documente" (Documents) tab

#### Delivering an Order

1. Go to "Documente" tab to see allocated orders
2. Tap on an order to open details
3. Use available actions:
   - **Navigate**: Opens Google Maps or Waze with customer address
   - **Call Customer**: Direct phone call to customer
   - **Change Payment Type**: Switch between Cash/Card/Invoice
   - **Finalize**: Mark order as delivered
   - **Unassign**: Return order to waiting status
   - **Cancel**: Cancel the order

#### Quick Order Creation

For on-the-spot sales (customer calls and orders immediately):
1. Tap "Comandă rapidă" (Quick order) button
2. Fill in order details (customer, products, payment)
3. Order is created with status "Finalizată" (Completed)
4. Driver is automatically assigned
5. No waiting time - order is immediately completed

#### Order History

Access personal delivery history:
- Filter by date range (today, this month, this year, custom)
- Filter by address type (All, City, Routes)
- Search by address or phone number
- View statistics: Cancelled orders, Revenue collected, Orders created

#### Profile

- View and edit personal data (name, phone)
- Change password
- Choose default navigation app (Google Maps or Waze)
- Toggle dark/light theme
- Logout

---

### Dispatcher (Dispecer) Features

#### Home Screen

The dispatcher's home screen is focused on order creation:
- **Order Creation Form**: Full-featured form to create new orders
- **Working Hours**: Order creation only available 07:00 - 01:00

#### Creating an Order

1. Fill in customer details:
   - Phone number
   - Address
   - Building/Apartment (optional)
   - Address type: City (Oraș) or Routes (Rute)

2. Select products:
   - Choose from product catalog
   - Set quantity for each product
   - Adjust prices if needed (default prices from catalog)

3. Set payment type:
   - Cash
   - Card
   - Invoice (Factură) - total becomes 0 for later billing

4. Optional settings:
   - Loyalty card toggle (5 lei discount per bottle)
   - Notes for driver

5. Tap "Creează comanda" (Create order)
6. Order is created with status "În așteptare" (Waiting)
7. Drivers receive push notification

#### Monitoring Orders

Go to "Documente" (Documents) tab:
- View all today's orders (all statuses)
- Real-time updates via Firestore stream
- Filter by order status
- Tap on order to edit or view details

#### Editing Orders

Dispatchers can edit any order:
1. Open order from "Documente" tab
2. Modify any field (customer, products, payment, etc.)
3. Unassign driver (returns order to waiting status)
4. Send urgent notification to assigned driver
5. Save changes

#### Order History

Access global order history:
- View all completed and cancelled orders
- Filter by date range
- Filter by address type
- Search by address or phone
- View statistics: Cancelled orders, Revenue collected, Total orders

#### Profile

Same as Driver profile (personal data, password, navigation, theme, logout)

---

### Admin Features

#### Home Screen

The admin dashboard provides complete system overview:
- **Statistics**: Today's orders, Total users, Delivered orders
- **Quick Actions**: Assign roles, Create order
- **My Orders**: Orders allocated to admin (if admin also delivers)
- **Live Orders**: Real-time list of all today's orders
- **Users List**: Quick view of all users

#### User Management

Access via Profile → "Gestionare utilizatori" (Manage users):

**User List View:**
- Users split into two sections:
  - "FĂRĂ ROL ATRIBUIT" (No role assigned)
  - "UTILIZATORI ACTIVI" (Active users)
- Tap on user to assign or change role

**Assigning Role to New User:**
1. Tap on unassigned user
2. View user details (name, email, phone)
3. Select role: Driver, Dispatcher, or Admin
4. Tap "Atribuie rol" (Assign role)
5. User's role is updated immediately

**Changing User Role:**
1. Tap on active user
2. View current role
3. Select new role
4. Confirm change (shows role transition visualization)
5. User's role is updated

**Important:** Role changes take effect immediately. User must logout and login to see new interface.

#### Product Management

Access via Profile → "Setări produse" (Product settings):

**Product List:**
- View all products in catalog
- Products ordered by position
- Each product shows name and price

**Adding New Product:**
1. Tap "+" button
2. Enter product name
3. Enter price
4. Tap "Adaugă" (Add)
5. Product appears in catalog

**Editing Product:**
1. Tap on product
2. Modify name or price
3. Tap "Salvează" (Save)

**Deleting Product:**
1. Tap on product
2. Tap "Șterge" (Delete)
3. Confirm deletion

#### Creating Orders

Same as Dispatcher - full order creation form with all features.

#### Monitoring Orders

Admin can monitor all orders in real-time:
- Home screen shows live order list
- Tap on order to edit or view details
- Can unassign drivers
- Can send urgent notifications

#### Order History

Advanced filtering options:
- Filter by date range
- Filter by address type
- **Filter by specific user** (unique to Admin)
- Search by address or phone
- View comprehensive statistics

#### Profile

Admin profile includes all standard features plus:
- User management access
- Product settings access
- Admin statistics (users count, today's revenue, today's orders)

---

### Payment Types

Three payment types are available:

#### Cash
- Customer pays with cash upon delivery
- Full order amount is collected
- Revenue is tracked in statistics

#### Card
- Customer pays with credit/debit card
- Full order amount is collected
- Revenue is tracked in statistics

#### Invoice (Factură)
- For business customers who pay later
- **Order total is set to 0 lei**
- Used for tracking deliveries without immediate payment
- Invoice is issued separately
- Does NOT count towards daily revenue

**Changing Payment Type:**
- Driver can change payment type during delivery
- Useful if customer wants to switch from cash to card
- Admin/Dispatcher can also change it when editing order

---

### Loyalty Card System

The loyalty card system rewards customers with discounts.

**How it works:**
- When creating an order, toggle "Card fidelitate" (Loyalty card)
- System automatically applies **5 lei discount per bottle**
- Discount applies only to products with "Butelie" in the name
- Discount is applied to each bottle individually

**Example:**
- Order: 3x Butelie 11kg (115 lei each)
- Without loyalty card: 345 lei
- With loyalty card: 330 lei (15 lei discount)

**Important:**
- Loyalty card is optional (toggle per order)
- Discount is automatic (no manual calculation needed)
- Only applies to bottle products (not accessories)
- Discount is reflected in order total

---

## Troubleshooting

### Common Issues and Solutions

#### 1. Flutter Build Errors

**Error:** `Could not determine the dependencies of task ':app:compileDebugJavaWithJavac'`

**Solution:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

---

#### 2. Firebase Connection Issues

**Error:** `FirebaseException: [core/not-initialized] Firebase has not been correctly initialized`

**Solution:**
- Verify `google-services.json` is in `android/app/` directory
- Verify `GoogleService-Info.plist` is in `ios/Runner/` directory (iOS)
- Run `flutterfire configure` to regenerate `firebase_options.dart`
- Check Firebase project ID matches your configuration

---

#### 3. Authentication Errors

**Error:** `FirebaseAuthException: [invalid-email] The email address is badly formatted`

**Solution:**
- Check email format (must include @ and domain)
- Remove leading/trailing spaces
- Verify email is registered in Firebase Authentication

**Error:** `FirebaseAuthException: [wrong-password] The password is invalid`

**Solution:**
- Verify password is correct
- Check caps lock is off
- Use "Forgot password?" to reset if needed

---

#### 4. EmailJS OTP Not Sending

**Error:** OTP email not received

**Solution:**
- Check `.env` file has correct EmailJS credentials
- Verify EmailJS service is active (check dashboard)
- Check EmailJS dashboard for error logs
- Verify email template uses correct variables (`{{to_email}}`, `{{otp_code}}`)
- Check spam/junk folder
- Verify email service is connected to your email provider

---

#### 5. Push Notifications Not Working

**Error:** Drivers don't receive push notifications

**Solution:**
- Verify `FCM_SERVICE_ACCOUNT_BASE64` in `.env` is correct
- Check Firebase Cloud Messaging is enabled
- Verify device has internet connection
- Check device notification permissions (Android/iOS settings)
- For Android: Verify `google-services.json` is in `android/app/`
- For iOS: Verify push notifications capability is enabled in Xcode
- Check Firebase Console → Messaging for delivery status

---

#### 6. Firestore Permission Denied

**Error:** `FirebaseException: [firestore/permission-denied] Missing or insufficient permissions`

**Solution:**
- Check Firestore security rules (Firebase Console → Firestore → Rules)
- For development, use test mode rules:
  ```
  rules_version = '2';
  service cloud.firestore {
    match /databases/{database}/documents {
      match /{document=**} {
        allow read, write: if request.auth != null;
      }
    }
  }
  ```
- **Warning:** Test mode allows any authenticated user to read/write all data
- Configure proper rules for production

---

#### 7. App Crashes on Startup

**Error:** App crashes immediately after launch

**Solution:**
- Check `.env` file exists and has all required variables
- Verify no line breaks in base64 strings
- Check `flutter logs` for detailed error messages
- Run `flutter clean` and rebuild
- Verify all Firebase configuration files are present

---

#### 8. Navigation Not Opening

**Error:** Tapping "Navigate" doesn't open Google Maps or Waze

**Solution:**
- Verify Google Maps or Waze is installed on device
- Check app has location permissions
- For iOS: Verify URL schemes are configured in `Info.plist`
- Check user's navigation preference in profile settings

---

#### 9. Build Fails with "Multiple dex files" Error

**Error:** `Execution failed for task ':app:mergeDexDebug'`

**Solution:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

---

#### 10. Hot Reload Not Working

**Issue:** Changes don't appear after hot reload

**Solution:**
- Hot reload doesn't work for all changes (e.g., `main()` function)
- Use hot restart instead: Press `Shift + R` in terminal
- Or stop and restart the app

---

### Getting Help

If you encounter issues not covered here:

1. **Check Flutter documentation**: https://docs.flutter.dev
2. **Check Firebase documentation**: https://firebase.google.com/docs
3. **Search GitHub Issues**: https://github.com/dastian23/GazProf/issues
4. **Create new issue**: Provide detailed error message and steps to reproduce

---

## Project Structure

```
GazProf/
├── android/                    # Android-specific files
│   ├── app/
│   │   ├── src/
│   │   └── google-services.json  # Firebase Android config (not in Git)
│   └── build.gradle
├── ios/                        # iOS-specific files
│   ├── Runner/
│   │   └── GoogleService-Info.plist  # Firebase iOS config (not in Git)
│   └── Podfile
├── lib/                        # Main Dart code
│   ├── auth/                   # Authentication screens
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── forgot_password_screen.dart
│   │   └── otp_screen.dart
│   ├── core/                   # Core utilities and constants
│   │   ├── constants.dart      # App constants, enums
│   │   ├── theme_provider.dart # Theme management
│   │   └── user_provider.dart  # User state management
│   ├── screens/                # App screens organized by role
│   │   ├── admin/              # Admin screens
│   │   │   ├── home/
│   │   │   ├── profile/
│   │   │   ├── documente/
│   │   │   └── istoric/
│   │   ├── dispecer/           # Dispatcher screens
│   │   │   ├── home/
│   │   │   ├── profile/
│   │   │   ├── documente/
│   │   │   └── istoric/
│   │   ├── sofer/              # Driver screens
│   │   │   ├── home/
│   │   │   ├── profile/
│   │   │   ├── documente/
│   │   │   └── istoric/
│   │   ├── niciunul/           # Unassigned user screens
│   │   └── shared/             # Shared screens (all roles)
│   ├── services/               # Backend services
│   │   ├── auth_service.dart
│   │   ├── fcm_service.dart
│   │   └── notification_service.dart
│   ├── widgets/                # Reusable widgets
│   │   ├── app_nav_bar.dart
│   │   └── custom_widgets.dart
│   ├── main.dart               # App entry point
│   └── firebase_options.dart   # Firebase config (not in Git)
├── assets/                     # Images, icons, SVGs
│   ├── logo_gazprof.png
│   ├── app_icon.png
│   └── *.svg
├── .env                        # Environment variables (not in Git)
├── .env.example                # Environment template
├── .gitignore                  # Git ignore rules
├── pubspec.yaml                # Flutter dependencies
├── README.md                   # This file
└── LICENSE                     # CC BY-NC-SA 4.0 license
```

---

## Technologies Used

### Core Framework
- **Flutter 3.11.5+** - UI framework
- **Dart 3.11.5+** - Programming language

### Backend & Services
- **Firebase Authentication** - User authentication
- **Cloud Firestore** - NoSQL database
- **Firebase Cloud Messaging (FCM)** - Push notifications
- **EmailJS** - Email service for OTP

### State Management
- **Provider** - State management solution

### UI & Design
- **google_fonts** - Custom fonts
- **flutter_svg** - SVG rendering
- **Cupertino Icons** - iOS-style icons

### Device Integration
- **google_maps_flutter** - Google Maps integration
- **geocoding** - Address to coordinates conversion
- **url_launcher** - Open URLs (Maps, Waze, Phone)

### Storage & Preferences
- **shared_preferences** - Local key-value storage
- **flutter_dotenv** - Environment variables

### Notifications
- **flutter_local_notifications** - Local notifications
- **firebase_messaging** - Push notifications

---

## License

This project is licensed under the **Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License** (CC BY-NC-SA 4.0).

See the [LICENSE](LICENSE) file for details.

### What This Means

**You are free to:**
- ✅ Share — copy and redistribute the material in any medium or format
- ✅ Adapt — remix, transform, and build upon the material

**Under the following terms:**
- **Attribution** — You must give appropriate credit to the original author
- **NonCommercial** — You may not use the material for commercial purposes
- **ShareAlike** — If you remix, transform, or build upon the material, you must distribute your contributions under the same license

### Commercial Use

If you need to use this project for commercial purposes, please contact the author for a separate license agreement.

---

## Contact & Support

**Author:** dastian23

**Repository:** https://github.com/dastian23/GazProf

**Issues:** https://github.com/dastian23/GazProf/issues

---

<div align="center">

**Made with ❤️ using Flutter & Firebase**

If you find this project helpful, please consider giving it a ⭐ on GitHub!

</div>
