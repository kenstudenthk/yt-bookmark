# CLAUDE.md — YT Bookmark Project Rules

> Read this file ONCE at session start. Reference only when needed.

---

## Project Overview

**YT Bookmark** — iOS app that saves YouTube timestamps via Share Extension,
organises them in folders, and resumes YouTube playback at the exact saved position.

**Bundle ID:** com.myapp.ytbookmark
**App Group:** group.com.myapp.ytbookmark
**Minimum iOS:** 17.0

---

## Xcode Targets

| Target | Bundle ID | Purpose |
|--------|-----------|---------|
| YTBookmark | com.myapp.ytbookmark | Main app |
| ShareExtension | com.myapp.ytbookmark.share | Receives YouTube URLs |
| BookmarkWidget | com.myapp.ytbookmark.widget | WidgetKit home screen widget |

All 3 targets must share App Group: `group.com.myapp.ytbookmark`

---

## Tech Stack

- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI
- **Persistence:** SwiftData (main app only)
- **State Management:** @Observable (iOS 17+, NOT @StateObject)
- **Widget:** WidgetKit
- **API:** YouTube Data API v3 (public key, no OAuth)
- **Architecture:** MVVM + Repository pattern

---

## Folder Structure

```
YTBookmark/
├── App/
│   ├── YTBookmarkApp.swift          # App entry point, scenePhase ingestion
│   └── Config.xcconfig              # API key (gitignored)
├── Models/
│   ├── VideoRecord.swift            # SwiftData model
│   ├── Folder.swift                 # SwiftData model
│   └── BookmarkStamp.swift          # SwiftData model
├── Repositories/
│   └── BookmarkRepository.swift     # ONLY layer that reads/writes SwiftData
├── Services/
│   ├── YouTubeAPIService.swift      # YouTube Data API v3 calls
│   ├── DeepLinkService.swift        # vnd.youtube:// + Safari fallback
│   ├── PendingRecordService.swift   # App Group UserDefaults ingestion
│   └── WidgetDataService.swift      # Writes widgetData to App Group
├── Parsers/
│   └── YouTubeURLParser.swift       # URL parsing (all 4 formats)
├── ViewModels/
│   ├── BookmarkListViewModel.swift
│   ├── FolderListViewModel.swift
│   └── SearchViewModel.swift
├── Views/
│   ├── Onboarding/
│   ├── BookmarkList/
│   ├── Folders/
│   └── Search/
├── Resources/
│   └── Assets.xcassets
ShareExtension/
├── ShareViewController.swift
├── ShareViewModel.swift
└── Info.plist
BookmarkWidget/
├── BookmarkWidget.swift
├── WidgetEntry.swift
└── Info.plist
YTBookmarkTests/
└── YouTubeURLParserTests.swift      # XCTest unit tests
```

---

## Architecture Rules (NEVER violate)

1. **Share Extension MUST NOT access SwiftData directly** — use App Group UserDefaults only
2. **Widget reads from App Group UserDefaults only** — not SwiftData
3. **API key in Config.xcconfig, loaded via Bundle** — never hardcode in source
4. **All errors surface to user via .alert()** — never silent fail
5. **Repository is the only layer that reads/writes SwiftData**
6. **ViewModels use @Observable** — never @StateObject or @ObservedObject
7. **All data objects are immutable** — create new instances, never mutate in place

---

## App Group Keys

| Key | Type | Used by |
|-----|------|---------|
| `pendingRecord` | JSON String | ShareExtension writes, Main App reads+deletes |
| `widgetData` | JSON Array String (max 5) | Main App writes, Widget reads |
| `hasCompletedOnboarding` | Bool | Main App only |

---

## Commit Message Format

```
<type>: <description>
```

Types: `feat` / `fix` / `refactor` / `docs` / `test` / `chore` / `perf`

Examples:
```
feat: implement YouTubeURLParser with all 4 formats
test: add XCTest coverage for URL parsing edge cases
fix: handle missing t= parameter gracefully
```

---

## Build Commands

```bash
# Build main app
xcodebuild -project YTBookmark.xcodeproj -scheme YTBookmark -sdk iphonesimulator build

# Run tests
xcodebuild test -project YTBookmark.xcodeproj -scheme YTBookmark -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15'

# Archive for distribution
xcodebuild archive -project YTBookmark.xcodeproj -scheme YTBookmark -archivePath build/YTBookmark.xcarchive
```

---

## Critical Rules for All Agents

- **Before writing any code:** describe approach and wait for approval (unless explicitly told to proceed)
- **Task scope:** if a task touches more than 3 files, break it into smaller tasks first
- **Bug fixing:** always write a failing test first, then fix until it passes
- **After writing code:** list what could break and suggest tests
- **Never fix a bug without a failing test first**

---

## Session Handover Protocol

1. Update `TASKS.md` — mark completed tasks `[x]`
2. Update `PROGRESS.md` — log what was done
3. Write `HANDOVER.md` — bridge for next session (see TASKS.md for format)
4. Run `/clear` after each task

---

## Config.xcconfig Template (do NOT commit actual key)

```
YOUTUBE_API_KEY = YOUR_KEY_HERE
```

Load in Swift:
```swift
let key = Bundle.main.infoDictionary?["YouTubeAPIKey"] as? String ?? ""
```

Info.plist entry:
```xml
<key>YouTubeAPIKey</key>
<string>$(YOUTUBE_API_KEY)</string>
```
