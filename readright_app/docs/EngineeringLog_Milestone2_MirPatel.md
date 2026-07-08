# ReadRight 2.0 — Milestone 2
### Mir Patel — Individual Engineering Log

**Date:** 2026-07-08

---

**1. Repo hygiene (blocking issue, found before any planned work could start)**

- Diagnosed why the freshly cloned team repo was effectively unusable: ~6,700 CocoaPods
  files (`ios/Pods`, `ios/.symlinks`) were committed to git, including symlinks with
  absolute paths from the original author's machine — broken for anyone else who clones the
  repo. The repo also lived on iCloud-synced Desktop, which was actively fighting git for
  the same files.
- Moved the project to `~/Developer` (outside iCloud sync). `git status` went from
  indefinite hangs to 1.3s.
- Rewrote `.gitignore` to the standard Flutter template (Pods, `.symlinks`, `ephemeral/`
  across iOS/macOS/Linux/Windows, `.dart_tool`, `*.env`) and untracked everything that
  should never have been committed, including a stray ephemeral Chrome browser profile
  (159 files) that had been swept into `.dart_tool` at some point.
- Left one pre-existing local change (`gradle-wrapper.properties`, a Gradle-version bump
  from a prior local Android Studio session) untouched — not mine to alter without knowing
  why it was there.

**2. Verified the inherited app actually builds under our team**

- `flutter pub get` — clean.
- `flutter build web` — succeeds (WASM dry-run warnings are pre-existing JS-interop
  packages, not errors).
- `pod install` on iOS — regenerated Pods cleanly against this machine's actual paths,
  confirming the dependency graph itself was fine once the broken committed symlinks were
  gone.
- Could not launch a live mobile simulator/emulator in this environment (no full Xcode.app,
  no Android SDK emulator installed here) — that verification still needs to happen on a
  machine with one configured.

**3. Built and proved the AI story de-risk spike**

- Stood up `backend/server.js`, a thin Node/Express proxy holding `OPENAI_API_KEY`
  server-side, exposing `POST /api/story` (Dolch-based prompt, `gpt-4o-mini`, input capped
  at 12 words / 300 response tokens as a cost guardrail).
- Wired `StoryService` + a minimal `StorySpikeScreen` into the Flutter app (reachable from
  the teacher dashboard) so the path is provable in the real app, not just via curl.
- Verified live: created a real teacher account through the actual signup flow, clicked
  through to the spike screen, generated a real story containing all requested Dolch words,
  confirmed zero console errors.
- Confirmed via `git log --all -p | grep` that the actual key value never touched git
  history at any point.

**4. Locked the M2 PRD**

- Extended the M1 Extension Proposal into an execution-ready PRD: MVP scope per pillar,
  explicit non-goals for this phase, architecture (including the documented pivot from the
  M1 plan's Firebase/Anthropic proxy to what we actually built), testing plan, and AI
  usage/risk assessment.
- Wrote the DMMT-style UX critique using three findings already verified in our own M1
  evaluation report against the actual inherited codebase (not findings about the other
  two candidate repos we didn't select).

**5. Backend proxy & secret-handling writeup**

- Wrote and rendered the required PDF: threat model (why embedding the key in the Flutter
  binary was the actual risk, demonstrated by what the inherited `.env`-as-asset pattern
  would have done with a real key), where the key lives now, how the proxy is structured,
  how it stays out of git across the team's workflow, and the known limitation (no proxy-side
  auth yet) with the M3 plan to close it.

**Still open going into M3:** we do not have our own Azure Speech key yet — pronunciation
assessment has no working provider behind it until we get one. Tracked in the PRD as a
prerequisite for the Section 3 fixes.
