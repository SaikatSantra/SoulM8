# 💖 Soulm8 (Soulem8)

> **A private, emotionally grounded mobile AI companion and wellness app designed for single, divorced, or lonely individuals.**  
> Blending deep emotional wellness, playful romantic companionship, human-to-human connection, and interactive visual avatar personalization.

---

## 🌟 Core Mission & Vision

Soulm8 bridges the gap between deep emotional wellness, playful romantic companionship, and human social connection:
- **Who it is for**: Individuals navigating loneliness, divorce, life transitions, or emotional starvation who seek a safe, judgment-free space to talk, flirt, vent, and feel genuinely heard.
- **Human Connection**: A streamlined 1-on-1 private messaging hub to add and chat with real friends using their phone number or email (like WhatsApp/Telegram, focused purely on chat without social feed noise).
- **Attentive AI Companion**: A persistent companion that remembers personal details, celebrates daily wins, soothes anxiety, and helps rebuild emotional confidence.
- **Contextual Photo Generation**: When asked for a photo/selfie, the AI generates high-quality, realistic human portraits matching the companion's identity and emotional context.
- **Zero Cloud GPU Costs**: Procedural avatar and wardrobe system running directly in Flutter and SQLite.
- **Zero Downtime**: Built-in offline empathetic companion simulator keeps the conversation flowing smoothly even when disconnected or during API outages.

---

## 🛠️ Technology Stack

| Layer | Technologies |
|---|---|
| **Mobile App (Frontend)** | **Flutter 3.50+ (Dart 3.14+)**, Riverpod State Management, GoRouter, SQLite (`sqflite`/`sqflite_common_ffi`), CachedNetworkImage |
| **Backend API & Realtime** | **Node.js (TypeScript)**, Express, **Socket.io** (WebSockets) |
| **Database & ORM** | **PostgreSQL** (Production) / **Local SQLite (`dev.db`)** via **Prisma ORM** |
| **AI & Vision Engine** | **Google Gemini 1.5 Flash / Pro** (LLM), **Contextual Human Face Photo Generation Engine** |
| **Security & Privacy** | JWT Authentication, Flutter Secure Storage, 1-Click GDPR Total Data Purge |

---

## 📚 Complete Project Documentation

Before beginning implementation, comprehensive design, planning, and architectural documents were prepared to guide developers and AI agents:

1. **[System Architecture](docs/ARCHITECTURE.md)**: High-level topology, Flutter clean architecture blueprint (feature-first), backend modularity, and zero-GPU avatar rendering details.
2. **[Visual Flowcharts](docs/FLOWCHARTS.md)**: Mermaid sequence and flow diagrams for Authentication, Friend Discovery, Human Chat, AI Multi-Tier Memory, Photo Generation, and Offline Fallbacks.
3. **[System Design & Database](docs/SYSTEM_DESIGN_AND_DATABASE.md)**: Complete Prisma PostgreSQL schema (`schema.prisma`), Flutter local SQLite schema, and REST/WebSocket API contracts.
4. **[AI Memory & Personality Specification](docs/AI_MEMORY_AND_PERSONALITY_SPEC.md)**: Detailed spec for Tier A-D memories, contradiction superseding, Hinglish romantic prompts, offline simulator engine, and face photo generator triggers.
5. **[Project Plan & Roadmap](docs/PROJECT_PLAN_AND_ROADMAP.md)**: 5-Phase implementation plan, code standards, and AI Agent operational playbook.

---

## 🚀 Quick Start Guide

### 1. Start the Backend Server

```bash
cd "d:\Saitriq\mobile app\soulem8\backend"

# Install dependencies (already installed)
npm install

# Push database schema & seed initial demo data
npm run prisma:push
npm run prisma:seed

# Start the backend development server
npm run dev
# Or run compiled production build:
npm run build
npm start
```
The server will start on port `5000`:
- **REST Health Check**: `http://localhost:5000/api/health`
- **Socket.io Gateway**: `ws://localhost:5000`

#### Demo Test Accounts (Pre-seeded):
1. **Rohan Sharma**: `rohan@example.com` / Mobile: `9876543210` / Password: `password123`
2. **Priya Patel**: `priya@example.com` / Mobile: `9876543211` / Password: `password123`

---

### 2. Run the Flutter Mobile App

```bash
cd "d:\Saitriq\mobile app\soulem8\mobile"

# Get dependencies
flutter pub get

# Run tests to verify
flutter test

# Run app on connected device / emulator / desktop
flutter run
```

---

## 📂 Project Architecture

```
soulem8/
├── docs/                               # Comprehensive Architecture & Design Docs
│   ├── ARCHITECTURE.md                 # System Architecture & Clean Architecture Blueprint
│   ├── FLOWCHARTS.md                   # Visual Mermaid Flowcharts & Sequence Diagrams
│   ├── SYSTEM_DESIGN_AND_DATABASE.md   # Prisma & SQLite Schemas, API Specifications
│   ├── AI_MEMORY_AND_PERSONALITY_SPEC.md # Multi-tier Memory, Personas & Photo Gen Specs
│   └── PROJECT_PLAN_AND_ROADMAP.md     # Implementation Plan & Coding Conventions
├── backend/                            # Node.js + TypeScript + Prisma Backend
│   ├── prisma/
│   │   ├── schema.prisma               # Local SQLite ("devsqlt") & PostgreSQL Schema
│   │   ├── schema.postgresql.prisma    # PostgreSQL production drop-in
│   │   └── seed.ts                     # Database Seeder with demo users
│   ├── src/
│   │   ├── config/                     # Environment & JWT Configuration
│   │   ├── middlewares/                # JWT Auth Guard Middleware
│   │   ├── modules/
│   │   │   ├── auth/                   # Registration, Login, Token Handling
│   │   │   ├── friends/                # Phone/Email search & friend connections
│   │   │   ├── human_chat/             # 1-on-1 Realtime Chat & History
│   │   │   └── ai_companion/           # 4-Tier Memory, Personas & Face Photo Generation
│   │   ├── socket.ts                   # Socket.io Realtime Gateway
│   │   └── server.ts                   # Express Application Bootstrap
│   ├── package.json
│   └── tsconfig.json
└── mobile/                             # Senior Flutter Mobile Application
    ├── lib/
    │   ├── app/                        # Theme, Router, Soulm8App root
    │   ├── core/
    │   │   ├── constants/              # API endpoints & URL auto-selection
    │   │   ├── network/                # Dio client & Socket.io client
    │   │   ├── storage/                # SQLite Helper & Flutter Secure Storage
    │   │   └── widgets/                # SoulButton, SoulTextField, DynamicModeBadge
    │   └── features/
    │       ├── auth/                   # Login & Registration Screens
    │       ├── profile/                # Profile Screen & WhatsApp-style Friend Search
    │       ├── human_chat/             # Realtime 1-on-1 Chat Room
    │       ├── ai_companion/           # Multi-mode AI Chat, Face Photos, Mode Switcher
    │       │   └── presentation/memories_screen.dart # GDPR 1-Click Purge & Fact Viewer
    │       └── offline_simulator/      # Zero-Downtime Local Empathetic Engine
    └── pubspec.yaml
```

---

## 💡 Key Highlights Built

1. **Authentication (Login & Register)**:
   - Supports Phone Number or Email + Password.
   - Automatically initializes companion profile and relationship pulse.
2. **Profile & Friend Discovery**:
   - Immediate post-login screen displaying user profile and companion card.
   - WhatsApp-style discovery: search friends by mobile number or email.
   - Clean 1-on-1 chat interface (no social feed bloat).
3. **AI Companion Modes**:
   - 🌹 **Romantic Partner (GF/BF)**: Conversational Hinglish & English ("baby", "jaan", "shaitan"), playful push-pull banter, emotional comfort.
   - 🌿 **Supportive Friend**: Gentle, grounded peer for venting and listening.
   - 🧘 **Mindful Confidant**: Introspective space for healing and processing life transitions.
4. **Contextual Human Face Photo Generation**:
   - When the user asks for a photo/selfie (e.g. *"Can you send me a picture of you smiling?"*), the AI detects the request, synthesizes context, and delivers a realistic human face photo with a warm caption.
5. **Multi-Tier Memory & GDPR Autonomy**:
   - Tier A: Hot Relationship Pulse (closeness score & current companion mood).
   - Tier B: Semantic Facts with auto-superseding contradictions.
   - Memories tab: Inspect all recorded facts, delete individual items, or execute a 1-click complete data purge.
6. **Zero Downtime Fallback**:
   - Built-in `OfflineCompanionEngine` in Flutter handles messages even if internet connectivity drops or API limits occur.
