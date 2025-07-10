import SwiftUI

class SettingsViewModel: ObservableObject {
    @Published var sections: [SettingsSection]
    
    init() {
        self.sections = [
            SettingsSection(title: nil, items: [
                SettingsItem(title: "Higgsfield Pro", icon: "crown.fill", type: .navigation)
            ]),
            SettingsSection(title: "App Settings", items: [
                SettingsItem(title: "Notifications", icon: "bell.fill", type: .toggle, isToggled: true),
                SettingsItem(title: "Auto Save", icon: "square.and.arrow.down.fill", type: .toggle, isToggled: true)
            ]),
            SettingsSection(title: "Support", items: [
                SettingsItem(title: "Rate App", icon: "star.fill", type: .navigation),
                SettingsItem(title: "Share App", icon: "square.and.arrow.up.fill", type: .navigation),
                SettingsItem(title: "Privacy Policy", icon: "hand.raised.fill", type: .navigation),
                SettingsItem(title: "Terms of Use", icon: "doc.fill", type: .navigation)
            ])
        ]
    }
} 