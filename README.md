# EstateTech 
**A Mobile app for Real Estate for the Brunei Market**

EstateTech is a high-end mobile application built with Flutter and Firebase, designed to solve the problem of scattered property information and limited visualization in Brunei. The system focuses on enhancing user decision-making through data science and immersive technology.

## Key Features
* **Contextual Recommendation Engine:** Real-time property ranking using Linear Regression weights derived from Kaggle House Price datasets.
* **Universal 360° VR Viewer:** A hybrid WebView architecture supporting immersive virtual walkthroughs from Kuula, Matterport, and Pannellum.
* **Geospatial Integration:** Precise property location picking and viewing via Google Maps SDK integration.
* **Real-time Communication Suite:** Professional messaging system featuring voice notes with recording timers and automated booking management.
* **Financial Decision Suite:** Airbnb-style rent affordability calculator integrated directly with the AI recommendation feed.

## Tech Stack
* **Frontend:** Flutter & Dart (State Management: Provider)
* **Backend:** Firebase (Authentication, Cloud Firestore, Storage)
* **Intelligence:** Python/Scikit-Learn (Offline Model Training) & Dart (On-device Inference)

## Project Structure
- lib/models/: Data models for Properties, Users, and Bookings.
- lib/services/: The logic layer, featuring the AI Engine (`ai_engine.dart`) and Notification services.
- lib/screens/: High-end UI modules including the Discovery Feed, 360 Tour, and Calculator.
- lib/widgets/: Reusable components such as Global User DPs and Custom Dashed Painters.

## Setup
1. Clone the repository.
2. Run flutter pub get.
3. Add your google-services.json (Android) or GoogleService-Info.plist (iOS) to the respective platform folders.
4. Build and run: flutter run.
