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
    // TODO: пробросить item для удаления

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#D1FE17"), .black]),
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    TextureVideoViewContainer(urlString: videoUrl.absoluteString, height: UIScreen.main.bounds.height * 0.6)
                        .cornerRadius(24)
                        .padding(.top, 90)
                        .padding(.horizontal, 16)
                        .clipped()
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
                            .font(.custom("SpaceGrotesk-Light_Medium", size: 17))
                            .foregroundColor(.white)
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
                    .background(
                              LinearGradient(
                                  gradient: Gradient(colors: [Color(hex: "#D1FE17"), .black]),
                                  startPoint: .top, endPoint: .bottom
                              )
                              .ignoresSafeArea(edges: .top)
                          )
                }
                Spacer()
                ResultShareButton(onShare: { showShareSheet = true })
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: [videoUrl])
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
