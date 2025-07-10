import SwiftUI
import ApphudSDK

class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()
    @Published var hasSubscription = false
    @Published var isLoading = true
    
    private init() {
        hasSubscription = Apphud.hasActiveSubscription()
    }
    
    @MainActor func checkSubscriptionStatus() async {
        hasSubscription = Apphud.hasActiveSubscription()
        if let subscriptions = Apphud.subscriptions() {
            hasSubscription = !subscriptions.isEmpty
        }
        print("Subscription status: \(hasSubscription)")
        isLoading = false
    }
}
