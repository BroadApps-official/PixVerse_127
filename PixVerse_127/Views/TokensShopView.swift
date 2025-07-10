import SwiftUI
import Combine
import ApphudSDK

struct TokensShopView: View {
    @StateObject var viewModel = TokensShopViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @ObservedObject private var manager = Manager.shared
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    Image("paywall")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 250)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.black.opacity(0.0), Color.black.opacity(0.85)]),
                                startPoint: .center, endPoint: .bottom
                            )
                        )
                        .ignoresSafeArea(edges: .top)
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.system(size: 22, weight: .bold))
                    }
                    .padding(.top, 4 + (UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0))
                    .padding(.trailing, 16)
                }
                .frame(height: 250)
                VStack(spacing: 4) {
                    Text("Need more generations?")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.top, 12)
                    Text("Buy additional tokens")
                        .font(.system(size: 15))
                        .foregroundColor(Color.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    HStack(spacing: 6) {
                        Text("My tokens:")
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                        Text("\(manager.availableGenerations)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(hex: "#D1FE17"))
                    }
                    .padding(.top, 2)
                    .padding(.bottom, 8)
                }
                VStack(spacing: 12) {
                    ForEach(Array(viewModel.tokenProducts.enumerated()), id: \.offset) { index, product in
                        TokenProductRow(product: product) {
                            viewModel.purchaseProduct(product: product)
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 8)
                .padding(.bottom, 24)
                Spacer()
            }
            HStack {
                Button(action: { openURL("https://docs.google.com/document/d/1OTKhILMhMAz3WaosGL6X8Td5y5XJDey3awcrg1BRdzY/edit?usp=sharing") }) {
                    Text("Privacy Policy")
                        .font(.system(size: 13))
                        .foregroundColor(Color.white.opacity(0.3))
                }
                Spacer()
                Button(action: { openURL("https://docs.google.com/document/d/1NI5V7ZrVBA4jlZSZTp_iAeC4MTuf85VFtJs5E73LnhI/edit?usp=sharing") }) {
                    Text("Terms of Use")
                        .font(.system(size: 13))
                        .foregroundColor(Color.white.opacity(0.3))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .background(Color.black.ignoresSafeArea())
        .onReceive(viewModel.$purchaseStatus) { status in
            guard let status = status else { return }
            switch status {
            case .success(let product):
                showAlert(title: "Success", message: "You bought \(product.amount) tokens.")
            case .failure(let error):
                showAlert(title: "Error", message: error)
            case .cancelled:
                showAlert(title: "Cancelled", message: "Purchase was cancelled.")
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            print("[Tokens] 🏪 Открыт магазин токенов (TokensShopView)")
        }
    }
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
    private func openURL(_ url: String) {
        if let url = URL(string: url) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - TokenProductRow
struct TokenProductRow: View {
    let product: TokenProduct
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                Text("\(product.amount) tokens")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.white)
                Spacer()
                if let saveText = product.saveText {
                    Text(saveText)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: "#D1FE17"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(hex: "#232325"))
                        .cornerRadius(6)
                        .padding(.trailing, 8)
                }
                Text(product.price)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.white)
                    .padding(.leading, 12)
                Image(systemName: "chevron.right")
                    .foregroundColor(Color.white.opacity(0.5))
                    .padding(.leading, 8)
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 20)
            .background(Color(hex: "#181818"))
            .cornerRadius(16)
        }
    }
}

// MARK: - CornerRadius for specific corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}
