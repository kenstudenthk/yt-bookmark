# TASKS.md — YT Bookmark Phase-by-Phase Task List

> Update status after EVERY task: [ ] todo / [~] in progress / [x] done
> Mark [x] BEFORE ending session. Read HANDOVER.md first each new session.

---

## Phase 0 — Planning (Current Phase)

- [x] Create CLAUDE.md (project rules, architecture, folder structure)
- [x] Create SPEC.md (full specification)
- [x] Create TASKS.md (this file)
- [x] Update everything-claude-code hook to allow project .md files (requires session restart)
- [x] Create FLOWS.md (data flow + all user flows)
- [x] Validate SPEC.md completeness — 32 issues found and resolved

---

## Phase 1 — Architecture & Foundation

### 1A. Navigation & UX Architecture
- [x] Define NavigationStack structure (single stack + toolbar, no tab bar)
- [x] Define all screen states: empty / loading / error / success
- [x] Save as UX-ARCHITECTURE.md

### 1B. Xcode Project Setup
- [x] Create Xcode project with 3 targets: YTBookmark, ShareExtension, BookmarkWidget
- [x] Configure App Group: group.com.myapp.ytbookmark on all 3 targets
- [x] Add Config.xcconfig with YOUTUBE_API_KEY placeholder
- [x] Configure Info.plist: LSApplicationQueriesSchemes (vnd.youtube), YouTubeAPIKey, ytbookmark:// URL scheme
- [ ] Commit: chore: create Xcode project with 3 targets and App Group

### 1C. SwiftData Models
- [x] Implement VideoRecord.swift (@Model)
- [x] Implement Folder.swift (@Model)
- [x] Implement BookmarkStamp.swift (@Model)
- [ ] Commit: feat: implement SwiftData models

### 1D. URL Parser (TDD)
- [ ] Write failing XCTest: youtu.be with t= (format 1)
- [ ] Write failing XCTest: youtu.be without t= (format 2)
- [ ] Write failing XCTest: youtube.com/watch with t= (format 3)
- [ ] Write failing XCTest: youtube.com/watch with formatted time (format 4)
- [ ] Write failing XCTest: formatted time parser (1h3m30s edge cases)
- [ ] Write failing XCTest: non-YouTube URL returns nil
- [ ] Implement YouTubeURLParser.swift until all tests pass
- [ ] Commit: feat: implement YouTubeURLParser with full XCTest coverage

### 1E. Share Extension
- [ ] Implement ShareExtension NSExtensionPrincipalClass
- [ ] Implement ShareViewModel (parse URL, hold state)
- [ ] Implement ShareView (SwiftUI confirmation UI)
- [ ] Implement PendingRecord codable struct (shared)
- [ ] Write pendingRecord to App Group UserDefaults on Save
- [ ] Handle invalid URL: show error alert
- [ ] Commit: feat: implement Share Extension

### 1F. Core Services
- [ ] Implement YouTubeAPIService.swift (fetch title + thumbnail)
- [ ] Implement DeepLinkService.swift (vnd.youtube:// + Safari fallback)
- [ ] Implement PendingRecordService.swift (read, ingest, delete from App Group)
- [ ] Implement WidgetDataService.swift (write widgetData to App Group)
- [ ] Implement BookmarkRepository.swift (CRUD on SwiftData)
- [ ] Commit: feat: implement core services

### 1G. Pending Ingestion
- [ ] Wire PendingRecordService in YTBookmarkApp.swift on scenePhase .active
- [ ] Show success toast after ingestion
- [ ] Test: no internet fallback (save with videoID as title)
- [ ] Commit: feat: implement pending record ingestion

### 1H. API Testing
- [ ] Test YouTubeAPIService: success response
- [ ] Test YouTubeAPIService: network error fallback
- [ ] Test YouTubeAPIService: quota exceeded (403) fallback
- [ ] Test YouTubeAPIService: empty items fallback
- [ ] Commit: test: YouTube API service coverage

---

## Phase 2 — Core UI

### 2A. UI Design Notes
- [ ] Design bookmark list row (thumbnail, title, timestamp badge, date)
- [ ] Design empty states for all views
- [ ] Design folder grid card
- [ ] Save as UI-NOTES.md — @ui-designer

### 2B. Bookmark List View
- [ ] Implement BookmarkListView with NavigationStack
- [ ] Implement BookmarkRowView (thumbnail + title + badge + date)
- [ ] Implement timestamp badge (mm:ss or "Start")
- [ ] Implement thumbnail async loading with placeholder
- [ ] Implement toolbar (search icon + folder icon)
- [ ] Implement long press context menu (Edit Note / Move to Folder / Delete)
- [ ] Implement empty state view
- [ ] Commit: feat: implement BookmarkListView

### 2C. Folder Views
- [ ] Implement FolderListView (grid, 2 columns, + button)
- [ ] Implement FolderCardView (colour + name + count)
- [ ] Implement CreateFolderSheet (name field + colour picker)
- [ ] Implement FolderDetailView (records in folder)
- [ ] Implement delete folder with confirm alert
- [ ] Implement MoveFolderSheet (assign record to folder)
- [ ] Commit: feat: implement Folder views

### 2D. Search View
- [ ] Implement SearchView with search bar
- [ ] Implement SearchViewModel with 300ms debounce
- [ ] In-memory filter on VideoRecord.title (case-insensitive)
- [ ] Implement empty result state
- [ ] Commit: feat: implement Search

### 2E. Evidence Collection
- [ ] Verify all screens match UX-ARCHITECTURE.md
- [ ] Verify empty states render
- [ ] Verify error alerts show correctly
- [ ] Verify loading states display

---

## Phase 3 — Polish & Distribution

### 3A. Onboarding
- [ ] Implement OnboardingView (3 screens with TabView paging)
- [ ] Implement OnboardingScreen 1: Welcome
- [ ] Implement OnboardingScreen 2: How-to-save (YouTube share toggle)
- [ ] Implement OnboardingScreen 3: Done
- [ ] Gate onboarding on UserDefaults "hasCompletedOnboarding"
- [ ] Commit: feat: implement onboarding flow

### 3B. Animations & Polish
- [ ] Add success toast animation when bookmark saved
- [ ] Add empty state illustrations
- [ ] Polish transitions and animations
- [ ] Commit: feat: add polish and animations

### 3C. Widget
- [ ] Implement WidgetEntry.swift (TimelineEntry)
- [ ] Implement BookmarkWidget.swift (small + medium views)
- [ ] Implement WidgetProvider (read from App Group widgetData)
- [ ] Implement deep link handling in main app (ytbookmark://)
- [ ] Ensure main app writes widgetData on every SwiftData modification
- [ ] Set 30-minute refresh policy
- [ ] Commit: feat: implement WidgetKit

### 3D. Reality Check
- [ ] Full end-to-end validation against SPEC.md
- [ ] Test: no internet when saving
- [ ] Test: YouTube App not installed (Safari fallback)
- [ ] Test: duplicate records
- [ ] Test: widget tap opens YouTube
- [ ] Test: onboarding first launch / skipped after
- [ ] Sign off before Phase 4

---

## Phase 4 — App Store

### 4A. Legal & Compliance
- [ ] Verify YouTube Data API Terms of Service compliance
- [ ] Generate Privacy Policy template
- [ ] Confirm App Store Review Guidelines compliance

### 4B. App Store Optimisation
- [ ] Write App Store title (max 30 chars)
- [ ] Write subtitle and description
- [ ] Suggest keywords for ASO
- [ ] Write screenshot captions for each feature

---

## Completion Checklist

Before marking any feature done:
- [ ] All edge cases from SPEC.md handled
- [ ] XCTest coverage written (for logic layers)
- [ ] No hardcoded API keys
- [ ] Errors surface to user via .alert()
- [ ] Architecture rules NOT violated
