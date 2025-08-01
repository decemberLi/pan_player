import SwiftUI
import Toasts

struct SettingsView: View {
    @Environment(\.presentToast) private var presentToast
    
    var body: some View {
        var jsonString = UserDefaults.standard.string(forKey: "115token")
        VStack {
            Text("设置")
                .font(.title)
                .padding()
            Text("115Token: \(jsonString ?? "未设置")")
            .onTapGesture {
                UIPasteboard.general.string = jsonString
                let toast = ToastValue(
                    icon: Image(systemName: "checkmark"),
                    message: "已复制到剪贴板"
                )
                presentToast(toast)
            }
        }
    }
}
