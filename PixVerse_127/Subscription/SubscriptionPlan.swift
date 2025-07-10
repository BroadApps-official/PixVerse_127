import SwiftUI
import ApphudSDK

struct SubscriptionPlan: Identifiable {
    let id = UUID()
    let period: String
    let price: String
    let pricePerWeek: String
    var isSelected: Bool
    let apphudProduct: ApphudProduct
    let discountPercentage: Int?
    let trialDescription: String?
}
