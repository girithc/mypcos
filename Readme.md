# MyPCOS: Women's Health App for Managing PCOS

## Overview

MyPCOS is a comprehensive mobile application designed to help women manage Polycystic Ovary Syndrome (PCOS) and keep track of menstrual cycles. The app features an AI-powered assistant (RAG AI) that provides up-to-date information and personalized insights on PCOS, helping users better understand and manage their condition.

## Features

* **PCOS Management:** Track symptoms, menstrual cycles, and lifestyle changes.
* **AI Assistance:** Get personalized insights and information using RAG AI.
* **Period Tracking:** Log menstrual cycles and related symptoms.
* **Health Insights:** Receive tips on managing PCOS effectively.
* **Interactive UI:** User-friendly interface for seamless navigation.
* **Apple Sign-In:** Secure and convenient user authentication using Apple ID.

## Technology Stack

### Frontend (Mobile App)

* **Framework:** Flutter
* **Platform:** Android, iOS, Web, Desktop (Linux, MacOS, Windows)
* **UI:** Dart, Flutter UI Libraries
* **Authentication:** Apple Sign-In, Firebase Authentication

### Backend (API Server)

* **Framework:** FastAPI
* **Languages:** Python
* **Database:** Qdrant (for RAG storage), Supabase (PostgreSQL)
* **RAG Model:** GPT-4 via OpenAI API

## AI Assistant (RAG)

* Uses **Qdrant** for efficient storage and retrieval of health data.
* Powered by **OpenAI's GPT-4** for intelligent responses and recommendations.
* Real-time updates to provide the latest insights and guidelines for PCOS management.

## File Structure

```
mypcos/
├── mobile/
│   ├── android/                # Android-specific files
│   ├── ios/                    # iOS-specific files, including Apple Sign-In setup
│   ├── lib/                    # Flutter source code
│   ├── assets/                 # Images, icons, data files
│   ├── linux/                  # Linux desktop support
│   ├── macos/                  # MacOS desktop support
│   ├── web/                    # Web support
│   ├── windows/                # Windows desktop support
│   └── pubspec.yaml            # Flutter dependencies
├── server/
│   ├── app/                    # FastAPI application code
│   ├── Dockerfile              # Docker configuration
│   ├── requirements.txt        # Python dependencies
│   └── supabase_schema.txt      # Database schema for Supabase
```

## Getting Started

### Frontend (Mobile)

1. Clone the repository:

   ```bash
   git clone https://github.com/girithc/mypcos-1.git
   ```
2. Navigate to the mobile directory:

   ```bash
   cd mypcos-1/mobile
   ```
3. Install dependencies:

   ```bash
   flutter pub get
   ```
4. Run the app:

   ```bash
   flutter run
   ```

### Backend (Server)

1. Navigate to the server directory:

   ```bash
   cd mypcos-1/server
   ```
2. Create a virtual environment:

   ```bash
   python3 -m venv env
   source env/bin/activate
   ```
3. Install dependencies:

   ```bash
   pip install -r requirements.txt
   ```
4. Run the FastAPI server:

   ```bash
   uvicorn app.main:app --reload
   ```

## Apple Sign-In Integration

1. Set up your **Apple Developer account** and configure **Apple Sign-In** in the **Apple Developer Console**.
2. Integrate **Apple Sign-In** in your Flutter project using the `sign_in_with_apple` package.
3. Configure the necessary **OAuth credentials** and update your **Info.plist** file for iOS.

## Docker Deployment

To deploy the backend using Docker:

```bash
docker build -t mypcos-server .
docker run -d -p 8000:8000 mypcos-server
```

## Contributing

1. Fork the repository.
2. Create a new branch:

   ```bash
   git checkout -b feature/my-feature
   ```
3. Commit your changes:

   ```bash
   git commit -m "Add new feature"
   ```
4. Push to the branch:

   ```bash
   git push origin feature/my-feature
   ```
5. Create a
