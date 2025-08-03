import SwiftUI

struct MainView: View {
    // 1. 获取或创建 Application Support 目录
    func getAppSupportURL() -> URL {
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        if !fileManager.fileExists(atPath: appSupportURL.path) {
            try? fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        }
        return appSupportURL
    }

    // 2. 写入文本文件
    func writeFile(content: String, to fileName: String) {
        let fileURL = getAppSupportURL().appendingPathComponent(fileName)
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            print("✅ 文件已保存至: \(fileURL.path)")
        } catch {
            print("❌ 错误: \(error)")
        }
    }
    
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Image(systemName: "house")
                    Text("主页")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("设置")
                }
        }
        .onAppear {
            writeFile(content: "1", to: "tmp")
        }
    }
}

#Preview {
    MainView()
}
