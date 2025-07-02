import SwiftUI

struct PhotoRequirementsView: View {
    var onOkay: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Drag indicator
            Capsule()
                .fill(Color.white.opacity(0.25))
                .frame(width: 44, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 8)

            Text("Photo requirements")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 0)

            VStack(alignment: .leading, spacing: 12) {
                Text("Good photos")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "#D1FE17"))

                HStack(spacing: 12) {
                    photoItem(imageName: "good1", label: "Face is visible", isGood: true)
                    photoItem(imageName: "good2", label: "Good lighting", isGood: true)
                    photoItem(imageName: "good3", label: "Front view", isGood: true)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Bad photos")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: "#D1FE17"))

                HStack(spacing: 12) {
                    photoItem(imageName: "bad1", label: "Face is hidden", isGood: false)
                    photoItem(imageName: "bad2", label: "Poor lighting", isGood: false)
                    photoItem(imageName: "bad3", label: "Bad angle", isGood: false)
                }
            }

            Button(action: onOkay) {
                Text("\(Image(systemName: "checkmark")) Okay")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    .background(Color(hex: "#D1FE17"))
                        .cornerRadius(16)
                }
            .padding(.horizontal)
        }
        .padding(.bottom, 16)
        .background(Color.black.edgesIgnoringSafeArea(.all))
        .presentationDetents([.height(500)])
    }

    private func photoItem(imageName: String, label: String, isGood: Bool) -> some View {
        VStack(spacing: 8) {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 90, height: 100)
                .clipped()
                .cornerRadius(8)
                .overlay(
                    Image(systemName: isGood ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(isGood ? .green : .red)
                        .padding(6),
                    alignment: .bottomTrailing
                )

            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .frame(width: 90)
        }
    }
}

#Preview {
    PhotoRequirementsView(onOkay: {})
} 
