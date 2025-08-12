import SwiftUI
import Toasts

struct SettingsView: View {
    @Environment(\.presentToast) private var presentToast
    @State private var showingClearAlert = false
    @Environment(\.pushWindow) private var pushWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    var body: some View {
        let jsonString = UserDefaults.standard.string(forKey: "115token")
        
        NavigationView {
            List {
                #if DEBUG
                Section("调试信息") {
                    HStack {
                        Text("115Token")
                        Spacer()
                        Text(jsonString ?? "未设置")
                            .foregroundColor(.secondary)
                    }
                    .onTapGesture {
                        UIPasteboard.general.string = jsonString
                        let toast = ToastValue(
                            icon: Image(systemName: "checkmark"),
                            message: "已复制到剪贴板"
                        )
                        presentToast(toast)
                    }
                    HStack {
                        Text("测试窗口")
                        Spacer()
                        Text("测试窗口")
                            .foregroundColor(.secondary)
                    }
                    .onTapGesture {
                        
                        Task {
                           await openImmersiveSpace(id: WindowIDs.immersiveSpaceID)
                           pushWindow(id: WindowIDs.emptyWindow)
                            try await Task.sleep(for: .seconds(3))
                            await dismissImmersiveSpace()
                            dismissWindow(id: WindowIDs.emptyWindow)
                        }
                    }
                }
                #endif
                
                Section("账户管理") {
                    Button(action: {
                        showingClearAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("清除115登录信息")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("V1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("法律信息") {
                    Button(action: {
                         let url = URL(string: "https://vrplayer.space/privacy_policy.html")!
                         UIApplication.shared.open(url)
                    }) {
                        HStack {
                            Image(systemName: "hand.raised")
                                .foregroundColor(.blue)
                            Text("隐私政策")
                                .foregroundColor(.blue)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }

                    Button(action: {
                         let url = URL(string: "mailto:yujia.december@gmail.com")!
                         UIApplication.shared.open(url)
                    }) {
                        HStack {
                            Image(systemName: "hand.raised")
                                .foregroundColor(.blue)
                            Text("联系邮箱 yujia.december@gmail.com")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
//                    Button(action: {
//                        // TODO: 跳转到用户协议页面
//                        // let url = URL(string: "https://example.com/terms")!
//                        // UIApplication.shared.open(url)
//                    }) {
//                        HStack {
//                            Image(systemName: "doc.text")
//                                .foregroundColor(.blue)
//                            Text("用户协议")
//                                .foregroundColor(.blue)
//                            Spacer()
//                            Image(systemName: "chevron.right")
//                                .foregroundColor(.secondary)
//                                .font(.caption)
//                        }
//                    }
                }
            }
            
            // 右侧
            ZStack {
                // 背景透明，保持与系统风格一致
                Color.clear
                Image(.goodman)
                    .fixedSize()
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.large)
        .alert("确认清除", isPresented: $showingClearAlert) {
            Button("取消", role: .cancel) { }
            Button("清除", role: .destructive) {
                TokenManager115.shared.clear()
                let toast = ToastValue(
                    icon: Image(systemName: "checkmark"),
                    message: "清除成功"
                )
                presentToast(toast)
            }
        } message: {
            Text("确定要清除115登录信息吗？此操作不可撤销。")
        }
    }
}
