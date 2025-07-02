import SwiftUI

struct PhotoSeeAllView: View {
    let selectedCategory: String
    @StateObject private var viewModel: PhotoSeeAllViewModel
    @Environment(\.presentationMode) var presentationMode

    // States for image picking and generation
    @State private var showImagePicker = false
    @State private var selectedUIImage: UIImage?
    @State private var selectedEffect: Template?
    @State private var isGenerating = false
    @State private var resultUrl: String?
    @State private var showSubscriptionSheet = false
    
    let columns = [
        GridItem(.fixed(175), spacing: 8),
        GridItem(.fixed(175), spacing: 8)
    ]

    init(selectedCategory: String) {
        self.selectedCategory = selectedCategory
        _viewModel = StateObject(wrappedValue: PhotoSeeAllViewModel(selectedCategory: selectedCategory))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                navBar()
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Spacer()
                } else if let errorMessage = viewModel.errorMessage {
                    Spacer()
                    Text(errorMessage)
                        .foregroundColor(.white)
                    Spacer()
                } else {
                    contentView
                }
            }
        }
        .onAppear {
            viewModel.loadStyles()
        }
        .navigationBarHidden(true)
    }
    
    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 16) {
                SegmentedControl(
                    segments: viewModel.categoryNames,
                    selected: $viewModel.selectedCategory
                )

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(Array(viewModel.effectsForSelectedCategory.enumerated()), id: \.element.id) { index, effect in
                        NavigationLink(destination: PhotoEffectDetailView(templates: viewModel.effectsForSelectedCategory, currentIndex: index)) {
                            TemplateCardView(template: effect)
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding(.top)
        }
    }

    @ViewBuilder
    private func navBar() -> some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }

            Spacer()

            Text("All Styles")
                .foregroundColor(.white)
                .font(.system(size: 17, weight: .medium))

            Spacer()

            Button(action: {
                showSubscriptionSheet = true
            }) {
                Image(systemName: "crown.fill")
                    .foregroundColor(.black)
                    .frame(width: 40, height: 40)
                    .background(Color(hex: "#D1FE17"))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .fullScreenCover(isPresented: $showSubscriptionSheet) {
            SubscriptionSheet(viewModel: SubscriptionViewModel())
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#D1FE17"), .black]),
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
        )
    }
} 
