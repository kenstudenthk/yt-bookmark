# YT Bookmark

> Save your place in any YouTube or Bilibili video — resume exactly where you left off.

YT Bookmark is a native iOS app that captures video timestamps directly from the Share Sheet. Share a YouTube or Bilibili link while watching, add an optional note, and the app stores the exact timestamp. Tap any bookmark to reopen the video at that moment. Organise bookmarks into colour-coded folders, search across everything, and glance at your most recent saves from a home screen widget.

---

## Features

- **One-tap save from any browser** — share a YouTube or Bilibili URL, the timestamp is captured automatically
- **Bilibili support** — handles `b23.tv` short links, `BV` IDs, and the Bilibili API (no key required)
- **Resume playback** — opens the native YouTube / Bilibili app at the saved second; falls back to Safari
- **Folders** — colour-coded, unlimited folders; move bookmarks between them from a sheet
- **Notes** — attach up to 500 characters of personal notes to any bookmark
- **Search** — global full-text search across titles and notes with 300 ms debounce
- **Home screen widget** — small (1 bookmark) and medium (3 bookmarks) WidgetKit sizes with deep-link taps
- **Offline resilience** — if API metadata fetch fails on save, the app retries silently on every next launch
- **Onboarding** — three-screen walkthrough shown once on first launch

---

## Requirements

| Requirement | Version |
|---|---|
| iOS | 17.0+ |
| Xcode | 15.0+ |
| Swift | 5.9+ |
| YouTube Data API v3 key | Required (free quota) |

---

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/kenstudenthk/yt-bookmark.git
cd yt-bookmark
```

### 2. Install XcodeGen

The project file is generated from `project.yml` using [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
xcodegen generate
```

### 3. Configure the YouTube API key

Create `YTBookmark/App/Config.xcconfig` (this file is gitignored):

```
YOUTUBE_API_KEY = YOUR_KEY_HERE
```

Get a free key from [Google Cloud Console](https://console.cloud.google.com/) → APIs & Services → YouTube Data API v3.

### 4. Set your development team

Open `project.yml` and replace `467H2GUMWN` with your own Apple Developer Team ID in all three target entries, then re-run `xcodegen generate`.

### 5. Build & run

```bash
# Build for simulator
xcodebuild -project YTBookmark.xcodeproj \
  -scheme YTBookmark \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  build

# Run tests
xcodebuild test \
  -project YTBookmark.xcodeproj \
  -scheme YTBookmark \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

Or open `YTBookmark.xcodeproj` in Xcode and press **⌘R**.

---

## Architecture

```
┌────────────────────────────────────────────────────┐
│                    Main App                        │
│  SwiftUI + SwiftData  ·  MVVM + Repository         │
│                                                    │
│  BookmarkRepository  ←──  @Query / ModelContext    │
│  PendingRecordService ──→  YouTubeAPIService        │
│                       ──→  BilibiliAPIService       │
│  WidgetDataService   ──→  App Group UserDefaults   │
└──────────────┬─────────────────┬───────────────────┘
               │  App Group      │  App Group
               ▼                 ▼
┌──────────────────┐   ┌─────────────────────────┐
│ Share Extension  │   │    BookmarkWidget        │
│ Writes pending   │   │  Reads widgetData JSON   │
│ record JSON      │   │  WidgetKit timeline      │
└──────────────────┘   └─────────────────────────┘
```

**Key rules:**
- Share Extension and Widget **never access SwiftData** — they use App Group `UserDefaults` only
- `BookmarkRepository` is the **only** layer that reads or writes SwiftData
- All ViewModels use `@Observable` (iOS 17+) — never `@StateObject`
- Data objects are **immutable** — new instances are created on every mutation

---

## Project Structure

```
YTBookmark/
├── App/
│   ├── YTBookmarkApp.swift          # Entry point, scenePhase ingestion, deep-link handler
│   └── Config.xcconfig              # API key (gitignored)
├── Models/
│   ├── VideoRecord.swift            # SwiftData — stores one bookmark
│   ├── Folder.swift                 # SwiftData — colour-coded group
│   └── BookmarkStamp.swift          # SwiftData — future stamps feature
├── Repositories/
│   └── BookmarkRepository.swift     # Only layer that reads/writes SwiftData
├── Services/
│   ├── YouTubeAPIService.swift      # YouTube Data API v3 — title + thumbnail
│   ├── BilibiliAPIService.swift     # Bilibili web API — title + thumbnail (no key)
│   ├── DeepLinkService.swift        # Opens YouTube / Bilibili app or Safari
│   ├── PendingRecordService.swift   # App Group ingestion + enrichment retry
│   └── WidgetDataService.swift      # Writes top-5 bookmarks to App Group
├── Parsers/
│   ├── YouTubeURLParser.swift       # Handles youtu.be, youtube.com, shorts, embeds
│   └── BilibiliURLParser.swift      # Handles bilibili.com, m.bilibili.com, BV IDs
├── ViewModels/
│   ├── BookmarkListViewModel.swift
│   ├── FolderListViewModel.swift
│   └── SearchViewModel.swift        # 300 ms debounce
├── Views/
│   ├── BookmarkList/
│   ├── Folders/
│   ├── Search/
│   └── Onboarding/
ShareExtension/
├── ShareViewController.swift        # NSExtensionRequestHandling entry point
├── ShareViewModel.swift             # URL extraction, b23.tv resolution, dual parser
└── ShareView.swift                  # SwiftUI sheet shown in share sheet
BookmarkWidget/
├── BookmarkWidget.swift             # TimelineProvider, small + medium views
└── WidgetEntry.swift                # Lightweight Codable snapshot (no SwiftData)
YTBookmarkTests/
├── YouTubeURLParserTests.swift
└── BilibiliURLParserTests.swift     # 19 test cases
```

---

## App Group Keys

| Key | Written by | Read by |
|---|---|---|
| `pendingRecord` | Share Extension | Main App (on `.active`) |
| `widgetData` | Main App | Widget |

---

## Supported URL Formats

### YouTube
| Format | Example |
|---|---|
| Short link | `https://youtu.be/dQw4w9WgXcQ?t=42` |
| Full URL | `https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42` |
| Shorts | `https://www.youtube.com/shorts/dQw4w9WgXcQ` |
| Embed | `https://www.youtube.com/embed/dQw4w9WgXcQ` |

### Bilibili
| Format | Example |
|---|---|
| Short link (b23.tv) | `https://b23.tv/UXCLMx2` |
| Full URL | `https://www.bilibili.com/video/BV1xx411c7mD` |
| Mobile | `https://m.bilibili.com/video/BV1xx411c7mD?t=60` |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 5.9 |
| UI | SwiftUI |
| Persistence | SwiftData |
| State management | `@Observable` (iOS 17) |
| Widget | WidgetKit |
| Project file | XcodeGen (`project.yml`) |
| YouTube metadata | YouTube Data API v3 |
| Bilibili metadata | `api.bilibili.com` (public, no auth) |

---

## License

MIT
