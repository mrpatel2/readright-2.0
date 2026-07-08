# ReadRight 2.0 — Milestone 2
### Mir Patel — Prompt Log

---

**Entry 1: Diagnosing why the inherited repo was unusable (Claude Code)**

| | |
|---|---|
| **1. Context** | After cloning the team repo fresh, every `git status`/`git rm` call hung for minutes with no output. Needed to know whether this was a disk, network, or repo-content problem before doing any other M2 work, since nothing else could proceed with an unusable repo. |
| **2. Prompt Excerpt** | "check now" / directed investigation across several turns as symptoms surfaced — asked Claude to check disk space, running processes, and whether files were actually materialized locally after it flagged `ios/Pods` and `ios/.symlinks` as committed and the repo as living on iCloud-synced Desktop. |
| **3. AI Summary** | Claude found two compounding problems: (1) ~6,700 CocoaPods-generated files, including symlinks with absolute paths from the original author's machine, were committed to git; (2) the repo lived on `~/Desktop`, which is iCloud-synced, and `brctl status` showed iCloud actively contending for the same files git needed to read — confirmed by `.git/hooks/*` sample files showing 0 disk blocks (cloud-only placeholders never downloaded locally). |
| **4. Human Evaluation** | Verified independently rather than trusting the diagnosis outright: checked `df -h` myself to rule out disk space, watched process state (`ps -o pid,etime,pcpu,state`) to confirm commands were blocked on I/O (0% CPU) not actually computing, and asked pointed follow-up ("what background thing?", "how much longer") when the fix wasn't landing fast enough to just trust it was working. |
| **5. Final Decision** | Accepted the root-cause diagnosis, but overrode the first fix attempt — a plain `mv` off Desktop also hung on the same iCloud contention. Had Claude kill it and confirmed the underlying claim (iCloud, not disk) before retrying, rather than repeating the same broken approach. |
| **6. Testing / Verification** | After the move to `~/Developer/readright-2.0`, timed `git status` directly: 1.36s total, down from indefinite hangs (multiple 60s+ timeouts). Confirmed `ios/Pods`/`ios/.symlinks` tracked-file count dropped from 6,671 to 0 after cleanup. |

---

**Entry 2: Backend proxy architecture — resolving a conflict between the M1 plan and the actual issued key (Claude Code)**

| | |
|---|---|
| **1. Context** | The M1 Extension Proposal specified a Firebase Cloud Function calling Anthropic Claude. The `.env` actually sitting in the repo had an `OPENAI_API_KEY`, not an Anthropic key. Needed to resolve this before writing any proxy code, since the two architectures aren't interchangeable. |
| **2. Prompt Excerpt** | Asked directly which was authoritative: "stick to what he gave us which is already there im sure" (confirming OpenAI over the M1 plan's Anthropic assumption), and separately chose a local Node/Express proxy over a Firebase Cloud Function for the M2 spike specifically, to avoid deploy lead time before proving the path works. |
| **3. AI Summary** | Claude built `backend/server.js`, a ~90-line Express server with one endpoint (`POST /api/story`), holding `OPENAI_API_KEY` server-side only, calling the `gpt-4o-mini` mini-tier model with a Dolch-based prompt, capped at 12 words/300 tokens per request as a cost guardrail. |
| **4. Human Evaluation** | Did not accept "it compiles" as sufficient. Required proof at two levels: a raw `curl` call against the proxy with real Dolch words, then a full live browser session (Playwright-driven, screenshots reviewed at each step) creating a real teacher account and clicking the actual in-app button — not just testing the backend in isolation. |
| **5. Final Decision** | Accepted the architecture with one explicit caveat written into the PRD: the Node/Express proxy is locked for M2's spike; whether it becomes a deployed service or migrates to a Firebase Function for M3 is deferred, since the `/api/story` contract doesn't change either way. |
| **6. Testing / Verification** | Live end-to-end run: created a teacher account through the real signup flow, navigated to the new "AI Story Spike" screen, clicked "Generate test story," and confirmed a real story rendered in-app ("I am at the park. All my friends are here...") containing all 6 requested Dolch words, with zero browser console errors. |

---

**Entry 3: Drafting the locked PRD from the M1 proposal + M1 evaluation report (Claude Code)**

| | |
|---|---|
| **1. Context** | M2 requires a locked, execution-ready PRD covering all three pillars plus a DMMT-style UX critique of the inherited app. Rather than write the critique from scratch, had Claude pull from our own M1 evaluation report on Jaredburne47/4150ReadRight, which already contained specific, code-verified findings. |
| **2. Prompt Excerpt** | "do everything you can" (broad instruction to proceed through the remaining M2 deliverables), following review of the M1 Extension Proposal and M1 Evaluation Report PDFs pulled into context. |
| **3. AI Summary** | Claude selected three UX findings from the M1 evaluation specific to the actual inherited codebase (not the other two candidates that weren't chosen): the silent zero-score fallback, the fixed 3-second recording window, and unsurfaced per-word accuracy data — and reframed each as a concrete child/teacher hesitation scenario with a corresponding M3 fix. |
| **4. Human Evaluation** | Checked that the critique used only findings about the codebase we actually inherited (Project 2 / Jaredburne47), not findings from Project 1 or 3 that don't apply to our app — the Cupertino-widget critique from the M1 report, for example, was about a different candidate and was correctly left out. |
| **5. Final Decision** | Accepted the three selected findings and the architecture section's explicit note that the backend proxy plan changed from the M1 proposal (Firebase/Anthropic) to what was actually built (Node/Express/OpenAI), rather than letting the PRD silently contradict the earlier document. |
| **6. Testing / Verification** | Cross-referenced each UX critique bullet against the actual M1 evaluation report text to confirm no claims were invented beyond what our own prior evaluation had already verified in the code. |
