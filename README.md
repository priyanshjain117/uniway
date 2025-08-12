# 📚 UNIWAY — Your Smart Campus Companion

**UNIWAY** is a next-generation **Flutter** mobile application designed to make campus life **smarter, faster, and more connected**.  
It combines **real-time campus navigation**, a **personalized home dashboard**, and a **modern, responsive design** that adapts beautifully to any device.

## ✨ Features

### 🏠 Home Dashboard
- Sleek **Google Fonts** typography for a professional look
- Engaging **Lottie animations** for an interactive, welcoming experience
- Quick access to essential sections through a **minimal and intuitive UI**
- Fully responsive scaling with **flutter_screenutil** for consistent visuals on all devices

### 🧭 Campus Navigation — *Nami*
- **Live GPS tracking** with precise accuracy via `geolocator`
- Interactive campus maps powered by **flutter_map** and **latlong2**
- **Route optimization and navigation** powered by **open_route_service**
- **Voice-assisted turn-by-turn guidance** using **flutter_tts**
- Smart route recalculation when the user deviates from the path
- **Dynamic pathfinding** through the **CampusNav API** for the fastest possible routes

### 🌟 Additional Highlights
- **GetX** for reactive, clean, and scalable state management
- **VelocityX** for elegant and efficient UI building
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
│   ├── home_screen.dart
│   ├── nami/
│   │   ├── controllers/
│   │   │   └── navigation_controller.dart
│   │   ├── screens/
│   │   │   └── nami_main.dart
│   │   ├── widgets/
│   │   │   └── location_inputs.dart
│   │   └── apis/
│   │       └── campus_nav_api.dart
│   └── common/
│       └── screens/
│           └── work_in_progress.dart
└── main.dart

```
## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.27.1
- Dart 3.6.0
- An emulator or a connected physical device

### Installation
```
# Clone the repository
git clone https://github.com/priyanshjain117/uniway
cd uniway

# Install dependencies
flutter pub get

# Run the app
flutter run
```


## 🛡️ License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 👨💻 Author

**Priyanshu**  
Developer •  Designer •  Problem Solver

[GitHub](https://github.com/priyanshjain117) | [LinkedIn](https://www.linkedin.com/in/priyanshu-jain-995b08322/)

---

*Made with ❤️ for the campus community*
