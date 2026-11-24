# 🗺️ Soulm8 Project Plan, Roadmap & Standards

This document serves as the master implementation plan, code standard guide, and AI Agent operational playbook for Soulm8.

---

## 1. Project Implementation Roadmap

### Phase 1: Foundation & Specifications (Current Phase)
- [x] Complete System Architecture (`docs/ARCHITECTURE.md`)
- [x] Complete Visual Flowcharts (`docs/FLOWCHARTS.md`)
- [x] Complete Database & API Specifications (`docs/SYSTEM_DESIGN_AND_DATABASE.md`)
- [x] Complete AI Memory & Personality Specs (`docs/AI_MEMORY_AND_PERSONALITY_SPEC.md`)
- [ ] Initialize Backend Project Structure (Node.js + TypeScript + Prisma + PostgreSQL)
- [ ] Initialize Flutter Mobile App Structure (Riverpod, GoRouter, Clean Feature-First)

### Phase 2: Authentication & Social Friend Hub
- [ ] Backend: JWT Auth, Registration, Login with Email or Phone
- [ ] Backend: User Profile Management, Friend Search by Phone/Email, Friend Connections
- [ ] Flutter: Loving visual design system (warm rose, deep plum, gentle lavender & dark mode palette)
- [ ] Flutter: Login & Registration screens with smooth animations and validation
- [ ] Flutter: Profile screen with friend search and add functionality
- [ ] Realtime WebSocket server & Flutter client integration for 1-on-1 human chat

### Phase 3: AI Companion Core & Multi-Tier Memory Engine
- [ ] Backend: LLM orchestration service (Google Gemini 1.5 Flash/Pro)
- [ ] Backend: 4-Tier Memory System (Pulse, Facts with conflict auto-superseding, Milestones, Summaries)
- [ ] Backend: Photo generation trigger & pipeline (Context-aware human face generator)
- [ ] Flutter: AI Chat screen with dynamic mode switcher (Romantic 🌹, Supportive 🌿, Mindful 🧘)
- [ ] Flutter: Memories Inspection & 1-Click GDPR Data Purge screen

### Phase 4: Offline Resilience & Zero-GPU Avatar
- [ ] Flutter: Local SQLite database integration (`sqflite`) for full offline caching
- [ ] Flutter: Offline Empathetic Companion Simulator (rule & intent matcher with local fact recall)
- [ ] Flutter: Zero-GPU procedural avatar renderer (Canvas/SVG layered face, hair, and wardrobe)
- [ ] Offline-to-online background synchronization queue

### Phase 5: Verification, Polish & Release Prep
- [ ] End-to-end integration testing for human messaging & AI streaming
- [ ] Security audit: Rate-limiting, token validation, memory sanitization
- [ ] Production build verification for Android and iOS

---

## 2. Senior Flutter Code Standards & Conventions

1. **Feature-First Clean Architecture**:
   - Every feature must be contained in its own directory with `presentation`, `domain`, and `data` layers.
   - Cross-cutting concerns belong strictly in `core/`.
2. **State Management with Riverpod**:
   - Use `AsyncNotifier` or `Notifier` with code generation or immutable state classes.
   - Never put business logic or API calls inside Flutter Widget classes.
3. **Design System & Aesthetics**:
   - Loving, emotionally soothing theme: warm peach, soft rose (`#FF6B8B`), comforting cream, deep slate dark mode.
   - Smooth micro-interactions: Hero transitions, subtle pulsing glow on companion avatar, fluid bubble chat animations.
4. **Resilience & Error Handling**:
   - All network calls must return `Result<T, Failure>` or handle exceptions explicitly.
   - Always fallback to local SQLite cache when network is unavailable.
5. **Linting & Code Quality**:
   - Strict analysis options with `flutter_lints` or `very_good_analysis`.

---

## 3. Backend (Node.js + Prisma) Code Standards

1. **Type Safety**: TypeScript `strict: true`. No implicit `any`.
2. **Database Integrity**: All data mutations handled via Prisma transactions (`prisma.$transaction`).
3. **Layered Separation**:
   - `controllers/`: HTTP & WebSocket request parsing and response formatting.
   - `services/`: Core business logic, memory conflict resolution, LLM prompt generation.
   - `repositories/`: Direct database queries via Prisma client.
4. **Environment Configuration**: Strictly validated using `dotenv` and `zod` schemas.

---

## 4. AI Agent Operational Playbook

*For future AI agents or developers updating or extending this codebase:*

1. **Before Modifying Features**:
   - Review `docs/FLOWCHARTS.md` and `docs/SYSTEM_DESIGN_AND_DATABASE.md` to ensure your change maintains relational integrity.
2. **Database Migrations**:
   - Always run `npx prisma migrate dev --name <migration_name>` when modifying `prisma/schema.prisma`.
   - Update `assets/db/migrations/` in the Flutter client if local SQLite tables are affected.
3. **Memory Engine Adjustments**:
   - If adding a new memory category or fact key, update the `MemoryCategory` enum in Prisma and the extraction prompt in the backend AI service.
4. **Zero-Downtime Verification**:
   - Whenever testing the AI chat, test both online mode and airplane mode to verify the local offline empathetic simulator activates seamlessly.
