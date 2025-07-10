import SwiftUI
import ApphudSDK
import Foundation
import UIKit

class Manager: ObservableObject {
    static let shared = Manager()
    
    @Published var isSubscribed: Bool = false
    @Published private(set) var userId: String = ""
    @Published private(set) var token: String = ""
    @Published private(set) var paywalls: [ApphudPaywall] = []
    @Published var availableGenerations: Int = 0
    private var isLoadingGenerations = false
    
    private init() {}
    
    func updateUserId(_ id: String) {
        self.userId = id
    }
    
    func updateGenerations(userId: String, bundleId: String) {
        guard !isLoadingGenerations else { return }
        isLoadingGenerations = true
        APIService.shared.fetchAvailableGenerations(userId: userId, bundleId: bundleId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoadingGenerations = false
                switch result {
                case .success(let count):
                    print("[Tokens] ✅ Получено количество токенов: \(count)")
                    self?.availableGenerations = count
                case .failure(let error):
                    print("[Tokens] ❌ Ошибка загрузки токенов: \(error.localizedDescription)")
                    self?.availableGenerations = 0
                }
            }
        }
    }
}
