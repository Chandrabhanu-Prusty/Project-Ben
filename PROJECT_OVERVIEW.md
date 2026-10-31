# Project BEN: Personal AI Notification & Voice Assistant
> *"Your phone, your notifications, your personal AI assistant."*

---

## 1. What is Project BEN? (Purpose & Problem Statement)
Modern smartphone users receive dozens to hundreds of notifications every day across WhatsApp, Gmail, Slack, Telegram, and social media apps. Constantly context-switching, opening apps, and searching for urgent messages causes severe **notification fatigue** and leads to missed deadlines or critical emails.

**BEN** is an intelligent, voice-first mobile companion inspired by the **Omnitrix**. It consolidates, filters, and summarizes notifications and emails in real-time, allowing users to talk directly to their personal AI assistant hands-free—**without ever opening separate apps**.

---

## 2. Key Highlights & Capabilities

```
┌────────────────────────────────────────────────────────────────────────┐
│                        PROJECT BEN ARCHITECTURE                        │
├──────────────────────┬──────────────────────┬──────────────────────────┤
│  1. SYSTEM OVERLAY   │  2. AI INTELLIGENCE  │  3. PRIVACY & SECURITY   │
│  Floating Omnitrix   │  Groq LLM + Whisper  │  On-Device SQLite Cache  │
│  Works over any app  │  Instant STT & TTS   │  36-Hour Auto-Pruning    │
│  Hands-free voice    │  Masculine Voice     │  Supabase Auth & RLS     │
└──────────────────────┴──────────────────────┴──────────────────────────┘
```

1. **Floating Omnitrix Overlay (Outside-the-App Interaction)**:
   - A draggable Omnitrix dial floats over any running application (YouTube, Instagram, games, home screen).
   - Tapping the dial activates an on-screen voice card: Ben listens, queries the AI, and speaks the answer out loud—the user never gets kicked out of what they are doing.

2. **Hands-Free Voice-to-Voice Connection**:
   - Integrated native Speech Recognition and a deep, resonant masculine Text-to-Speech (TTS) voice engine.
   - Outputs are spoken immediately upon generation, eliminating the need to tap "Listen" manually.

3. **Smart Notification & Email Extraction**:
   - Intercepts incoming notifications as well as active status bar notifications.
   - Extracts multi-line email summaries from Gmail, Outlook, and other messaging apps.
   - Classifies alerts into **Urgent (Needs Attention)**, **Action Required**, and **Informational**.

4. **Siri / JARVIS-Style General Assistant**:
   - Not restricted to notifications: Ben is aware of local time and date, answering general questions (*"What is the time?"*, math, facts, advice, greetings).
   - Configurable salutations (*"Master"*, *"Sir"*, *"Ma'am"*) with loyal, sophisticated assistant demeanor.

5. **Strict 36-Hour Privacy Retention**:
   - Notification and chat histories are stored locally on the device in SQLite and automatically pruned after 36 hours.

---

## 3. Visual Showcase (Screenshots)

### 📸 Display 1: Startup & Visual Identity
> *Showcases the glowing animated 3D Omnitrix emblem on splash and the clean home feed.*

```
+------------------------------------------------------------------------+
|                                                                        |
|                 [ INSERT SCREENSHOT: SPLASH & LOGO ]                   |
|                (Animated Omnitrix dial + "BEN" title)                  |
|                                                                        |
+------------------------------------------------------------------------+
```

---

### 📸 Display 2: Smart Notification Digest & Dashboard
> *Demonstrates the AI Digest card, Urgent priority alerts, and multi-line email previews.*

```
+------------------------------------------------------------------------+
|                                                                        |
|              [ INSERT SCREENSHOT: DASHBOARD & DIGEST ]                 |
|           (Needs Attention feed + Smart AI notification pills)         |
|                                                                        |
+------------------------------------------------------------------------+
```

---

### 📸 Display 3: Hands-Free Floating Voice Assistant
> *Shows the floating Omnitrix overlay expanded on top of another app while speaking with Ben.*

```
+------------------------------------------------------------------------+
|                                                                        |
|         [ INSERT SCREENSHOT: FLOATING OVERLAY IN ACTION ]              |
|        (Floating Omnitrix card answering a query outside the app)      |
|                                                                        |
+------------------------------------------------------------------------+
```

---

## 4. Tech Stack Breakdown (For Junior Developers)

| Layer | Technologies Used | Role in Project |
|---|---|---|
| **Frontend UI** | Flutter & Dart | Cross-platform UI, dark green/black Omnitrix theme, reactive state management |
| **Native Android** | Kotlin, `WindowManager`, `Accessibility/NotificationListener` | Draggable floating overlay service, status-bar notification listener |
| **Speech & Audio** | Android `SpeechRecognizer` & `TextToSpeech` (TTS) | Low-latency voice capture and deep masculine voice synthesis |
| **AI Backend** | Groq Cloud API (`openai/gpt-oss-20b`, `whisper-large-v3-turbo`) | Sub-second natural language summarization and voice transcription |
| **Auth & Cloud** | Supabase (PostgreSQL, Row Level Security, Triggers) | Secure user authentication, profile sync, and password recovery |
| **Local Storage** | SQLite (`sqflite`), `SharedPreferences` | Encrypted on-device notification buffer with 36-hour TTL expiration |

---

## 5. Key Learning Takeaways for 2nd-Year Juniors
- **Bridging Flutter & Native Android**: How to use MethodChannels and Android Services (`SYSTEM_ALERT_WINDOW`) to build UI components that live outside Flutter's view hierarchy.
- **LLM Prompt Engineering with Structured JSON**: How to constrain AI outputs to strict schemas for seamless UI parsing and voice playback.
- **Privacy-by-Design Architecture**: Storing sensitive notification data on-device with automated time-to-live (TTL) expiration rather than pushing raw personal data to cloud servers.

