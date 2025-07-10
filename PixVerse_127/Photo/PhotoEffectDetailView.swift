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
                HorizontalPager(pageCount: templates.count, currentIndex: $currentIndex) { index in
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
                                .font(.system(size: 20))
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
                .font(.system(size: 17))
                .foregroundColor(.white)
            Spacer()
            if !subscriptionManager.hasSubscription {
                CrownCircleButton {
                    showSubscriptionSheet = true
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
            Text("\(Image(systemName: "sparkles.square.filled.on.square")) Select effect")
                .font(.system(size: 17))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.white)
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

struct HorizontalPager<Content: View>: View {
    let pageCount: Int
    @Binding var currentIndex: Int
    let content: (Int) -> Content

    @GestureState private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var animatingIndex: Int? = nil
    @State private var animatedDragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let spacing: CGFloat = 8
            let cardWidth = width * 0.85
            HStack(spacing: spacing) {
                ForEach(0..<pageCount, id: \.self) { index in
                    content(index)
                        .frame(width: cardWidth, height: geometry.size.height)
                        .cornerRadius(24)
                        .clipped()
                        .scaleEffect(index == currentIndex ? 1.0 : 0.92)
                        .opacity(abs(index - currentIndex) > 1 ? 0 : 1)
                        .animation(.interactiveSpring(response: 0.38, dampingFraction: 0.85, blendDuration: 0.25), value: currentIndex)
                }
            }
            .frame(width: width, alignment: .leading)
            .offset(x: -CGFloat(currentIndex) * (cardWidth + spacing) + (width - cardWidth) / 2 + (isDragging ? dragOffset : animatedDragOffset))
            .highPriorityGesture(
                DragGesture()
                    .onChanged { _ in
                        if !isDragging { isDragging = true }
                    }
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { value in
                        let threshold = cardWidth / 4
                        var newIndex = currentIndex
                        if value.translation.width < -threshold {
                            newIndex = min(currentIndex + 1, pageCount - 1)
                        } else if value.translation.width > threshold {
                            newIndex = max(currentIndex - 1, 0)
                        }
                        isDragging = false
                        if newIndex == currentIndex {
                            // Плавно возвращаем dragOffset к нулю
                            animatedDragOffset = value.translation.width
                            withAnimation(.interactiveSpring(response: 0.38, dampingFraction: 0.85, blendDuration: 0.25)) {
                                animatedDragOffset = 0
                            }
                        } else {
                            animatedDragOffset = 0
                            withAnimation(.interactiveSpring(response: 0.38, dampingFraction: 0.85, blendDuration: 0.25)) {
                                currentIndex = newIndex
                            }
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

struct CrownCircleButton: View {
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#7A1DF2"), Color(hex: "#F2315F")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                Image(systemName: "crown.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.white)
            }
            .frame(width: 44, height: 44)
        }
    }
} 
 
