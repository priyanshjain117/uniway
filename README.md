# 📚 UNIWAY

A **Flutter**-based mobile application designed to make campus life smarter, easier, and more connected.  
The app integrates **campus navigation**, **home dashboard features**, and a **beautiful, responsive UI** optimized for all devices.

---

## ✨ Features

### 🏠 Home Dashboard
- Modern UI with **Google Fonts** and **Lottie animations** for a smooth, welcoming experience.
- Quick navigation to major app sections.
- Fully responsive with **flutter_screenutil** for consistent scaling.

### 🧭 Campus Navigation (Nami)
- Real-time navigation with **interactive maps** using `flutter_map`.
- **GPS-based location tracking** powered by `geolocator`.
- Voice-assisted turn-by-turn directions with **Text-to-Speech (TTS)**.
- Dynamic path calculation via **CampusNav API**.
- Supports route recalculations on-the-fly.

### 🌟 Additional Highlights
- **GetX** state management for reactive, organized code.
- **VelocityX** for rapid and elegant UI building.
- Modular, maintainable architecture for future feature expansion.
- Easily adaptable for other campuses or environments.

---

## 🛠️ Tech Stack

| Category       | Technology / Package |
|----------------|----------------------|
| Framework      | Flutter (Dart)       |
| State Mgmt     | GetX                 |
| UI/UX          | VelocityX, Google Fonts, Lottie Animations |
| Maps           | flutter_map, latlong2 |
| GPS            | geolocator           |
| Voice          | flutter_tts          |
| Networking     | http                 |

---

## 📂 Project Structure

```plaintext
lib/
├── core/
│   ├── home/
│   │   └── screens/
│   │       └── home_screen.dart
│   ├── nami/
│   │   ├── controllers/
│   │   │   └── navigation_controller.dart
│   │   ├── screens/
│   │   │   └── nami_main.dart
│   │   └── apis/
│   │       └── campus_nav_api.dart
│   └── common/
│       └── screens/
│           └── work_in_progress.dart
└── main.dart
