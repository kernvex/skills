# Frames

Give the conversation eyes: extract scene-change frames so visual content (screen recordings, demos, slides) can be Read as images beside the transcript.

## 1. Get the video into the cache

A local file is used where it is. For URLs:

```bash
yt-dlp -f "bv*[height<=720]/b[height<=720]/b" -P ~/.cache/watch/<id> -o "video.%(ext)s" <url>
```

(For Loom this is the one case that needs a download — the transcript never does.)

## 2. Extract scene-change frames

```bash
mkdir -p ~/.cache/watch/<id>/frames
ffmpeg -i ~/.cache/watch/<id>/video.* \
  -vf "select='gt(scene,0.3)',scale=512:-2" -fps_mode vfr \
  ~/.cache/watch/<id>/frames/%03d.jpg
```

Calibrate to land between ~10 and 100 frames:

- Over 100 (busy footage): raise the threshold to `0.4`.
- Under ~10 (static screencast): fall back to interval sampling — `-vf "fps=1/10,scale=512:-2"` — and cap at 100 frames.

## 3. Read them

Read the frames as images, in order. Frame filenames are sequential, not timestamps — anchor what you see to the transcript's timeline by content, and cite the transcript timestamp when describing a moment.
