# 🎵 桌面积词 LyricFloat

> macOS 菜单栏积词 App — 播放「音乐」App 时，把当前歌曲的积词实时显示在菜单栏上。

macOS 自带的「音乐」App 没有控制台积词（歌词）。LyricFloat 用 AppleScript 读取当前播放曲目，
把积词「卡拉 OK」式地同步显示在系统菜单栏，并支持上一首 / 播放暂停 / 下一首 等控制。

---

## ✨ 功能特性

- 🎤 **菜单栏实时积词**：当前句积词滚动显示在菜单栏 ♪ 图标上
- 📚 **积词来源自动切换**：优先读「音乐」App 内置积词，读取不到再走 QQ 音乐在线积词回退
- ⏯️ **播放控制**：右击菜单可直接 上一首 / 播放暂停 / 下一首
- 📊 **丰富状态信息**：右击菜单显示歌曲名、播放状态、播放进度（含百分比）、积词来源与行数
- ⚡ 高性能：播放时 2s 轮询、暂停时 5s 轮询，渲染仅 5fps，节省 CPU / 内存
- 🎨 自带应用图标（♩ 音符），可在 Dock / Finder 中识别

## 📸 截图

| 菜单栏图标 | 右击菜单 |
| --- | --- |
| ♪ 积词滚动… | 见下方「交互说明」 |

> 由于是菜单栏 App，主界面即状态栏图标；点击 / 右击展开菜单即可看到全部功能。

---

## 🚀 安装

1. 下载并双击 [`桌面积词-1.0.0.dmg`](https://github.com/HEI-XIU/LyricFloat/releases)，把 `LyricFloat.app` 拖入 `Applications` 文件夹（DMG 内含 Applications 快捷方式，直接拖拽即可）。
2. 打开「访达 → 应用程序」，按住 `control` 键点按 `LyricFloat.app` → 打开（首次可能被 Gatekeeper 拦截，选择「打开」）。
3. 在「音乐」App 中播放歌曲，菜单栏即出现 ♪ 图标并显示积词。

> ⚠️ **首次授权**：App 需要控制「音乐」App。请前往
> **系统设置 → 隐私与安全性 → 自动化**，勾选允许 `LyricFloat` 控制 `音乐`。
> 未授权时右击菜单会提示「权限未授权」。

---

## 🖱️ 使用说明

点击菜单栏 ♪ 图标（右击查看功能菜单）：

- **🎵 歌曲名 — 歌手**：当前播放的曲目信息
- **▶ 播放中 / ⏸ 已暂停**：实时播放状态
- **⏱ 播放进度**：已播放 / 总时长 (百分比)
- **📝 积词来源**：Music 内置积词 / QQ 音乐积词 / 权限错误提示
- **📄 积词行数**：时间轴积词或纯文本积词的行数
- **⏮ 上一首**：切到上一首
- **⏸ 暂停 / ▶ 播放**：播放暂停切换
- **⏭ 下一首**：切到下一首
- **🔄 重新获取积词**：手动刷新当前积词
- **🚪 退出**：退出 App

---

## 🧱 目录结构

```
LyricFloat/
├── Sources/
│   ├── main.swift          # 入口（NSApplication + AppDelegate）
│   ├── AppDelegate.swift   # 菜单栏 UI、定时轮询、播放控制、渲染
│   ├── NowPlaying.swift    # AppleScript 读取播放状态与内置积词
│   ├── LyricsFetcher.swift # 积词源调度（内置 → QQ 在线）
│   ├── LRC.swift           # LRC 时间轴解析器
│   └── QQMusic.swift       # QQ 音乐在线搜索与积词接口
├── tools/
│   └── makeicon.swift      # 图标生成工具（CoreGraphics 绘制音符）
├── Info.plist              # Bundle 配置（LSUIElement 等）
├── build.sh                # 一键编译 → .app → 签名 → .dmg
└── README.md
```

---

## 🔧 从源码构建

需要 macOS 12+ 与 **Command Line Tools**（`xcode-select --install`）。

```bash
cd LyricFloat
bash build.sh
```

输出 `LyricFloat-1.0.0.dmg`，可直接拖拽安装。

---

## 🔮 积词来源说明

1. **「音乐」App 内置积词**：通过 AppleScript `lyrics of current track` 读取，无需网络。
2. **QQ 音乐在线积词**：当内置积词为空时，根据曲名 + 歌手搜索 QQ 音乐正版曲目，再拉取 LRC 积词。

---

## ⚠️ 已知限制

- 读取「音乐」App 需要首次手动授予自动化权限。
- 这是 **ad-hoc 本地签名** 版本，非 App Store / 公证发行；换机器被 Gatekeeper 拦截时请「右键 → 打开」。
- 在线积词依赖网络，QQ 音乐接口偶发限流会提示「在线积词未找到」。

---

## 📝 License

MIT
