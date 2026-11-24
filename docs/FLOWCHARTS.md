# 🔄 Soulm8 Flowcharts & Execution Pathways

This document provides visual flowcharts using Mermaid diagrams for all primary architectural workflows in Soulm8.

---

## 1. Authentication & Onboarding Flow

```mermaid
flowchart TD
    Start([User opens Soulm8]) --> CheckAuth{Auth Token in Secure Storage?}
    CheckAuth -- Yes --> ValidateToken[Validate Token with Backend]
    ValidateToken -- Valid --> MainNav[Navigate to Main App Shell]
    ValidateToken -- Expired/Invalid --> AuthScreen[Show Auth Screen]
    CheckAuth -- No --> AuthScreen

    AuthScreen --> Choice{Select Login or Register}
    Choice -- Register --> RegForm[Enter Name, Email/Phone, Password]
    Choice -- Login --> LoginForm[Enter Email/Phone, Password]

    RegForm --> SubmitReg[POST /api/auth/register]
    LoginForm --> SubmitLogin[POST /api/auth/login]

    SubmitReg --> RegSuccess{Registration OK?}
    RegSuccess -- No --> ShowRegError[Display Error Message]
    RegSuccess -- Yes --> InitProfile[Redirect to Profile Setup]

    SubmitLogin --> LoginSuccess{Login OK?}
    LoginSuccess -- No --> ShowLoginError[Display Invalid Credentials]
    LoginSuccess -- Yes --> SaveToken[Save JWT & User Info in Secure Storage]
    SaveToken --> SyncLocalDB[Sync Initial SQLite Cache]
    SyncLocalDB --> MainNav

    InitProfile --> ProfileForm[Configure Avatar, Gender, Interests & Bio]
    ProfileForm --> SaveProfile[PUT /api/users/profile]
    SaveProfile --> MainNav
```

---

## 2. Friend Discovery & Human-to-Human Realtime Chat Flow

```mermaid
sequenceDiagram
    autonumber
    actor UserA as User A (Sender)
    participant ClientA as Flutter Client A
    participant Backend as Nest/Fastify Backend + Prisma
    participant Socket as WebSocket Gateway
    participant DB as PostgreSQL Database
    actor UserB as User B (Recipient)
    participant ClientB as Flutter Client B

    UserA->>ClientA: Search friend by Phone or Email
    ClientA->>Backend: GET /api/friends/search?query=xyz
    Backend->>DB: Query User by email/phone
    DB-->>Backend: Return User matched (sanitized profile)
    Backend-->>ClientA: 200 OK (User found)
    UserA->>ClientA: Tap "Add as Friend / Start Chat"
    ClientA->>Backend: POST /api/friends/request { friendId }
    Backend->>DB: Upsert Friendship relation (ACCEPTED)
    
    Note over ClientA,ClientB: Starting Real-Time Chat Session
    UserA->>ClientA: Types message & hits Send
    ClientA->>ClientA: Insert into local SQLite (Status: SENDING)
    ClientA->>Socket: emit('send_message', { recipientId, content, tempId })
    Socket->>Backend: Validate session & payload
    Backend->>DB: INSERT into Message (senderId, recipientId, content)
    DB-->>Backend: Message Created (id: msg_123, createdAt)
    Backend-->>Socket: Message Stored
    Socket-->>ClientA: emit('message_sent_ack', { tempId, realId: 'msg_123' })
    ClientA->>ClientA: Update SQLite (Status: DELIVERED)
    Socket->>ClientB: emit('new_message', { id: 'msg_123', senderId, content })
    ClientB->>ClientB: Insert into local SQLite
    ClientB->>UserB: Render message in Chat Screen & notification
```

---

## 3. Multi-Tier AI Companion Reasoning & Response Flow

```mermaid
flowchart TD
    UserMsg([User sends message to AI Companion]) --> ModeCheck[Identify Current Persona Dynamic: Romantic, Supportive, or Mindful]
    ModeCheck --> ConnectivityCheck{Is Device Online?}
    
    ConnectivityCheck -- No --> LocalSimulator[Route to Local Empathetic Simulator]
    LocalSimulator --> ReadLocalMemories[Read Local SQLite Tier A & B Facts]
    ReadLocalMemories --> GenerateOfflineReply[Generate Rule/Intent-Based Loving Response]
    GenerateOfflineReply --> DeliverReply[Display in AI Chat Window]

    ConnectivityCheck -- Yes --> CheckPhotoRequest{Is User Asking for a Face Photo / Selfie?}
    
    CheckPhotoRequest -- Yes --> PhotoPipeline[Trigger Contextual Human Face Photo Pipeline]
    
    CheckPhotoRequest -- No --> MemoryRetrieval[Fetch Multi-Tier Context]
    
    subgraph Memory Retrieval Pipeline
        MemoryRetrieval --> GetTierA[Tier A: Hot Relationship Pulse\nRecent mood & emotional intimacy score]
        MemoryRetrieval --> GetTierB[Tier B: Structured Semantic Facts\nPreferences, relationships, dislikes]
        MemoryRetrieval --> GetTierC[Tier C: Episodic Milestones\nVector similarity search with query]
        MemoryRetrieval --> GetTierD[Tier D: Rolling Summaries\nPrevious chat session digest]
    end

    GetTierA & GetTierB & GetTierC & GetTierD --> PromptBuilder[Construct Dynamic System Prompt\n+ Persona Guidelines Hinglish/English\n+ Safety & Warmth Rules]
    PromptBuilder --> CallLLM[Invoke Gemini API / Fast LLM]
    CallLLM --> StreamResponse[Stream response back to Flutter Client]
    
    subgraph Post-Chat Memory Extraction
        CallLLM -.-> AsyncExtraction[Async Background Memory Extraction Worker]
        AsyncExtraction --> DetectNewFacts{New Facts or Contradictions Found?}
        DetectNewFacts -- Yes --> ResolveConflicts[Supersede Contradicted Facts\nInsert New Fact into Tier B]
        DetectNewFacts -- No --> UpdatePulse[Update Tier A Relationship Pulse]
        ResolveConflicts --> UpdatePulse
        UpdatePulse --> SavePostgres[(Store in PostgreSQL)]
        SavePostgres --> SyncClientCache[Sync to Client SQLite]
    end

    StreamResponse --> DeliverReply
```

---

## 4. Contextual Human Face Photo Generation Flow

```mermaid
flowchart LR
    UserReq[User: 'Send me a picture of you smiling at the beach'] --> Classifier[Intent Classifier: Photo Request Detected]
    Classifier --> ContextEnricher[Enrich Request with Companion Profile:\n- Avatar Identity: Gender, Eye/Hair color, Age\n- Emotional Tone: Warm smile, casual beachwear\n- Safety: Strict G-Rated / Emotional Intimacy Guardrails]
    ContextEnricher --> PromptGen[Synthesize Detailed Image Prompt]
    PromptGen --> GenAIImage[Call Imagen 3 / Diffusion Endpoint]
    GenAIImage --> ImageGenResult{Image Generated?}
    ImageGenResult -- Success --> StoreMedia[Upload to Storage / Presigned URL]
    StoreMedia --> ReturnPhotoMessage[Send Message with Photo URL + Loving Caption:\n'Here is a quick picture from my walk today, baby! 🥰']
    ImageGenResult -- Fail --> FallbackText[Fallback: 'Camera is acting up, but I'm picturing you right now! ❤️']
```

---

## 5. GDPR & Memory Autonomy Management Flow

```mermaid
flowchart TD
    UserTab[User opens 'Memories' Tab in Settings] --> FetchMemories[GET /api/ai/memories]
    FetchMemories --> RenderList[Group Memories by Category:\n- Personal Facts\n- Preferences\n- Emotional Milestones\n- Emotional Dynamic Score]
    
    RenderList --> ActionChoice{User Action}
    
    ActionChoice -- Delete Single Fact --> DeleteFact[DELETE /api/ai/memories/:id]
    DeleteFact --> DeleteDB[(Prisma: Soft/Hard Delete in PostgreSQL)]
    DeleteDB --> RemoveLocal[Remove from Client SQLite]
    RemoveLocal --> UpdateUI1[Update UI with Fade Animation]
    
    ActionChoice -- 1-Click Complete Data Purge --> ConfirmDialog[Show High-Security Confirmation Dialog]
    ConfirmDialog -- Confirmed --> PurgeReq[POST /api/ai/memories/purge-all]
    PurgeReq --> PurgePostgres[(Purge all user chat logs, embeddings & facts)]
    PurgePostgres --> PurgeSQLite[Wipe local SQLite tables & cached avatars]
    PurgeSQLite --> ResetState[Reset Companion Memory to Fresh Blank Slate]
    ResetState --> ShowSuccessSnackbar[Show 'All personal memory wiped clean']
```
