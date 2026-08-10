# Loom transcript via GraphQL

Loom's public GraphQL endpoint serves transcripts for link-shared videos — no auth, no download, no dependencies beyond curl. English only.

## 1. Metadata (title, author, date)

```bash
curl -s 'https://www.loom.com/graphql' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -H 'x-loom-request-source: loom_web_45a5bd4' \
  -H 'apollographql-client-name: web' \
  -H 'apollographql-client-version: 45a5bd4' \
  -d '{
    "operationName": "GetVideoSSR",
    "variables": {"id": "<VIDEO_ID>", "password": null},
    "query": "query GetVideoSSR($id: ID!, $password: String) { getVideo(id: $id, password: $password) { ... on RegularUserVideo { id name description createdAt owner { display_name } } } }"
  }'
```

## 2. Transcript URLs

```bash
curl -s 'https://www.loom.com/graphql' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -H 'x-loom-request-source: loom_web_45a5bd4' \
  -H 'apollographql-client-name: web' \
  -H 'apollographql-client-version: 45a5bd4' \
  -d '{
    "operationName": "FetchVideoTranscript",
    "variables": {"videoId": "<VIDEO_ID>", "password": null},
    "query": "query FetchVideoTranscript($videoId: ID!, $password: String) { fetchVideoTranscript(videoId: $videoId, password: $password) { ... on VideoTranscriptDetails { id video_id source_url captions_source_url } ... on GenericError { message } } }"
  }'
```

## 3. Download

Fetch `captions_source_url` (WebVTT, timestamped — preferred) with `curl -sL` into the cache dir as `transcript.vtt`; fall back to `source_url` (JSON segments) as `transcript.json`.

## Errors

- `GenericError` in the response: report its message (typically a private or password-protected video — out of v1 scope).
- Both URLs null: the video has no transcript — fall back to the mlx-whisper branch in `SKILL.md` step 3.
