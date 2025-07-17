import SwiftUI
import ApphudSDK
import WebKit

struct SubscriptionSheet: View {
    @ObservedObject var viewModel: SubscriptionViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showCloseButton = false
    @State private var showingTerms = false
    @State private var showingPrivacyPolicy = false
    @State private var isWebViewLoading = false
    @State private var webViewError: Error?
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        headerView(geometry: geometry)
                        subscriptionPlansView(geometry: geometry)
                        cancelAnytimeView
                        continueButton(geometry: geometry)
                        legalLinksView
                    }
                    .background(Color.black)
                    .foregroundColor(.white)
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(trailing: closeButton)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    viewModel.loadPaywall()
                    impactFeedback.prepare()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation { showCloseButton = true }
                    }
                }
                .onDisappear {
                    impactFeedback.impactOccurred(intensity: 0)
                }
            }
            .background(Color.black)
        }
    }
    
    private func headerView(geometry: GeometryProxy) -> some View {
        ZStack(alignment: .bottom) {
            Image("paywall")
                .resizable()
                .scaledToFill()
                .frame(maxHeight: geometry.size.height * 0.6)
                .clipped()
            LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color.black.opacity(1)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: geometry.size.height * 0.15)
            
            VStack(spacing: 22){
                HStack(alignment: .center, spacing: 8) {
                    Text("Unreal videos with")
                        .font(.system(size: 28))
                        .bold()
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                       // .padding(.horizontal, 16)
                    ProButton()
                }
                
                VStack(alignment: .leading, spacing: geometry.size.height * 0.015) {
                    ForEach(["Access to all effects", "Access to all functions"], id: \.self) { key in
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.white)
                            Text(LocalizedStringKey(key))
                                .foregroundColor(.white)
                                .font(.system(size: 15))
                        }
                    }
                }
            }
            .padding(.vertical, geometry.size.height * 0.02)
        }
    }
    
    private func subscriptionPlansView(geometry: GeometryProxy) -> some View {
        VStack(spacing: geometry.size.height * 0.02) {
            if viewModel.subscriptionPlans.isEmpty {
                Text("No subscription plans")
                    .foregroundColor(.gray)
                    .font(.body)
                    .onAppear {
                        print("⚠️ No subscription plans visible")
                    }
            } else {
                ForEach(Array(viewModel.subscriptionPlans.enumerated()), id: \ .element.id) { index, plan in
                    SubscriptionPlanRow(
                        icon: plan.period.lowercased().contains("year") ? "checkmark.circle.fill" : "checkmark.circle.fill",
                        title: "Just " + plan.price + (plan.period.lowercased().contains("year") ? " / Year" : " / Week"),
                        subtitle: "Auto renewable. Cancel anytime.",
                        badge: plan.discountPercentage != nil ? "SAVE \(plan.discountPercentage!)%" : nil,
                        isSelected: plan.isSelected,
                        generationLabel: index == 0 ? "100 generation" : (index == 1 ? "10 generation" : nil)
                    )
                    .onTapGesture {
                        impactFeedback.impactOccurred()
                        viewModel.selectPlan(plan)
                    }
                }
            }
        }
        .padding(.top, 28)
        .padding(.horizontal, 16)
    }

    private func continueButton(geometry: GeometryProxy) -> some View {
        Button(action: {
            impactFeedback.impactOccurred()
            viewModel.purchaseSubscription()
        }) {
            Text("Continue")
                .font(.body.bold())
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    viewModel.selectedSubscription != nil ?
                    AnyView(Color.white)
                    : AnyView(Color.gray.opacity(0.5))
                )
                .cornerRadius(12)
        }
        .padding(.horizontal, 16)
        .padding(.top, geometry.size.height * 0.03)
        .disabled(viewModel.isPurchasing)
        .opacity(viewModel.isPurchasing ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: viewModel.selectedSubscription != nil)
        .accessibilityLabel("continue_purchase")
    }
    
    private var legalLinksView: some View {
        HStack(spacing: 12) {
            Spacer()
            Button(action: {
                if let url = URL(string: "https://docs.google.com/document/d/1e-xc2g95aJvAMR4RWQd8ES3G6PgtgBdpa7iDM42lhIM/edit?usp=sharing") {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Privacy Policy")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color.white.opacity(0.4))
            }
            Spacer()
            Button(action: {
                impactFeedback.impactOccurred()
                viewModel.restorePurchases { _ in }
            }) {
                Text("Restore Purchases")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color.white.opacity(0.6))
            }
            Spacer()
            Button(action: {
                if let url = URL(string: "https://docs.google.com/document/d/1j5btwXXG8axk-rSJPHWq3GmT-KCxq9lB-PjYJ-IrvBY/edit?usp=sharing") {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Terms of Use")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color.white.opacity(0.4))
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    
    private var closeButton: some View {
        Button(action: {
            if showCloseButton {
                if let unwrappedPaywall = viewModel.currentPaywall {
                    Apphud.paywallClosed(unwrappedPaywall)
                    print("Paywall closed: \(unwrappedPaywall.identifier)")
                } else {
                    print("Warning: No paywall to close")
                }
                dismiss()
            }
        }) {
            Image(systemName: "xmark")
                .foregroundColor(showCloseButton ? .white : .clear)
        }
        .accessibilityLabel("close")
        .accessibilityHidden(!showCloseButton)
    }
    
    private var cancelAnytimeView: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 12))
                .foregroundColor(Color.white.opacity(0.4))
            Text("Cancel Anytime")
                .font(.system(size: 12))
                .foregroundColor(Color.white.opacity(0.4))
        }
        .padding(.top, 12)
    }
}

#Preview {
    SubscriptionSheet(viewModel: SubscriptionViewModel())
}
