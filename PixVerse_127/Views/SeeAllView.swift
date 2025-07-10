import SwiftUI

struct SeeAllView: View {
    let selectedCategory: String
    @StateObject private var viewModel: SeeAllViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showSubscriptionSheet = false
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared

    init(selectedCategory: String) {
        self.selectedCategory = selectedCategory
        _viewModel = StateObject(wrappedValue: SeeAllViewModel(selectedCategory: selectedCategory))
    }

    let columns = [
        GridItem(.fixed(175), spacing: 8),
        GridItem(.fixed(175), spacing: 8)
    ]

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
            viewModel.loadEffects()
        }
        .navigationBarHidden(true)
    }

    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 16) {
                SegmentedControl(
                    segments: viewModel.categories,
                    selected: $viewModel.selectedCategory
                )

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(viewModel.effectsForSelectedCategory) { effect in
                        NavigationLink(destination: EffectsPageView(effects: viewModel.effectsForSelectedCategory, currentIndex: viewModel.effectsForSelectedCategory.firstIndex(of: effect) ?? 0)) {
                            ZStack(alignment: .bottomLeading) {
                                TextureVideoViewContainer(urlString: effect.imageUrl, height: 311)
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 175, height: 311)
                                    .clipped()
                                    .cornerRadius(8)

                                LinearGradient(
                                    gradient: Gradient(colors: [.clear, .black.opacity(0.8)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: 60)
                                Text(effect.title)
                                    .font(.system(size: 15))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.bottom, 8)
                            }
                            .frame(width: 175, height: 311)
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

            Text("All templates")
                .foregroundColor(.white)
                .font(.system(size: 17, weight: .medium))

            Spacer()

            Button(action: { showSubscriptionSheet = true }) {
                if !subscriptionManager.hasSubscription {
                    CrownCircleButton {
                        showSubscriptionSheet = true
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .fullScreenCover(isPresented: $showSubscriptionSheet) {
            SubscriptionSheet(viewModel: SubscriptionViewModel())
        }
    }
}

struct SeeAllView_Previews: PreviewProvider {
    static var previews: some View {
        SeeAllView(selectedCategory: "Category 1")
    }
} 
