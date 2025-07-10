import Foundation
import Combine

class SeeAllViewModel: ObservableObject {
    @Published var sections: [EffectSection] = []
    @Published var categories: [String] = []
    @Published var selectedCategory: String = "" {
        didSet {
            updateEffectsForSelectedCategory()
        }
    }
    @Published var effectsForSelectedCategory: [Effect] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    init(selectedCategory: String) {
        self.selectedCategory = selectedCategory
    }

    func loadEffects() {
        isLoading = true
        APIService.shared.fetchTemplatesByCategories(appName: "com.dmyver.skp1l3n", ai: ["pika", "pv"]) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let categories):
                    let newSections = categories
                        .filter { $0.categoryTitleEn != "Hug and Kiss" }
                        .map { category in
                            EffectSection(
                                title: category.categoryTitleEn,
                                effects: category.templates.map { template in
                                    Effect(
                                        id: String(template.id),
                                        title: template.title ?? template.effect ?? "No name",
                                        imageUrl: template.previewSmall ?? template.preview ?? "trend1",
                                        category: EffectCategory(rawValue: category.categoryTitleEn ?? "") ?? .unknown
                                    )
                                }
                            )
                        }
                    self?.sections = newSections
                    let categoryNames = newSections.map { $0.title }
                    self?.categories = categoryNames
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
        if let section = sections.first(where: { $0.title == selectedCategory }) {
            effectsForSelectedCategory = section.effects
        } else {
            effectsForSelectedCategory = []
        }
    }
}
