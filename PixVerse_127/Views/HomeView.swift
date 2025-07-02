import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedTab: HomeTab = .effects
    @State private var showSubscriptionSheet = false
    @State private var showTokensShop = false
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var manager = Manager.shared
    
    private let trendEffects: [Effect] = [
        Effect(id: "trend", title: "Trend effect", imageUrl: "trend1", category: EffectCategory(rawValue: "Popular") ?? .unknown, isPro: true),
        Effect(id: "trend2", title: "Trend effect", imageUrl: "trend2", category: EffectCategory(rawValue: "Popular") ?? .unknown, isPro: true),
        Effect(id: "trend3", title: "Trend effect", imageUrl: "trend3", category: EffectCategory(rawValue: "Popular") ?? .unknown, isPro: true)
    ]
    
    var body: some View {
      //  NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack {
                        Text("Pixune")
                            .font(.custom("SpaceGrotesk-Light_Bold", size: 34))
                            .kerning(0.4)
                            .foregroundColor(.white)
                        Spacer()
                        if subscriptionManager.hasSubscription {
                            MCPButton(tokens: manager.availableGenerations, onTap: { showTokensShop = true })
                        } else {
                            ProButton(onTap: { showSubscriptionSheet = true })
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "#D1FE17"), .black]),
                            startPoint: .top, endPoint: .bottom
                        )
                        .ignoresSafeArea(edges: .top)
                    )
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
                                EffectBannerView(effects: trendEffects)
                                
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
                                }
                            }
                        } else {
                            MCPPromptView()
                        }
                    }
                }
            //}
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
 
