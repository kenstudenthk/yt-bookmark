# UX-ARCHITECTURE.md — Navigation & Screen States

> Reference when building any View or ViewModel.
> All navigation decisions made here override any assumption from SPEC.md.

---

## 1. Navigation Pattern Decision

**Pattern: Single NavigationStack (no Tab Bar)**

Rationale:
- The app has one primary entity (bookmarks) — a tab bar implies equal-weight sections
- Folders and Search are secondary features accessed via toolbar icons
- Simpler NavigationStack avoids tab bar state restoration complexity
- SPEC.md section 8 already specifies "toolbar: search + folder icons" — this confirms the pattern

---

## 2. Navigation Hierarchy

```
YTBookmarkApp
│
├── OnboardingView (fullScreenCover — shown if !hasCompletedOnboarding)
│       Screen 1: Welcome
│       Screen 2: How to save
│       Screen 3: Done
│       └── "Get Started" → sets hasCompletedOnboarding = true → dismisses
│
└── NavigationStack (root)
        │
        BookmarkListView  ← ROOT VIEW
        │   Toolbar leading:  [Folders icon]
        │   Toolbar trailing: [Search icon]
        │
        ├── → FolderListView  (NavigationLink, push)
        │       Toolbar trailing: [+]
        │       │
        │       ├── .sheet → CreateFolderSheet
        │       │
        │       └── → FolderDetailView  (NavigationLink, push)
        │               (same row interactions as BookmarkListView)
        │               .sheet → EditNoteSheet
        │               .sheet → MoveFolderSheet
        │
        ├── .sheet → SearchView  (modal sheet, not push)
        │       (full screen sheet with search bar at top)
        │
        ├── .sheet → EditNoteSheet  (from long-press context menu)
        │
        └── .sheet → MoveFolderSheet  (from long-press context menu)
```

**Navigation type rationale:**
- FolderListView → **push** (it is a destination, back button makes sense)
- FolderDetailView → **push** (drill-down pattern, back to folder list)
- SearchView → **sheet** (overlay, dismiss to return; feels like a modal search experience)
- EditNoteSheet → **sheet** (quick edit, not a full destination)
- MoveFolderSheet → **sheet** (picker, not a full destination)
- CreateFolderSheet → **sheet** (form, not a full destination)

---

## 3. Screen State Machines

### 3.1 BookmarkListView

```
States: empty | list

empty:
  Condition: BookmarkRepository returns 0 records
  UI: centred icon + "Share a YouTube video to get started"
  No list, no toolbar search (search icon still visible but tapping shows empty SearchView)

list:
  Condition: 1+ records exist
  UI: List with BookmarkRowView entries, sorted savedAt DESC
  Thumbnail loading sub-states:
    loading:  grey 120×68 rectangle + play icon (ProgressView or placeholder asset)
    loaded:   AsyncImage rendered
    error:    grey 120×68 rectangle + play icon (same as loading placeholder)

Transitions:
  empty → list: automatic via @Query when first record created
  list → empty: automatic via @Query when last record deleted
```

### 3.2 FolderListView

```
States: empty | list

empty:
  Condition: 0 folders exist
  UI: centred icon + "Create a folder to organise your bookmarks"
  + button still visible in toolbar

list:
  Condition: 1+ folders exist
  UI: 2-column grid of FolderCardView
  Each card: colour swatch (full card background, semi-opaque) + name + "N bookmarks" count

Transitions:
  empty ↔ list: automatic via @Query
```

### 3.3 FolderDetailView

```
States: empty | list

Title: folder name (shown in navigation bar)

empty:
  Condition: folder has 0 records
  UI: centred icon + "No bookmarks in this folder yet"

list:
  Condition: 1+ records in folder
  UI: same BookmarkRowView layout as BookmarkListView
  Sorted: savedAt DESC

Transitions:
  empty ↔ list: automatic via @Query
```

### 3.4 SearchView

```
States: idle | searching | results | no-results

idle:
  Condition: query is empty string
  UI: search bar (focused/active) + "Search your bookmarks" hint text
  List area: empty

searching:
  Condition: query non-empty, debounce timer active (< 300ms since last keystroke)
  UI: search bar with query text
  List area: previous results shown (or idle if first search)
  No visible spinner (debounce is fast enough to not need one)

results:
  Condition: query non-empty, debounce elapsed, 1+ matches found
  UI: list of BookmarkRowView matching records
  Tap row → DeepLinkService (same as BookmarkListView)

no-results:
  Condition: query non-empty, debounce elapsed, 0 matches
  UI: "No results for '[query]'" centred text

Transitions:
  idle → searching: any keystroke
  searching → results / no-results: after 300ms debounce
  results / no-results → idle: query cleared
  any → dismiss: swipe down sheet / Cancel button
```

### 3.5 OnboardingView

```
States: screen-1 | screen-2 | screen-3

Navigation: TabView with .page style (swipe or Continue button)
Back navigation: none (forward only)

screen-1 (Welcome):
  Illustration: app icon or hero image
  Title: "Never lose your place"
  Subtitle: "Save any YouTube timestamp in one tap"
  CTA: "Continue"

screen-2 (How to save):
  Illustration: screenshot of YouTube share sheet with extension visible
  Title: "Share from YouTube"
  Subtitle: "Tap Share → YT Bookmark to save your timestamp"
  CTA: "Continue"

screen-3 (Done):
  Illustration: checkmark or success state
  Title: "You're all set!"
  Subtitle: "Your saved bookmarks will appear in the app"
  CTA: "Get Started"
  Action: set hasCompletedOnboarding = true → dismiss OnboardingView

No skip button. No "X" dismiss. User must tap through all 3 screens.
```

### 3.6 CreateFolderSheet

```
States: empty-name | valid-name

empty-name (initial state):
  Name field: empty, placeholder "Folder name"
  Char count: hidden
  Colour picker: first colour pre-selected (#FF6B6B)
  Save button: disabled (greyed out)

valid-name:
  Name field: 1–30 chars entered
  Char count: shown as "N/30" in grey when ≤ 25 chars
  Char count: shown as "N/30" in red when 26–30 chars
  Save button: enabled

over-limit (> 30 chars — prevented by .onChange, not a real state):
  Input is trimmed at 30 chars; user cannot type beyond limit

Cancel: dismiss sheet, no save
Save: BookmarkRepository.createFolder() → dismiss sheet
```

### 3.7 EditNoteSheet

```
States: editing

Pre-filled: current record.note value
Text editor: multi-line, max 500 chars
Char count: shown as "N/500" — grey ≤ 400, orange 401–490, red 491–500
Input capped at 500 chars via .onChange

Cancel: dismiss, no save
Save: BookmarkRepository.update(record, note: newNote) → dismiss
```

### 3.8 MoveFolderSheet

```
States: list

Shows: all Folder entries + "Uncategorised" option at top
Current assignment: checkmark on current folder (or "Uncategorised" if nil)

Tap folder: BookmarkRepository.update(record, folder: folder) → dismiss
Tap Uncategorised: BookmarkRepository.update(record, folder: nil) → dismiss
Cancel: dismiss, no change
```

---

## 4. Toolbar Layout

### BookmarkListView toolbar

```
NavigationBar:
  Title:   "YT Bookmark" (large title style)
  Leading: [folder.badge.fill] icon → NavigationLink to FolderListView
  Trailing:[magnifyingglass] icon → show SearchView as .sheet
```

### FolderListView toolbar

```
NavigationBar:
  Title:   "Folders" (inline title)
  Leading: [back chevron] (automatic)
  Trailing:[plus] icon → show CreateFolderSheet
```

### FolderDetailView toolbar

```
NavigationBar:
  Title:   [folder name] (inline title)
  Leading: [back chevron] (automatic)
  Trailing: (none)
```

### SearchView (sheet)

```
Top: search bar with Cancel button
No NavigationBar (it is a plain sheet)
Cancel button: dismisses sheet, clears query
```

---

## 5. Gesture Inventory

| View | Gesture | Action |
|------|---------|--------|
| BookmarkListView | Tap row | DeepLinkService.open() |
| BookmarkListView | Swipe left on row | Delete record (immediate) |
| BookmarkListView | Long press row | Context menu: Edit Note / Move to Folder |
| FolderListView | Tap card | Push FolderDetailView |
| FolderListView | Long press card | Context menu: Delete Folder (with confirm alert) |
| FolderDetailView | Tap row | DeepLinkService.open() |
| FolderDetailView | Swipe left on row | Delete record (immediate) |
| FolderDetailView | Long press row | Context menu: Edit Note / Move to Folder |
| SearchView | Tap row | DeepLinkService.open() |
| SearchView | Swipe down | Dismiss sheet |
| OnboardingView | Swipe left | Advance to next screen |
| Any sheet | Swipe down | Dismiss (unless form has unsaved changes — no guard in v1) |

---

## 6. Alert Inventory

| Trigger | Title | Message | Actions |
|---------|-------|---------|---------|
| Delete Folder (long press) | "Delete '[name]'?" | "Bookmarks will be moved to Uncategorised." | Cancel / Delete (destructive) |
| Share Extension: existing pendingRecord | "Replace saved bookmark?" | "A bookmark is already waiting to be saved. Continuing will replace it." | Cancel / Continue |
| Share Extension: non-YouTube URL | "Not a YouTube Link" | "Please share a YouTube video." | OK |
| Share Extension: App Group write failure | "Save Failed" | "Failed to save. Please try again." | OK |
| SwiftData error | "Something went wrong" | error.localizedDescription | OK |

---

## 7. Toast Specification

**Trigger:** successful bookmark ingestion
**Text:** "Bookmark saved!"
**Duration:** 2 seconds, then auto-dismiss with fade-out
**Position:** bottom of screen, above safe area
**VoiceOver:** `UIAccessibility.post(notification: .announcement, argument: "Bookmark saved")`
**Implementation:** custom overlay via `.overlay(alignment: .bottom)` on root NavigationStack

---

## 8. Deep Link Navigation State Machine

Trigger: `onOpenURL` receives `ytbookmark://open?v={videoID}&t={timestamp}`

```
1. Validate videoID matches [A-Za-z0-9_-]{11} → if invalid, discard silently
2. Dismiss any active sheet (SearchView / EditNoteSheet / MoveFolderSheet / CreateFolderSheet)
3. Pop NavigationStack to root (BookmarkListView)
4. Call DeepLinkService.open(videoID, timestamp)
```

State is managed via:
- `@State var navigationPath = NavigationPath()` in root ContentView
- `@State var activeSheet: ActiveSheet? = nil` (enum covering all sheets)
- Deep link handler sets `navigationPath = NavigationPath()` and `activeSheet = nil` before opening

---

## 9. Sheet Management Pattern

Use a single `ActiveSheet` enum to manage all sheets from `BookmarkListView`:

```swift
enum ActiveSheet: Identifiable {
    case search
    case editNote(VideoRecord)
    case moveToFolder(VideoRecord)

    var id: String { ... }
}
```

`FolderListView` manages its own `CreateFolderSheet` presentation independently.
`FolderDetailView` reuses the same `ActiveSheet` pattern for Edit Note and Move to Folder.

---

## 10. Accessibility Notes

- All SF Symbols must have `.accessibilityLabel()` set (toolbar icons have no visible text)
- Thumbnail images: `.accessibilityLabel(record.title)`
- Timestamp badges: `.accessibilityLabel("Saved at \(formattedTime)")`
- Colour picker in CreateFolderSheet: each swatch needs `.accessibilityLabel(colourName)`
- Delete swipe action: `.accessibilityLabel("Delete bookmark")`
- Toast: VoiceOver announcement (see section 7)
