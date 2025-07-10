import SwiftUI

struct ResultShareButton: View {
    let onShare: () -> Void
    var body: some View {
        Button(action: onShare) {
            HStack {
                Image(systemName: "square.and.arrow.up")
                Text("Share")
            }
            .font(.system(size: 17))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.white)
            .cornerRadius(16)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 34)
    }
} 
