# 💳 Wallet App

A feature-rich, production-ready **Flutter wallet & finance management app** built with clean architecture, real-time tracking, biometric security, and a premium dark-mode UI. Designed for Android, iOS, Web, and Desktop platforms.

---

## ✨ Features

### 🔐 Authentication & Security
- **Email & Password login** with form validation
- **Sign-up** with avatar customization
- **Biometric unlock** — supports Face ID, Touch ID, and Fingerprint (Android & iOS)
- **Account Recovery** — 7-day cooldown-based recovery flow with anti-abuse protection
- **Forgot Password** screen with identity verification
- **Audit Log** — every action (login, navigation, transaction, etc.) is recorded with timestamps

### 💰 Wallet & Finance Dashboard
- **Real-time balance** display with animated stats
- **Income vs. Expense** breakdown using beautiful `fl_chart` bar & line charts
- **Add Money** — top up your wallet balance with payment method selection
- **Send Money** — transfer to contacts with smart search
- **Pay Bill** — utility and service bill payments

### 📊 Transactions
- Full **transaction history** with date grouping
- Filter and search across all transactions
- Income & expense categorization with color-coded badges
- **CSV / PDF Export** support

### 💳 Cards Management
- Elegant **3D credit/debit card widget** with gradient designs
- **Manual card entry** screen with card number formatting, expiry & CVV validation
- **QR Scanner** — scan card QR codes using `mobile_scanner`
- Support for multiple cards with swipeable card carousel

### 🔔 Bill Reminders
- Create, edit, and delete **bill reminders** with due dates
- Local push notifications via `flutter_local_notifications`
- Timezone-aware scheduling with `flutter_timezone`
- Visual overdue and upcoming alerts

### 🎫 Tickets & Bookings
- Manage **Flight, Train, and Bus** travel tickets
- Ticket card UI with authentic **barcode rendering**
- View boarding pass image or **PDF ticket** attachment
- **Calendar Sync** — automatically import travel events from device calendar (Google / iCloud)
- Filter by Upcoming / History

### 🗺️ Live Journey Tracker
- **Real-time GPS tracking** using `geolocator` with hardware position streams
- **Haversine distance calculation** for accurate remaining distance
- **Dynamic intermediate stops** generated via geographic projection along the route
- **60+ Indian city coordinate database** (airport codes, railway station codes, city names)
- Real-time telemetry panel: Speed, Altitude (flights), Next Stop, Distance, ETA
- Simulation mode as fallback when GPS is unavailable
- Animated route canvas with progress indicator and pulsing vehicle icon
- "Mark as Completed" to archive the journey

### 📝 Notes
- Rich note-taking with title and body
- Attach images from gallery or camera
- Attach PDF files with in-app PDF viewer (`pdfrx`)
- Full-screen image viewer

### 👤 Profile
- Edit name, email, and avatar (camera / gallery)
- Save images to device gallery via `gal`
- Toggle **biometric authentication**
- **Dark / Light theme** toggle persisted across sessions
- View full **audit log** history
- Secure logout

### 🔗 Contacts
- Auto-import phone contacts via `flutter_contacts`
- Contact-based **send money** flow
- Permission handling for contacts access

### 🌍 Platforms Supported
| Platform | Status |
|----------|--------|
| Android  | ✅ Full support |
| iOS      | ✅ Full support |
| Web      | ✅ Full support (SQLite via sqflite_common_ffi_web) |
| macOS    | ✅ Desktop support |
| Linux    | ✅ Desktop support |
| Windows  | ✅ Desktop support |

---

## 🛠️ Tech Stack

| Category | Library / Tool |
|----------|---------------|
| Framework | Flutter (Dart SDK `^3.11.5`) |
| State Management | `provider ^6.1.2` |
| Local Database | `sqflite ^2.3.3` + `sqlite3_flutter_libs` |
| Web SQLite | `sqflite_common_ffi_web ^1.1.1` |
| Preferences | `shared_preferences ^2.3.2` |
| Charts | `fl_chart ^1.2.0` |
| Icons | `lucide_icons ^0.257.0` |
| Fonts | `google_fonts ^8.1.0` |
| Biometrics | `local_auth ^3.0.1` |
| Notifications | `flutter_local_notifications ^18.0.1` |
| Timezone | `timezone ^0.9.4` + `flutter_timezone ^5.0.2` |
| QR Scanner | `mobile_scanner ^6.0.0` |
| Camera | `camera ^0.11.0` |
| Image Picker | `image_picker ^1.1.2` |
| Contacts | `flutter_contacts ^2.0.2` |
| Permissions | `permission_handler ^12.0.1` |
| Location / GPS | `geolocator ^13.0.2` |
| Gallery Save | `gal ^2.3.2` |
| File Picker | `file_picker ^11.0.2` |
| PDF Viewer | `pdfrx ^2.4.1` |
| Calendar Sync | `device_calendar ^4.3.3` |
| HTTP Client | `http ^1.2.2` |
| Internationalization | `intl ^0.20.2` |

---

## 📁 Project Structure

```
lib/
├── main.dart                  # App entry point, MultiProvider setup, bootstrap logic
├── models/                    # Data models
│   ├── transaction.dart
│   ├── user.dart
│   ├── ticket_item.dart
│   ├── bill_reminder.dart
│   ├── note_item.dart
│   ├── contact.dart
│   ├── notification_item.dart
│   └── audit_log.dart
├── providers/                 # State management (ChangeNotifier)
│   ├── auth_provider.dart
│   ├── wallet_provider.dart
│   ├── transaction_provider.dart
│   ├── cards_provider.dart
│   ├── ticket_provider.dart
│   ├── bill_reminder_provider.dart
│   ├── note_provider.dart
│   ├── notification_provider.dart
│   ├── contact_provider.dart
│   ├── theme_provider.dart
│   ├── navigation_provider.dart
│   └── audit_log_provider.dart
├── repositories/              # Data persistence layer
│   └── preferences_repository.dart
├── services/                  # Business logic & external services
│   ├── auth_service.dart
│   ├── wallet_service.dart
│   ├── transaction_service.dart
│   ├── biometric_service.dart
│   ├── local_notification_service.dart
│   ├── notification_service.dart
│   ├── contact_service.dart
│   ├── calendar_sync_service.dart
│   └── api_client.dart
├── screens/                   # All app screens (23 screens)
│   ├── home_screen.dart
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── dashboard_view.dart
│   ├── transactions_view.dart
│   ├── cards_view.dart
│   ├── profile_view.dart
│   ├── send_money_screen.dart
│   ├── add_money_screen.dart
│   ├── pay_bill_screen.dart
│   ├── transactions_screen.dart
│   ├── bill_reminders_screen.dart
│   ├── scanner_screen.dart
│   ├── manual_card_entry_screen.dart
│   ├── tickets_view.dart
│   ├── add_ticket_screen.dart
│   ├── live_journey_tracker.dart
│   ├── loans_screen.dart
│   ├── note_detail_screen.dart
│   ├── notification_screen.dart
│   ├── partying_screen.dart
│   ├── forgot_password_screen.dart
│   └── account_recovery_screen.dart
├── widgets/                   # Reusable UI components
│   └── credit_card_widget.dart
└── theme/
    └── app_theme.dart         # Global theme, colors, gradients
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.11.5`
- Dart SDK `>=3.0.0`
- Android Studio / Xcode (for device targets)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/wallet_app.git
   cd wallet_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run on a device or emulator**
   ```bash
   flutter run
   ```

4. **Build release APK (Android)**
   ```bash
   flutter build apk --release
   ```

5. **Build for Web**
   ```bash
   flutter build web --release
   ```

---

## 📱 Permissions Required

### Android (`AndroidManifest.xml`)
- `INTERNET`
- `USE_BIOMETRIC` / `USE_FINGERPRINT`
- `CAMERA`
- `READ_CONTACTS`
- `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION`
- `READ_MEDIA_IMAGES`
- `RECEIVE_BOOT_COMPLETED` (notifications)
- `READ_CALENDAR` / `WRITE_CALENDAR`

### iOS (`Info.plist`)
- `NSFaceIDUsageDescription`
- `NSCameraUsageDescription`
- `NSContactsUsageDescription`
- `NSLocationWhenInUseUsageDescription`
- `NSPhotoLibraryUsageDescription`
- `NSCalendarsUsageDescription`

---

## 🎨 Design System

The app uses a custom design system defined in `app_theme.dart`:

| Token | Value |
|-------|-------|
| Primary Purple | `#7C3AED` |
| Accent Green | `#10B981` |
| Background Dark | `#0A0A0F` |
| Card Dark | `#12121A` |
| Text Grey | `#9CA3AF` |

- **Typography**: Google Fonts (system-wide)
- **Glassmorphism** bottom navigation bar with `BackdropFilter` blur
- **Animated** tab transitions using `AnimatedSwitcher` and `AnimatedPositioned`
- Fully supports **Dark & Light mode** with `ThemeProvider`

---

## 📸 Screenshots

> _Screenshots will be added soon._

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

Built with ❤️ using Flutter.
