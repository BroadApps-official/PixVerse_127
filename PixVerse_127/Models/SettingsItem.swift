import Foundation

enum SettingsItemType {
    case toggle
    case navigation
    case button
}

struct SettingsItem: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let type: SettingsItemType
    var isToggled: Bool = false
    var action: (() -> Void)?
}

struct SettingsSection: Identifiable {
    let id = UUID()
    let title: String?
    let items: [SettingsItem]
} 