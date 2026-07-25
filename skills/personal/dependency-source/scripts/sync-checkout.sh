#!/usr/bin/env bash
#
# Materialise a dependency's source as a git worktree under the research root.
#
#   sync-checkout.sh fetch    <git-url>         ensure the bare store exists and is current
#   sync-checkout.sh checkout <git-url> <ref>   ensure a worktree for <ref> exists; print its path
#
# Layout (see ../../.agents/adr/0001-worktree-per-version.md):
#
#   $ROOT/.repos/<owner>/<repo>.git   bare, blobless, shared object store
#   $ROOT/<owner>/<repo>@<ref>/       one worktree per ref
#
# Run `fetch` first when you need to inspect tags before choosing a ref.

set -euo pipefail

ROOT="${DEPENDENCY_SOURCE_ROOT:-$HOME/kernvex/research}"

die() { printf 'sync-checkout: %s\n' "$*" >&2; exit 1; }

# https://github.com/colinhacks/zod.git -> "colinhacks zod"
# git@github.com:colinhacks/zod.git     -> "colinhacks zod"
parse_slug() {
  local url="${1%.git}"
  url="${url%/}"
  url="${url//:/\/}"
  local repo="${url##*/}"
  local rest="${url%/*}"
  local owner="${rest##*/}"
  [ -n "$owner" ] && [ -n "$repo" ] || die "cannot parse owner/repo from: $1"
  printf '%s %s\n' "$owner" "$repo"
}

ensure_bare() {
  local url="$1"
  if [ ! -d "$BARE" ]; then
    mkdir -p "$(dirname "$BARE")"
    # Blobless: full commit and tag graph, file contents fetched on demand.
    # Servers that refuse the filter get a plain bare clone instead.
    if ! git clone --bare --filter=blob:none "$url" "$BARE"; then
      rm -rf "$BARE"
      git clone --bare "$url" "$BARE" || die "clone failed: $url"
    fi
    git -C "$BARE" config remote.origin.fetch '+refs/heads/*:refs/heads/*'
  fi

  # A shallow store cannot serve arbitrary refs — repair it in place.
  if [ -f "$BARE/shallow" ]; then
    git -C "$BARE" fetch --unshallow --tags origin || true
  fi

  git -C "$BARE" fetch --tags --prune origin
}

cmd_fetch() {
  local url="$1"
  ensure_bare "$url"
  printf 'store: %s\n' "$BARE"
  printf 'tags:  %s\n' "$(git -C "$BARE" tag --list | wc -l | tr -d ' ')"
}

cmd_checkout() {
  local url="$1" ref="$2"
  ensure_bare "$url"

  git -C "$BARE" rev-parse -q --verify "$ref^{commit}" >/dev/null \
    || die "ref not found in $BARE: $ref"

  local want kind
  want="$(git -C "$BARE" rev-parse "$ref^{commit}")"
  if git -C "$BARE" rev-parse -q --verify "refs/tags/$ref" >/dev/null; then
    kind=tag
  else
    kind=mutable
  fi

  local tree="$ROOT/$OWNER/$REPO@${ref//\//-}"

  if [ -e "$tree" ]; then
    [ -e "$tree/.git" ] || die "$tree exists but is not a git worktree — inspect it by hand"

    local head dirty
    head="$(git -C "$tree" rev-parse HEAD)"
    dirty="$(git -C "$tree" status --porcelain)"

    # A pinned worktree is immutable: reuse it untouched unless something moved.
    # Mutable refs (branches) always re-point; a dirty tree is an anomaly, repaired.
    if [ "$kind" != tag ] || [ "$head" != "$want" ] || [ -n "$dirty" ]; then
      git -C "$tree" reset --hard "$want"
      git -C "$tree" clean -fd   # -fd, not -fdx: ignored files are expensive and never source
    fi
  else
    mkdir -p "$(dirname "$tree")"
    git -C "$BARE" worktree add --detach "$tree" "$want" >/dev/null
  fi

  printf 'path: %s\n' "$tree"
  printf 'ref:  %s (%s)\n' "$ref" "$kind"
  printf 'sha:  %s\n' "$want"
}

main() {
  local action="${1:-}" url="${2:-}"
  [ -n "$action" ] && [ -n "$url" ] || die "usage: sync-checkout.sh fetch|checkout <git-url> [ref]"

  read -r OWNER REPO <<<"$(parse_slug "$url")"
  BARE="$ROOT/.repos/$OWNER/$REPO.git"

  case "$action" in
    fetch)    cmd_fetch "$url" ;;
    checkout) [ -n "${3:-}" ] || die "checkout needs a ref"; cmd_checkout "$url" "$3" ;;
    *)        die "unknown action: $action" ;;
  esac
}

main "$@"
