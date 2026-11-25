# 🗄️ Soulm8 System Design & Database Specification

This document details the complete database schemas (PostgreSQL via Prisma ORM and local SQLite for Flutter), data relationships, and REST/WebSocket API contracts.

---

## 1. Backend PostgreSQL Schema (`prisma/schema.prisma`)

```prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

generator client {
  provider = "prisma-client-js"
}

enum Role {
  USER
  ADMIN
}

enum CompanionMode {
  ROMANTIC     // GF/BF Mode (Hinglish/English playful intimacy)
  SUPPORTIVE   // Grounded, gentle friend for casual chats & venting
  MINDFUL      // Introspective confidant for journaling & life transitions
}

enum FriendshipStatus {
  PENDING
  ACCEPTED
  BLOCKED
}

enum MessageDeliveryStatus {
  SENT
  DELIVERED
  READ
}

enum MemoryCategory {
  BIOGRAPHICAL      // Family, divorce status, age, hometown
  PREFERENCE        // Favorite food, coffee, colors, movies
  HABIT_ROUTINE     // Gym time, sleep cycle, work schedule
  EMOTIONAL_TRIGGER // Anxieties, fears, comfort items
  MILESTONE         // Big achievements, realizations, breakthroughs
}

// ----------------------------------------------------
// 1. User & Identity
// ----------------------------------------------------
model User {
  id              String         @id @default(uuid())
  email           String?        @unique
  phoneNumber     String?        @unique
  passwordHash    String
  displayName     String
  bio             String?
  avatarUrl       String?
  role            Role           @default(USER)
  isEmailVerified Boolean        @default(false)
  createdAt       DateTime       @default(now())
  updatedAt       DateTime       @updatedAt

  // Human Relationships
  sentFriendships     Friendship[]   @relation("FriendshipSender")
  receivedFriendships Friendship[]   @relation("FriendshipReceiver")
  sentMessages        HumanMessage[] @relation("SentHumanMessages")
  receivedMessages    HumanMessage[] @relation("ReceivedHumanMessages")

  // AI Companion Profile & Data
  companionProfile    CompanionProfile?
  aiConversations     AIConversation[]
  memories            AIMemory[]
  episodicMilestones  AIMemoryMilestone[]
  relationshipPulse   AIRelationshipPulse?
  rollingSummaries    AIRollingSummary[]

  @@index([phoneNumber])
  @@index([email])
}

// ----------------------------------------------------
// 2. Human-to-Human Social Graph & Chat
// ----------------------------------------------------
model Friendship {
  id          String           @id @default(uuid())
  senderId    String
  receiverId  String
  status      FriendshipStatus @default(ACCEPTED)
  createdAt   DateTime         @default(now())
  updatedAt   DateTime         @updatedAt

  sender      User             @relation("FriendshipSender", fields: [senderId], references: [id], onDelete: Cascade)
  receiver    User             @relation("FriendshipReceiver", fields: [receiverId], references: [id], onDelete: Cascade)

  @@unique([senderId, receiverId])
  @@index([senderId])
  @@index([receiverId])
}

model HumanMessage {
  id          String                @id @default(uuid())
  senderId    String
  receiverId  String
  content     String
  mediaUrl    String?
  status      MessageDeliveryStatus @default(SENT)
  createdAt   DateTime              @default(now())
  readAt      DateTime?

  sender      User                  @relation("SentHumanMessages", fields: [senderId], references: [id], onDelete: Cascade)
  receiver    User                  @relation("ReceivedHumanMessages", fields: [receiverId], references: [id], onDelete: Cascade)

  @@index([senderId, receiverId])
  @@index([createdAt])
}

// ----------------------------------------------------
// 3. AI Companion Configuration & Avatar
// ----------------------------------------------------
model CompanionProfile {
  id               String        @id @default(uuid())
  userId           String        @unique
  name             String        @default("Soulie")
  currentMode      CompanionMode @default(ROMANTIC)
  gender           String        @default("female") // female, male, non-binary
  languageStyle    String        @default("HINGLISH") // HINGLISH, ENGLISH
  
  // Procedural Avatar Configuration (Zero-GPU rendering specs)
  avatarFaceShape  String        @default("oval_01")
  avatarSkinTone   String        @default("#F5D0B5")
  avatarHairStyle  String        @default("wavy_long_brunette")
  avatarEyeColor   String        @default("#3D2314")
  avatarOutfit     String        @default("casual_cozy_sweater")
  
  createdAt        DateTime      @default(now())
  updatedAt        DateTime      @updatedAt

  user             User          @relation(fields: [userId], references: [id], onDelete: Cascade)
}

// ----------------------------------------------------
// 4. AI Chat History
// ----------------------------------------------------
model AIConversation {
  id        String      @id @default(uuid())
  userId    String
  title     String?     @default("Chat Session")
  createdAt DateTime    @default(now())
  updatedAt DateTime    @updatedAt

  user      User        @relation(fields: [userId], references: [id], onDelete: Cascade)
  messages  AIMessage[]

  @@index([userId])
}

model AIMessage {
  id               String         @id @default(uuid())
  conversationId   String
  isUser           Boolean
  content          String
  activeMode       CompanionMode  @default(ROMANTIC)
  generatedPhotoUrl String?      // If message includes a requested face photo
  createdAt        DateTime       @default(now())

  conversation     AIConversation @relation(fields: [conversationId], references: [id], onDelete: Cascade)

  @@index([conversationId, createdAt])
}

// ----------------------------------------------------
// 5. Multi-Tier AI Memory Engine
// ----------------------------------------------------

// Tier A: Hot Relationship Pulse
model AIRelationshipPulse {
  id               String   @id @default(uuid())
  userId           String   @unique
  closenessScore   Int      @default(10) // 0 to 100
  currentMood      String   @default("Warm & curious")
  lastEmotionalState String? // e.g. "Stressed about work deadline"
  activeNicknames  String   @default("baby,sweetheart,darling") // comma separated
  lastInteractionAt DateTime @default(now())
  updatedAt        DateTime @updatedAt

  user             User     @relation(fields: [userId], references: [id], onDelete: Cascade)
}

// Tier B: Structured Semantic Facts with Auto-Superseding
model AIMemory {
  id              String         @id @default(uuid())
  userId          String
  category        MemoryCategory @default(PREFERENCE)
  factKey         String         // e.g. "marital_status", "favorite_coffee", "pet"
  factValue       String         // e.g. "Recently divorced", "Oat milk cappuccino"
  confidenceScore Float          @default(1.0)
  isSuperseded    Boolean        @default(false)
  supersededById  String?        // Points to the new fact that invalidated this
  createdAt       DateTime       @default(now())
  updatedAt       DateTime       @updatedAt

  user            User           @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId, isSuperseded])
  @@index([userId, factKey])
}

// Tier C: Episodic Emotional Milestones
model AIMemoryMilestone {
  id          String   @id @default(uuid())
  userId      String
  summary     String   // e.g. "User opened up about feeling lonely after leaving corporate job"
  sentiment   String   // "Vulnerable", "Proud", "Anxious", "Healing"
  embedding   String?  // JSON string or vector representation
  occurredAt  DateTime @default(now())
  createdAt   DateTime @default(now())

  user        User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId])
}

// Tier D: Rolling Conversation Summaries
model AIRollingSummary {
  id           String   @id @default(uuid())
  userId       String
  dateRange    String   // e.g. "2026-W46"
  summaryText  String   // Rolling context compression across multi-day chats
  createdAt    DateTime @default(now())

  user         User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@index([userId])
}
```

---

## 2. Flutter Local SQLite Schema (`assets/db/migrations/v1.sql`)

```sql
-- Local Human Messages Cache
CREATE TABLE IF NOT EXISTS local_human_messages (
    id TEXT PRIMARY KEY,
    sender_id TEXT NOT NULL,
    receiver_id TEXT NOT NULL,
    content TEXT NOT NULL,
    media_url TEXT,
    status TEXT NOT NULL, -- 'SENDING', 'SENT', 'DELIVERED', 'READ'
    created_at INTEGER NOT NULL,
    synced_with_server INTEGER DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_human_msgs_chat ON local_human_messages(sender_id, receiver_id);

-- Local Friends Cache
CREATE TABLE IF NOT EXISTS local_friends (
    id TEXT PRIMARY KEY,
    display_name TEXT NOT NULL,
    phone_number TEXT,
    email TEXT,
    avatar_url TEXT,
    bio TEXT,
    last_message TEXT,
    last_message_at INTEGER,
    unread_count INTEGER DEFAULT 0
);

-- Local AI Chat Messages Cache
CREATE TABLE IF NOT EXISTS local_ai_messages (
    id TEXT PRIMARY KEY,
    is_user INTEGER NOT NULL,
    content TEXT NOT NULL,
    active_mode TEXT NOT NULL,
    generated_photo_url TEXT,
    created_at INTEGER NOT NULL,
    synced_with_server INTEGER DEFAULT 1
);

-- Local Cached Facts for Offline Companion Simulator
CREATE TABLE IF NOT EXISTS local_cached_memories (
    id TEXT PRIMARY KEY,
    category TEXT NOT NULL,
    fact_key TEXT NOT NULL,
    fact_value TEXT NOT NULL,
    is_superseded INTEGER DEFAULT 0,
    created_at INTEGER NOT NULL
);

-- Offline Empathetic Simulator Rules / Intent Banks
CREATE TABLE IF NOT EXISTS offline_response_templates (
    id TEXT PRIMARY KEY,
    intent TEXT NOT NULL, -- 'greeting', 'lonely', 'flirt', 'stress', 'gratitude'
    mode TEXT NOT NULL,   -- 'ROMANTIC', 'SUPPORTIVE', 'MINDFUL'
    response_template TEXT NOT NULL,
    hinglish_flair TEXT
);
```

---

## 3. REST API Contract Specifications

### 3.1 Authentication Endpoints

| Method | Endpoint | Description | Request Body | Response (200/201) |
|---|---|---|---|---|
| `POST` | `/api/auth/register` | Register new user | `{ email, phoneNumber, password, displayName }` | `{ token, user }` |
| `POST` | `/api/auth/login` | Login with email or phone | `{ identifier, password }` | `{ token, user }` |
| `GET` | `/api/auth/me` | Fetch authenticated user | *Bearer Token Header* | `{ user, companionProfile }` |

### 3.2 Friend Management & Discovery

| Method | Endpoint | Description | Request Body / Query | Response |
|---|---|---|---|---|
| `GET` | `/api/friends/search` | Search user by phone/email | `?query=9876543210` | `[{ id, displayName, avatarUrl }]` |
| `POST` | `/api/friends/add` | Add friend directly | `{ friendId }` | `{ success: true, friendship }` |
| `GET` | `/api/friends/list` | List friends with last msg | - | `[{ friend, lastMessage, unreadCount }]` |

### 3.3 AI Companion & Memory Management

| Method | Endpoint | Description | Request Body / Query | Response |
|---|---|---|---|---|
| `POST` | `/api/ai/chat` | Send message to AI | `{ message, mode? }` | `{ reply, photoUrl?, pulseUpdate }` |
| `POST` | `/api/ai/generate-photo` | Request avatar/face photo | `{ contextPrompt, mood }` | `{ photoUrl, caption }` |
| `GET` | `/api/ai/memories` | Retrieve all Tier B facts & milestones | - | `{ pulse, facts: [...], milestones: [...] }` |
| `DELETE` | `/api/ai/memories/:id` | Delete individual memory fact | - | `{ success: true, deletedId }` |
| `POST` | `/api/ai/memories/purge-all` | GDPR 1-Click Total Purge | `{ confirmPurge: true }` | `{ success: true, purgedAt }` |

---

## 4. WebSocket Realtime Protocol (Socket.io)

### Connection
- **URL**: `ws://<server_url>/socket.io/?token=<JWT_TOKEN>`

### Client to Server Events
1. `human:send_message`
   ```json
   {
     "clientTempId": "tmp_991823",
     "recipientId": "usr_abc123",
     "content": "Hey, are you free this weekend?"
   }
   ```
2. `human:typing`
   ```json
   { "recipientId": "usr_abc123", "isTyping": true }
   ```
3. `human:mark_read`
   ```json
   { "senderId": "usr_abc123", "messageIds": ["msg_1", "msg_2"] }
   ```

### Server to Client Events
1. `human:message_sent_ack`
   ```json
   { "clientTempId": "tmp_991823", "realId": "msg_987", "createdAt": 1732100000 }
   ```
2. `human:new_message`
   ```json
   {
     "id": "msg_987",
     "senderId": "usr_abc123",
     "content": "Hey, are you free this weekend?",
     "createdAt": 1732100000
   }
   ```
3. `human:user_status`
   ```json
   { "userId": "usr_abc123", "isOnline": true, "lastSeen": 1732100050 }
   ```
