# 🎵 LyricFloat

> macOS 菜单栏歌词工具 — 实时显示「音乐」App 当前播放歌曲的歌词

[![Release](https://img.shields.io/badge/Release-v1.0.0-blue?style=flat-square)](https://github.com/HEI-XIU/LyricFloat/releases/tag/v1.0.0)
[![Platform](https://img.shields.io/badge/Platform-macOS%2012%2B-lightgrey?style=flat-square)](https://github.com/HEI-XIU/LyricFloat)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](https://github.com/HEI-XIU/LyricFloat)

macOS 自带的「音乐」App 没有菜单栏歌词。LyricFloat 通过 AppleScript 读取当前播放曲目，将歌词「卡拉 OK」式地同步显示在系统菜单栏，并支持播放控制。

---

## 📥 下载安装

[![Download](https://img.shields.io/badge/Download-LyricFloat%20v1.0.0-blue?style=for-the-badge&logo=apple)](https://github.com/HEI-XIU/LyricFloat/releases/download/v1.0.0/LyricFloat-1.0.0.dmg)

1. 点击上方按钮或前往 [Releases 页面](https://github.com/HEI-XIU/LyricFloat/releases) 下载 `LyricFloat-1.0.0.dmg`
2. 双击打开 DMG，将 `LyricFloat.app` 拖拽到 `Applications` 文件夹
3. 首次打开时，右键 `LyricFloat.app` → 选择「打开」（绕过 Gatekeeper 提示）
4. 在「音乐」App 中播放歌曲，菜单栏即出现 ♪ 图标并显示歌词

> ⚠️ **首次使用需要授权自动化权限**：前往 **系统设置 → 隐私与安全性 → 自动化**，勾选允许 `LyricFloat` 控制 `音乐`。未授权时会提示「权限未授权」。

---

## ✨ 功能特性

| 功能 | 说明 |
|------|------|
| 🎤 **菜单栏实时歌词** | 当前句歌词滚动显示在菜单栏 ♪ 图标上 |
| 📚 **歌词来源自动切换** | 优先读取「音乐」App 内置歌词，读取不到时自动从 QQ 音乐在线获取 |
| ⏯️ **播放控制** | 右击菜单可直接控制上一首 / 播放暂停 / 下一首 |
| 📊 **状态信息** | 右击菜单显示歌曲名、播放状态、播放进度（含百分比）、歌词来源与行数 |
| ⚡ **低资源占用** | 播放时 2s 轮询、暂停时 5s 轮询，渲染仅 5fps，节省 CPU / 内存 |
| 🎨 **应用图标** | 自带音符图标，可在 Dock / Finder 中识别 |

---

## 🖱️ 使用说明

点击菜单栏 ♪ 图标，**右击** 查看功能菜单：

| 菜单项 | 说明 |
|--------|------|
| 🎵 歌曲名 — 歌手 | 当前播放的曲目信息 |
| ▶ 播放中 / ⏸ 已暂停 | 实时播放状态 |
| ⏱ 播放进度 | 已播放 / 总时长 (百分比) |
| 📝 歌词来源 | Music 内置歌词 / QQ 音乐歌词 / 权限错误提示 |
| 📄 歌词行数 | 时间轴歌词或纯文本歌词的行数 |
| ⏮ 上一首 | 切换到上一首 |
| ⏸ 暂停 / ▶ 播放 | 播放 / 暂停切换 |
| ⏭ 下一首 | 切换到下一首 |
| 🔄 重新获取歌词 | 手动刷新当前歌词 |
| 🚪 退出 | 退出应用 |

---

## 🧱 项目结构

```
LyricFloat/
├── Sources/
│   ├── main.swift          # 入口（NSApplication + AppDelegate）
│   ├── AppDelegate.swift   # 菜单栏 UI、定时轮询、播放控制、渲染
│   ├── NowPlaying.swift    # AppleScript 读取播放状态与内置歌词
│   ├── LyricsFetcher.swift # 歌词源调度（内置 → QQ 在线）
│   ├── LRC.swift           # LRC 时间轴解析器
│   └── QQMusic.swift       # QQ 音乐在线搜索与歌词接口
├── tools/
│   └── makeicon.swift      # 图标生成工具（CoreGraphics 绘制音符）
├── Info.plist              # Bundle 配置（LSUIElement 等）
├── build.sh                # 一键编译 → .app → 签名 → .dmg
└── README.md
```

---

## 🔧 从源码构建

需要 macOS 12+ 与 **Xcode Command Line Tools**：

```bash
# 安装 Command Line Tools（如未安装）
xcode-select --install

# 构建
cd LyricFloat
bash build.sh
```

构建完成后输出 `LyricFloat-1.0.0.dmg`，可直接拖拽安装。

---

## 🔮 歌词来源

1. **「音乐」App 内置歌词**：通过 AppleScript `lyrics of current track` 读取，无需网络，优先使用
2. **QQ 音乐在线歌词**：当内置歌词为空时，根据曲名 + 歌手搜索 QQ 音乐曲目，拉取 LRC 歌词

---

## ⚠️ 已知限制

- 读取「音乐」App 需要首次手动授予自动化权限
- Ad-hoc 本地签名版本，非 App Store / 公证发行；被 Gatekeeper 拦截时请「右键 → 打开」
- 在线歌词依赖网络，QQ 音乐接口偶发限流会提示「在线歌词未找到」

---

## 📝 License

MIT © HEI-XIU
