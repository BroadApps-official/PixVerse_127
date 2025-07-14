import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedTab: HomeTab = .effects
    @State private var showSubscriptionSheet = false
    @State private var showTokensShop = false
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var manager = Manager.shared
    
    var body: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack {
                        Text("AI Video")
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
                    .onChange(of: subscriptionManager.hasSubscription) { hasSub in
                        if hasSub { showSubscriptionSheet = false }
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
                                    }
                                } else if let error = viewModel.errorMessage {
                                    Text(error)
                                        .foregroundColor(.red)
                                        .padding()
                                } else {
                                    VStack(spacing: 20) {
                                        ForEach(viewModel.sections) { section in
                                            EffectSectionView(title: section.title, effects: section.effects)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.top, 24)
                                }
                            }
                        } else {
                            MCPPromptView()
                        }
                    }
                }
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.loadEffects()
        }
    }
}

#Preview {
    HomeView()
} 
 
