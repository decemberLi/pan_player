import SwiftUI
import Toasts

// 正确导入项目中的类型
struct FileListView115: View {
    @Environment(\.presentToast) var presentToast
    @Environment(AppModel.self) private var appModel
    
    let currentDir: FileItem?
    @State private var fileList: [FileItem] = []
    @State private var isLoading = false
    @State private var offset = 0
    @State private var hasMore = false
    @State private var showVideo = false
    @State private var showVideoSelection = false
    @State private var availableVideos: [VideoURL115] = []
    @State private var selectedVideoURL: URL?
    
    private let gridItems = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    var body: some View {
        let title = currentDir?.fn ?? "115"
        Group{
            if isLoading && fileList.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: gridItems, spacing: 10) {
                        ForEach(fileList, id: \.fid) { file in
                            FileItemView(file: file) { selectedFile in
                                handleFileSelection(selectedFile)
                            }
                        }
                    }
                    .padding()
                    if hasMore {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .onAppear {
                                Task { await loadFiles() }
                            }
                    }
        }
        .refreshable {
           await loadFiles()
        }
            }
        }
        .navigationTitle(title)
        .onAppear {
            guard fileList.isEmpty else{
                return
            }
            Task {
              await  loadFiles()
            }
            
        }
        .fullScreenCover(isPresented: $showVideo) {
            PlayView()
        }
        .navigationDestination(for: FileItem.self) { dir in
            let cid = dir.fid
            if cid == "root" {
                FileListView115(currentDir: nil)
            } else {
                FileListView115(currentDir: dir)
            }
        }
        .actionSheet(isPresented: $showVideoSelection) {
            ActionSheet(
                title: Text("选择视频质量"),
                message: Text("请选择要播放的视频质量"),
                buttons: availableVideos.map { video in
                    .default(Text("\(video.title) (\(video.width)x\(video.height))")) {
                        if let remoteURL = URL(string: video.url) {
                            let playURL: URL
                            if video.title == "原画" {
                                print("[FileListView115] choose 原画 -> via proxy")
                                playURL = LocalHTTPProxy.shared.proxyURL(for: remoteURL)
                            } else {
                                print("[FileListView115] choose 清晰度=\(video.title) -> direct url")
                                playURL = remoteURL
                            }
                            print("[FileListView115] final play url=\(playURL.absoluteString)")
                            selectedVideoURL = playURL
                            appModel.selectVideo(url: playURL)
                            showVideo = true
                        } else {
                            print("[FileListView115] invalid video.url: \(video.url)")
                        }
                    }
                } + [.cancel()]
            )
        }
    }
    
    @MainActor
    private func loadFiles() async{
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            let cid = currentDir?.fid
            let data = try await DataManager115.shared.getFileList(cid: cid, limit: 100, offset: offset)
            
            if let newData = data.data {
                if offset == 0 {
                    fileList = newData
                } else {
                    fileList.append(contentsOf: newData)
                }
                
                // 更新分页状态
                if let count = data.count{
                    hasMore = fileList.count < count
                } else {
                    hasMore = !newData.isEmpty
                }
                
                offset += newData.count
            } else {
                hasMore = false
            }
        } catch {
            print("加载文件列表失败: \(error)")
            let toast = ToastValue(
                icon: Image(systemName: "exclamationmark.triangle"),
                message: "加载文件列表失败"
            )
            presentToast(toast)
        }
    }
    
    private func handleFileSelection(_ file: FileItem) {
        // 判断是文件夹还是文件
        if file.fc == "0" { // 文件夹
            
        } else { // 文件
            // 判断是否是视频文件
            if file.isVideoFile {
                playVideo(file)
            } else {
                // 弹出toast：不支持该文件播放
                let toast = ToastValue(
                    icon: Image(systemName: "exclamationmark.triangle"),
                    message: "不支持该文件播放"
                )
                presentToast(toast)
            }
        }
    }
    
    
    private func playVideo(_ file: FileItem) {
        guard let pickCode = file.pc else { return }
        
        Task {
            do {
                let downloadData = try await DataManager115.shared.getFileDownloadURL(pick_code: pickCode)
                let videoData = try await DataManager115.shared.getVideoPlayURL(pick_code: pickCode)
                
                
                if var videoUrls = videoData.data?.videoUrl, !videoUrls.isEmpty {
                    if !downloadData.isEmpty &&  videoUrls.count > 1{
                        print("[FileListView115] append 原画 download url len=\(downloadData.count)")
                        videoUrls.append(VideoURL115(url: downloadData, height: 0, width: 0, definition: 0, title: "原画", definitionN: 0))
                    } else if downloadData.isEmpty {
                        print("[FileListView115] no downloadData for 原画")
                    }
                    await MainActor.run {
                        availableVideos = videoUrls
                        showVideoSelection = true
                    }
                } else {
                    let toast = ToastValue(
                        icon: Image(systemName: "exclamationmark.triangle"),
                        message: "获取视频播放地址失败"
                    )
                    presentToast(toast)
                }
            } catch {
                print("[FileListView115] 获取视频播放地址失败: \(error)")
                let toast = ToastValue(
                    icon: Image(systemName: "exclamationmark.triangle"),
                    message: "获取视频播放地址失败"
                )
                presentToast(toast)
            }
        }
    }
}

struct FileItemView: View {
    let file: FileItem
    let onTap: (FileItem) -> Void
    
    var body: some View {
        Group {
            if file.fc == "0" {
                NavigationLink(value: file) {
                    VStack(spacing: 5) {
                        FileIconView(file: file)
                            .font(.system(size: 40))
                            .frame(width: 50, height: 50)
                        
                        Text(file.fn ?? "Unknown")
                            .font(.caption)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .background(Color.clear)
                    .contentShape(Rectangle())
                    .padding()
                }
                .buttonStyle(.plain)
                
            }else{
                Button(action: {
                    onTap(file)
                }) {
                    VStack(spacing: 5) {
                        FileIconView(file: file)
                            .font(.system(size: 40))
                            .frame(width: 50, height: 50)
                        
                        Text(file.fn ?? "Unknown")
                            .font(.caption)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .background(Color.clear)
                    .contentShape(Rectangle())
                    .padding()
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        
    }
}

struct FileIconView: View {
    let file: FileItem
    
    var body: some View {
        Group {
            if file.fc == "0" { // 文件夹
                Image(systemName: "folder.fill")
                        .foregroundColor(.blue)
                
            } else { // 文件
                if file.isVideoFile {
                    Image(systemName: "video.fill")
                        .foregroundColor(.red)
                } else {
                    Image(systemName: "doc.fill")
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    
}
