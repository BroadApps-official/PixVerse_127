import SwiftUI

struct FeedbackView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appState: AppStateManager
    let appStoreId = "6748326417"
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Spacer()
                
                Image("heart")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 260, height: 260)
                
                Text("Do you like our app?")
                    .font(.system(size: 20))
                    .bold()
                    .foregroundColor(.white)
                
                Text("Please rate our app so we can improve it for \n you and make it even cooler")
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 39)
                
                HStack(spacing: 15) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("No")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "#9D3AE91F").opacity(0.12))
                            .foregroundColor(Color(hex: "#9D3AE9"))
                            .cornerRadius(12)
                            .font(.system(size: 17, weight: .bold))
                    }
                    
                    Button(action: {
                        openAppStoreReview()
                      //  appState.markAsRated()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Yes")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.white)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                            .font(.system(size: 17, weight: .bold))
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(Color(hex: "#9D3AE9"))
                            .padding()
                    }
                }
                Spacer()
            }
        }
    }
    
    private func openAppStoreReview() {
        guard let url = URL(string: "https://apps.apple.com/app/id\(appStoreId)?action=write-review") else { return }
        UIApplication.shared.open(url, options: [:]) { _ in }
    }
}
