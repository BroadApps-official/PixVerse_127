import SwiftUI
import PhotosUI
import AVKit
import Combine

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedTab: HomeTab = .effects
    @State private var showSubscriptionSheet = false
    @State private var showTokensShop = false
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var manager = Manager.shared
    
    // MCP Prompt states
    @State private var promptText: String = ""
    @State private var usePhoto: Bool = false
    @State private var selectedPhoto: UIImage? = nil
    @State private var isGenerating: Bool = false
    @State private var resultUrl: String? = nil
    @State private var errorMessage: String? = nil
    @State private var showPhotoPicker: Bool = false
    @State private var showPhotoRequirements = false
    @State private var showLoadingView: Bool = false
    @State private var showResultView: Bool = false
    @State private var showResultUrlError: Bool = false
    @State private var pollingTimer: Timer? = nil
    @State private var selectedResolution: VideoResolution = .p720
    
    var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack {
                        Text("Higgsfield")
                            .font(.system(size: 34, weight: .bold))
                            .kerning(0.4)
                            .foregroundColor(.white)
                        Spacer()
                        if subscriptionManager.hasSubscription {
                            ProButtons(tokens: manager.availableGenerations, onTap: { showTokensShop = true })
                        } else {
                            ProButton(onTap: { showSubscriptionSheet = true })
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .fullScreenCover(isPresented: $showSubscriptionSheet) {
                        SubscriptionSheet(viewModel: SubscriptionViewModel())
                    }
                    .fullScreenCover(isPresented: $showTokensShop) {
                        TokensShopView()
                    }
                    SegmentedMenuView(selectedTab: $selectedTab)
                        .padding(.top, 16)
                    
                    ScrollView {
                        if selectedTab == .effects {
                            VStack(spacing: 20) {
                                if viewModel.isLoading {
                                    ForEach(0..<2, id: \.self) { _ in
                                        VStack(alignment: .leading, spacing: 12) {
                                            HStack {
                                                RoundedRectangle(cornerRadius: 6)
                                                    .fill(Color.gray.opacity(0.2))
                                                    .frame(width: 120, height: 22)
                                                Spacer()
                                            }
                                            ScrollView(.horizontal, showsIndicators: false) {
                                                HStack(spacing: 8) {
                                                    ForEach(0..<3, id: \.self) { _ in
                                                        RoundedRectangle(cornerRadius: 16)
                                                            .fill(Color.gray.opacity(0.15))
                                                            .frame(width: 140, height: 249)
                                                    }
                                                }
                                                .padding(.horizontal, 8)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical)
                                    }
                                } else if let error = viewModel.errorMessage {
                                    Text(error)
                                        .foregroundColor(.red)
                                        .padding()
                                } else {
                                    LazyVStack(spacing: 20) {
                                        ForEach(viewModel.sections) { section in
                                            EffectSectionView(title: section.title, effects: section.effects)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical)
                                }
                            }
                        } else {
                            promptView
                        }
                    }
                    
                    // Generate button - always at bottom
                    if selectedTab == .prompt {
                        VStack {
                            Button(action: {
                                if !subscriptionManager.hasSubscription {
                                    showSubscriptionSheet = true
                                    return
                                }
                                generate()
                            }) {
                                HStack {
                                    Spacer()
                                    Image(systemName: "wand.and.stars")
                                    Text("Generate")
                                        .font(.system(size: 17, weight: .bold))
                                    Spacer()
                                }
                                .foregroundColor(.black)
                                .padding(.vertical, 18)
                                .foregroundColor((promptText.isEmpty || promptText.count > 200) ? .white.opacity(0.5) : .black)
                                .background((promptText.isEmpty || promptText.count > 200 || (usePhoto && selectedPhoto == nil)) ? Color.gray.opacity(0.3) : Color.accentColor)
                                .cornerRadius(18)
                                .padding(.horizontal, 16)
                            }
                            .disabled(promptText.isEmpty || promptText.count > 200 || (usePhoto && selectedPhoto == nil) || isGenerating)
                            .padding(.bottom, 16)
                        }
                    }
                }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPicker(selectedImage: $selectedPhoto)
        }
        .fullScreenCover(isPresented: $showLoadingView) {
            GenerationLoadingView(onClose: {
                showLoadingView = false
                isGenerating = false
            })
        }
        .fullScreenCover(isPresented: $showResultView) {
            if let url = resultUrl, let videoUrl = URL(string: url) {
                GenerationResultView(videoUrl: videoUrl, onDismiss: {
                    showResultView = false
                    resultUrl = nil
                    promptText = ""
                })
            } else {
                Color.clear
                    .onAppear {
                        showResultView = false
                        showResultUrlError = true
                    }
            }
        }
        .alert(isPresented: $showResultUrlError) {
            Alert(title: Text("Ошибка"), message: Text("Не удалось открыть результат. Попробуйте ещё раз."), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            viewModel.loadEffects()
            Manager.shared.updateGenerations(userId: Manager.shared.userId, bundleId: Bundle.main.bundleIdentifier ?? "")
        }
    }
    
    // MARK: - Prompt View
    @ViewBuilder
    private var promptView: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.08))
                    CustomTextEditorContainer(text: $promptText)
                    if promptText.isEmpty {
                        Text("Enter any query to create your video using")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white.opacity(0.25))
                            .padding(.top, 16)
                            .padding(.horizontal, 14)
                    }
                }
                .frame(height: 240)
                .padding(.horizontal, 16)
                .padding(.top, 12)

                // Resolution section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Resolution")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                    HStack(spacing: 8) {
                        resolutionButton(for: .p720)
                        resolutionButton(for: .p1080)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.top, 12)
                .padding(.bottom, 12)

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Use a photo")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(.white)
                        Spacer()
                        Toggle("", isOn: $usePhoto)
                            .toggleStyle(SwitchToggleStyle(tint: Color(hex: "#9D3AE9")))
                    }

                    if usePhoto {
                        HStack {
                            Spacer()
                            Button(action: {
                                if !UserDefaults.standard.bool(forKey: "photoReqShown") {
                                    showPhotoRequirements = true
                                } else {
                                    showPhotoPicker = true
                                }
                            }) {
                                ZStack {
                                    if let image = selectedPhoto {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 140, height: 140)
                                            .clipShape(RoundedRectangle(cornerRadius: 20))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(Color(hex: "#9D3AE9"), style: StrokeStyle(lineWidth: 3, dash: [8]))
                                            )
                                            .overlay(
                                                Image(systemName: "arrow.2.circlepath")
                                                    .resizable()
                                                    .frame(width: 32, height: 32)
                                                    .foregroundColor(Color(hex: "#9D3AE9"))
                                                    .background(Color.black.opacity(0.6))
                                                    .clipShape(Circle())
                                                    .padding(6),
                                                alignment: .center
                                            )
                                    } else {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color(hex: "#232415"))
                                            .frame(width: 96, height: 96)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color(hex: "#9D3AE9"), style: StrokeStyle(lineWidth: 2, dash: [6]))
                                            )
                                            .overlay(
                                                Image(systemName: "plus")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 32, height: 32)
                                                    .foregroundColor(Color(hex: "#9D3AE9"))
                                            )
                                    }
                                }
                            }
                            Spacer()
                        }
                    }
                }
                .padding(16)
                .background(Color(hex: "#181818"))
                .cornerRadius(14)
                .padding(.horizontal, 16)
                .padding(.top, 24)

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.system(size: 15, weight: .regular))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                }
            }
        }
        .sheet(isPresented: $showPhotoRequirements) {
            PhotoRequirementsView {
                UserDefaults.standard.set(true, forKey: "photoReqShown")
                showPhotoRequirements = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showPhotoPicker = true
                }
            }
        }
    }
    
    // MARK: - Generate Function
    private func generate() {
        print("[HomeView] 🚀 generate() called")
        errorMessage = nil
        resultUrl = nil
        isGenerating = true
        showLoadingView = true

        guard !promptText.isEmpty else {
            print("[HomeView] ❌ Prompt is empty")
            errorMessage = "Prompt can't be empty"
            isGenerating = false
            return
        }

        let historyId = UUID().uuidString
        print("[HomeView] 🔑 Generated historyId: \(historyId)")
        
        let historyItem = HistoryItem(
            id: historyId,
            date: Date(),
            previewUrl: nil,
            resultUrl: nil,
            status: .inProgress,
            type: .video,
            prompt: promptText
        )
        
        print("[HomeView] 📝 Adding item to history: id=\(historyId), prompt=\(promptText)")
        HistoryViewModel.shared.add(item: historyItem)

        if usePhoto, let imageToSend = selectedPhoto {
            print("[HomeView] 🖼️ Starting generation with image: YES")
            GenerationManager.shared.generateImg2Video(prompt: promptText, image: imageToSend, resolution: selectedResolution) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let generationId):
                        print("[HomeView] ✅ Generation started successfully: \(generationId)")
                        self.pollVideoStatus(generationId: generationId, historyId: historyId)
                    case .failure(let error):
                        print("[HomeView] ❌ Generation failed: \(error)")
                        isGenerating = false
                        errorMessage = error.localizedDescription
                        print("[HomeView] 🔄 Updating history status to failed for id: \(historyId)")
                        HistoryViewModel.shared.updateStatus(id: historyId, status: .failed, resultUrl: nil)
                    }
                }
            }
        } else {
            print("[HomeView] 📝 Starting text-only generation")
            GenerationManager.shared.generateTxt2Video(prompt: promptText, resolution: selectedResolution) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let generationId):
                        print("[HomeView] ✅ Generation started successfully: \(generationId)")
                        self.pollVideoStatus(generationId: generationId, historyId: historyId)
                    case .failure(let error):
                        print("[HomeView] ❌ Generation failed: \(error)")
                        isGenerating = false
                        errorMessage = error.localizedDescription
                        print("[HomeView] 🔄 Updating history status to failed for id: \(historyId)")
                        HistoryViewModel.shared.updateStatus(id: historyId, status: .failed, resultUrl: nil)
                    }
                }
            }
        }
    }
    
    // MARK: - Poll Video Status
    private func pollVideoStatus(generationId: String, historyId: String) {
        print("[HomeView] 🔄 pollVideoStatus: \(generationId) for historyId: \(historyId)")
        pollingTimer?.invalidate()
        GenerationManager.shared.getGenerationStatus(generationId: generationId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let status):
                    let dataObj = status.data
                    let statusStr = dataObj?.status
                    let url = dataObj?.resultUrl
                    print("[HomeView] 📊 Status update: \(statusStr ?? "nil"), resultUrl: \(url ?? "nil")")
                    
                    if let url = url, ["finished", "ok"].contains((statusStr ?? "").lowercased()) {
                        print("[HomeView] ✅ Generation finished! resultUrl: \(url)")
                        isGenerating = false
                        showLoadingView = false
                        resultUrl = url
                        showResultView = true
                        print("[HomeView] 🔄 Updating history status to finished for id: \(historyId)")
                        HistoryViewModel.shared.updateStatus(id: historyId, status: .finished, resultUrl: url)
                        pollingTimer?.invalidate()
                    } else {
                        print("[HomeView] ⏳ Still processing... status: \(statusStr ?? "unknown")")
                        pollingTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { _ in
                            self.pollVideoStatus(generationId: generationId, historyId: historyId)
                        }
                    }
                case .failure(let error):
                    print("[HomeView] ❌ Error getting generation status: \(error)")
                    isGenerating = false
                    showLoadingView = false
                    errorMessage = error.localizedDescription
                    print("[HomeView] 🔄 Updating history status to failed for id: \(historyId)")
                    HistoryViewModel.shared.updateStatus(id: historyId, status: .failed, resultUrl: nil)
                    pollingTimer?.invalidate()
                }
            }
        }
    }
}

// MARK: - PhotoPicker
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }

            provider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.async {
                    self.parent.selectedImage = image as? UIImage
                }
            }
        }
    }
}

#Preview {
    HomeView()
} 
 

// MARK: - Resolution Button
private extension HomeView {
    func resolutionButton(for resolution: VideoResolution) -> some View {
        Button(action: { selectedResolution = resolution }) {
            Text(resolution == .p720 ? "720" : "1080")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(selectedResolution == resolution ? .white : .white.opacity(0.6))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(selectedResolution == resolution ? Color(hex: "#9D3AE9") : Color.clear, lineWidth: 1)
                )
        }
    }
} 
 
