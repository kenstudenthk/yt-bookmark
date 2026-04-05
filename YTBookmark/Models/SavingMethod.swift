// YTBookmark/Models/SavingMethod.swift
enum SavingMethod: String, Codable, CaseIterable {
    case ask     // Always show conflict sheet
    case cover   // Silently update existing record's timestamp + note
    case addNew  // Silently create a new record
}
