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

  const prompt = buildDolchStoryPrompt({ words, theme, gradeLevel });

  try {
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

    if (!story) {
      return res.status(502).json({ error: "model returned no story" });
    }

    res.json({ story, wordsRequested: words, model: OPENAI_MODEL });
  } catch (err) {
    console.error("Story generation failed:", err);
    res.status(500).json({ error: "internal error generating story" });
  }
});

function buildDolchStoryPrompt({ words, theme, gradeLevel }) {
  const level = gradeLevel || "kindergarten";
  const topic = theme ? ` about ${theme}` : "";

  return {
    system:
      "You are a children's story writer for ReadRight, a literacy app for early readers. " +
      "You write very short, simple stories that help kids practice Dolch sight words in context. " +
      "Always write exactly 3-5 short sentences. Use simple vocabulary appropriate for the " +
      "requested grade level. Do not include a title, headings, or any text besides the story itself.",
    user:
      `Write a ${level}-level story${topic}. ` +
      `Naturally include as many of these Dolch sight words as possible: ${words.join(", ")}. ` +
      "Keep sentences short and concrete, the way an early reader would encounter them.",
  };
}

app.listen(PORT, () => {
  console.log(`ReadRight story proxy listening on http://localhost:${PORT}`);
});
