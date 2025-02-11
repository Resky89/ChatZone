# ChatZone 💬

## 🚀 Overview

ChatZone is a simple and user-friendly chat application that enables seamless communication. It offers various key features such as messaging, status updates, communities, and calls. This application is integrated with the API available in the repository [ChatZone API](https://github.com/Resky89/ChatZone-api).

## ✨ Key Features

### 💭 Real-Time Messaging
- Instant message delivery
- Read receipts

### 📱 Status Updates
- Share photos and videos
- 24-hour visibility

### 👥 Communities (Read-only)
- View available interest-based groups
- SView participant
- View upcoming events
> Note: Currently, features like creating groups, posting, and event planning are under development

### 📞 Calls (Read-only)
- View call history
- See missed calls
- Check call duration
> Note: Active calling features are coming soon

## 🛠️ Installation

### Prerequisites
- Flutter SDK (Latest stable version)
- Dart SDK
- Android Studio / VS Code
- Git

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/Resky89/ChatZone.git
   cd ChatZone
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

## 🚦 Running the Application

1. **Start the development server**
   ```bash
   flutter run
   ```

2. **Build for production**
   ```bash
   flutter build apk  # For Android
   flutter build ios  # For iOS
   ```

## 🔌 API Integration

ChatZone requires our backend API to function. Please ensure you have:

1. Set up the [ChatZone API](https://github.com/Resky89/ChatZone-api)
2. Updated the API endpoint in your `.env` file
3. Configured all necessary API keys and tokens

## 🤝 Contributing

We love contributions! Here's how you can help:

1. Fork the repository
2. Create your feature branch
   ```bash
   git checkout -b feature/AmazingFeature
   ```
3. Commit your changes
   ```bash
   git commit -m 'Add some AmazingFeature'
   ```
4. Push to the branch
   ```bash
   git push origin feature/AmazingFeature
   ```
5. Open a Pull Request



