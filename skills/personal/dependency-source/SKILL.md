---
name: dependency-source
description: Check out a dependency's real source at the exact version in use and return the path to it. Use when you need to read a library's actual implementation — verifying what an API really does, tracing behaviour you can't explain, checking what changed between versions — rather than recalling it from memory. Not for general research or for libraries you already know well enough.
---

# Dependency Source

You are about to describe how a library behaves. You don't actually know — you remember a version, and the project is probably on a different one. Go read the source.

This skill **provisions a checkout and nothing else**. It resolves a library to a repo, works out which version this project uses, materialises that version as a git worktree under the research root, and hands back the path. It answers no questions. Reading the source is the caller's job — the one that made you reach for this in the first place.

Wanting an investigation written up instead? That's the `/research` skill.

## The four steps

### 1. Which repo

Resolve the package name to a git URL from **registry metadata only**:

| Ecosystem | Where the URL comes from |
| --- | --- |
| npm | `npm view <pkg> repository.url` |
| Go | the module path *is* the URL |
| Python | PyPI `project_urls` — frequently missing or pointing at docs |
| Rust | `cargo info <crate>`, `repository` field |

If metadata is absent, or the value doesn't look like a git host, **stop and ask for the URL**. Never search the web for it, never guess `github.com/<name>/<name>`, never take the first plausible hit. A guessed URL lands you in a fork or an abandoned mirror, and you then read source that doesn't match the runtime while believing it does — wrong, and silently so.

Given a URL or `owner/repo` directly, skip this step.

### 2. Which version

Ask three sources in order and **report which one answered**:

1. **The installed artifact** — `node_modules/<pkg>/package.json`, the venv's `.dist-info`, `go list -m <mod>`, `cargo metadata`. The code the project actually executes.
2. **The lockfile** — `pnpm-lock.yaml`, `package-lock.json`, `uv.lock`, `Cargo.lock`, `go.sum`. Exact, and right even when nothing is installed.
3. **The manifest range** — `^3.4.6` is not a version. Resolving it against the registry answers "what *would* install", a different question from "what *is* installed". Last resort, and say so.

Installed wins because behaviour that surprised you came from the bytes on disk, and those legitimately drift from the lockfile. Go collapses the ladder — `go.mod` is already exact.

Outside these four ecosystems, don't guess: say the ecosystem isn't detected and ask for a ref, or use the latest release.

**No version asked for and none to detect** (a tool you're just reading, like lazygit): use the **newest release tag**, falling back to the default branch only if the repo has no tags. Unreleased `main` is code nobody runs. If the default branch is well ahead of that tag, mention it — that's when asking for `main` explicitly makes sense.

### 3. Which ref

Run `scripts/sync-checkout.sh fetch <url>` first so the tags are local, then match the version against them:

```
3.4.6  →  v3.4.6  →  <pkg>@3.4.6  →  <any-prefix>@3.4.6
```

For npm there's one more rung, and it's the strongest: `npm view <pkg>@<version> gitHead` gives the commit the published tarball was built from — exact even when a repo tags erratically or not at all.

**No match anywhere: stop and ask.** Do not fall back to the default branch. A checkout on `main` reads plausibly and describes code the project doesn't run, and nothing in the output would hint that anything is wrong. Say what's installed, say the repo has no matching tag, and offer the nearest tag, the default branch, or a ref of the user's choosing.

### 4. Check it out

```bash
scripts/sync-checkout.sh checkout <git-url> <ref>
```

The script owns every git mechanic — blobless clone, unshallowing, `fetch --tags --prune`, worktree creation, reuse, and the reset rules. Don't hand-roll these; the failure modes (a missing `--tags` so the new version's tag isn't there, a stray `-fdx` that deletes a `node_modules` you built) all produce checkouts that look perfectly fine.

Worktrees pinned to a tag are immutable — created once, reused forever, never re-pointed. Branch refs are mutable and get re-pointed on reuse.

## What to report

Three things, in the response — nothing written to disk:

- **The path.** For a monorepo, give the repo root *and* the package's subdirectory, labelled. Find the subdirectory by matching the `name` field in `package.json` / `Cargo.toml`, or the module subpath for Go. If nothing matches, or several things do, give the root alone and say why — the same no-guessing rule as step 1. Never give the subdirectory alone: a library's behaviour often lives in a sibling package.
- **The resolved ref**, and the sha.
- **Which source answered the version question**, per step 2. `^3.4.6` in a manifest and `3.9.1` on disk are both true statements about "the version", and only one of them is the code running.

Persist none of it. A note saying where a checkout lives goes stale, is specific to this machine, and `CONTEXT.md` is a glossary — see [../CONTEXT.md](../CONTEXT.md) for the vocabulary this skill uses.

## Housekeeping

Nothing prunes the research root. Worktrees accumulate as versions do; clear stale ones by hand with `git worktree prune` in the bare store plus `rm -rf` on the tree.
