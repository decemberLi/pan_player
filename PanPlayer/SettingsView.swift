import SwiftUI
import Toasts

struct SettingsView: View {
    @Environment(\.presentToast) private var presentToast
    @State private var showingClearAlert = false
    
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
                        // TODO: 跳转到隐私政策页面
                        // let url = URL(string: "https://example.com/privacy")!
                        // UIApplication.shared.open(url)
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
                        // TODO: 跳转到用户协议页面
                        // let url = URL(string: "https://example.com/terms")!
                        // UIApplication.shared.open(url)
                    }) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                            Text("用户协议")
                                .foregroundColor(.blue)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
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
}
