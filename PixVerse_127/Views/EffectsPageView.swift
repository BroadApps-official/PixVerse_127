import SwiftUI
import PhotosUI

struct EffectsPageView: View {
    @StateObject private var viewModel: EffectsPageViewModel
    @Environment(\.presentationMode) private var presentationMode
    @State private var showConfirmation = false
    @State private var showPhotoPicker = false
    @State private var showPhotoRequirements = false
    @State private var showSubscriptionSheet = false
    @State private var showCameraPicker = false
    @State private var cameraImage: UIImage? = nil
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared

    init(effects: [Effect], currentIndex: Int) {
        _viewModel = StateObject(wrappedValue: EffectsPageViewModel(effects: effects, currentIndex: currentIndex))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            GeometryReader { geometry in
                let height = geometry.size.height
                let peek: CGFloat = 4
                let cardHeight = height - 2 * peek
                VerticalPager(pageCount: viewModel.effects.count, currentIndex: $viewModel.currentIndex) { index in
                    ZStack {
                        TextureVideoViewContainer(urlString: viewModel.effects[index].imageUrl, height: cardHeight)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: cardHeight)
                            .clipped()
                    }
                    .cornerRadius(24)
                    .clipped()
                    .frame(width: geometry.size.width, height: cardHeight)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            VStack {
                // Top Navigation
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.14))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text(viewModel.currentEffect.title)
                        .font(.custom("SpaceGrotesk-Light_Medium", size: 17))
                        .foregroundColor(.white)
                    Spacer()
                    if !subscriptionManager.hasSubscription {
                        Button(action: { showSubscriptionSheet = true }) {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.black)
                                .frame(width: 40, height: 40)
                                .background(Color(hex: "#D1FE17"))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .fullScreenCover(isPresented: $showSubscriptionSheet) {
                    SubscriptionSheet(viewModel: SubscriptionViewModel())
                }
                Spacer()
                bottomBar()
            }
            if viewModel.isGenerating {
                GenerationLoadingView()
                    .zIndex(100)
            }
            if let resultUrl = viewModel.resultUrl, let url = URL(string: resultUrl) {
                GenerationResultView(videoUrl: url) {
                    viewModel.resultUrl = nil
                }
            }
        }
        .alert(isPresented: $viewModel.showError) {
            Alert(title: Text("Error"), message: Text(viewModel.errorMessage), dismissButton: .default(Text("OK")))
        }
        .confirmationDialog("Select action", isPresented: $showConfirmation, titleVisibility: .visible) {
            Button("Take a photo") { showCameraPicker = true }
            Button("Select from gallery") { showPhotoPicker = true }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $viewModel.selectedPhotoItem, matching: .images, photoLibrary: .shared())
        .sheet(isPresented: $showCameraPicker) {
            CameraPicker(image: $cameraImage)
        }
        .onChange(of: cameraImage) { img in
            if let img = img {
                viewModel.selectedPhotoItem = nil
                viewModel.isGenerating = true
            }
        }
        .navigationBarHidden(true)
    }

    private func bottomBar() -> some View {
        Button(action: {
            if !subscriptionManager.hasSubscription {
                showSubscriptionSheet = true
                return
            }
            if let img = cameraImage {
                viewModel.startGeneration(with: img)
            } else {
                showConfirmation = true
            }
        }) {
            Text("\(Image(systemName: "sparkles")) Select")
                .font(.custom("SpaceGrotesk-Light_Bold", size: 17))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.accentColor)
                .cornerRadius(16)
        }
        .padding(.horizontal, 16).padding(.bottom, 34)
        .sheet(isPresented: $showPhotoRequirements) {
            PhotoRequirementsView {
                UserDefaults.standard.set(true, forKey: "photoReqShown")
                showPhotoRequirements = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showConfirmation = true
                }
            }
        }
    }
}

struct EffectDetailContentView: View {
    let effect: Effect
    
    var body: some View {
        VStack(spacing: 24) {
            VideoThumbnailView(urlString: effect.imageUrl, height: 311)
                .frame(width: 175, height: 311)
                .cornerRadius(16)
                .padding(.top, 8)
        }
    }
}

#Preview {
    EffectsPageView(effects: [
        Effect(id: "1", title: "Cubes", imageUrl: "effect_cubes", category: .popular),
        Effect(id: "2", title: "Cartoon", imageUrl: "effect_cartoon", category: .popular),
        Effect(id: "3", title: "Anime", imageUrl: "effect_anime", category: .popular)
    ], currentIndex: 0)
}

struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}


