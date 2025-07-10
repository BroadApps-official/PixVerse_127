import Foundation
import ApphudSDK
import StoreKit
import Combine

class SubscriptionViewModel: ObservableObject {
    
    enum SubscriptionType {
        case weekly
        case yearly
    }
    
    @Published var selectedSubscription: SubscriptionType? = nil
    @Published var isPurchasing: Bool = false
    @Published var products: [ApphudProduct] = []
    @Published var currentPaywall: ApphudPaywall?
    @Published var subscriptionPlans: [SubscriptionPlan] = []
    
    private var weeklyPricePerWeek: Double?
    
    @MainActor
    func loadPaywall(identifier: String = "main") {
        print("🔄 [loadPaywall] Start loading paywall with identifier: \(identifier)")
        
        Apphud.paywallsDidLoadCallback { [weak self] paywalls, error in
            guard let self = self else {
                print("❌ [loadPaywall] ViewModel deallocated")
                return
            }
            
            if let error = error {
                print("❌ [loadPaywall] Failed to load paywalls: \(error.localizedDescription)")
                return
            }

            print("✅ [loadPaywall] Paywalls loaded: \(paywalls.count)")
            
            for pw in paywalls {
                print("➡️ Paywall: \(pw.identifier), products: \(pw.products.map { $0.productId })")
            }

            guard let paywall = paywalls.first(where: { $0.identifier == identifier }) else {
                print("❌ [loadPaywall] Paywall '\(identifier)' not found")
                return
            }

            let validProducts = paywall.products.filter { $0.skProduct != nil }
            if validProducts.isEmpty {
                print("❌ [loadPaywall] No valid products (skProduct == nil)")
                return
            }

            print("✅ [loadPaywall] Valid products: \(validProducts.map { $0.productId })")

            Apphud.paywallShown(paywall)
            
            DispatchQueue.main.async {
                self.currentPaywall = paywall
                self.products = validProducts
                self.prepareSubscriptionPlans()
            }
        }
    }
    
    @MainActor func purchaseSubscription() {
        guard let selectedType = selectedSubscription else {
            print("Error: No subscription selected")
            return
        }
        guard let product = getSelectedProduct(for: selectedType) else {
            print("Error: No product found for \(selectedType)")
            return
        }
        
        print("Purchasing product: \(product.productId)")
        isPurchasing = true
        
        Apphud.purchase(product) { [weak self] result in
            DispatchQueue.main.async {
                self?.isPurchasing = false
                if let error = result.error {
                    print("Purchase failed: \(error.localizedDescription)")
                } else if result.subscription != nil || result.nonRenewingPurchase != nil {
                    print("Purchase successful")
                    NotificationCenter.default.post(name: .reloadApp, object: nil)
                } else {
                    print("Purchase cancelled or not processed")
                }
            }
        }
    }
    
    @MainActor func restorePurchases(completion: @escaping (Bool) -> Void) {
        print("Restoring purchases...")
        Apphud.restorePurchases { subscriptions, purchases, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Restore failed: \(error.localizedDescription)")
                }
                let restored = (subscriptions?.isEmpty == false || purchases?.isEmpty == false)
                print("Restore result: \(restored)")
                completion(restored)
            }
        }
    }
    
    func selectPlan(_ plan: SubscriptionPlan) {
        print("Selecting plan: \(plan.period)")
        subscriptionPlans.indices.forEach { subscriptionPlans[$0].isSelected = false }
        if let index = subscriptionPlans.firstIndex(where: { $0.id == plan.id }) {
            subscriptionPlans[index].isSelected = true
            selectedSubscription = plan.period.lowercased().contains("year") ? .yearly : .weekly
            print("Selected subscription: \(selectedSubscription?.description ?? "none")")
        }
    }
    
    private func getSelectedProduct(for type: SubscriptionType) -> ApphudProduct? {
        switch type {
        case .weekly:
            let weeklyProduct = products.first(where: { $0.productId == "week_4.99_nottrial"})
            print("Selected weekly product: \(weeklyProduct?.productId ?? "none")")
            return weeklyProduct
        case .yearly:
            let yearlyProduct = products.first(where: { $0.productId == "yearly_39.99_nottrial" && $0.skProduct?.subscriptionPeriod?.unit == .year })
            print("Selected yearly product: \(yearlyProduct?.productId ?? "none")")
            return yearlyProduct
        }
    }
    
    private func prepareSubscriptionPlans() {
        print("🛠️ [prepareSubscriptionPlans] Start preparing plans...")
        var newPlans: [SubscriptionPlan] = []
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency

        let sortedProducts = products.sorted {
            ($0.skProduct?.price.doubleValue ?? 0) < ($1.skProduct?.price.doubleValue ?? 0)
        }

        if let weeklyProduct = sortedProducts.first(where: { $0.productId == "week_4.99_nottrial" }) {
            weeklyPricePerWeek = weeklyProduct.skProduct?.price.doubleValue
            print("📊 Weekly base price: \(weeklyPricePerWeek ?? 0)")
        }

        for product in sortedProducts.reversed() {
            guard let skProduct = product.skProduct else {
                print("⚠️ Skipping product \(product.productId): No skProduct")
                continue
            }

            formatter.locale = skProduct.priceLocale
            let priceString = formatter.string(from: skProduct.price) ?? "\(skProduct.price)"
            let priceValue = skProduct.price.doubleValue
            var periodString: String
            var pricePerWeek: String
            var discountPercentage: Int? = nil
            var trialDescription: String? = nil

            switch product.productId {
            case "yearly_39.99_nottrial":
                periodString = "yearly"
                let weeksInYear = 52.0
                let weeklyPrice = priceValue / weeksInYear
                pricePerWeek = formatter.string(from: NSNumber(value: weeklyPrice)) ?? "\(weeklyPrice)"
                if let weeklyBase = weeklyPricePerWeek {
                    let yearlyCost = weeklyBase * weeksInYear
                    let savings = yearlyCost - priceValue
                    discountPercentage = Int((savings / yearlyCost) * 100)
                }

            case "week_4.99_nottrial":
                periodString = "weekly"
                pricePerWeek = priceString

            default:
                periodString = "unknown"
                pricePerWeek = priceString
            }

            // Free trial detection
            if let intro = skProduct.introductoryPrice, intro.price == 0 {
                let unit = intro.subscriptionPeriod.unit
                let count = intro.subscriptionPeriod.numberOfUnits
                let unitString: String
                switch unit {
                case .day: unitString = count == 1 ? "day" : "days"
                case .week: unitString = count == 1 ? "week" : "weeks"
                case .month: unitString = count == 1 ? "month" : "months"
                case .year: unitString = count == 1 ? "year" : "years"
                @unknown default: unitString = "period"
                }
                trialDescription = "\(count) \(unitString) free trial"
            }

            print("🧩 Adding plan → ID: \(product.productId), Period: \(periodString), Price: \(priceString), Trial: \(trialDescription ?? "none")")

            let plan = SubscriptionPlan(
                period: periodString,
                price: priceString,
                pricePerWeek: "\(pricePerWeek)/week",
                isSelected: periodString == "yearly",
                apphudProduct: product,
                discountPercentage: discountPercentage,
                trialDescription: trialDescription
            )

            newPlans.append(plan)
        }

        DispatchQueue.main.async {
            self.subscriptionPlans = newPlans
            print("✅ [prepareSubscriptionPlans] Final plans:")
            for plan in newPlans {
                print("   • \(plan.period): \(plan.price) (\(plan.pricePerWeek))")
            }

            if !newPlans.isEmpty && self.selectedSubscription == nil {
                self.selectPlan(newPlans[0])
                print("🟢 Default selected plan: \(newPlans[0].period)")
            } else if newPlans.isEmpty {
                print("❌ [prepareSubscriptionPlans] No valid plans generated")
            }
        }
    }
}

extension SubscriptionViewModel.SubscriptionType: CustomStringConvertible {
    var description: String {
        switch self {
        case .weekly: return "weekly"
        case .yearly: return "yearly"
        }
    }
}

extension Notification.Name {
    static let reloadApp = Notification.Name("reloadApp")
}
