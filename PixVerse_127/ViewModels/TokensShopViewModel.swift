import Foundation
import Combine
import ApphudSDK
import StoreKit

struct TokenProduct {
    let id: String
    let amount: Int
    let price: String
    let productId: String
    let saveText: String?
}

class TokensShopViewModel: ObservableObject {
    @Published var title: String = "Get Tokens"
    @Published var descriptionText: String = "Buy tokens to generate more amazing content!"
    @Published var tokenProducts: [TokenProduct] = []
    @Published var purchaseStatus: PurchaseStatus? = nil
    @Published var isLoadingProducts: Bool = false
    @Published var isPurchasing: Bool = false
    @Published var myTokens: Int = 56 

    enum PurchaseStatus {
        case success(TokenProduct)
        case failure(String)
        case cancelled
    }

    private var apphudProducts: [ApphudProduct] = []

    init() {
        print("[TokensShop] Init TokensShopViewModel")
        Task { @MainActor in
            self.subscribeToPaywalls()
        }
    }

    @MainActor
    private func subscribeToPaywalls() {
        print("[TokensShop] Start loading paywalls...")
        self.isLoadingProducts = true
        Apphud.paywallsDidLoadCallback { [weak self] paywalls, error in
            guard let self = self else { return }

            self.isLoadingProducts = false

            if let error = error {
                print("[TokensShop] ❌ Error loading paywalls: \(error.localizedDescription)")
                return
            }

            guard let paywall = paywalls.first(where: { $0.identifier == "tokens" }),
                  !paywall.products.isEmpty else {
                print("[TokensShop] ❌ No paywall with identifier 'Tokens' or no products found")
                return
            }

            let products = paywall.products
            self.apphudProducts = products

            self.tokenProducts = products.map { product in
                let tokenAmount = self.tokenAmount(for: product.productId)
                let price = product.skProduct?.price.stringValue ?? "?"
                let currency = product.skProduct?.priceLocale.currencySymbol ?? "?"
                print("[TokensShop] Product loaded: id=\(product.productId), amount=\(tokenAmount), price=\(price) \(currency)")
                return TokenProduct(
                    id: UUID().uuidString,
                    amount: tokenAmount,
                    price: "\(price) \(currency)",
                    productId: product.productId,
                    saveText: product.skProduct.map { self.calculateSaveText(for: $0) } ?? nil
                )
            }
            print("[TokensShop] tokenProducts count after map: \(self.tokenProducts.count)")
        }
    }

    @MainActor
    func purchaseProduct(product: TokenProduct) {
        print("[Tokens] 🛒 Покупка токенов: productId=\(product.productId), amount=\(product.amount), price=\(product.price)")
        isPurchasing = true
        Apphud.purchase(product.productId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isPurchasing = false
                if let purchase = result.nonRenewingPurchase, result.error == nil {
                    print("[Tokens] ✅ Покупка успешна: \(purchase.productId), amount=\(product.amount)")
                    self?.purchaseStatus = .success(product)
                    Manager.shared.updateGenerations(userId: Manager.shared.userId, bundleId: Bundle.main.bundleIdentifier ?? "")
                } else if let error = result.error {
                    print("[Tokens] ❌ Ошибка покупки: \(error.localizedDescription)")
                    self?.purchaseStatus = .failure(error.localizedDescription)
                } else {
                    print("[Tokens] ⚠️ Покупка отменена пользователем")
                    self?.purchaseStatus = .cancelled
                }
            }
        }
    }

    private func tokenAmount(for productId: String) -> Int {
        let components = productId.split(separator: ".").first?.split(separator: "_")
        guard let amountString = components?.first else { return 0 }
        return Int(amountString) ?? 0
    }

    private func calculateSaveText(for product: SKProduct) -> String? {
        let basePrices: [String: Decimal] = [
            "com.appname.100tokens": 19.99,
            "com.appname.500tokens": 99.95,
            "com.appname.1000tokens": 199.90,
            "com.appname.2000tokens": 399.80
        ]

        let productId = product.productIdentifier
        guard let basePrice = basePrices[productId] else { return nil }

        let actualPrice = product.price as Decimal
        let basePriceDouble = NSDecimalNumber(decimal: basePrice).doubleValue
        let actualPriceDouble = NSDecimalNumber(decimal: actualPrice).doubleValue

        if actualPriceDouble < basePriceDouble {
            let discount = ((basePriceDouble - actualPriceDouble) / basePriceDouble * 100).rounded()
            return "SAVE \(Int(discount))%"
        }

        return nil
    }
} 
