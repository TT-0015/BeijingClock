# BeijingClock

极简 macOS 原生北京时间时钟，使用 Swift、SwiftUI 和 AppKit，无第三方依赖。

- 固定 `Asia/Shanghai` 时区，24 小时制 `HH:mm:ss`，每秒读取系统时间，无需联网。
- 默认纯黑全屏，白色等宽轻字重数字居中显示。
- `Control + Command + F` 切换全屏，`Esc` 返回小窗口，`Command + Q` 退出。
- 全屏自动隐藏鼠标；移动后显示，静止约 2 秒再次隐藏。
- 无模糊材质、无数字动画；窗口不可见时暂停时间视图，恢复时读取当前时间。

## 构建

需要 Apple Silicon Mac、macOS 13 或更高版本，以及 Xcode 或 Command Line Tools。

```sh
sh ./build.sh
open dist/BeijingClock.app
```

也可使用 Xcode 打开 `BeijingClock.xcodeproj`，选择 BeijingClock target 后构建运行。

脚本生成本地临时签名的 App，不包含 Developer ID 签名或公证。实际整机功耗取决于显示器、亮度及其他运行中的应用，本项目未测量整机功耗。

## 许可证

[MIT](LICENSE)
