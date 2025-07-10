import SwiftUI

class PhotoViewModel: ObservableObject {
    // MARK: - Properties for Styles/Effects
    @Published var categories: [StyleCategory] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    // MARK: - Properties for Text-to-Image
    @Published var prompt: String = "" {
        didSet {
            if prompt.count > 300 {
                prompt = String(prompt.prefix(300))
            }
        }
    }
    @Published var isGenerating = false
    @Published var generationStatus: String?
    @Published var resultUrl: String?
    @Published var showError = false
    
    private var pollTimer: Timer?

    init() {
        fetchStyles()
    }
    
    // MARK: - Methods for Styles/Effects
    func fetchStyles() {
        isLoading = true
        errorMessage = nil
        // Используем новый метод с кэшем
        PhotoAPIService.shared.fetchStylesWithCache { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let categories):
                    self?.categories = categories
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Methods for Text-to-Image
    func generateImageFromPrompt() {
        guard !prompt.isEmpty else {
            errorMessage = "Please enter a prompt"
            showError = true
            return
        }

        isGenerating = true
        generationStatus = "Sending prompt..."
        let userId = UIDevice.current.identifierForVendor?.uuidString ?? "ios-test-user-1121"
        let historyId = UUID().uuidString
        
        let historyItem = HistoryItem(
            id: historyId,
            date: Date(),
            previewUrl: nil,
            resultUrl: nil,
            status: .inProgress,
            type: .photo,
            prompt: prompt,
            jobId: nil,
            generationId: nil
        )
        HistoryViewModel.shared.add(item: historyItem)
        
        PhotoAPIService.shared.generatePhotoFromText(userId: userId, prompt: prompt) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let jobId):
                    self?.pollStatus(jobId: jobId, historyId: historyId)
                case .failure(let error):
                    self?.isGenerating = false
                    self?.errorMessage = error.localizedDescription
                    self?.showError = true
                    HistoryViewModel.shared.updateStatus(id: historyId, status: .failed, resultUrl: nil)
                }
            }
        }
    }

    private func pollStatus(jobId: String, historyId: String) {
        generationStatus = "Generating image..."
        let userId = UIDevice.current.identifierForVendor?.uuidString ?? "ios-test-user-1121"
        
        pollTimer?.invalidate()
        
        pollTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] timer in
            PhotoAPIService.shared.checkGenerationStatus(userId: userId, jobId: jobId) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let statusResponse):
                        if let data = statusResponse.data {
                            self?.generationStatus = "Status: \(data.status ?? "...") (\(data.progress ?? 0)%)"
                            
                            let status = data.status?.lowercased()
                            
                            if status == "completed" || status == "succeeded" {
                                if let url = data.resultUrl {
                                    self?.isGenerating = false
                                    self?.resultUrl = url
                                    HistoryViewModel.shared.updateStatus(id: historyId, status: .finished, resultUrl: url)
                                    timer.invalidate()
                                }
                            } else if status == "failed" || status == "error" {
                                self?.isGenerating = false
                                self?.errorMessage = data.error ?? "Generation failed"
                                self?.showError = true
                                HistoryViewModel.shared.updateStatus(id: historyId, status: .failed, resultUrl: nil)
                                timer.invalidate()
                            }
                        }
                    case .failure(let error):
                        self?.isGenerating = false
                        self?.errorMessage = error.localizedDescription
                        self?.showError = true
                        HistoryViewModel.shared.updateStatus(id: historyId, status: .failed, resultUrl: nil)
                        timer.invalidate()
                    }
                }
            }
        }
    }
    
    func resetPromptState() {
        resultUrl = nil
        prompt = ""
    }
    
    func pasteFromClipboard() {
        if let string = UIPasteboard.general.string {
            prompt = string
        }
    }

    deinit {
        pollTimer?.invalidate()
    }
} 
