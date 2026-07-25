# One worktree per version, not one clone re-pointed

`dependency-source` keeps checked-out dependencies under a **Research root** (`~/kernvex/research`). The obvious layout is one clone per repo, re-pointed to whichever version the current project needs. We rejected it: a re-point silently yanks the ref out from under any agent still reading that path, and parallel agents on projects using different versions of the same library collide constantly. Instead each version gets its own immutable **Pinned worktree** (`<owner>/<repo>@<ref>`), all backed by one blobless **Bare store** per repo under `.repos/`.

## Considered options

- **One flat clone per repo, re-pointed.** Matches the layout that was already on disk and is the cheapest thing to build. Rejected: collisions between concurrent agents, and it produces the worst failure this skill exists to prevent — source that looks right while describing a version the project doesn't run.
- **A separate full clone per version.** No collisions, but pays for the entire history once per version. Five versions of one library means five copies of its object graph.
- **Worktrees off a shared bare store.** Chosen. Version six costs only its working tree.

Owner is part of the path (`colinhacks/zod@v3.4.6`, not `zod@v3.4.6`) so two repos sharing a name can never occupy the same directory — a structural guarantee rather than a check that has to run and be right.

## Consequences

- The research root grows without bound. Nothing prunes it; stale worktrees are removed by hand.
- Browsing is two levels deep, and paths carry an `@ref` suffix.
- The bare store must keep the full ref graph, which is why it's cloned `--filter=blob:none` rather than shallow — every ref stays checkoutable. Shallow clones (the previous habit) cannot serve a version they weren't cloned at, so the script unshallows any it finds.
- Because pinned worktrees are never re-pointed, a dirty one is an anomaly rather than a routine state. The script repairs it (`reset --hard`, `clean -fd`, keeping ignored files) instead of treating cleanup as a normal step.
