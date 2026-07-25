# Personal Skills

Skills tied to my own machine and setup, not promoted in the plugin. This context holds the vocabulary those skills use, which is separate from the issue-tracker language of the root context.

## Language

### Dependency source

**Research root**:
The directory holding every checked-out dependency — `~/kernvex/research`. Overridable with `DEPENDENCY_SOURCE_ROOT`.
_Avoid_: research folder, clone dir, cache

**Bare store**:
The bare, blobless clone of a repo under the **Research root**, holding the shared object graph that every **Pinned worktree** of that repo draws on. One per repo.
_Avoid_: mirror, cache repo

**Pinned worktree**:
A working tree checked out at one immutable ref, named `<owner>/<repo>@<ref>`. Created once and reused; never re-pointed to a different version. A worktree on a branch is *not* pinned — branch refs are mutable and get re-pointed on reuse.
_Avoid_: checkout dir, clone

**Resolved ref**:
The concrete tag or commit a version resolved to, after matching against the repo's tags. Distinct from the **Version** itself: `3.4.6` is a version, `v3.4.6` is the ref it resolved to.
_Avoid_: tag, revision

**Version source**:
Which of installed artifact, lockfile, or manifest range answered the question "what version is this project using". Always reported, because the three disagree and only one describes the code actually running.
_Avoid_: version origin, lookup method

## Relationships

- A **Bare store** backs many **Pinned worktrees** of the same repo
- A **Pinned worktree** sits at exactly one **Resolved ref**
- A **Version source** produces a version, which resolves to a **Resolved ref**
