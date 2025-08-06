import SwiftUI
import Toasts

struct SettingsView: View {
    @Environment(\.presentToast) private var presentToast
    
    var body: some View {
        let jsonString = UserDefaults.standard.string(forKey: "115token")
        VStack {
            Text("设置")
                .font(.title)
                .padding()
            
            #if DEBUG
            Text("115Token: \(jsonString ?? "未设置")")
                .padding()
            .onTapGesture {
                UIPasteboard.general.string = jsonString
                let toast = ToastValue(
                    icon: Image(systemName: "checkmark"),
                    message: "已复制到剪贴板"
                )
                presentToast(toast)
            }
            #endif
            Text("清除115登录信息")
                .onTapGesture {
                    TokenManager115.shared.clear()
                    let toast = ToastValue(
                        icon: Image(systemName: "checkmark"),
                        message: "清除成功"
                    )
                    presentToast(toast)
                }
            Text("V1.0.0")
        }
    }
}
