# HANDOVER.md — Session Bridge

> NEXT AGENT: Read THIS file first. Then read ONLY the files listed below. Do NOT re-read the entire project.

---

## Last Session Summary

**Date:** 2026-03-22
**Agent:** Claude Sonnet 4.6 (Session 2)
**Tasks Completed:** Phase 0 — FLOWS.md + SPEC.md validation

---

## Files Created / Modified

| File | What Changed |
|------|-------------|
| `FLOWS.md` | Created — 12 sections: system boundary diagram, all data flows, all user flows, error states, App Group key reference |
| `SPEC.md` | Major update — 32 issues resolved (see change summary below) |
| `TASKS.md` | Phase 0 tasks all marked [x] |
| `PROGRESS.md` | Session 2 log added |
| `HANDOVER.md` | This file (replaced previous) |

---

## Key Changes to SPEC.md (32 Issues Resolved)

### Data Model Changes
- `VideoRecord`: added `needsEnrichment: Bool` for API retry tracking
- `VideoRecord`: `lastTimestamp` explicitly write-once (not updated on open)
- `VideoRecord`: `note` max 500 chars, `thumbnailURL` never empty (always mqdefault.jpg fallback)
- `BookmarkStamp`: added `var video: VideoRecord` back-reference + cascade delete rule
- `BookmarkStamp`: marked **PHASE 5 / FUTURE** — model defined, no v1 UI
- `Folder`: duplicate names explicitly allowed

### URL Parser Changes
- Both `youtube.com` and `www.youtube.com` supported
- `videoID` must match `[A-Za-z0-9_-]{11}` — nil if invalid
- Formatted-time regex must match at least one group (no empty match)
- Non-parseable `t=` values → timestamp = 0 (silent fallback)
- YouTube Shorts explicitly out-of-scope

### Share Extension Changes
- Checks for existing `pendingRecord` before overwriting — shows warning alert
- Cancel button defined: `extensionContext?.cancelRequest(withError:)`
- App Group write failure → error alert (not silent)
- Confirmation UI explicitly shows videoID (not title)

### Ingestion Changes
- Delete `pendingRecord` key BEFORE API call (concurrency guard)
- Enrichment retry: on every `.active`, re-fetch all `needsEnrichment == true` records

### UI Changes
- Delete is **swipe-to-delete** (no confirmation) — long-press only has Edit Note + Move to Folder
- `@Query` used everywhere (no pull-to-refresh needed)
- Thumbnail loading: grey rectangle + play icon placeholder
- `FolderDetailView` fully specified (was missing)
- Empty state for FolderDetailView added
- Toast: 2 seconds auto-dismiss + VoiceOver announcement
- Widget deep link: validates videoID, dismisses sheets, navigates to list

### Security / Config
- DEBUG `fatalError` if YouTubeAPIKey is empty
- App Group data classification explicitly documented (low-sensitivity, unencrypted acceptable)
- Deep link parameter validation specified

---

## Phase 0 Status: COMPLETE ✅

All Phase 0 tasks done:
- [x] CLAUDE.md
- [x] SPEC.md (validated, 32 issues resolved)
- [x] TASKS.md
- [x] FLOWS.md
- [x] PROGRESS.md
- [x] Hook update

---

## Next Tasks

**Phase 1A — UX Architecture**
- Define NavigationStack structure (tab bar? toolbar? full NavigationStack?)
- Define all screen states: empty / loading / error / success per view
- Save as `UX-ARCHITECTURE.md`

**Phase 1B — Xcode Project Setup**
- Create Xcode project: 3 targets (YTBookmark, ShareExtension, BookmarkWidget)
- Configure App Group on all 3 targets
- Add Config.xcconfig (YOUTUBE_API_KEY placeholder)
- Configure Info.plist: LSApplicationQueriesSchemes, YouTubeAPIKey, ytbookmark:// URL scheme

**Recommended order:** 1A → 1B → 1C (SwiftData Models) → 1D (URL Parser TDD)

---

## Warnings / Gotchas for Next Agent

1. **`BookmarkStamp` UI is deferred to Phase 5.** Do not implement stamp creation/listing UI in v1. The SwiftData model must still be defined to avoid migrations later.

2. **`lastTimestamp` is write-once.** Do not add any logic to update it when the user opens YouTube.

3. **Ingestion order matters:** delete `pendingRecord` key FIRST, then call YouTube API. Not after.

4. **Thumbnail is never empty string.** Always use `mqdefault.jpg` fallback URL.

5. **Delete is swipe-to-delete** (no confirmation alert). Long-press context menu has only Edit Note + Move to Folder.

6. **`@Query` everywhere** for lists — no manual refresh logic needed.

---

## Files Next Agent Needs to Read

1. `HANDOVER.md` (this file) ✓
2. `TASKS.md` — to confirm Phase 1A is next
3. `SPEC.md` — when implementing a specific section
4. `FLOWS.md` — when implementing cross-boundary communication
5. `CLAUDE.md` — for architecture rules
