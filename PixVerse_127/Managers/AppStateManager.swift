import SwiftUI
import StoreKit
import UIKit

class AppStateManager: ObservableObject {
    @Published var shouldShowFeedback = false
    private let videoGenerationKey = "videoGenerationCount"
    private let appLaunchKey = "appLaunchCount"
    private let hasRatedKey = "hasRated"
    
    init() {
        registerDefaults()
        incrementAppLaunchCount()
        updateFeedbackState()
        Manager.shared.updateGenerations(userId: Manager.shared.userId, bundleId: Bundle.main.bundleIdentifier ?? "")
    }
    
    private func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            videoGenerationKey: 0,
            appLaunchKey: 0,
            hasRatedKey: false
        ])
    }
    
    func incrementVideoGeneration() {
        let currentCount = UserDefaults.standard.integer(forKey: videoGenerationKey)
        UserDefaults.standard.set(currentCount + 1, forKey: videoGenerationKey)
        updateFeedbackState()
    }
    
    private func incrementAppLaunchCount() {
        let currentCount = UserDefaults.standard.integer(forKey: appLaunchKey)
        UserDefaults.standard.set(currentCount + 1, forKey: appLaunchKey)
        updateFeedbackState()
    }
    
    func markAsRated() {
        UserDefaults.standard.set(true, forKey: hasRatedKey)
        shouldShowFeedback = false
    }
    
    private func updateFeedbackState() {
        let videoCount = UserDefaults.standard.integer(forKey: videoGenerationKey)
        let launchCount = UserDefaults.standard.integer(forKey: appLaunchKey)
        let hasRated = UserDefaults.standard.bool(forKey: hasRatedKey)
        
        shouldShowFeedback = !hasRated && (
            videoCount == 3 ||
            videoCount == 6 ||
            launchCount == 3
        )
    }
}
