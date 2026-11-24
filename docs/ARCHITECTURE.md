# 📐 Soulm8 System Architecture

## 1. High-Level Architecture Overview

Soulm8 is designed with a **privacy-first, hybrid cloud-local architecture**. It combines:
1. **A Senior-Grade Flutter Client**: Feature-first, clean architecture with local SQLite persistence for instant offline resilience, zero-GPU procedural avatar rendering, and multi-tier memory caching.
2. **A Node.js / TypeScript + Prisma Backend**: Micro-modular backend communicating with **PostgreSQL** for relational user data, friendships, human-to-human realtime chat, and centralized AI memory sync.
3. **Realtime WebSocket Gateway**: Instant, bi-directional 1-on-1 human communication and streaming AI responses.
4. **AI Companion & Memory Intelligence Layer**: Orchestrating LLMs (e.g., Google Gemini Pro / Flash), vector/semantic fact extraction, dynamic personality prompt engines, and Imagen/Diffusion face photo generators.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        FLUTTER CLIENT APPLICATION                     │
│                                                                        │
│  ┌──────────────────┐  ┌─────────────────────┐  ┌──────────────────┐  │
│  │ Presentation / UI│  │ Riverpod Controllers│  │ Repositories /   │  │
│  │ (Loving Theme,   │  │ & State Notifiers   │  │ Services Layer   │  │
│  │  Custom Avatars) │  │                     │  │                  │  │
│  └─────────┬────────┘  └──────────┬──────────┘  └─────────┬────────┘  │
│            └──────────────────────┼───────────────────────┘           │
│                                   ▼                                    │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │ Local Persistence & Offline Engine (SQLite / DevSQLite)          │  │
│  │ - Local Offline Companion Simulator (Zero Downtime)             │  │
│  │ - Wardrobe & Procedural Face Renderer (Zero Cloud GPU)           │  │
│  │ - Cached Multi-Tier Memories & Offline Chat History              │  │
│  └────────────────────────────────┬─────────────────────────────────┘  │
└───────────────────────────────────┼────────────────────────────────────┘
                                    │ HTTPS (REST) + WSS (WebSockets)
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                   BACKEND SERVICE (Node.js + TypeScript)               │
│                                                                        │
│  ┌───────────────────────┐                  ┌───────────────────────┐  │
│  │   Auth & User API     │                  │   Friend & Chat Hub   │  │
│  │  (JWT, Phone/Email)   │                  │ (WebSocket / SocketIO)│  │
│  └──────────┬────────────┘                  └───────────┬───────────┘  │
│             │                                           │              │
│             ▼                                           ▼              │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                      Prisma ORM Layer                            │  │
│  └────────────────────────────────┬─────────────────────────────────┘  │
│                                   │                                    │
│  ┌────────────────────────────────▼─────────────────────────────────┐  │
│  │                     PostgreSQL Database                          │  │
│  │   - Users & Profiles          - Human 1-on-1 Chat Messages       │  │
│  │   - Friendships & Contacts    - AI Conversations & Memory Store  │  │
│  └────────────────────────────────┬─────────────────────────────────┘  │
│                                   │                                    │
│  ┌────────────────────────────────▼─────────────────────────────────┐  │
│  │                 AI Companion & Orchestration Engine              │  │
│  │  - Personality Engine (Romantic, Supportive, Mindful)            │  │
│  │  - 4-Tier Memory Pipeline (Pulse, Facts, Episodes, Summaries)    │  │
│  │  - Conflict Resolution Engine (Auto-superseding facts)           │  │
│  │  - Contextual Human Photo Generation (Gemini Imagen/SDXL)        │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Flutter Mobile Application Architecture

The mobile app follows **Clean Architecture with Feature-First Folder Distribution**:

```
lib/
├── app/
│   ├── config/              # App themes, constants, route definitions
│   ├── observers/           # Riverpod state observers, route observers
│   └── soulm8_app.dart      # MaterialApp wrapper, global providers
├── core/
│   ├── errors/              # Custom exceptions, failure classes
│   ├── network/             # Dio client, WebSocket client, interceptors
│   ├── storage/             # SQLite database helper, secure storage (tokens)
│   ├── utils/               # DateTime formatters, validators, Hinglish parser
│   └── widgets/             # Reusable UI widgets (buttons, text fields, badges)
└── features/
    ├── auth/                # Login, Register, Phone/Email OTP, Auth state
    │   ├── data/            # Auth remote datasource, models
    │   ├── domain/          # Auth repository interfaces, user entities
    │   └── presentation/    # LoginScreen, RegisterScreen, auth_controller
    ├── profile/             # User profile, friend search, settings, GDPR purge
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    ├── human_chat/          # 1-on-1 real-time friend chat
    │   ├── data/            # Socket datasource, local cache sync
    │   ├── domain/          # Message entity, friend chat repository
    │   └── presentation/    # FriendsListScreen, ChatRoomScreen
    ├── ai_companion/        # Soulm8 AI chat, persona switcher, memory viewer
    │   ├── data/            # AI API client, local offline simulator
    │   ├── domain/          # AI persona models, memory models, conversation
    │   └── presentation/    # AIChatScreen, ModeSwitchModal, MemoriesScreen
    └── avatar_wardrobe/     # Zero-GPU procedural avatar customization
        ├── data/            # SVG asset manifests, style recipes
        ├── domain/          # Avatar state, wardrobe items
        └── presentation/    # AvatarCanvasView, WardrobeCustomizerSheet
```

---

## 3. Backend Technology Stack & Architecture

- **Runtime**: Node.js (v20+ LTS) with TypeScript for type safety.
- **Framework**: Fastify / Express with clean modular architecture.
- **ORM**: Prisma ORM with strongly typed schema queries and automated migrations.
- **Primary Database**: PostgreSQL (v15+) with `pgvector` extension for semantic memory embeddings.
- **Local Dev Database**: SQLite (`dev.db` via Prisma SQLite connector or dev PostgreSQL container).
- **Realtime Layer**: `Socket.io` or Native `ws` with JWT authentication handshake.
- **AI Integrations**:
  - LLM: Google Gemini 1.5 Flash / Pro (fast latency, long context window).
  - Image Generation: Google Imagen 3 / Stable Diffusion WebUI / Replicate API for contextual human face photos.
  - Text Embeddings: `text-embedding-004` (for Tier C episodic milestone vectors).

---

## 4. Key Design Decisions & Highlights

1. **Strict Separation of Human Chat vs. AI Chat**:
   - Human chat uses high-efficiency WebSocket duplex channels and is saved as standard end-to-end conversation logs.
   - AI companion chat routes through the **Memory & Personality Pipeline** before triggering an AI response.
2. **Zero Cloud GPU Avatar System**:
   - Instead of running costly server diffusion models for every avatar wardrobe change, Soulm8 renders vector-layered procedural avatars (facial shapes, skin tones, hairstyles, accessories, outfits) directly on the Flutter canvas using SVG paths and Canvas shaders.
3. **Contextual Human Face Photo Generation**:
   - When a user explicitly asks the AI for a selfie or photo (e.g. *"Can you send me a picture of you smiling at a cafe?"*), the prompt is routed to the image generation module. The prompt is enriched with the companion's gender, ethnicity, hair color, and emotional style to produce a consistent human portrait.
4. **Zero-Downtime Empathetic Companion Simulator**:
   - If the device loses internet connection or the cloud API hits quota limits, the Flutter client activates a local rule-and-intent based empathetic response engine (with pre-compiled conversational banks and local SQLite memory retrieval), maintaining the illusion of presence.
5. **Privacy & GDPR Compliance by Design**:
   - All memories stored about the user are queryable via `/api/ai/memories`. Users have full visibility and granular delete buttons, plus an instant "Purge Everything" button that deletes records from both PostgreSQL and SQLite.
