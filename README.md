## PanPlayer

一个基于 SwiftUI + RealityKit 的沉浸式视频播放器，面向 visionOS。支持本地视频/相册视频/115 网盘视频播放，并可在沉浸式空间中以半球（VR180）投影方式观看。播放控制采用自定义控制面板，支持快进/快退、拖拽进度条、分辨率与音轨选项展示（当流提供时）。

Android版本[decemberLi/easy_vr_player](https://github.com/decemberLi/easy-vr-player-android)

### 核心特性

- **沉浸式播放（VR180）**: 在 `ImmersiveSpace` 中使用自定义球面网格进行半球投影，结合 Metal 计算着色器实现高效的 YUV → RGB 转换。
- **多源输入**:
  - 相册选择视频（支持 Spatial Video 选取并拷贝到临时目录）
  - 文件导入器选择本地视频
  - 115 网盘授权登录、浏览与播放（支持清晰度选项与“原画”直链）
- **本地 HTTP 代理（边下边播）**: 对 115 的“原画”下载直链，自动通过本地代理转发并支持 Range/分块，达到即点即播效果。
- **播放控制面板**: 播放/暂停、±15s 跳转、进度拖拽、码率显示、分辨率/音轨切换入口（当可用）。
- **统一状态管理**: 通过 `@Observable` 的 `AppModel` 与自定义 `VideoPlayer` 暴露播放状态与控制接口，UI 与沉浸式视图共享同一播放器。

## 环境要求

- Xcode（建议使用最新正式版，对应 Swift 6 工具链）
- visionOS SDK（建议使用最新版本）
- 目标平台：visionOS（支持模拟器与真机）。工程中包含部分 iOS 相关能力，但主体验为 visionOS。

## 构建与运行

1. 使用 Xcode 打开 `PanPlayer.xcodeproj`。
2. 选择 Team 及签名，修改 Bundle Identifier 以满足本地签名策略。
3. 选择 Apple Vision Pro 模拟器或真机作为运行目标。
4. 直接运行（SPM 依赖会自动解析）。

如遇到首次编译较慢或 Metal/RealityKit 资源索引耗时，请耐心等待。

提示：若在解析 SPM 依赖时出现“package 使用 Swift tools 6.2.0，但当前安装为 6.1.0”之类提示，请升级至支持相应 Swift 工具链版本的 Xcode。

## 使用说明

应用启动后，进入包含“主页/设置”的 `TabView`：

- **主页 `ContentView`**：

  - “相册视频”：打开系统相册视频选择器。若选择 Spatial Video，会拷贝一份到临时目录并播放。
  - “选择视频文件”：打开文件导入器，选取本地 `.mp4/.mov/...` 视频。
  - “115 网盘”：若未登录，将弹框引导至网页授权；完成授权后进入文件列表。

- **115 文件页 `FileListView115`**：

  - 点击目录进入下级；点击视频文件会弹出“清晰度选择”（当接口返回多清晰度时）。若也获取到直链，将额外出现“原画”选项。
  - 选择“原画”时，会通过本地 HTTP 代理把下载直链包装为可边下边播的地址再交给播放器；其它清晰度则直接使用返回的播放 URL。
  - 选定后进入播放器页面。

- **播放器 `PlayView`**：

  - 基于 `KSVideoPlayerView` 的平面播放器；点击播放器内“VR/沉浸式”按钮将打开 `ImmersiveSpace`。

- **沉浸式 `ImmersiveView`**：

  - 视频以 VR180 半球投影显示。
  - 轻点空间任意处可显示/隐藏控制面板。
  - 控制面板支持播放/暂停、±15s、拖拽进度、（可用时）分辨率与音轨选项；可点击返回按钮退出沉浸式空间。

- **设置 `SettingsView`**：
  - 清除 115 登录信息。
  - Debug 区（仅 Debug 构建可见）：复制当前 token，快速打开/关闭沉浸式空间做联调等。

## 目录结构与模块

- `PanPlayerApp.swift`：应用入口，声明 `WindowGroup` 与 `ImmersiveSpace`。
- `MainView.swift`：顶层 `TabView`（主页/设置）。
- `ContentView.swift`：入口页，负责相册/文件/115 网盘入口与导航。
- `PlayView.swift`：平面播放器页面，内含进入沉浸式的触发。
- `ImmersiveView.swift`：沉浸式空间，创建 RealityKit 实体、半球网格与控制面板附件。
- `Utils/Video/VideoPlayer.swift`：统一的播放控制器，封装 KSPlayer 状态与方法，供 UI 与沉浸式共用。
- `Utils/Video/Immersive/VideoPlaybackViewModel.swift`：
  - 负责加载 `SBSMaterial.usda` 着色材料，创建/替换 `TextureResource`。
  - Metal 计算通道：NV12 与 I420 的 YUV → BGRA 转换并写入 RealityKit 纹理队列。
- `Utils/Video/Views/ControlPanel.swift`：沉浸式控制面板及子视图（信息、进度、分辨率/音轨等）。
- `Utils/Video/Utils/VideoTools.swift`：生成 VR180/VR360 球面网格与辅助工具。
- `Utils/Video/Shaders.metal`：Metal 内核（`yuv420ToRGB`/`yuv420PToRGB` 等）。
- `Utils/Network/LocalHTTPProxy.swift`：本地 HTTP 代理（支持 GET/HEAD 与 Range），用于 115 原画直链的边下边播。
- `Utils/HeadTracker.swift`：头部跟踪（当前工程仅创建/停止，未启用实时跟踪回调）。
- `Utils/String+MD5.swift`：用于 115 授权 state 的 MD5 生成。
- `115/Data/*` 与 `115/View/FileListView115.swift`：115 网盘 API、数据模型与文件浏览/播放入口。
- `WebViewContainer.swift`：承载 115 网页授权，拦截回调参数 `code/state` 并传回应用。
- `SBSMaterial.usda`：RealityKit Shader Graph 资源，绑定到视频纹理用于沉浸式渲染。

## 依赖与第三方

- KSPlayer（含 FFmpeg 能力，封装为 `KSVideoPlayerView` 与 `MEPlayerItem` 等）
- Toasts（轻提示）
- RealityKit / ARKit / AVKit / PhotosUI / SwiftUI / Metal / UniformTypeIdentifiers
- `Packages/RealityKitContent`（Apple 示例资产与辅助 Bundle）

依赖通过 SPM 自动解析，无需手动安装。

## 权限与网络

- 相册权限：用于选择视频（`NSPhotoLibraryUsageDescription` 已在 Info.plist 配置）。
- ATS：已启用任意加载（开发阶段方便请求 115 的 http 资源，正式发布建议收敛到必要域名白名单）。

## 可选配置（OpenImmersive）

文件 `Config.swift` 支持从 `openimmersive.plist` 读取自定义参数（如控制面板位置、可选项开关、网格半径、抓点调试等）。工程当前未提供该 plist，均使用默认值。若需定制，请在应用 Bundle 根目录创建 `openimmersive.plist`，可用键包括：

- `customHttpUrlScheme`、`controlPanelVerticalOffset`、`controlPanelHorizontalOffset`、`controlPanelTilt`
- `controlPanelMediaInfoMaxHeight`、`controlPanelShowBitrate`、`controlPanelShowResolutionOptions`、`controlPanelShowAudioOptions`
- `controlPanelScrubberTint`（#RRGGBB 或 #RRGGBBAA）
- `videoScreenSphereRadius`、`tapCatcherShowDebug`

## 已知限制 / 备注

- `FFmpegFrameDecoder` 方案暂未启用，当前使用 KSPlayer 的回调帧通路（`VideoPlaybackViewModel.player?.onVideoFrame`）驱动纹理更新。
- 码率/分辨率/音轨选项仅在 HLS 流（m3u8）且清单包含相关信息时可见。
- 115 网盘授权码通过 Cloudflare Worker 兑换 token，其余 115 API 由客户端直连；Debug 下提供了便捷复制/测试入口。
- 沉浸式为 VR180 半球投影，若视频为其他投影方式（VR360/矩形），需调整 `VideoTools` 或 `StreamModel.projection` 的使用策略。

### 本地 HTTP 代理（边下边播）

- **背景**：`DataManager115.getFileDownloadURL` 拿到的是下载直链，某些情况下直接交给播放器并不能获得最佳的首帧/拖拽体验；本地代理通过透传 Range 支持，实现“边下边播”。
- **工作方式**：
  - 启动一个仅本机可访问的 HTTP 端口（随机端口）。
  - 接收形如 `GET /proxy?url=<remote>` 的请求，将其转发为对 `<remote>` 的 GET/HEAD 请求，并透传 `Range` 等关键头，源站返回的数据流会原样回写。
  - 透传的响应头包含 `Content-Type`、`Content-Length`、`Accept-Ranges`、`Content-Range`、`ETag`、`Last-Modified` 等，以确保播放器按需分段请求与跳转。
- **代码入口**：
  - `Utils/Network/LocalHTTPProxy.swift`：代理实现（Network.framework + URLSession 流式转发）。
  - `AppModel.init()`：应用启动时 `LocalHTTPProxy.shared.start()` 自动启动代理。
  - `FileListView115.swift`：在清晰度 ActionSheet 中，当 `video.title == "原画"` 时使用 `LocalHTTPProxy.shared.proxyURL(for:)` 包装真实下载 URL，其它清晰度保持原始播放 URL。
- **注意事项**：
  - 代理仅支持 GET/HEAD；默认不附加额外鉴权头（直链通常已带签名）。如源站额外需要 Header，可在 `ProxySession` 中设置。
  - 若播放未启动，可查看控制台是否输出“LocalHTTPProxy ready on port: ...”，以确认代理端口已就绪。
  - 已实现“签名还原策略”：避免对直链进行二次编码/错误解码，保证签名完整；当收到 `/proxy?url=<encoded>` 时仅解码一次并按原样转发到上游。
  - 已实现“分段上限策略”：对上游 Range 做单次 8MiB 限制（如客户端请求 bytes=0-3111448464，会改为 bytes=0-8388607）。播放器将持续请求后续区间，实现稳定的边下边播。

## 维护脚本与调试

- `SettingsView` 的 Debug 分区可快速验证 Immersive Space 开/关与 Toast。
- 如需导出帧用于调试，可在 `VideoTools.dumpPixelBufferAsImage` 里启用并写出到临时目录。

## 许可证

项目中包含第三方库与资产，请遵循其各自的开源/使用协议。工程本身未显式指定 License，可根据实际需要添加。

## 未使用文件清单（可考虑删除）

以下文件在当前代码路径中未被调用/引用，仅作占位或旧版本遗留：

- `tmp/SBSMaterial.usda`
- `tmp/VideoPlaybackViewModel_old.swift`
- `Resource/FileList.json`
- `Resource/video_file.json`
- `PanPlayer/115/Data/DownloadFileData115.swift`（空实现，未被使用）
- `PanPlayer/Utils/Video/Immersive/FFmpegFrameDecoder.swift`（解码方案占位，当前未启用）

如将来启用或替换为新的实现，请相应更新此列表。
