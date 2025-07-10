import SwiftUI
import AVKit

struct GenerationResultView: View {
    let videoUrl: URL
    var effectTitle: String? = nil
    var onDismiss: (() -> Void)? = nil
    var onShare: (() -> Void)? = nil
    var onMenu: (() -> Void)? = nil
    
    @State private var showShareSheet = false
    @State private var localVideoUrl: URL? = nil
    @State private var isLoading = true
    @State private var showMenu = false
    @State private var showDeleteAlert = false
    @State private var showSaveSuccess = false
    @State private var showSaveError = false
    @State private var saveErrorText = ""
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    VStack(spacing: 0) {
                        ZStack(alignment: .top) {
                            if isLoading {
                                ProgressView("Loading video...")
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.top, 100)
                            } else if let localUrl = localVideoUrl {
                                VideoPlayer(player: AVPlayer(url: localUrl))
                                    .frame(height: 360)
                                    .cornerRadius(24)
                                    .padding(.top, 56)
                                    .padding(.horizontal, 16)
                            }
                            LinearGradient(
                                gradient: Gradient(colors: [Color.black.opacity(0.5), .clear]),
                                startPoint: .top, endPoint: .bottom
                            )
                            .frame(height: 120)
                            .cornerRadius(24)
                            .padding(.top, 90)
                            .padding(.horizontal, 16)
                        }
                        Spacer()
                    }
                    HStack {
                        Button(action: { onDismiss?() }) {
                            Image(systemName: "chevron.backward")
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 32, height: 32)
                                .background(Color.white.opacity(0.14))
                                .clipShape(Circle())
                        }
                        Spacer()
                        if let effectTitle = effectTitle {
                            Text(effectTitle)
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Menu {
                            Button("Save to gallery", action: saveToGallery)
                            Button("Save to files", action: saveToFiles)
                            Button("Delete", role: .destructive, action: { showDeleteAlert = true })
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.black)
                                .frame(width: 32, height: 32)
                                .background(Color(hex: "#D1FE17"))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
                Spacer()
                Button(action: {
                    if let onShare = onShare {
                        onShare()
                    } else {
                        showShareSheet = true
                    }
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(.system(size: 17))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "#D1FE17"))
                    .cornerRadius(16)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 34)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let localUrl = localVideoUrl {
                ActivityView(activityItems: [localUrl])
            }
        }
        .onAppear {
            VideoCacheManager.shared.downloadAndCache(url: videoUrl) { localUrl in
                DispatchQueue.main.async {
                    self.localVideoUrl = localUrl
                    self.isLoading = false
                }
            }
        }
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Delete result?"),
                message: Text("This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    onDismiss?()
                },
                secondaryButton: .cancel()
            )
        }
        .alert(isPresented: $showSaveSuccess) {
            Alert(title: Text("Saved!"), message: nil, dismissButton: .default(Text("OK")))
        }
        .alert(isPresented: $showSaveError) {
            Alert(title: Text("Error"), message: Text(saveErrorText), dismissButton: .default(Text("OK")))
        }
    }
    
    private func downloadVideo(url: URL) {
        // Скачивание видео в Фотоальбом
        let session = URLSession.shared
        session.downloadTask(with: url) { localURL, response, error in
            guard let localURL = localURL else { return }
            UISaveVideoAtPathToSavedPhotosAlbum(localURL.path, nil, nil, nil)
        }.resume()
    }
    
    private func saveToGallery() {
        guard let localUrl = localVideoUrl else { return }
        UISaveVideoAtPathToSavedPhotosAlbum(localUrl.path, nil, nil, nil)
        showSaveSuccess = true
        showMenu = false
    }
    
    private func saveToFiles() {
        guard let localUrl = localVideoUrl else { return }
        let picker = UIDocumentPickerViewController(forExporting: [localUrl])
        UIApplication.shared.windows.first?.rootViewController?.present(picker, animated: true)
        showMenu = false
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    GenerationResultView(videoUrl: URL(string: "https://www.w3schools.com/html/mov_bbb.mp4")!, onDismiss: {}, onMenu: {})
} 
