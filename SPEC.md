# SPEC.md — YT Bookmark Full Specification

> Read this file only when the feature you are implementing is described here.
> Last updated: 2026-03-22 (Phase 0 validation pass — 32 issues resolved)

---

## 1. App Identity

| Property | Value |
|----------|-------|
| App Name | YT Bookmark |
| Bundle ID | com.myapp.ytbookmark |
| App Group | group.com.myapp.ytbookmark |
| Min iOS | 17.0 |
| Language | Swift 5.9+ |
| UI | SwiftUI |

---

## 2. Data Models

### 2.1 VideoRecord (SwiftData @Model)

```swift
@Model
class VideoRecord {
    var id: UUID
    var videoID: String          // YouTube video ID, always [A-Za-z0-9_-]{11}
    var title: String            // From YouTube API; fallback = videoID if API fails
    var thumbnailURL: String     // From YouTube API; fallback = mqdefault.jpg URL
    var savedAt: Date            // When saved via Share Extension
    var lastTimestamp: Int       // Seconds; 0 if no t= param. Write-once — not updated on open.
    var note: String             // Optional user note; default = ""; max 500 chars
    var needsEnrichment: Bool    // true if API fetch failed; retried on next .active
    var folder: Folder?          // nil = uncategorised
    var stamps: [BookmarkStamp]  // Phase 5 — future feature; not used in v1
}
```

**Thumbnail fallback (canonical):** `https://img.youtube.com/vi/{videoID}/mqdefault.jpg`
Use this URL when the YouTube Data API fails or returns no thumbnail. Never store an empty string.

**`lastTimestamp` is write-once.** It is set at save time from the Share Extension URL.
It is NOT updated when the user opens YouTube via DeepLinkService.

**`needsEnrichment`** is set to `true` when the YouTube API call fails at ingestion time.
On every `scenePhase == .active`, `PendingRecordService` re-fetches all records where `needsEnrichment == true`.

### 2.2 Folder (SwiftData @Model)

```swift
@Model
class Folder {
    var id: UUID
    var name: String         // Required; max 30 chars; duplicate names allowed
    var colorHex: String     // One of 6 preset hex values (see below)
    var createdAt: Date
    var records: [VideoRecord]
}
```

Preset colour hex values:
- `#FF6B6B` (red)
- `#4ECDC4` (teal)
- `#45B7D1` (blue)
- `#96CEB4` (green)
- `#FFEAA7` (yellow)
- `#DDA0DD` (purple)

Duplicate folder names are allowed. No uniqueness enforcement.

### 2.3 BookmarkStamp (SwiftData @Model) — PHASE 5 / FUTURE

> **v1 scope: model defined but no UI implemented.** Do not build stamp creation, listing, or deletion UI in v1.

```swift
@Model
class BookmarkStamp {
    var id: UUID
    var timestamp: Int        // Seconds
    var label: String         // User-provided; max 50 chars
    var createdAt: Date
    var video: VideoRecord    // Back-reference; required for cascade delete
}
```

Cascade delete rule: when a `VideoRecord` is deleted, all its `BookmarkStamp` entries are deleted.
Sort order (future): ascending by `timestamp`.

---

## 3. App Group Shared Data

Suite name: `group.com.myapp.ytbookmark`

### 3.1 Pending Record (key: `"pendingRecord"`)

Written by ShareExtension. Read + deleted by main app on `scenePhase == .active`.

JSON structure:
```json
{
  "videoID": "dQw4w9WgXcQ",
  "rawURL": "https://youtu.be/dQw4w9WgXcQ?t=101",
  "timestamp": 101,
  "savedAt": "2026-03-22T10:00:00Z"
}
```

**Single-slot constraint:** only one pending record can exist at a time.
If a record already exists when the user saves a new one, the Share Extension shows a warning:
> "A bookmark is already waiting to be saved. Continuing will replace it."
The user can proceed (overwrites) or cancel.

**Data classification:** stored unencrypted as a UserDefaults plist. Data is transient and low-sensitivity (YouTube URL + timestamp). Accepted risk.

### 3.2 Widget Data (key: `"widgetData"`)

Written by main app on every SwiftData modification. Max 5 items. Never deleted — overwritten each time.

JSON structure:
```json
[
  {
    "videoID": "dQw4w9WgXcQ",
    "title": "Never Gonna Give You Up",
    "thumbnailURL": "https://img.youtube.com/vi/dQw4w9WgXcQ/mqdefault.jpg",
    "timestamp": 101
  }
]
```

**Data classification:** stored unencrypted. Low-sensitivity (public YouTube metadata). Accepted risk.

---

## 4. URL Parsing Rules (YouTubeURLParser.swift)

### 4.1 Supported URL Formats

| Format | Example | Source |
|--------|---------|--------|
| youtu.be + t= | `https://youtu.be/ID?t=101&si=xxx` | YouTube App, timestamp toggle ON |
| youtu.be no t= | `https://youtu.be/ID?si=xxx` | YouTube App, timestamp toggle OFF |
| youtube.com/watch + t= | `https://youtube.com/watch?v=ID&t=101` | Safari share |
| youtube.com/watch formatted | `https://youtube.com/watch?v=ID&t=1h3m30s` | Safari right-click |

Both `youtube.com` and `www.youtube.com` are supported. Strip `www.` before matching.

**Out of scope (v1):** `youtube.com/shorts/{ID}` — returns nil, Share Extension shows "Not a YouTube link".

### 4.2 Parsing Rules

- Strip `si=` parameter (tracking noise; discard)
- Both `youtube.com` and `www.youtube.com` are accepted
- Missing `t=` → `timestamp = 0`
- `t=SECONDS` (positive integer) → return as-is
- `t=XhYmZs` (formatted) → convert via section 4.3
- `t=` with any other value (e.g. `t=abc`, `t=1.5`) → `timestamp = 0` (silent fallback)
- `videoID` must match `[A-Za-z0-9_-]{11}` — if not, return `nil`
- Empty or whitespace `videoID` → return `nil`

### 4.3 Formatted Time Parser

```
1h3m30s → 5610
3m30s   → 210
30s     → 30
1h      → 3600
```

Regex: `(?:(\d+)h)?(?:(\d+)m)?(?:(\d+)s)?`

**Validation:** at least one capture group must be non-nil and non-empty.
If all three groups are nil (empty match), treat as `timestamp = 0` — do not accept the parse.

### 4.4 Return Type

```swift
struct ParsedYouTubeURL {
    let videoID: String   // Always matches [A-Za-z0-9_-]{11}
    let timestamp: Int    // 0 if not present or unparseable
}
// Returns nil if not a supported YouTube URL or videoID is invalid
```

---

## 5. Share Extension

Receives `public.url` from YouTube App or Safari.

### Flow

1. Extract URL string from `NSItemProvider`
2. Parse with `YouTubeURLParser`
3. **Invalid URL** → show error alert: "Not a YouTube link"
   - Cancel: call `extensionContext?.cancelRequest(withError: NSError(...))`
4. **Valid URL** → check App Group for existing `pendingRecord`
   - If exists → show warning alert: "A bookmark is already waiting to be saved. Continuing will replace it."
     - Cancel → `extensionContext?.cancelRequest(withError:)` (discard new)
     - Continue → proceed to step 5
   - If empty → proceed to step 5
5. Show confirmation UI:
   - Video ID displayed (title not available until main app ingests)
   - Timestamp badge (`mm:ss` or "Start" if 0)
   - Optional note text field
   - Save button + Cancel button
6. **User taps Cancel** → `extensionContext?.cancelRequest(withError: NSError(...))`
7. **User taps Save**:
   - Encode `PendingRecord` → JSON string
   - Write to App Group UserDefaults key `"pendingRecord"`
   - **If write fails** → show error alert: "Failed to save. Please try again." → stay on sheet
   - **If write succeeds** → `extensionContext?.completeRequest(returningItems: nil)`

> **Note:** The confirmation UI intentionally shows the video ID, not the video title.
> The title and thumbnail are fetched by the main app after ingestion.

---

## 6. YouTube Data API v3

**Endpoint:** `GET https://www.googleapis.com/youtube/v3/videos?part=snippet&id={videoID}&key={API_KEY}`

**API Key loading:**
```swift
let key = Bundle.main.infoDictionary?["YouTubeAPIKey"] as? String ?? ""
```
In DEBUG builds: if key is empty, call `fatalError("YouTubeAPIKey is missing from Info.plist")`.
Done Criteria: CI must validate the key is present before archiving.

**Success response:** save `title` and `thumbnailURL` from `snippet`; set `needsEnrichment = false`.

**Error handling (any failure):**

| Error | title | thumbnailURL | needsEnrichment |
|-------|-------|--------------|-----------------|
| Network error | videoID | mqdefault.jpg URL | true |
| 403 quota exceeded | videoID | mqdefault.jpg URL | true |
| Empty `items` array | videoID | mqdefault.jpg URL | true |
| Any other HTTP error | videoID | mqdefault.jpg URL | true |

**Thumbnail fallback:** `https://img.youtube.com/vi/{videoID}/mqdefault.jpg`
Always use this URL; never store an empty string in `thumbnailURL`.

---

## 7. Pending Record Ingestion

**Trigger:** `scenePhase == .active` in `YTBookmarkApp.swift`

**Concurrency guard:** delete `"pendingRecord"` from UserDefaults BEFORE making the API call.
This prevents duplicate ingestion if the app foregrounds twice during a slow API call.

### New Record Flow

1. Read `"pendingRecord"` from App Group UserDefaults
2. If nil → skip to step 8
3. **Immediately delete** `"pendingRecord"` key from UserDefaults
4. Decode `PendingRecord` JSON
5. Call `YouTubeAPIService.fetchMetadata(videoID)`
   - Success → `title`, `thumbnailURL`, `needsEnrichment = false`
   - Error → `title = videoID`, `thumbnailURL = mqdefault.jpg URL`, `needsEnrichment = true`
6. `BookmarkRepository.create(VideoRecord)`
7. `WidgetDataService.updateWidgetData()` → write top 5 to `"widgetData"` → `WidgetCenter.shared.reloadAllTimelines()`
8. Show toast: "Bookmark saved!" (2 seconds, auto-dismiss; VoiceOver announces the text)

### Enrichment Retry Flow (step runs after step 8)

9. Query all `VideoRecord` where `needsEnrichment == true`
10. For each: call `YouTubeAPIService.fetchMetadata(videoID)`
    - Success → update `title`, `thumbnailURL`, `needsEnrichment = false`
    - Still fails → leave `needsEnrichment = true` (retry next `.active`)
11. If any records updated → `WidgetDataService.updateWidgetData()`

---

## 8. Bookmark List View

- `NavigationStack`; toolbar: search icon (leading or trailing) + folder icon
- List sorted by `savedAt` DESC
- Powered by `@Query` — automatically reflects SwiftData changes (no pull-to-refresh needed)
- Row: Thumbnail 120×68 | Title (2 lines max) | Timestamp badge | Date
- **Thumbnail loading state:** grey rectangle + play icon placeholder while loading or on error
- **Tap row** → `DeepLinkService.open(videoID, timestamp)`
- **Swipe left on row** → Delete (immediate, no undo, no confirmation alert)
- **Long press row** → context menu with two actions only:
  - Edit Note → `EditNoteSheet` (text field, max 500 chars, Save / Cancel)
  - Move to Folder → `MoveFolderSheet` (folder picker, Save / Cancel)
- **Empty state:** "Share a YouTube video to get started"

---

## 9. Open YouTube (DeepLinkService)

```
Primary:  vnd.youtube://watch?v={videoID}&t={timestamp}
Fallback: https://youtu.be/{videoID}?t={timestamp}
```

- Check `canOpenURL("vnd.youtube://")` before attempting primary
- If false → use Safari fallback
- Add `vnd.youtube` to `LSApplicationQueriesSchemes` in `Info.plist`

**Deep link receipt (ytbookmark:// from Widget):**
1. Validate `videoID` parameter matches `[A-Za-z0-9_-]{11}` — if invalid, silently discard
2. Dismiss all active sheets
3. Navigate to root `BookmarkListView`
4. Call `DeepLinkService.open(videoID, timestamp)`

---

## 10. Folder Feature

- Grid layout, 2 columns
- Each card: colour swatch + name + video count

### 10.1 Folder List View
- `+` button → `CreateFolderSheet`
- Tap card → `FolderDetailView`
- Long press card → delete
  - Confirmation alert: "Delete '[name]'? Bookmarks will be moved to Uncategorised."
  - Confirm → `BookmarkRepository.deleteFolder()` → all records set `folder = nil`

### 10.2 Create Folder Sheet
- Name text field (required; max 30 chars)
  - > 30 chars → Save button disabled + red character count shown
- 6-colour picker (one must always be selected)
- Save / Cancel

### 10.3 Folder Detail View
- Shows all `VideoRecord` entries where `record.folder == thisFolder`, sorted `savedAt` DESC
- Powered by `@Query` (live updates)
- Same row layout and interactions as Bookmark List View (swipe-to-delete, long-press menu)
- **Empty state:** "No bookmarks in this folder yet"

### 10.4 Move to Folder Sheet
- Lists all folders + "Uncategorised" option
- Selecting one updates `record.folder` via `BookmarkRepository.update()`

---

## 11. Search Feature

- Case-insensitive partial match on `VideoRecord.title`
- 300ms debounce on user input
- Global search across all folders and uncategorised records
- Powered by in-memory filter on `@Query` result
- **Empty result state:** "No results for '[query]'"
- Dismiss keyboard on scroll

---

## 12. Widget (WidgetKit)

- **Small** widget: 1 item
- **Medium** widget: 3 items
- Reads from App Group `"widgetData"` key
- Tap deep link: `ytbookmark://open?v={videoID}&t={timestamp}`
- **Refresh policy:** `TimelineReloadPolicy.after(Date(timeIntervalSinceNow: 1800))` — 30-minute background fallback
- **Immediate updates:** main app calls `WidgetCenter.shared.reloadAllTimelines()` on every SwiftData write; the 30-minute policy is only the background baseline
- **Empty state (no widgetData):** "No bookmarks yet" placeholder

---

## 13. Onboarding

- Show on first launch: check `UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")`
- If false → `OnboardingView` (full screen cover)
- If true → `BookmarkListView` directly

Screen 1: **Welcome** — "Never lose your place"
Screen 2: **How to save** — YouTube share toggle instruction with screenshot/illustration
Screen 3: **Done** — "You're all set!" + "Get Started" button
  - Sets `hasCompletedOnboarding = true`
  - Dismisses to `BookmarkListView`

---

## 14. Edge Cases

| Scenario | Behaviour |
|----------|-----------|
| Duplicate video saved twice | Allow — creates two separate `VideoRecord` entries |
| No internet when saving | Save with `title=videoID`, `thumbnailURL=mqdefault.jpg`, `needsEnrichment=true`; retry next `.active` |
| t=0 or missing | "Start" badge; opens video from beginning |
| YouTube App not installed | Safari fallback (transparent to user) |
| Delete record | Swipe-to-delete, immediate, no undo |
| Folder name > 30 chars | Save button disabled + red character count |
| widgetData > 5 items | Keep 5 most recent only |
| pendingRecord already exists | Warning alert before overwriting |
| t= value not parseable (e.g. `t=abc`) | timestamp = 0 (silent fallback) |
| videoID fails validation | Parser returns nil; Share Extension shows "Not a YouTube link" |
| App Group write fails in Share Extension | Error alert: "Failed to save. Please try again." |
| ingest() called concurrently | Safe — pendingRecord deleted before API call |
| YouTube Shorts URL shared | "Not a YouTube link" (v1 out of scope) |
| Widget deep link with invalid videoID | Silently discard |
| www.youtube.com URL | Supported — strip www. before parsing |
| API key missing at runtime (DEBUG) | fatalError to catch before shipping |
| needsEnrichment record (offline save) | Re-fetched on every subsequent .active until success |

---

## 15. URL Scheme

Main app registers: `ytbookmark://`

Supported deep links:
- `ytbookmark://open?v={videoID}&t={timestamp}` → used by Widget

Parameter validation before acting:
- `videoID` must match `[A-Za-z0-9_-]{11}` — if invalid, discard silently
- `timestamp` must be a non-negative integer — if missing or invalid, default to 0

---

## 16. Done Criteria

| Feature | Done When |
|---------|-----------|
| URL Parser | All 4 formats + all edge cases from section 4 pass XCTest |
| Share Extension | Receives URL, validates, shows confirmation UI, handles existing pendingRecord, writes to App Group |
| Pending Ingestion | Reads on .active, deletes key first, creates record, retries needsEnrichment, shows toast |
| Bookmark List | @Query list + swipe-delete + long-press menu + empty state + thumbnail placeholder |
| Folder Feature | Create, list, detail, assign, delete all work correctly |
| Search | Real-time debounced global search with empty state |
| Widget | Small + medium render, empty state, deep link works and validates videoID |
| Onboarding | 3 screens first launch, skipped after |
| API Key | CI validates key is present before archiving; DEBUG fatalError if missing |
