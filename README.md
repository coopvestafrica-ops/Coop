# Coopvest Africa Mobile App

A secure, scalable mobile application for Coopvest Africa cooperative financial services platform. Built with Flutter for both Android and iOS.

## 🎯 Overview

Coopvest Africa is a national cooperative platform focused on savings, loans, investments, and member-based financial services for salaried workers in African markets.

### Key Features

- **Secure Authentication** - Email/phone registration, biometric login, KYC verification
- **Wallet Management** - Track balance, contributions, transactions, and statements
- **Loan System** - Apply for loans with QR-based three-guarantor model
- **Guarantor System** - Innovative peer-to-peer loan guarantor verification
- **Investment Pool** - Participate in cooperative investment projects
- **Real-Time Tracking** - WebSocket-based progress updates
- **Offline Support** - Works seamlessly on low-bandwidth networks
- **Dark Mode** - Full light and dark theme support

## 🛠️ Technology Stack

### Frontend
- **Framework:** Flutter 3.16+
- **Language:** Dart 3.2+
- **State Management:** Riverpod 2.4+
- **Architecture:** Clean Architecture with MVVM

### Networking & API
- **HTTP Client:** Dio 5.3+
- **API Integration:** Retrofit 4.0+
- **JSON Serialization:** json_serializable 6.7+

### Storage & Security
- **Local Database:** SQLite 2.3+
- **Secure Storage:** flutter_secure_storage 9.0+
- **Encryption:** encrypt 5.0+
- **Biometric Auth:** local_auth 2.1+

### QR & Scanning
- **QR Generation:** qr_flutter 4.0+
- **QR Scanning:** mobile_scanner 3.5+

### Notifications
- **Push Notifications:** Firebase Cloud Messaging 14.6+
- **Local Notifications:** flutter_local_notifications 16.1+

### UI & Design
- **Design System:** Material Design 3
- **Typography:** Inter font family
- **Icons:** Material Design Icons + Custom

## 📁 Project Structure

```
lib/
├── config/                          # App configuration
│   ├── app_config.dart             # App constants
│   └── theme_config.dart           # Design system & themes
│
├── core/                            # Core utilities
│   ├── network/
│   │   └── api_client.dart         # API client with interceptors
│   └── utils/
│       └── utils.dart              # Validators, formatters, extensions
│
├── data/                            # Data layer
│   ├── models/
│   │   ├── auth_models.dart        # Authentication models
│   │   ├── wallet_models.dart      # Wallet models
│   │   └── loan_models.dart        # Loan models
│   └── repositories/
│       └── auth_repository.dart    # Authentication repository
│
├── presentation/                    # Presentation layer
│   ├── providers/
│   │   ├── auth_provider.dart      # Auth state management
│   │   ├── wallet_provider.dart    # Wallet state management
│   │   └── loan_provider.dart      # Loan state management
│   └── widgets/
│       └── common/
│           ├── buttons.dart        # Button components
│           ├── cards.dart          # Card components
│           └── inputs.dart         # Input components
│
└── main.dart                        # App entry point
```

## 🚀 Getting Started

### Prerequisites

- Flutter 3.16+ ([Install Flutter](https://flutter.dev/docs/get-started/install))
- Dart 3.2+
- Android Studio or Xcode
- Git

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/coopvestafrica-ops/Coop.git
cd Coop
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Generate code**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. **Run the app**
```bash
flutter run
```

## 📱 Building for Production

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🔐 Security Features

- ✅ AES-256 encryption for sensitive data
- ✅ HTTPS/TLS for all communications
- ✅ SSL certificate pinning
- ✅ Biometric authentication
- ✅ Secure token storage
- ✅ Session timeout (30 minutes)
- ✅ Device binding
- ✅ Jailbreak/root detection

## 📊 Design System

### Colors
- **Primary:** #1B5E20 (Coopvest Green)
- **Secondary:** #2E7D32
- **Tertiary:** #558B2F
- **Success:** #2E7D32
- **Warning:** #F57C00
- **Error:** #C62828

### Typography
- **Font Family:** Inter
- **Scale:** 11-point scale (Display, Headline, Body, Label)
- **Minimum Size:** 14px for body text

### Components
- Buttons (Primary, Secondary, Tertiary, Icon)
- Cards (Standard, Elevated, Outlined)
- Input Fields (Text, Dropdown, Checkbox, Radio)
- Modals & Dialogs
- Navigation (Bottom tabs, Top app bar)

## 🧪 Testing

### Run tests
```bash
flutter test
```

### Run with coverage
```bash
flutter test --coverage
```

## 📚 Documentation

- [Design System](./coopvest_design_system.md)
- [User Flows](./coopvest_user_flows.md)
- [Technical Architecture](./coopvest_technical_architecture.md)
- [QR System](./coopvest_qr_guarantor_system.md)
- [Implementation Guide](./COOPVEST_IMPLEMENTATION_GUIDE.md)
- [State Management](./STATE_MANAGEMENT_SETUP.md)

## 🤝 Contributing

1. Create a feature branch (`git checkout -b feature/amazing-feature`)
2. Commit your changes (`git commit -m 'Add amazing feature'`)
3. Push to the branch (`git push origin feature/amazing-feature`)
4. Open a Pull Request

## 📝 License

This project is proprietary and confidential. All rights reserved by Coopvest Africa.

## 👥 Team

- **Product:** Coopvest Africa Team
- **Development:** Flutter Development Team
- **Design:** UI/UX Design Team

## 📞 Support

For support, email support@coopvest.com or visit our website at https://coopvest.com

## 🗺️ Roadmap

### Phase 1: Foundation ✅
- [x] Project setup & design system
- [x] State management with Riverpod
- [x] API client & networking

### Phase 2: Authentication (In Progress)
- [ ] Login & registration screens
- [ ] KYC submission
- [ ] Biometric setup
- [ ] Session management

### Phase 3: Core Features
- [ ] Wallet & contributions
- [ ] Loan application
- [ ] QR-based guarantor system
- [ ] Real-time tracking

### Phase 4: Advanced Features
- [ ] Investment system
- [ ] Profile & settings
- [ ] Notifications
- [ ] Analytics

### Phase 5: Optimization
- [ ] Performance optimization
- [ ] Security audit
- [ ] User testing
- [ ] App store submission

## 📈 Performance Targets

- **App Startup:** < 2 seconds
- **Screen Load:** < 1 second
- **Animation FPS:** 60 FPS
- **Memory Usage:** < 150 MB
- **Battery Usage:** < 5% per hour

## 🔄 Version History

### v1.0.0 (Current)
- Initial project setup
- Design system implementation
- State management with Riverpod
- API client with interceptors
- Reusable component library

---

**Last Updated:** December 2025  
**Status:** Active Development  
**Maintainer:** Coopvest Africa Development Team
