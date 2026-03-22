# FLOWS.md — YT Bookmark Data Flows & User Flows

> Reference this file when implementing cross-boundary communication or user-facing flows.
> All data flow boundaries enforce the architecture rules in CLAUDE.md.

---

## 1. System Architecture Boundaries

```
┌─────────────────────────────────────────────────────────────────┐
│                    iOS Process Boundary                          │
│                                                                  │
│  ┌──────────────────┐          ┌──────────────────────────────┐ │
│  │  ShareExtension  │          │       Main App               │ │
│  │  (separate proc) │          │   (YTBookmark target)        │ │
│  │                  │          │                              │ │
│  │  ShareViewModel  │          │  YTBookmarkApp               │ │
│  │  YouTubeURLParser│          │  BookmarkListViewModel       │ │
│  │  ShareView       │          │  FolderListViewModel         │ │
│  │                  │          │  SearchViewModel             │ │
│  │  ❌ NO SwiftData │          │  BookmarkRepository          │ │
│  │  ❌ NO direct DB │          │  ✅ SwiftData (only here)    │ │
│  └────────┬─────────┘          └──────────┬───────────────────┘ │
│           │                               │                      │
│           │          App Group            │                      │
│           │   group.com.myapp.ytbookmark  │                      │
│           └──────────────┬────────────────┘                      │
│                          │                                       │
│                    UserDefaults                                  │
│               ┌──────────┴──────────┐                           │
│               │  "pendingRecord"    │  "widgetData"             │
│               └─────────────────────┘                           │
│                          │                                       │
│           ┌──────────────┘                                       │
│  ┌────────┴─────────┐                                           │
│  │  BookmarkWidget  │                                           │
│  │  (separate proc) │                                           │
│  │  WidgetProvider  │                                           │
│  │  WidgetEntry     │                                           │
│  │  ❌ NO SwiftData │                                           │
│  └──────────────────┘                                           │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Core Data Flow: Save a Bookmark

```
YouTube App / Safari
      │
      │  public.url (Share Sheet)
      ▼
ShareExtension
  1. NSExtensionPrincipalClass receives item
  2. Extract URL string from NSItemProvider
  3. YouTubeURLParser.parse(url)
      ├── Invalid → show error alert "Not a YouTube link"
      └── Valid   → ParsedYouTubeURL { videoID, timestamp }
  4. Show ShareView (confirmation UI)
      ├── Parsed video ID displayed
      ├── Timestamp badge (mm:ss or "Start")
      └── Note text field (optional)
  5. User taps Save
  6. Encode PendingRecord → JSON string
  7. UserDefaults(suiteName: "group.com.myapp.ytbookmark")
         .set(jsonString, forKey: "pendingRecord")
  8. extensionContext?.completeRequest(returningItems: nil)

      ─── App Group boundary crossed ───

Main App (on scenePhase == .active)
  PendingRecordService.ingest()
  1. Read "pendingRecord" from App Group UserDefaults
  2. If nil → exit (no pending record)
  3. Decode PendingRecord JSON
  4. YouTubeAPIService.fetchMetadata(videoID)
      ├── Success  → title, thumbnailURL from API
      └── Error    → title = videoID, thumbnailURL = ""
  5. BookmarkRepository.create(VideoRecord)
      └── SwiftData .insert() + .save()
  6. WidgetDataService.updateWidgetData()
      └── Fetch latest 5 records → encode → write "widgetData"
  7. UserDefaults delete "pendingRecord"
  8. Show toast: "Bookmark saved!"
```

---

## 3. Core Data Flow: Open YouTube from Bookmark

```
Main App
  User taps BookmarkRowView
      │
      ▼
  BookmarkListViewModel.openBookmark(record)
      │
      ▼
  DeepLinkService.open(videoID: record.videoID, timestamp: record.lastTimestamp)
      │
      ├── canOpenURL("vnd.youtube://")  →  true
      │       └── openURL("vnd.youtube://watch?v={videoID}&t={timestamp}")
      │
      └── canOpenURL("vnd.youtube://")  →  false
              └── openURL("https://youtu.be/{videoID}?t={timestamp}")
```

---

## 4. Core Data Flow: Widget → Open YouTube

```
BookmarkWidget
  User taps widget entry
      │
      ▼
  Link URL: "ytbookmark://open?v={videoID}&t={timestamp}"

      ─── Deep link ───

Main App (onOpenURL)
  YTBookmarkApp.swift handles ytbookmark://
      │
      ▼
  DeepLinkService.open(videoID, timestamp)
      │  (same vnd.youtube / Safari fallback as above)
```

---

## 5. Core Data Flow: Widget Refresh

```
Main App (every SwiftData write)
  WidgetDataService.updateWidgetData()
  1. BookmarkRepository.fetchRecent(limit: 5)
  2. Map to [WidgetEntry] (videoID, title, thumbnailURL, timestamp)
  3. Encode to JSON string
  4. UserDefaults(suiteName: "group.com.myapp.ytbookmark")
         .set(jsonString, forKey: "widgetData")
  5. WidgetCenter.shared.reloadAllTimelines()

      ─── App Group boundary ───

BookmarkWidget (WidgetProvider)
  getTimeline(in:completion:)
  1. Read "widgetData" from App Group UserDefaults
  2. Decode [WidgetEntry]
  3. If empty → show placeholder entry
  4. Return Timeline with 30-minute refresh policy
```

---

## 6. User Flow: First Launch (Onboarding)

```
App Launch
      │
      ▼
  YTBookmarkApp checks UserDefaults "hasCompletedOnboarding"
      │
      ├── false / missing
      │       └── Show OnboardingView (full screen)
      │               Screen 1: "Never lose your place" + Continue
      │               Screen 2: YouTube share toggle instruction + Continue
      │               Screen 3: "You're all set!" + Get Started
      │                   └── Set "hasCompletedOnboarding" = true
      │                   └── Dismiss → BookmarkListView
      │
      └── true
              └── BookmarkListView directly
```

---

## 7. User Flow: Browse Bookmarks

```
BookmarkListView
  ├── scenePhase .active → PendingRecordService.ingest() [see Flow 2]
  │
  ├── Empty state
  │       └── "Share a YouTube video to get started"
  │
  ├── List (sorted by savedAt DESC)
  │       └── BookmarkRowView (thumbnail | title | badge | date)
  │               ├── Tap → DeepLinkService [see Flow 3]
  │               │
  │               └── Long press → context menu
  │                       ├── Edit Note
  │                       │       └── EditNoteSheet → BookmarkRepository.update()
  │                       ├── Move to Folder
  │                       │       └── MoveFolderSheet → BookmarkRepository.update()
  │                       └── Delete
  │                               └── confirm → BookmarkRepository.delete()
  │                                   └── WidgetDataService.updateWidgetData()
  │
  └── Toolbar
          ├── Search icon → SearchView
          └── Folder icon → FolderListView
```

---

## 8. User Flow: Folders

```
FolderListView
  ├── Grid (2 columns)
  │       └── FolderCardView (colour | name | count)
  │               └── Tap → FolderDetailView
  │                       └── BookmarkListView filtered to this folder
  │
  ├── + button → CreateFolderSheet
  │       ├── Name field (max 30 chars, required)
  │       │       └── > 30 chars → disabled Save + red char count
  │       ├── 6-colour picker
  │       └── Save → BookmarkRepository.createFolder()
  │
  └── Long press FolderCard → delete
          └── Alert: "Delete [name]? Records will be uncategorised"
              └── Confirm → BookmarkRepository.deleteFolder()
                      └── All records → folder = nil
```

---

## 9. User Flow: Search

```
SearchView
  ├── Search bar (focused on appear)
  │
  ├── User types query
  │       └── SearchViewModel debounces 300ms
  │               └── filter all VideoRecords (in-memory)
  │                       case-insensitive partial match on .title
  │                       across ALL folders + uncategorised
  │
  ├── Results list
  │       └── BookmarkRowView (same as Browse)
  │               └── Tap → DeepLinkService [see Flow 3]
  │
  └── Empty result
          └── "No results for '[query]'"
```

---

## 10. Data Consistency Rules

| Event | SwiftData | App Group widgetData | Action |
|-------|-----------|----------------------|--------|
| Create bookmark | ✅ insert | ✅ update (top 5) | Always both |
| Delete bookmark | ✅ delete | ✅ update (top 5) | Always both |
| Edit note | ✅ update | ❌ no update needed | Note not in widgetData |
| Move to folder | ✅ update | ❌ no update needed | Folder not in widgetData |
| Delete folder | ✅ update records | ❌ no update needed | Records still exist |

---

## 11. Error States

| Layer | Error | User-Facing Behaviour |
|-------|-------|-----------------------|
| ShareExtension | Non-YouTube URL | Alert: "Not a YouTube link" |
| ShareExtension | App Group write fails | Alert: "Failed to save. Try again." |
| YouTubeAPIService | Network error | Silently save with videoID as title |
| YouTubeAPIService | 403 quota exceeded | Silently save with videoID as title |
| YouTubeAPIService | Empty items | Silently save with videoID as title |
| DeepLinkService | vnd.youtube unavailable | Safari fallback (transparent) |
| BookmarkRepository | SwiftData error | Alert via .alert() in View |
| Widget | "widgetData" missing/empty | Placeholder "No bookmarks yet" |

---

## 12. App Group UserDefaults Keys Reference

| Key | Written by | Read by | Deleted by | Format |
|-----|------------|---------|------------|--------|
| `pendingRecord` | ShareExtension | Main App | Main App (after ingest) | JSON string |
| `widgetData` | Main App | BookmarkWidget | Never (overwritten) | JSON array string |
| `hasCompletedOnboarding` | Main App | Main App | Never | Bool |
