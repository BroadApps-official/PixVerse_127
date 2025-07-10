import SwiftUI
import StoreKit
import ApphudSDK
import MessageUI
import Kingfisher

struct SettingsView: View {
    @State private var notificationsEnabled = true
    @State private var cacheSize = VideoCacheManager.shared.cacheSizeString()
    @State private var showSubscriptionSheet = false
    @State private var showShareSheet = false
    @State private var showMail = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var mailResult: Result<MFMailComposeResult, Error>? = nil
    @State private var showCacheAlert = false
    @State private var showTokensShop = false
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var manager = Manager.shared
    
    var body: some View {
        return ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                HStack {
                    Text("Settings")
                        .font(.system(size: 34))
                        .kerning(0.4)
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
                VStack(spacing: 0) {
                    Spacer().frame(height: 0)
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 8) {
                            if subscriptionManager.hasSubscription {
                                SubscriptionDetailsCard(tokens: manager.availableGenerations, onBuy: { showTokensShop = true })
                                    .padding(.bottom, 28)
                            }
                            Button(action: { showSubscriptionSheet = true }) {
                                HStack {
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(Color(hex: "#9D3AE9"))
                                    Text("Upgrade plan")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white)
                                }
                                .padding()
                                .background(LinearGradient(
                                    gradient: Gradient(colors: [Color(hex: "#7A1DF2"), Color(hex: "#F2315F")]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                                .cornerRadius(16)
                            }
                            .padding(.horizontal, 16)
                            SectionHeader(title: "Support us")
                            SettingsRow(icon: "star.fill", text: "Rate app", action: { rateApp() })
                            SettingsRow(icon: "square.and.arrow.up", text: "Share with friends", action: { showShareSheet = true })
                            SectionHeader(title: "Actions")
                            SettingsToggleRow(icon: "bell.fill", text: "Notifications", isOn: $notificationsEnabled)
                            SettingsRow(icon: "trash.fill", text: "Clear cache", trailing: AnyView(Text(cacheSize).foregroundColor(.white.opacity(0.5))), action: { showCacheAlert = true })
                            SettingsRow(icon: "arrow.clockwise", text: "Restore purchases", action: { restorePurchases() })
                            SectionHeader(title: "Info & legal")
                            SettingsRow(icon: "envelope.fill", text: "Contact us", action: { openURL("https://docs.google.com/forms/d/e/1FAIpQLScceYKs6jrxUJU81dMdGGhyG_sHwY8eMPp7voJOnbaZaCy46w/viewform?usp=dialog")})
                            SettingsRow(icon: "doc.text.fill", text: "Privacy Policy", action: { openURL("https://docs.google.com/document/d/1OTKhILMhMAz3WaosGL6X8Td5y5XJDey3awcrg1BRdzY/edit?usp=sharing") })
                            SettingsRow(icon: "doc.text.fill", text: "Usage Policy", action: { openURL("https://docs.google.com/document/d/1NI5V7ZrVBA4jlZSZTp_iAeC4MTuf85VFtJs5E73LnhI/edit?usp=sharing") })
                            Spacer(minLength: 40)
                        }
                    }
                }
            }
            .background(Color.black.ignoresSafeArea())
            .sheet(isPresented: $showShareSheet) {
                ActivityView(activityItems: [URL(string: "https://apps.apple.com/us/app/pixune/id6748326417")!])
            }
            .sheet(isPresented: $showMail) {
                MailView(isShowing: $showMail, result: $mailResult)
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Info"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .alert("Clear cache?", isPresented: $showCacheAlert) {
                Button("Clear", role: .destructive) {
                    clearCache()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("The cached files of your videos will be deleted from your phone's memory. But your download history will be retained.")
            }
            .onAppear {
                cacheSize = VideoCacheManager.shared.cacheSizeString()
            }
        }
    }

    private func rateApp() {
        guard let url = URL(string: "itms-apps://itunes.apple.com/app/id6748326417?action=write-review") else { return }
        UIApplication.shared.open(url)
    }
    private func clearCache() {
        VideoCacheManager.shared.clearCache()
        cacheSize = VideoCacheManager.shared.cacheSizeString()
        alertMessage = "Cache cleared"
        showAlert = true
    }
    private func restorePurchases() {
        Apphud.restorePurchases { subscriptions, purchases, error in
            alertMessage = "Purchases restored"
            showAlert = true
        }
    }
    private func openURL(_ url: String) {
        if let url = URL(string: url) {
            UIApplication.shared.open(url)
        }
    }
}

struct SectionHeader: View {
    let title: String
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 2)
    }
}

struct SettingsRow: View {
    let icon: String
    let text: String
    var trailing: AnyView? = nil
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color(hex: "#9D3AE9"))
                Text(text)
                    .foregroundColor(.white)
                    .font(.system(size: 17, weight: .medium))
                Spacer()
                if let trailing = trailing {
                    trailing
                }
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(hex: "#9D3AE9").opacity(0.7))
            }
            .padding()
            .background(Color.white.opacity(0.08))
            .cornerRadius(14)
        }
        .padding(.horizontal, 16)
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let text: String
    @Binding var isOn: Bool
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "#9D3AE9"))
            Text(text)
                .foregroundColor(.white)
                .font(.system(size: 17, weight: .medium))
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(14)
        .padding(.horizontal, 16)
    }
}

struct MailView: UIViewControllerRepresentable {
    @Binding var isShowing: Bool
    @Binding var result: Result<MFMailComposeResult, Error>?
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setToRecipients(["support@d.ai"])
        vc.setSubject("Support request")
        vc.mailComposeDelegate = context.coordinator
        return vc
    }
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailView
        init(_ parent: MailView) { self.parent = parent }
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.result = error == nil ? .success(result) : .failure(error!)
            parent.isShowing = false
        }
    }
}

struct SubscriptionDetailsCard: View {
    var tokens: Int = 0
    var onBuy: () -> Void = {}
    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(hex: "#9D3AE9"), lineWidth: 1.5)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(hex: "#181818"))
                )
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Subscription details")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        Text("Information on subscription\nbenefits and prices")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    Spacer()
                    ZStack {
                        CrownCircleButton(action: {})
                    }
                }
                .padding(.bottom, 2)
                HStack(spacing: 8) {
                    Text("My tokens:")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.white)
                    Text("\(tokens)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(hex: "#9D3AE9"))
                }
                Button(action: { onBuy() }) {
                    Text("Buy")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.white)
                        .cornerRadius(12)
                }
                .padding(.top, 8)
            }
            .padding(18)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}
