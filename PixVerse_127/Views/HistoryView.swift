import SwiftUI
import AVKit
import Kingfisher

enum HistoryTab {
    case video
    case photo
}

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel.shared
    @State private var selectedTab: HistoryTab = .video
    @State private var showSubscriptionSheet = false
    @State private var showTokensShop = false
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var manager = Manager.shared
    
    var body: some View {
       // NavigationView {
            let items = filteredItems
            VStack(spacing: 0) {
                HStack {
                    Text("History")
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
                
                
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    segmentButton(title: "Video", isSelected: selectedTab == .video) {
                        withAnimation { selectedTab = .video }
                    }
                    segmentButton(title: "Photo", isSelected: selectedTab == .photo) {
                        withAnimation { selectedTab = .photo }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                ZStack {
                    if filteredItems.isEmpty {
                            HistoryEmptyView(onCreate: {
                                // TODO: Навигация на генерацию (реализовать по необходимости)
                            })
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.fixed(175), spacing: 8),
                                GridItem(.fixed(175), spacing: 8)
                            ], spacing: 8) {
                                ForEach(items) { item in
                                    HistoryGridCell(item: item)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.top, 20)
                        }
                    }
                }
                }
           
        }
    }
    
    private var filteredItems: [HistoryItem] {
        viewModel.items.filter { $0.type == (selectedTab == .video ? .video : .photo) }
    }
    
    private func segmentButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.custom("SpaceGrotesk-Light_Medium", size: 13))
                .kerning(-0.08)
                .foregroundColor(isSelected ? .accentColor : .customSecondaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? Color.segmentSelectedBackground : Color.segmentUnselectedBackground)
                .cornerRadius(40)
                .overlay(
                    RoundedRectangle(cornerRadius: 40)
                        .stroke(isSelected ? Color.accentColor : Color.customDivider, lineWidth: 1)
                )
                .animation(.easeInOut, value: isSelected)
        }
    }
}

struct HistoryCardView: View {
    let item: HistoryItem
    @State private var showPlayer = false
    @State private var showShare = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                if let url = item.resultUrl, item.status == .finished {
                    Button(action: { showPlayer = true }) {
                        VideoThumbnailView(urlString: url, height: 180)
                            .frame(height: 180)
                            .cornerRadius(18)
                            .overlay(
                                Image(systemName: "play.circle.fill")
                                    .resizable()
                                    .frame(width: 48, height: 48)
                                    .foregroundColor(.white.opacity(0.85))
                            )
                    }
                    .sheet(isPresented: $showPlayer) {
                        AVPlayerView(url: URL(string: url)!)
                    }
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.white.opacity(0.07))
                            .frame(height: 180)
                        if item.status == .inProgress {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                                .scaleEffect(1.5)
                        } else if item.status == .failed {
                            Image(systemName: "xmark.octagon.fill")
                                .resizable()
                                .frame(width: 48, height: 48)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            HStack {
                Text(item.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
                Text(item.status == .finished ? "Ready" : item.status == .inProgress ? "Processing" : "Failed")
                    .font(.subheadline)
                    .foregroundColor(item.status == .finished ? .green : item.status == .failed ? .red : .orange)
            }
            if let url = item.resultUrl, item.status == .finished {
                HStack(spacing: 16) {
                    Button(action: { downloadVideo(url: url) }) {
                        HStack {
                            Image(systemName: "arrow.down.to.line")
                            Text("Download")
                        }
                        .font(.custom("SpaceGrotesk-Light_Bold", size: 15))
                        .foregroundColor(.black)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.accentColor)
                        .cornerRadius(14)
                    }
                    Button(action: { showShare = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .font(.custom("SpaceGrotesk-Light_Bold", size: 15))
                        .foregroundColor(.black)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.accentColor)
                        .cornerRadius(14)
                    }
                    .sheet(isPresented: $showShare) {
                        ActivityView(activityItems: [URL(string: url)!])
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.06))
        .cornerRadius(22)
        .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 6)
    }
    
    private func downloadVideo(url: String) {
        guard let videoUrl = URL(string: url) else { return }
        let session = URLSession.shared
        session.downloadTask(with: videoUrl) { localURL, response, error in
            guard let localURL = localURL else { return }
            UISaveVideoAtPathToSavedPhotosAlbum(localURL.path, nil, nil, nil)
        }.resume()
    }
}

struct HistoryGridItemView: View {
    let item: HistoryItem
    var isSelected: Bool = false
    @State private var isLoadingStatus = false
    @State private var showDeleteAlert = false
    @State private var showSaveSuccess = false
    @State private var showSaveError = false
    @State private var saveErrorText = ""
    @EnvironmentObject var historyViewModel: HistoryViewModel
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            ZStack(alignment: .bottomLeading) {
                if let url = item.resultUrl, url.hasPrefix("http") {
                    if item.type == .video {
                        TextureVideoViewContainer(urlString: url, height: 311)
                            .frame(width: 175, height: 311)
                            .clipped()
                    } else {
                        KFImage(URL(string: url))
                            .resizable()
                            .placeholder { Color.gray.opacity(0.2) }
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 175, height: 311)
                            .clipped()
                    }
                } else if let preview = item.previewUrl {
                    Image(preview)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 175, height: 311)
                        .clipped()
                } else {
                    Color.gray.opacity(0.2)
                        .frame(width: 175, height: 311)
                }
                if let title = itemTitle {
                    Text(title)
                        .font(.custom("SpaceGrotesk-Light_Medium", size: 17))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.7), radius: 4, x: 0, y: 2)
                        .padding(.horizontal, 12)
                        .padding(.bottom, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .background(Color.black)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            if let prompt = item.prompt, !prompt.isEmpty {
                Text("Prompt")
                    .font(.custom("SpaceGrotesk-Light_Medium", size: 11))
                    .foregroundColor(Color(hex: "D1FE17"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(hex: "D1FE17"), lineWidth: 2)
                    )
                    .padding(10)
            }
        }
        .frame(width: 175, height: 311)
        .onAppear {
            if item.resultUrl == nil && item.status == .inProgress && !isLoadingStatus {
                isLoadingStatus = true
                if let jobId = item.jobId {
                    let userId = UIDevice.current.identifierForVendor?.uuidString ?? "ios-test-user-1121"
                    PhotoAPIService.shared.checkGenerationStatus(userId: userId, jobId: jobId) { result in
                        DispatchQueue.main.async {
                            isLoadingStatus = false
                            if case let .success(status) = result, let url = status.data?.resultUrl, status.data?.status?.lowercased() == "ok" || status.data?.status?.lowercased() == "finished" {
                                HistoryViewModel.shared.updateStatus(id: item.id, status: .finished, resultUrl: url)
                            }
                        }
                    }
                } else if let generationId = item.generationId {
                    APIService.shared.getGenerationStatus(generationId: generationId) { result in
                        DispatchQueue.main.async {
                            isLoadingStatus = false
                            if case let .success(status) = result, let url = status.data?.resultUrl, status.data?.status?.lowercased() == "ok" || status.data?.status?.lowercased() == "finished" {
                                HistoryViewModel.shared.updateStatus(id: item.id, status: .finished, resultUrl: url)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var itemTitle: String? {
        if let url = item.resultUrl, url.contains("cartoon") {
            return "Cartoon"
        }
        return nil
    }
    private func isPromt(_ item: HistoryItem) -> Bool {
        if let url = item.resultUrl, url.contains("promt") {
            return true
        }
        return false
    }
    
    private func saveToGallery() {
        guard let url = item.resultUrl, let fileUrl = URL(string: url) else { return }
        if item.type == .video {
            // Сохранить видео
            let session = URLSession.shared
            session.downloadTask(with: fileUrl) { localURL, response, error in
                guard let localURL = localURL else { return }
                UISaveVideoAtPathToSavedPhotosAlbum(localURL.path, nil, nil, nil)
                showSaveSuccess = true
            }.resume()
        } else {
            // Сохранить фото
            KingfisherManager.shared.retrieveImage(with: fileUrl) { result in
                switch result {
                case .success(let value):
                    UIImageWriteToSavedPhotosAlbum(value.image, nil, nil, nil)
                    showSaveSuccess = true
                case .failure(let error):
                    saveErrorText = error.localizedDescription
                    showSaveError = true
                }
            }
        }
    }
    private func saveToFiles() {
        guard let url = item.resultUrl, let fileUrl = URL(string: url) else { return }
        if item.type == .video {
            let session = URLSession.shared
            session.downloadTask(with: fileUrl) { localURL, response, error in
                guard let localURL = localURL else { return }
                let picker = UIDocumentPickerViewController(forExporting: [localURL])
                UIApplication.shared.windows.first?.rootViewController?.present(picker, animated: true)
            }.resume()
        } else {
            KingfisherManager.shared.retrieveImage(with: fileUrl) { result in
                switch result {
                case .success(let value):
                    let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
                    if let data = value.image.jpegData(compressionQuality: 0.95) {
                        do {
                            try data.write(to: tempUrl)
                            let picker = UIDocumentPickerViewController(forExporting: [tempUrl])
                            UIApplication.shared.windows.first?.rootViewController?.present(picker, animated: true)
                        } catch {
                            saveErrorText = error.localizedDescription
                            showSaveError = true
                        }
                    }
                case .failure(let error):
                    saveErrorText = error.localizedDescription
                    showSaveError = true
                }
            }
        }
    }
}

struct HistoryGridCell: View {
    let item: HistoryItem
    var body: some View {
        if let url = item.resultUrl, url.hasPrefix("http") {
            if item.type == .video {
                NavigationLink(destination: HistoryResultView(videoUrl: URL(string: url)!, historyItem: item)) {
                    HistoryGridItemView(item: item)
                }
            } else {
                NavigationLink(destination: PhotoResultView(resultUrl: url, historyItem: item, onDismiss: {}).navigationBarBackButtonHidden()) {
                    HistoryGridItemView(item: item)
                }
            }
        } else {
            HistoryGridItemView(item: item)
        }
    }
}

#Preview {
    HistoryView()
} 
