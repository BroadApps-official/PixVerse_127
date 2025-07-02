import SwiftUI
import PhotosUI
import AVKit
import Combine

struct MCPPromptView: View {
    @StateObject private var viewModel = PromptViewModel()
    @State private var promptText: String = ""
    @State private var usePhoto: Bool = false
    @State private var selectedPhoto: UIImage? = nil
    @State private var isGenerating: Bool = false
    @State private var resultUrl: String? = nil
    @State private var errorMessage: String? = nil
    @State private var showPhotoPicker: Bool = false
    @State private var showPlayer: Bool = false
    @State private var showPhotoRequirements = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var pollingTimer: Timer? = nil
    @State private var showLoadingView: Bool = false
    @State private var showResultView: Bool = false
    @State private var showResultUrlError: Bool = false
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showSubscriptionSheet = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.08))
                        CustomTextEditorContainer(text: $promptText)
                        if promptText.isEmpty {
                            Text("Enter your prompt...")
                                .font(.custom("SpaceGrotesk-Light_Regular", size: 16))
                                .foregroundColor(.white.opacity(0.25))
                                .padding(.top, 16)
                                .padding(.horizontal, 14)
                        }
                    }
                    .frame(height: 120)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Use a photo")
                                .font(.custom("SpaceGrotesk-Light_Bold", size: 20))
                                .foregroundColor(.white)
                            Spacer()
                            Toggle("", isOn: $usePhoto)
                                .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.78, green: 1.0, blue: 0.29)))
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
                                                        .stroke(Color(hex: "#D1FE17"), style: StrokeStyle(lineWidth: 3, dash: [8]))
                                                )
                                                .overlay(
                                                    Image(systemName: "arrow.2.circlepath")
                                                        .resizable()
                                                        .frame(width: 32, height: 32)
                                                        .foregroundColor(Color(hex: "#D1FE17"))
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
                                                        .stroke(Color(hex: "#D1FE17"), style: StrokeStyle(lineWidth: 2, dash: [6]))
                                                )
                                                .overlay(
                                                    Image(systemName: "plus")
                                                        .resizable()
                                                        .scaledToFit()
                                                        .frame(width: 32, height: 32)
                                                        .foregroundColor(Color(hex: "#D1FE17"))
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
                            .font(.custom("SpaceGrotesk-Light_Regular", size: 15))
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)
                    }
                }
            }
            Spacer()
                .frame(height: 140)
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
                        Image(systemName: "sparkles")
                        Text("Generate")
                            .font(.custom("SpaceGrotesk-Light_Bold", size: 17))
                            .foregroundColor((promptText.isEmpty || promptText.count > 300) ? .black : .black)
                        Spacer()
                    }
                    .foregroundColor(.black)
                    .padding(.vertical, 18)
                    .background((promptText.isEmpty || promptText.count > 300 || (usePhoto && selectedPhoto == nil)) ? Color.accentColor.opacity(0.4) : Color.accentColor)
                    .cornerRadius(18)
                    .padding(.horizontal, 16)
                }
                .disabled(promptText.isEmpty || promptText.count > 300 || (usePhoto && selectedPhoto == nil) || isGenerating)
                Spacer().frame(height: 60)
            }
            .background(Color.black.ignoresSafeArea(edges: .bottom))
        }
        .background(Color.black.ignoresSafeArea())
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPicker(selectedImage: $selectedPhoto)
        }
        .ignoresSafeArea(.keyboard)
        .fullScreenCover(isPresented: $showLoadingView) {
            GenerationLoadingView()
        }
        .fullScreenCover(isPresented: $showResultView) {
            if let url = resultUrl, let videoUrl = URL(string: url) {
                GenerationResultView(videoUrl: videoUrl, onDismiss: {
                    showResultView = false
                    resultUrl = nil
                    promptText = ""
                })
                .onAppear {
                    print("[DEBUG] Показываем GenerationResultView, resultUrl = \(url)")
                }
            } else {
                Color.clear
                    .onAppear {
                        print("[DEBUG] Ошибка: resultUrl невалидный")
                        showResultView = false
                        showResultUrlError = true
                    }
            }
        }
        .alert(isPresented: $showResultUrlError) {
            Alert(title: Text("Ошибка"), message: Text("Не удалось открыть результат. Попробуйте ещё раз."), dismissButton: .default(Text("OK")))
        }
        .fullScreenCover(isPresented: $showSubscriptionSheet) {
            SubscriptionSheet(viewModel: SubscriptionViewModel())
        }
    }

    private func generate() {
        errorMessage = nil
        resultUrl = nil
        isGenerating = true
        showLoadingView = true

        guard !promptText.isEmpty else {
            errorMessage = "Prompt can't be empty"
            isGenerating = false
            return
        }

        let historyId = UUID().uuidString
        let historyItem = HistoryItem(
            id: historyId,
            date: Date(),
            previewUrl: nil,
            resultUrl: nil,
            status: .inProgress,
            type: .video,
            prompt: promptText
        )
        HistoryViewModel.shared.add(item: historyItem)

        let imageToSend = usePhoto ? selectedPhoto ?? UIImage() : UIImage()
        GenerationManager.shared.generateImg2Video(prompt: promptText, image: imageToSend) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let generationId):
                    self.pollVideoStatus(generationId: generationId, historyId: historyId)
                case .failure(let error):
                    isGenerating = false
                    errorMessage = error.localizedDescription
                    HistoryViewModel.shared.updateStatus(id: historyId, status: .failed, resultUrl: nil)
                }
            }
        }
    }

    private func pollVideoStatus(generationId: String, historyId: String) {
        pollingTimer?.invalidate()
        GenerationManager.shared.getGenerationStatus(generationId: generationId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let status):
                    let dataObj = status.data
                    let statusStr = dataObj?.status
                    let url = dataObj?.resultUrl
                    print("[DEBUG] pollVideoStatus: status=\(String(describing: statusStr)), url=\(String(describing: url))")
                    if let url = url, ["finished", "ok"].contains((statusStr ?? "").lowercased()) {
                        print("[DEBUG] Готово! url = \(url)")
                        isGenerating = false
                        showLoadingView = false
                        resultUrl = url
                        print("[DEBUG] resultUrl присвоен: \(resultUrl ?? "nil")")
                        showResultView = true
                        print("[DEBUG] showResultView = true")
                        HistoryViewModel.shared.updateStatus(id: historyId, status: .finished, resultUrl: url)
                        pollingTimer?.invalidate()
                    } else {
                        print("[DEBUG] Статус не финальный, повторяем polling")
                        pollingTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { _ in
                            self.pollVideoStatus(generationId: generationId, historyId: historyId)
                        }
                    }
                case .failure(let error):
                    print("[DEBUG] Ошибка генерации: \(error.localizedDescription)")
                    isGenerating = false
                    showLoadingView = false
                    errorMessage = error.localizedDescription
                    HistoryViewModel.shared.updateStatus(id: historyId, status: .failed, resultUrl: nil)
                    pollingTimer?.invalidate()
                }
            }
        }
    }
}

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

// MARK: - AVPlayerView
struct AVPlayerView: View {
    let url: URL

    var body: some View {
        VideoPlayer(player: AVPlayer(url: url))
            .edgesIgnoringSafeArea(.all)
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
