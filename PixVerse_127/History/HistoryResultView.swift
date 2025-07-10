import SwiftUI
import AVKit

struct HistoryResultView: View {
    let videoUrl: URL
    let historyItem: HistoryItem
    @Environment(\.presentationMode) private var presentationMode
    @State private var showShareSheet = false
    @State private var showDeleteAlert = false
    @State private var showSaveSuccess = false
    @State private var showSaveError = false
    @State private var saveErrorText = ""
    @State private var isLoadingShare = false
    @State private var localShareUrl: URL? = nil
    @State private var showCopiedToast = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.backward")
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.14))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text("Result")
                        .font(.system(size: 17))
                        .foregroundColor(.white)
                    Spacer()
                    Menu {
                        Button("Save to gallery", action: saveToGallery)
                        Button("Save to files", action: saveToFiles)
                        Button("Delete", role: .destructive, action: { showDeleteAlert = true })
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color(hex: "#9D3AE9"))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                TextureVideoViewContainer(urlString: videoUrl.absoluteString, height: UIScreen.main.bounds.height * 0.55)
                    .cornerRadius(24)
                    .padding(.top, 28)
                    .padding(.horizontal, 16)
                if let prompt = historyItem.prompt, !prompt.isEmpty {
                    PromptBlock(prompt: prompt, onCopy: {
                        showCopiedToast = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { showCopiedToast = false }
                    })
                    .padding(.top, 8)
                }
                Spacer(minLength: 0)
                Button(action: {
                    isLoadingShare = true
                    let session = URLSession.shared
                    session.downloadTask(with: videoUrl) { localURL, response, error in
                        DispatchQueue.main.async {
                            isLoadingShare = false
                        }
                        guard let localURL = localURL else {
                            saveErrorText = error?.localizedDescription ?? "Download error"
                            showSaveError = true
                            return
                        }
                        let tempDir = FileManager.default.temporaryDirectory
                        let newURL = tempDir.appendingPathComponent(UUID().uuidString + ".mp4")
                        do {
                            try FileManager.default.moveItem(at: localURL, to: newURL)
                            DispatchQueue.main.async {
                                localShareUrl = newURL
                                showShareSheet = true
                            }
                        } catch {
                            DispatchQueue.main.async {
                                saveErrorText = error.localizedDescription
                                showSaveError = true
                            }
                        }
                    }.resume()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 24)
            }
            .ignoresSafeArea(edges: .bottom)
            if showCopiedToast {
                ToastView(text: "Text copied")
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
            }
        }
        .alert(isPresented: $showDeleteAlert) {
            Alert(
                title: Text("Delete result?"),
                message: Text("This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    HistoryViewModel.shared.remove(historyItem)
                    presentationMode.wrappedValue.dismiss()
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
        .sheet(isPresented: $showShareSheet, onDismiss: {
            if let url = localShareUrl {
                try? FileManager.default.removeItem(at: url)
                localShareUrl = nil
            }
        }) {
            if let url = localShareUrl {
                ActivityView(activityItems: [url])
            }
        }
        .navigationBarHidden(true)
    }
    
    private func saveToGallery() {
        let session = URLSession.shared
        session.downloadTask(with: videoUrl) { localURL, response, error in
            guard let localURL = localURL else { return }
            let tempDir = FileManager.default.temporaryDirectory
            let newURL = tempDir.appendingPathComponent(UUID().uuidString + ".mp4")
            do {
                try FileManager.default.moveItem(at: localURL, to: newURL)
                UISaveVideoAtPathToSavedPhotosAlbum(newURL.path, nil, nil, nil)
                DispatchQueue.main.async {
                    showSaveSuccess = true
                }
            } catch {
                DispatchQueue.main.async {
                    saveErrorText = error.localizedDescription
                    showSaveError = true
                }
            }
        }.resume()
    }
    
    private func saveToFiles() {
        let session = URLSession.shared
        session.downloadTask(with: videoUrl) { localURL, response, error in
            guard let localURL = localURL else {
                saveErrorText = error?.localizedDescription ?? "Download error"
                showSaveError = true
                return
            }
            let tempDir = FileManager.default.temporaryDirectory
            let newURL = tempDir.appendingPathComponent(UUID().uuidString + ".mp4")
            do {
                try FileManager.default.moveItem(at: localURL, to: newURL)
                DispatchQueue.main.async {
                    let picker = UIDocumentPickerViewController(forExporting: [newURL])
                    UIApplication.shared.windows.first?.rootViewController?.present(picker, animated: true)
                }
            } catch {
                DispatchQueue.main.async {
                    saveErrorText = error.localizedDescription
                    showSaveError = true
                }
            }
        }.resume()
    }
}
