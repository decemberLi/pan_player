import SwiftUI
import Toasts

// 正确导入项目中的类型
struct FileListView115: View {
    @Environment(\.presentToast) var presentToast
    @Environment(AppModel.self) private var appModel
    
    let cid: String?
    @State private var fileList: [FileItem] = []
    @State private var isLoading = false
    @State private var offset = 0
    @State private var hasMore = true
    @State private var showVideo = false
    
    private let gridItems = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridItems, spacing: 10) {
                ForEach(fileList, id: \.fid) { file in
                    FileItemView(file: file) { selectedFile in
                        handleFileSelection(selectedFile)
                    }
                }
                
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .padding()
        }
        .navigationTitle(cid == nil ? "根目录" : "文件夹")
        .onAppear {
            loadFiles()
        }
        .onDisappear {
            // 重置状态
            fileList = []
            offset = 0
            hasMore = true
        }
        .fullScreenCover(isPresented: $showVideo) {
            PlayView()
        }
        .navigationDestination(for: String.self) { cid in
            if cid == "root" {
                FileListView115(cid: nil)
            } else {
                FileListView115(cid: cid)
            }
        }
    }
    
    private func loadFiles() {
        guard !isLoading && hasMore else { return }
        
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                let data = try await DataManager115.shared.getFileList(cid: cid, limit: 20, offset: offset)
                
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
                let videoData = try await DataManager115.shared.getVideoPlayURL(pick_code: pickCode)
                
                if let videoUrlString = videoData.data?.videoUrl?.first?.url,
                   let url = URL(string: videoUrlString) {
                    await MainActor.run {
                        appModel.selectVideo(url: url)
                        showVideo = true
                    }
                } else {
                    let toast = ToastValue(
                        icon: Image(systemName: "exclamationmark.triangle"),
                        message: "获取视频播放地址失败"
                    )
                    presentToast(toast)
                }
            } catch {
                print("获取视频播放地址失败: \(error)")
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
                NavigationLink(value: file.fid) {
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
