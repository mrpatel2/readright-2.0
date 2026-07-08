# ReadRight 2.0 — Milestone 2 PRD (Locked)

**Team:** Mihir Patel, Mir Patel
**Base:** Jaredburne47/4150ReadRight, inherited and extended per the M1 Extension Proposal
**Status:** Locked at M2 — M3 is execution against this document, not discovery

---

## 1. Objective & MVP

**Phase objective.** Get the inherited app running under our own team/secrets, prove the AI
Story Builder pipeline works end to end through a backend proxy, and lock a specific,
buildable plan for all three pillars so M3 is implementation only.

**MVP for M3 (minimum required features per pillar):**

- **Pronunciation:** real local fallback (no more silent zero-score), adaptive recording
  duration by syllable count, per-word accuracy surfaced to the student.
- **AI Story Builder:** teacher picks a Dolch list + optional theme from the dashboard, gets
  a 3–5 sentence story with target words highlighted, story persists to Firestore.
- **Dolch games:** Fill the Blank (P0 — the MVP minimum) wired to the existing mastery/
  `AttemptRecord` model. Flash Dash (P1, added to the pillar in the latest Extension
  Proposal revision) is a stretch goal for M3 if Fill the Blank lands with time to spare —
  we are not committing to both as the M3 minimum bar, to avoid the exact scope creep this
  PRD exists to prevent.

**Explicitly NOT built this phase (M2):** the production Story Builder UI, either Dolch
game, per-word accuracy visualization, adaptive recording duration, or Azure integration
fixes. M2 delivers the proxy + one proven spike story only — see Section 5.

---

## 2. Architecture

**State management.** Unchanged from the M1 proposal: Provider stays, each new feature
(story builder, each game) gets its own `ChangeNotifier` rather than expanding existing
providers.

**Backend proxy — locked decision, revised from M1.** The M1 proposal called for a Firebase
Cloud Function between the app and Anthropic. Two things changed: the key actually issued
to us this term is an OpenAI key (`OPENAI_API_KEY`, mini-tier model `gpt-4o-mini`), not
Anthropic, and for the M2 de-risk spike we needed something we could stand up and prove in
hours, not a deployed cloud function. We built a thin Node/Express proxy
(`backend/server.js`) instead:

- `POST /api/story` — takes `{ words[], theme?, gradeLevel? }`, builds a Dolch-based prompt,
  calls the OpenAI mini-tier model, returns `{ story }`.
- The key lives only in `backend/.env` (gitignored), read via `process.env`. The Flutter app
  never sees it — see the separate proxy & secret-handling writeup for the full argument.
- `readright_app/lib/services/story_service.dart` calls the proxy over HTTP; platform-aware
  base URL (`10.0.2.2` for Android emulator, `localhost` elsewhere).

For M3, this proxy either gets deployed (Render/Railway/Fly.io — anything that holds an env
var and doesn't need a paid Firebase plan) or migrated into a Firebase Cloud Function if we
want everything on one platform. That choice is deferred; the `/api/story` contract will not
change, so either path is a deployment detail, not a rewrite.

**Data model.** Extend `Student`/`AttemptRecord` with a `source` field
(`pronunciation | fill_blank | story_reading`). New `StoryRecord` model in Firestore, one
document per generated story, owned at the `ClassRoom` level (teacher content, not student
content).

**No changes to:** auth flow, class/student management screens, accessibility service, or
the existing `Student`/`ClassRoom` Firestore shape.

---

## 3. DMMT-Style UX Critique of the Inherited App

Pulled from our own M1 evaluation of Jaredburne47/4150ReadRight, reframed as: where does a
child or teacher get stuck, and what do we do about it.

1. **A weak connection silently tells a child they failed.** `cloud_fallback_assessor.dart`
   returns a hardcoded zero score whenever Azure is unreachable — indistinguishable from
   actually mispronouncing the word. A child on a flaky classroom Wi-Fi gets "you got it
   wrong" for a network blip, not "try again." **Fix (M3):** replace the fallback with a
   real local score (string-similarity, matching Project 1's approach) or an honest "try
   again later" UI state — never a false failure.
2. **A single fixed recording window punishes longer words.** The 3-second cap is the same
   for "the" and "because." A child correctly saying a longer word gets cut off mid-word and
   scored on an incomplete recording — they did nothing wrong but the app tells them they
   did. **Fix (M3):** `WordTimingService` scales the window to syllable count.
3. **The app already has the data to help and doesn't show it.** Azure returns per-word/
   per-phoneme accuracy in the `NBest` response, and `AssessmentResult` captures it — but the
   student only ever sees pass/fail. A child who gets "wrong" has no idea which part of the
   word to fix, and a teacher can't coach anything specific from a single number. **Fix
   (M3):** a simple visual per-word breakdown instead of binary pass/fail.

---

## 4. Testing Plan

- **Proxy:** manual + scripted checks against `/api/story` — empty word list (400), >12
  words (400), valid request (200 with story containing requested words). No unit framework
  needed for a 60-line spike server; this graduates to `supertest` if the proxy grows in M3.
- **WordTimingService (M3):** unit tests over a syllable-count table (short/long/edge words
  like "the" vs "beautiful").
- **Fallback assessor (M3):** unit test asserting it never returns a hardcoded zero for
  non-empty audio input.
- **Regression:** existing auth flow, dashboard navigation, and word-list management get a
  manual smoke pass after each pillar lands, since none of the M2/M3 work should touch that
  code.
- **AI output validation:** for every generated story, check (a) all/most requested words
  present, (b) sentence count in range, (c) no obviously broken output (empty string, error
  text) before it's shown to a student.

---

## 5. AI Usage & Risks

**What stays human.** The teacher always chooses the word list and theme — the AI never
initiates generation or picks its own topic. We review real spike output before trusting the
prompt shape (done for M2: see the generated sample story in `backend/` testing notes).

**Validation.** Automated: word-count bound (≤12), sentence-count instruction in the prompt.
Manual: we read every story generated during the spike before calling the path "proven."

**Risk assessment.**
- *Schema risk:* low. `StoryRecord` is additive — no changes to `Student`/`ClassRoom`.
- *Concurrency risk:* low. The proxy is stateless; concurrent requests don't share mutable
  state.
- *Cost risk:* bounded by the 12-word cap and a 300-token response cap in `server.js`, mini-
  tier model only, per the course's hard requirement.
- *Regression risk:* low for M2 — the only touched existing file is
  `teacher_dashboard_screen.dart`, which gained one new nav card and nothing else.

**Open item before M3:** we do not yet have an Azure Speech key of our own — the inherited
`.env` never had one, and pronunciation assessment currently has no working provider behind
it. Getting our own Azure key (or course-provided equivalent) is a prerequisite for the
Pillar 1 fixes in Section 3, tracked separately from the AI story key.
