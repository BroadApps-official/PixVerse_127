import SwiftUI
import PhotosUI
import Kingfisher
import Lottie

struct PhotoEffectDetailView: View {
    let templates: [Template]
    @State var currentIndex: Int
    
    @StateObject private var viewModel = PhotoEffectDetailViewModel()
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var showConfirmation = false
    @State private var showPhotoPicker = false
    @State private var showPhotoRequirements = false
    @GestureState private var dragOffset: CGFloat = 0
    @State private var showSubscriptionSheet = false
    @State private var showCameraPicker = false
    @State private var cameraImage: UIImage? = nil
    
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    
    private var currentTemplate: Template {
        templates[currentIndex]
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                let window = UIApplication.shared.windows.first
                let topSafeArea = window?.safeAreaInsets.top ?? 0
                let bottomSafeArea = window?.safeAreaInsets.bottom ?? 0
                VerticalPager(pageCount: templates.count, currentIndex: $currentIndex) { index in
                    ZStack {
                        if let url = URL(string: templates[index].preview) {
                            KFImage(url)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height - 8)
                                .clipped()
                        } else {
                            Color.gray.opacity(0.2)
                        }
                    }
                }
                VStack {
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.45), .clear]),
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: topSafeArea + 32)
                    Spacer()
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, Color.black.opacity(0.45)]),
                        startPoint: .top, endPoint: .bottom
                    )
                    .frame(height: bottomSafeArea + 32)
                }
                .ignoresSafeArea()
            }
            VStack {
                navBar()
                Spacer()
                bottomBar()
            }
            if viewModel.showFirstTimeHint {
                Color.black.opacity(0.65)
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 24) {
                            Spacer()
                            Text("Swipe up and down to see\nmore effects")
                                .multilineTextAlignment(.center)
                                .font(.custom("SpaceGrotesk-Light_Medium", size: 20))
                                .foregroundColor(.white)
                                .padding(.bottom, 8)
                            LottieView(animation: .named("Swipe.json"))
                                .playing(loopMode: .autoReverse)
                                .frame(width: 170, height: 170)
                                .padding()
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.hideFirstTimeHint()
                        }
                        .gesture(DragGesture().onEnded { _ in
                            viewModel.hideFirstTimeHint()
                        })
                    )
                    .zIndex(10)
            }
            if viewModel.isGenerating {
                GenerationLoadingView()
                    .zIndex(100)
            }
            if let url = viewModel.resultUrl,
               let item = HistoryViewModel.shared.items.first(where: { $0.resultUrl == url }) {
                 PhotoResultView(resultUrl: url, historyItem: item, onDismiss: {
                     viewModel.resultUrl = nil
                 })
            }
        }
        .alert(isPresented: $viewModel.showError) {
            Alert(title: Text("Error"), message: Text(viewModel.errorMessage), dismissButton: .default(Text("OK")))
        }
        .confirmationDialog("Select action", isPresented: $showConfirmation, titleVisibility: .visible) {
            Button("Take a photo") { showCameraPicker = true }
            Button("Select from gallery") { showPhotoPicker = true }
        }
        .photosPicker(isPresented: $showPhotoPicker, selection: $viewModel.selectedPhotoItem, matching: .images)
        .onChange(of: showPhotoPicker) { isPresented in
            if !isPresented {
                viewModel.setTemplate(currentTemplate)
            }
        }
        .sheet(isPresented: $showCameraPicker) {
            CameraPicker(image: $cameraImage)
        }
        .onChange(of: cameraImage) { img in
            if let img = img {
                viewModel.setTemplate(currentTemplate)
                viewModel.isGenerating = true
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showSubscriptionSheet) {
            SubscriptionSheet(viewModel: SubscriptionViewModel())
        }
    }

    @ViewBuilder
    private func navBar() -> some View {
        HStack {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "chevron.backward")
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.14))
                    .clipShape(Circle())
            }
            Spacer()
            Text(currentTemplate.title ?? "Style")
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
        .padding(.horizontal, 16).padding(.top, 20)
    }

    @ViewBuilder
    private func bottomBar() -> some View {
        Button(action: {
            if !subscriptionManager.hasSubscription {
                showSubscriptionSheet = true
                return
            }
            if !UserDefaults.standard.bool(forKey: "photoReqShown") {
                showPhotoRequirements = true
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

struct VerticalPager<Content: View>: View {
    let pageCount: Int
    @Binding var currentIndex: Int
    let content: (Int) -> Content

    @GestureState private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            let peek: CGFloat = 4
            let cardHeight = height - 2 * peek
            ZStack {
                ForEach(0..<pageCount, id: \.self) { index in
                    if abs(index - currentIndex) <= 1 {
                        content(index)
                            .frame(width: geometry.size.width, height: cardHeight)
                            .cornerRadius(24)
                            .clipped()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .offset(y: CGFloat(index - currentIndex) * height + dragOffset)
                    }
                }
            }
            .animation(.spring(), value: currentIndex)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.height
                    }
                    .onEnded { value in
                        let threshold = height / 24
                        var newIndex = currentIndex
                        if value.translation.height < -threshold {
                            newIndex = min(currentIndex + 1, pageCount - 1)
                        } else if value.translation.height > threshold {
                            newIndex = max(currentIndex - 1, 0)
                        }
                        withAnimation(.spring()) {
                            currentIndex = newIndex
                        }
                    }
            )
        }
    }
}

// MARK: - PhotoResultView with dismiss action
fileprivate struct PhotoResultView2: View {
    let resultUrl: String
    var onDismiss: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.opacity(0.8).ignoresSafeArea()
                .onTapGesture(perform: onDismiss)
            
            VStack(spacing: 24) {
                Spacer()
                if let url = URL(string: resultUrl) {
                    AsyncImage(url: url) { img in
                        img.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView().progressViewStyle(.circular).tint(.white)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(16)
                    .padding()
                }
                Spacer()
            }
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
            .padding()
        }
    }
} 
 
