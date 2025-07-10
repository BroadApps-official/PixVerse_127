import Foundation
import Combine

class PhotoSeeAllViewModel: ObservableObject {
    @Published var categories: [StyleCategory] = []
    @Published var categoryNames: [String] = []
    @Published var selectedCategory: String = "" {
        didSet {
            updateEffectsForSelectedCategory()
        }
    }
    @Published var effectsForSelectedCategory: [Template] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    init(selectedCategory: String) {
        self.selectedCategory = selectedCategory
    }

    func loadStyles() {
        isLoading = true
        PhotoAPIService.shared.fetchStylesWithCache { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let categories):
                    self?.categories = categories
                    let categoryNames = categories.compactMap { $0.title }
                    self?.categoryNames = categoryNames
                    if categoryNames.contains(self?.selectedCategory ?? "") {
                        // Оставляем выбранную категорию
                    } else if let firstCategory = categoryNames.first {
                        self?.selectedCategory = firstCategory
                    }
                    self?.updateEffectsForSelectedCategory()
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func updateEffectsForSelectedCategory() {
        if let category = categories.first(where: { $0.title == selectedCategory }) {
            effectsForSelectedCategory = category.templates
        } else {
            effectsForSelectedCategory = []
        }
    }
} 