---
name: watch
description: Watch a video — YouTube URL, Loom URL, or local file — by loading its transcript into context to discuss, summarize, or answer questions about it. Use when the user shares a video link and asks about its content, or supplies a verified transcript to check for drift.
argument-hint: [url-or-file] [verified-transcript-file]
---

# Watch

Bring a video's spoken content into context and work with it there. Transcript-first: frames are a separate, on-request branch.

## Vocabulary

- **Verified Transcript** — a human-checked transcript the user hands you (`.txt`, `.md`, `.vtt`, `.srt`, or pasted text). Ground truth: the text you reason over whenever it exists.
- **Auto Transcript** — captions or ASR text this skill fetches. Reasoned over only when no Verified Transcript exists.
- **Drift** — a material discrepancy between the two: a name, number, negation, or claim that differs. Filler words, punctuation, and casing are not Drift.

## Steps

1. **Resolve the source** and its cache id:
   - Loom: `loom.com/share/<id>` or `loom.com/embed/<id>` — the id is the 32-char hex segment.
   - YouTube: any URL yt-dlp accepts — the id is the 11-char video id.
   - Local file: an existing path — the id is the first 12 chars of `shasum -a 256 <file>`.

   A URL matching none of these (other platforms, login-gated video): tell the user it's outside this skill's v1 scope and stop.

2. **Check the cache.** If `~/.cache/watch/<id>/` already holds a transcript file, use it and skip step 3.

3. **Fetch the Auto Transcript** into `~/.cache/watch/<id>/`, by source:
   - **Loom** — the dependency-free GraphQL recipe in [LOOM.md](LOOM.md).
   - **YouTube** — `yt-dlp --skip-download --write-subs --write-auto-subs --sub-langs "<lang>.*" --sub-format vtt -P ~/.cache/watch/<id> -o transcript <url>` where `<lang>` is the video's language (default `en`). Manual subs beat auto subs when both land.
   - **No captions, or local file** — a Verified Transcript already in hand makes ASR pure waste: use it and skip this branch. Otherwise obtain audio (`yt-dlp -x -P ~/.cache/watch/<id> -o audio <url>`; a local file is used as-is) and transcribe on-device: `mlx_whisper <audio> --output-dir ~/.cache/watch/<id> --output-format vtt` (flags per `mlx_whisper --help` if rejected; the tool is installed by esetup — if missing, say so and point at `setup.sh` rather than installing it yourself).

   Done when the cache dir holds a transcript — or you have told the user the video has no obtainable transcript and stopped.

4. **Drift check** — only when a Verified Transcript exists *and* an Auto Transcript was fetched. Compare them and report every Drift, quoting both versions with timestamps; report "no drift" when clean. From here on, reason only over the Verified Transcript.

5. **Work with it.** Answer the question, discuss, or summarize — citing timestamps (`3:41`) so claims are checkable against the video.

## On request

- **Frames** — the user asks what's on screen, or the answer is visual: [FRAMES.md](FRAMES.md).
- **Notes** — the user asks to keep notes: persist them via the `/obsidian-vault` skill, and include the Drift report verbatim when one was produced.
