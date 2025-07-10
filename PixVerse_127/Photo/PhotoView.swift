import SwiftUI
import PhotosUI
import Kingfisher

struct PhotoView: View {
    @StateObject private var viewModel = PhotoViewModel()
    @State private var selectedTab: HomeTab = .effects
    
    @State private var selectedTemplate: Template? = nil
    @State private var showImagePicker = false
    @State private var selectedUIImage: UIImage? = nil
    @State private var isGeneratingFromTemplate = false
    @State private var resultUrlFromTemplate: String? = nil
    @State private var currentHistoryItem: PhotoHistoryItem? = nil
    @State private var showPhotoRequirements = false
    @State private var showSubscriptionSheet = false
    @State private var showTokensShop = false
    
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var manager = Manager.shared
    

    var body: some View {
            ZStack {
                VStack(spacing: 0) {
                    HStack {
                        Text("AI Photo")
                            .font(.system(size: 34))
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
                    
                    if selectedTab == .effects {
                        effectsView()
                    } else {
                        promptView()
                    }
                }
                
                if viewModel.isGenerating || isGeneratingFromTemplate {
                    GenerationLoadingView()
                        .zIndex(100)
                }
                
                if let url = viewModel.resultUrl,
                   let item = HistoryViewModel.shared.items.first(where: { $0.resultUrl == url }) {
                    PhotoResultView(resultUrl: url, historyItem: item, onDismiss: {
                        viewModel.resetPromptState()
                    })
                }
                
                if let url = resultUrlFromTemplate,
                   let item = HistoryViewModel.shared.items.first(where: { $0.resultUrl == url }) {
                    PhotoResultView(resultUrl: url, historyItem: item, onDismiss: {
                        resultUrlFromTemplate = nil
                    })
                }
            }
            .sheet(isPresented: $showPhotoRequirements) {
                PhotoRequirementsView {
                    UserDefaults.standard.set(true, forKey: "photoReqShown")
                    showPhotoRequirements = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showImagePicker = true
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedUIImage, onImagePicked: { image in
                    selectedUIImage = image
                    if let template = selectedTemplate, let img = image {
                        startGeneration(template: template, image: img)
                    }
                })
            }
            .alert(isPresented: $viewModel.showError) {
                Alert(title: Text("Error"), message: Text(viewModel.errorMessage ?? "Unknown error"), dismissButton: .default(Text("OK")))
            }
            .navigationBarHidden(true)
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private func effectsView() -> some View {
        if viewModel.isLoading {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
                .frame(maxHeight: .infinity)
        } else if let error = viewModel.errorMessage {
            Text(error)
                .foregroundColor(.red)
                .padding()
                .frame(maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 24, pinnedViews: [.sectionHeaders]) {
                    ForEach(viewModel.categories, id: \.id) { category in
                        Section {
                            if let title = category.title {
                                templateSection(title: title, templates: category.templates)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
        }
    }

    @ViewBuilder
    private func promptView() -> some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 20) {
            ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.08))
                        VStack(alignment: .leading, spacing: 0) {
                CustomTextEditorContainer(text: $viewModel.prompt)
                                .font(.system(size: 16))
                    .foregroundColor(.white)
                                .frame(height: 240)
                                .padding(.top, 8)
                                .padding(.horizontal, 8)
                    .background(Color.clear)
                    .colorScheme(.dark)
            }
                        if viewModel.prompt.isEmpty {
                            Text("Type in what you want to see")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.top, 16)
                                .padding(.horizontal, 16)
                                .allowsHitTesting(false)
                        }
                    }
                    .frame(height: 240)
                    .padding(.horizontal, 16)
                    Spacer(minLength: 0)
                }
                .padding(.top, 24)
            }
            Button(action: {
                if !subscriptionManager.hasSubscription {
                    showSubscriptionSheet = true
                    return
                }
                viewModel.generateImageFromPrompt()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "scribble.variable")
                    Text("Generate")
                }
                .font(.system(size: 17))
                .foregroundColor((viewModel.prompt.isEmpty || viewModel.prompt.count > 300) ? .white.opacity(0.5) : .black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background((viewModel.prompt.isEmpty || viewModel.prompt.count > 300) ? .gray.opacity(0.3) : .white)
                .cornerRadius(16)
            }
            .disabled(viewModel.prompt.isEmpty || viewModel.prompt.count > 300)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    private func templateSection(title: String, templates: [Template]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                Spacer()
                NavigationLink(destination: PhotoSeeAllView(selectedCategory: title)) {
                    HStack(spacing: 4) {
                        Text("All")
                            .font(.system(size: 13))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                }
            }
            .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(Array(templates.enumerated()), id: \ .element.id) { index, template in
                        NavigationLink(destination: PhotoEffectDetailView(templates: templates, currentIndex: index)) {
                            TemplateCardView(template: template)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - Logic for Template-based generation
    
    private func startGeneration(template: Template, image: UIImage) {
        if !subscriptionManager.hasSubscription {
            showSubscriptionSheet = true
            return
        }
        isGeneratingFromTemplate = true
        let historyItem = PhotoHistoryItem(
            id: UUID().uuidString,
            templateId: template.id,
            templateTitle: template.title,
            previewUrl: template.preview,
            resultUrl: nil,
            date: Date(),
            status: "pending"
        )
        PhotoHistoryManager.shared.add(historyItem)
        currentHistoryItem = historyItem
        let history = HistoryItem(
            id: historyItem.id,
            date: historyItem.date,
            previewUrl: historyItem.previewUrl,
            resultUrl: nil,
            status: .inProgress,
            type: .photo,
            prompt: nil
        )
        HistoryViewModel.shared.add(item: history)
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            isGeneratingFromTemplate = false
            return
        }
        PhotoAPIService.shared.generatePhoto(imageData: imageData, styleId: template.id, userId: "ios-test-user-1121") { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let jobId):
                    pollStatusForTemplate(jobId: jobId, historyItem: historyItem)
                case .failure:
                    isGeneratingFromTemplate = false
                }
            }
        }
    }
    
    private func pollStatusForTemplate(jobId: String, historyItem: PhotoHistoryItem) {
        PhotoAPIService.shared.checkGenerationStatus(userId: "ios-test-user-1121", jobId: jobId) { result in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                switch result {
                case .success(let status):
                    if let url = status.data?.resultUrl, status.data?.status == "OK" {
                        let finishedItem = PhotoHistoryItem(
                            id: historyItem.id,
                            templateId: historyItem.templateId,
                            templateTitle: historyItem.templateTitle,
                            previewUrl: historyItem.previewUrl,
                            resultUrl: url,
                            date: historyItem.date,
                            status: "finished"
                        )
                        PhotoHistoryManager.shared.update(finishedItem)
                        HistoryViewModel.shared.updateStatus(id: historyItem.id, status: .finished, resultUrl: url)
                        resultUrlFromTemplate = url
                        isGeneratingFromTemplate = false
                    } else if status.data?.status == "FAILED" || status.data?.status == "ERROR" {
                        let failedItem = PhotoHistoryItem(
                            id: historyItem.id,
                            templateId: historyItem.templateId,
                            templateTitle: historyItem.templateTitle,
                            previewUrl: historyItem.previewUrl,
                            resultUrl: nil,
                            date: historyItem.date,
                            status: "failed"
                        )
                        PhotoHistoryManager.shared.update(failedItem)
                        HistoryViewModel.shared.updateStatus(id: historyItem.id, status: .failed, resultUrl: nil)
                        isGeneratingFromTemplate = false
                    } else {
                        pollStatusForTemplate(jobId: jobId, historyItem: historyItem)
                    }
                case .failure:
                    isGeneratingFromTemplate = false
                }
            }
        }
    }

    // MARK: - Helper functions

    private func isPhoto(_ url: String) -> Bool {
        url.lowercased().hasSuffix(".jpg") || url.lowercased().hasSuffix(".jpeg") || url.lowercased().hasSuffix(".png")
    }
}

// MARK: - ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onImagePicked: (UIImage?) -> Void
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
                parent.onImagePicked(uiImage)
            } else {
                parent.onImagePicked(nil)
            }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onImagePicked(nil)
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - PhotoResultView
struct PhotoResultView: View {
    let resultUrl: String
    let historyItem: HistoryItem
    var onDismiss: () -> Void
    var effectTitle: String? = nil
    var onShare: (() -> Void)? = nil
    @Environment(\.presentationMode) private var presentationMode
    @State private var showDeleteAlert = false
    @State private var showSaveSuccess = false
    @State private var showSaveError = false
    @State private var saveErrorText = ""
    @State private var showShareSheet = false
    @State private var showCopiedToast = false
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss(); onDismiss() }) {
                        Image(systemName: "chevron.backward")
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.14))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text(effectTitle ?? "Result")
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                    Spacer()
                    Menu {
                        Button("Save to gallery", action: saveToGallery)
                        Button("Save to files", action: saveToFiles)
                        Button("Delete", role: .destructive, action: { showDeleteAlert = true })
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color(hex: "#9D3AE9"))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                if let url = URL(string: resultUrl) {
                    KFImage(url)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(16)
                        .padding(.top, 32)
                        .padding(.horizontal, 16)
                }
                if let prompt = historyItem.prompt, !prompt.isEmpty {
                    PromptBlock(prompt: prompt, onCopy: {
                        showCopiedToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { showCopiedToast = false }
                    })
                }
                Spacer(minLength: 0)
                ResultShareButton(onShare: { showShareSheet = true })
                    .padding(.bottom, 24)
            }
            .ignoresSafeArea(edges: .bottom)
            if showCopiedToast {
                ToastView(text: "Text copied")
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
            }
        }
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Delete result?"),
                message: Text("This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    HistoryViewModel.shared.remove(historyItem)
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel()
            )
        }
        .alert(isPresented: $showSaveSuccess) {
            Alert(title: Text("Saved!"), message: nil, dismissButton: .default(Text("OK")))
        }
        .alert(isPresented: $showSaveError) {
            Alert(title: Text("Error"), message: Text(saveErrorText), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = URL(string: resultUrl) {
                ActivityView(activityItems: [url])
            }
        }
        .navigationBarHidden(true)
    }
    
    private func saveToGallery() {
        guard let url = URL(string: resultUrl) else { return }
        KingfisherManager.shared.retrieveImage(with: url) { result in
            switch result {
            case .success(let value):
                UIImageWriteToSavedPhotosAlbum(value.image, nil, nil, nil)
                showSaveSuccess = true
            case .failure(let error):
                saveErrorText = error.localizedDescription
                showSaveError = true
            }
        }
    }
    private func saveToFiles() {
        guard let url = URL(string: resultUrl) else { return }
        KingfisherManager.shared.retrieveImage(with: url) { result in
            switch result {
            case .success(let value):
                let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
                if let data = value.image.jpegData(compressionQuality: 0.95) {
                    do {
                        try data.write(to: tempUrl)
                        let picker = UIDocumentPickerViewController(forExporting: [tempUrl])
                        UIApplication.shared.windows.first?.rootViewController?.present(picker, animated: true)
                    } catch {
                        saveErrorText = error.localizedDescription
                        showSaveError = true
                    }
                }
            case .failure(let error):
                saveErrorText = error.localizedDescription
                showSaveError = true
            }
        }
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// Кастомный TextEditor с динамическим UI
struct CustomTextEditor: UIViewRepresentable {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    var onPaste: (() -> Void)? = nil
    var onCopy: (() -> Void)? = nil
    var onClear: (() -> Void)? = nil

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont(name: "SFPRO", size: 16)
        textView.textColor = UIColor.white
        textView.backgroundColor = .clear
        textView.returnKeyType = .done
        textView.keyboardAppearance = .dark
        textView.layer.cornerRadius = 12
        textView.layer.masksToBounds = true
        textView.isScrollEnabled = true
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 36, right: 12)
        return textView
    }
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        if !text.isEmpty {
            uiView.layer.borderWidth = 1.5
            uiView.layer.borderColor = UIColor(named: "AccentColor")?.cgColor ?? UIColor(red: 0.82, green: 1.0, blue: 0.09, alpha: 1).cgColor // #D1FE17
        } else {
            uiView.layer.borderWidth = 1.0
            uiView.layer.borderColor = UIColor.clear.cgColor
        }
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: CustomTextEditor
        init(_ parent: CustomTextEditor) { self.parent = parent }
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            if text == "\n" {
                textView.resignFirstResponder()
                return false
            }
            return true
        }
    }
}

struct CustomTextEditorContainer: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    private var isOverLimit: Bool { text.count > 300 }
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            CustomTextEditor(text: $text)
                .frame(height: 240)
                .focused($isFocused)
            HStack {
                Text("\(text.count)/300")
                    .font(.system(size: 13))
                    .foregroundColor(isOverLimit ? Color.red : .white.opacity(0.5))
                    .padding(.leading, 8)
                Spacer()
                if !text.isEmpty {
                    HStack(spacing: 8) {
                        Button(action: { text = UIPasteboard.general.string ?? text }) {
                            Text("Past")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "#9D3AE9"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(8)
                        }
                        Button(action: { UIPasteboard.general.string = text }) {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(Color(hex: "#9D3AE9"))
                                .padding(8)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(8)
                        }
                        Button(action: { text = "" }) {
                            Image(systemName: "trash")
                                .foregroundColor(Color(hex: "#9D3AE9"))
                                .padding(8)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.trailing, 8)
                }
            }
            .frame(height: 36)
            .padding(.bottom, 4)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(text.isEmpty ? Color.clear : (isOverLimit ? Color.red : Color(hex: "#9D3AE9")), lineWidth: 1.5)
        )
        .animation(.easeInOut, value: isOverLimit)
    }
}

struct ToastView: View {
    let text: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Color(hex: "#22C55E"))
                .font(.system(size: 18, weight: .bold))
            Text(text)
                .foregroundColor(.white)
                .font(.system(size: 15, weight: .semibold))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .background(Color.black.opacity(0.92))
        .cornerRadius(16)
        .shadow(radius: 8)
        .padding(.top, 60)
    }
}

struct PromptBlock: View {
    let prompt: String
    var onCopy: (() -> Void)? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Promt")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color(hex: "#A259FF"))
                Spacer()
                Button(action: {
                    UIPasteboard.general.string = prompt
                    onCopy?()
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            Text(prompt)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
        }
        .padding(.top, 6)
        .padding(.horizontal, 16)
    }
} 
