# ChatZone 💬

<div align="center">
🌍 Select Language / Pilih Bahasa: 
<a href="#" onclick="switchLanguage('en'); return false;">English</a> | 
<a href="#" onclick="switchLanguage('id'); return false;">Bahasa Indonesia</a>
</div>

<div id="en-content">

## 🚀 Overview

ChatZone is a simple and user-friendly chat application that enables seamless communication. It offers various key features such as messaging, status updates, communities, and calls. This application is integrated with the API available in the repository [ChatZone API](https://github.com/Resky89/ChatZone-api).

## ✨ Key Features

### 💭 Real-Time Messaging
- Instant message delivery
- Read receipts
- Typing indicators
- Media sharing capabilities

### 📱 Status Updates
- Share photos, videos, and text updates
- 24-hour visibility
- View counter
- Quick reactions

### 👥 Communities (Read-only)
- View available interest-based groups
- Browse group content
- See group members
- View upcoming events
> Note: Currently, features like creating groups, posting, and event planning are under development

### 📞 Calls (Read-only)
- View call history
- See missed calls
- Check call duration
- View participant lists
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

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Contact & Support

- **Issues**: [GitHub Issues](https://github.com/Resky89/ChatZone/issues)
- **Email**: support@chatzone.com
- **Discord**: [Join our community](#)

## 🙏 Acknowledgments

- Thanks to all our contributors
- Flutter team for the amazing framework
- Our amazing community of users

</div>

<div id="id-content" style="display: none;">

## 🚀 Ikhtisar

ChatZone adalah aplikasi obrolan yang sederhana dan ramah pengguna yang memungkinkan komunikasi yang lancar. Aplikasi ini menawarkan berbagai fitur utama seperti perpesanan, pembaruan status, komunitas, dan panggilan. Aplikasi ini terintegrasi dengan API yang tersedia di repositori [ChatZone API](https://github.com/Resky89/ChatZone-api).

## ✨ Fitur Utama

### 💭 Perpesanan Real-Time
- Pengiriman pesan instan
- Tanda terima dibaca
- Indikator mengetik
- Kemampuan berbagi media

### 📱 Pembaruan Status
- Bagikan foto, video, dan pembaruan teks
- Visibilitas 24 jam
- Penghitung tampilan
- Reaksi cepat

### 👥 Komunitas (Hanya Lihat)
- Lihat grup berbasis minat yang tersedia
- Jelajahi konten grup
- Lihat anggota grup
- Lihat acara mendatang
> Catatan: Saat ini, fitur seperti membuat grup, posting, dan perencanaan acara masih dalam pengembangan

### 📞 Panggilan (Hanya Lihat)
- Lihat riwayat panggilan
- Lihat panggilan tidak terjawab
- Cek durasi panggilan
- Lihat daftar peserta
> Catatan: Fitur panggilan aktif akan segera hadir

## 🛠️ Instalasi

### Prasyarat
- Flutter SDK (Versi stabil terbaru)
- Dart SDK
- Android Studio / VS Code
- Git

### Langkah-langkah Pengaturan

1. **Klon repositori**
   ```bash
   git clone https://github.com/Resky89/ChatZone.git
   cd ChatZone
   ```

2. **Instal dependensi**
   ```bash
   flutter pub get
   ```

3. **Konfigurasi lingkungan**
   ```bash
   cp .env.example .env
   # Edit .env dengan konfigurasi Anda
   ```

## 🚦 Menjalankan Aplikasi

1. **Mulai server pengembangan**
   ```bash
   flutter run
   ```

2. **Build untuk produksi**
   ```bash
   flutter build apk  # Untuk Android
   flutter build ios  # Untuk iOS
   ```

## 🔌 Integrasi API

ChatZone memerlukan API backend untuk berfungsi. Pastikan Anda telah:

1. Menyiapkan [ChatZone API](https://github.com/Resky89/ChatZone-api)
2. Memperbarui endpoint API di file `.env` Anda
3. Mengonfigurasi semua kunci dan token API yang diperlukan

## 🤝 Kontribusi

Kami sangat menghargai kontribusi! Berikut cara Anda dapat membantu:

1. Fork repositori
2. Buat branch fitur Anda
   ```bash
   git checkout -b feature/FiturLuar-Biasa
   ```
3. Commit perubahan Anda
   ```bash
   git commit -m 'Menambahkan FiturLuar-Biasa'
   ```
4. Push ke branch
   ```bash
   git push origin feature/FiturLuar-Biasa
   ```
5. Buka Pull Request

## 📝 Lisensi

Proyek ini dilisensikan di bawah Lisensi MIT - lihat file [LICENSE](LICENSE) untuk detail.

## 📞 Kontak & Dukungan

- **Masalah**: [GitHub Issues](https://github.com/Resky89/ChatZone/issues)
- **Email**: support@chatzone.com
- **Discord**: [Bergabung dengan komunitas kami](#)

## 🙏 Ucapan Terima Kasih

- Terima kasih kepada semua kontributor kami
- Tim Flutter untuk framework yang luar biasa
- Komunitas pengguna kami yang luar biasa

</div>

<script>
function switchLanguage(lang) {
    if (lang === 'en') {
        document.getElementById('en-content').style.display = 'block';
        document.getElementById('id-content').style.display = 'none';
    } else {
        document.getElementById('en-content').style.display = 'none';
        document.getElementById('id-content').style.display = 'block';
    }
}

// Set default language to English
window.onload = function() {
    switchLanguage('en');
}
</script>

---
