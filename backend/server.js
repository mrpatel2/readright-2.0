import express from "express";
import cors from "cors";
import dotenv from "dotenv";

dotenv.config();

const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
const OPENAI_MODEL = process.env.OPENAI_MODEL || "gpt-4o-mini";
const PORT = process.env.PORT || 8787;

if (!OPENAI_API_KEY) {
  console.error("Missing OPENAI_API_KEY in backend/.env — refusing to start.");
  process.exit(1);
}

const app = express();
app.use(cors());
app.use(express.json());

// Dolch lists are all plain English words/short phrases — this shape also
// keeps the "words" field from being usable as a prompt-injection vector.
const WORD_PATTERN = /^[a-zA-Z][a-zA-Z' -]{0,19}$/;
const ALLOWED_GRADE_LEVELS = new Set([
  "prek",
  "kindergarten",
  "1st",
  "2nd",
  "3rd",
]);
const MAX_THEME_LENGTH = 80;

app.get("/health", (_req, res) => {
  res.json({ ok: true, model: OPENAI_MODEL });
});

// Proves the AI story path: Flutter app -> this proxy -> OpenAI mini-tier
// model -> story back. The proxy is the only thing that ever sees the key.
app.post("/api/story", async (req, res) => {
  const { words, theme, gradeLevel } = req.body ?? {};

  if (!Array.isArray(words) || words.length === 0) {
    return res.status(400).json({ error: "words must be a non-empty array of Dolch sight words" });
  }
  if (words.length > 12) {
    return res.status(400).json({ error: "words must be 12 or fewer per story" });
  }
  if (!words.every((w) => typeof w === "string" && WORD_PATTERN.test(w))) {
    return res.status(400).json({ error: "words must be plain Dolch sight words" });
  }
  if (gradeLevel !== undefined && !ALLOWED_GRADE_LEVELS.has(gradeLevel)) {
    return res.status(400).json({ error: `gradeLevel must be one of: ${[...ALLOWED_GRADE_LEVELS].join(", ")}` });
  }

  let cleanTheme;
  if (theme !== undefined) {
    if (typeof theme !== "string") {
      return res.status(400).json({ error: "theme must be a string" });
    }
    cleanTheme = theme
      .split("")
      .filter((ch) => {
        const code = ch.charCodeAt(0);
        return code >= 32 && code !== 127;
      })
      .join("")
      .trim()
      .slice(0, MAX_THEME_LENGTH);
  }

  try {
    // Content-safety guardrail #1: screen the teacher's own input before it
    // ever reaches the story prompt. Teacher-authored, but still free text.
    if (cleanTheme) {
      const inputFlagged = await isFlaggedByModeration(cleanTheme);
      if (inputFlagged) {
        return res.status(422).json({ error: "That interest/theme isn't appropriate for a children's story. Please try a different one." });
      }
    }

    const prompt = buildDolchStoryPrompt({ words, theme: cleanTheme, gradeLevel });

    const response = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${OPENAI_API_KEY}`,
      },
      body: JSON.stringify({
        model: OPENAI_MODEL,
        messages: [
          { role: "system", content: prompt.system },
          { role: "user", content: prompt.user },
        ],
        max_tokens: 300,
        temperature: 0.7,
      }),
    });

    if (!response.ok) {
      const detail = await response.text();
      console.error("OpenAI API error:", response.status, detail);
      return res.status(502).json({ error: "story generation failed upstream" });
    }

    const data = await response.json();
    const story = data.choices?.[0]?.message?.content?.trim();

    if (data.usage) {
      // Soft cost visibility — not a hard cap, just something to eyeball
      // during a session. See PRD_Milestone2.md section 5, cost risk.
      console.log(
        `[story usage] model=${OPENAI_MODEL} prompt=${data.usage.prompt_tokens} completion=${data.usage.completion_tokens} total=${data.usage.total_tokens}`,
      );
    }

    if (!story) {
      return res.status(502).json({ error: "model returned no story" });
    }

    // Content-safety guardrail #2: screen the model's own output before it
    // ever reaches a student's screen, regardless of how clean the input was.
    const outputFlagged = await isFlaggedByModeration(story);
    if (outputFlagged) {
      console.error("Generated story failed moderation check — withheld from client.");
      return res.status(422).json({ error: "Generated story didn't pass our content check. Please try generating again." });
    }

    res.json({ story, wordsRequested: words, model: OPENAI_MODEL });
  } catch (err) {
    console.error("Story generation failed:", err);
    res.status(500).json({ error: "internal error generating story" });
  }
});

/// Calls OpenAI's moderation endpoint (no extra cost, not the mini-tier
/// generation model) and returns true if the text was flagged. Fails closed:
/// if the moderation call itself errors, we treat the text as flagged rather
/// than silently skipping the safety check.
async function isFlaggedByModeration(text) {
  try {
    const response = await fetch("https://api.openai.com/v1/moderations", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${OPENAI_API_KEY}`,
      },
      body: JSON.stringify({ input: text }),
    });

    if (!response.ok) {
      console.error("Moderation call failed:", response.status, await response.text());
      return true;
    }

    const data = await response.json();
    return Boolean(data.results?.[0]?.flagged);
  } catch (err) {
    console.error("Moderation call errored:", err);
    return true;
  }
}

function buildDolchStoryPrompt({ words, theme, gradeLevel }) {
  const level = gradeLevel || "kindergarten";
  const topic = theme ? ` about ${theme}` : "";

  return {
    system:
      "You are a children's story writer for ReadRight, a literacy app for early readers. " +
      "You write very short, simple, wholesome stories that help kids practice Dolch sight words " +
      "in context. Content must be age-appropriate for a young child: no violence, scary content, " +
      "romance, real people, brand names, or advertising. Always write exactly 3-5 short sentences. " +
      "Use simple vocabulary appropriate for the requested grade level. Do not include a title, " +
      "headings, or any text besides the story itself. If asked to write about something " +
      "inappropriate for a young child, instead write a gentle, unrelated story using the same " +
      "sight words.",
    user:
      `Write a ${level}-level story${topic}. ` +
      `Naturally include as many of these Dolch sight words as possible: ${words.join(", ")}. ` +
      "Keep sentences short and concrete, the way an early reader would encounter them.",
  };
}

app.listen(PORT, () => {
  console.log(`ReadRight story proxy listening on http://localhost:${PORT}`);
});
