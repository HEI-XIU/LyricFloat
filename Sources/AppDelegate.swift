import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem?
    private var pollTimer: Timer?
    private var renderTimer: Timer?

    private var lastTrackKey = ""
    private var lastPosition: TimeInterval = 0
    private var lastPositionTime = Date()
    private var isPlaying = false
    private var lyricsResult: LyricsResult = LyricsResult.none
    private var currentTitle = ""
    private var currentArtist = ""
    private var lyricsSource = ""
    private var currentDuration: TimeInterval = 0
    private var currentError = ""

    // 乐观更新标记：用户点击了播放/暂停但 AppleScript 尚未返回
    private var optimisticToggle = false

    // 缓存上次标题栏文字，避免冗余刷新
    private var lastStatusBarText = ""

    // 上次 AppleScript 完整结果，用于检测真实变化
    private var lastRawInfo: NowPlayingInfo?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        startTimers()
        pollNow()
    }

    // MARK: - 菜单栏

    private func setupMenuBar() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.title = "♪ 积词加载中…"
            button.toolTip = "LyricFloat"
        }
        let menu = NSMenu()
        menu.delegate = self

        // 歌曲信息
        let songItem = NSMenuItem(title: "未在播放", action: nil, keyEquivalent: "")
        songItem.isEnabled = false; songItem.tag = 100
        menu.addItem(songItem)

        // 播放状态
        let stateItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        stateItem.isEnabled = false; stateItem.tag = 102
        menu.addItem(stateItem)

        // 播放进度
        let progressItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        progressItem.isEnabled = false; progressItem.tag = 103
        menu.addItem(progressItem)

        // 积词来源
        let sourceItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        sourceItem.isEnabled = false; sourceItem.tag = 101
        menu.addItem(sourceItem)

        // 积词行数
        let lyricCountItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        lyricCountItem.isEnabled = false; lyricCountItem.tag = 104
        menu.addItem(lyricCountItem)

        menu.addItem(NSMenuItem.separator())

        // 播放控制
        let prevItem = NSMenuItem(title: "⏮ 上一首", action: #selector(previousTrack), keyEquivalent: "")
        prevItem.tag = 200
        menu.addItem(prevItem)

        let playPauseItem = NSMenuItem(title: "⏸ 暂停", action: #selector(togglePlayPause), keyEquivalent: " ")
        playPauseItem.tag = 201
        menu.addItem(playPauseItem)

        let nextItem = NSMenuItem(title: "⏭ 下一首", action: #selector(nextTrack), keyEquivalent: "")
        nextItem.tag = 202
        menu.addItem(nextItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "🔄 重新获取积词", action: #selector(refreshLyrics), keyEquivalent: "r"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "🚪 退出", action: #selector(quitApp), keyEquivalent: "q"))
        item.menu = menu
        statusItem = item
    }

    // MARK: - NSMenuDelegate — 菜单即将打开时刷新最新状态
    func menuWillOpen(_ menu: NSMenu) {
        updateMenuStatus()
    }

    private func updateMenuStatus() {
        guard let menu = statusItem?.menu else { return }
        let hasTrack = !currentTitle.isEmpty

        // 歌曲信息
        menu.item(withTag: 100)?.title = hasTrack ? "🎵 \(currentTitle) — \(currentArtist)" : "⏹ 未在播放"

        // 播放状态
        menu.item(withTag: 102)?.title = hasTrack ? (isPlaying ? "▶ 播放中" : "⏸ 已暂停") : ""

        // 播放进度
        if let pi = menu.item(withTag: 103) {
            if hasTrack && currentDuration > 0 {
                let pos = currentInterpolatedPosition()
                let cur = formatTime(pos)
                let tot = formatTime(currentDuration)
                let pct = min(Int((pos / currentDuration) * 100), 100)
                pi.title = "⏱ \(cur) / \(tot) (\(pct)%)"
            } else if hasTrack {
                pi.title = "⏱ \(formatTime(currentInterpolatedPosition()))"
            } else {
                pi.title = ""
            }
        }

        // 积词来源
        if let si = menu.item(withTag: 101) {
            if !currentError.isEmpty { si.title = "⚠️ \(currentError)" }
            else if lyricsSource.isEmpty { si.title = "⏳ 等待积词…" }
            else { si.title = "📝 来源：\(lyricsSource)" }
        }

        // 积词行数
        if let lc = menu.item(withTag: 104) {
            switch lyricsResult {
            case .timed(let lines): lc.title = "📄 时间轴积词 \(lines.count) 行"
            case .plain(let t):
                let cnt = t.components(separatedBy: .newlines).filter { !$0.isEmpty }.count
                lc.title = "📄 纯文本积词 \(cnt) 行"
            case .none: lc.title = hasTrack ? "📄 暂无积词" : ""
            }
        }

        // 播放/暂停按钮
        if let pp = menu.item(withTag: 201) {
            pp.title = hasTrack ? (isPlaying ? "⏸ 暂停" : "▶ 播放") : "▶ 播放"
        }

        // 控制按钮启用
        menu.item(withTag: 200)?.isEnabled = hasTrack
        menu.item(withTag: 201)?.isEnabled = hasTrack
        menu.item(withTag: 202)?.isEnabled = hasTrack
    }

    // MARK: - 定时器（自适应频率）

    private func startTimers() {
        // 播放时 2s 轮询，暂停时 5s — 减少 AppleScript 进程开销
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.pollNow()
        }
        // 位置插值 5fps（0.2s），比 30fps 节省 83% 的刷新调用
        renderTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.renderTick()
        }
    }

    private func adjustPollInterval() {
        pollTimer?.invalidate()
        let interval: TimeInterval = isPlaying ? 2.0 : 5.0
        pollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.pollNow()
        }
    }

    // MARK: - 轮询

    @objc private func pollNow() {
        let (info, error) = MusicQuery.nowPlayingInfo()

        // 错误 — 仅当状态变化时更新
        if let error = error {
            guard lastRawInfo != nil || currentError != error else { return }
            currentTitle = ""; currentArtist = ""; currentDuration = 0
            currentError = error; lyricsSource = ""
            lastRawInfo = nil
            updateMenuStatus()
            updateStatusBarTitle()
            return
        }

        // 无播放 — 仅当状态变化时更新
        guard info.isValid else {
            guard lastRawInfo != nil else { return }
            currentTitle = ""; currentArtist = ""; currentDuration = 0
            currentError = ""; lyricsSource = ""
            lastRawInfo = nil
            lyricsResult = .none
            updateMenuStatus()
            updateStatusBarTitle()
            return
        }

        let stateChanged = lastRawInfo?.state != info.state
        let trackChanged = info.trackKey != lastTrackKey

        // 始终同步位置（防止 render 漂移）
        lastPosition = info.position
        lastPositionTime = Date()
        optimisticToggle = false

        // 既没切歌也没切状态 → 只更新标题栏位置
        if !trackChanged && !stateChanged && lastRawInfo != nil {
            updateStatusBarTitle()
            return
        }

        // 同步真实状态
        isPlaying = info.isPlaying
        currentTitle = info.title
        currentArtist = info.artist
        currentDuration = info.duration
        currentError = ""
        lastRawInfo = info

        adjustPollInterval()

        if trackChanged {
            lastTrackKey = info.trackKey
            lyricsResult = .none
            lyricsSource = "正在获取积词…"
            updateMenuStatus()
            updateStatusBarTitle()
            fetchLyrics(info: info)
        } else {
            updateMenuStatus()
            updateStatusBarTitle()
        }
    }

    private func fetchLyrics(info: NowPlayingInfo) {
        LyricsFetcher.fetch(info: info) { [weak self] result, source in
            DispatchQueue.main.async {
                guard let self = self, self.lastTrackKey == info.trackKey else { return }
                self.lyricsResult = result
                self.lyricsSource = source
                self.updateMenuStatus()
                self.updateStatusBarTitle()
            }
        }
    }

    // MARK: - 渲染

    private func renderTick() {
        guard isPlaying else { return }
        lastPosition += Date().timeIntervalSince(lastPositionTime)
        lastPositionTime = Date()
        updateStatusBarTitle()
    }

    private func currentInterpolatedPosition() -> TimeInterval {
        guard isPlaying else { return lastPosition }
        return lastPosition + Date().timeIntervalSince(lastPositionTime)
    }

    private func updateStatusBarTitle() {
        guard let button = statusItem?.button else { return }
        var text = "♪"
        let pos = currentInterpolatedPosition()
        switch lyricsResult {
        case .timed(let lines):
            if !lines.isEmpty {
                let idx = LRC.index(for: lines, at: pos)
                let line = lines[idx].text
                text = line.count > 22 ? "♪ " + String(line.prefix(22)) + "…" : "♪ " + line
            } else {
                text = "♪ 无积词"
            }
        case .plain(let t):
            let line = t.components(separatedBy: .newlines).first ?? ""
            let short = line.count > 20 ? String(line.prefix(20)) + "…" : line
            text = "♪ " + short
        case .none:
            text = currentTitle.isEmpty ? "♪" : "♪ 等待积词…"
        }
        // 避免重复设置相同文字（减少 AppKit 内部布局计算）
        guard text != lastStatusBarText else { return }
        lastStatusBarText = text
        button.title = text
        button.needsDisplay = true
    }

    // MARK: - 播放控制（乐观更新 — 立即响应）

    @objc private func togglePlayPause() {
        optimisticToggle = true
        isPlaying.toggle()
        lastPositionTime = Date()
        updateMenuStatus()
        updateStatusBarTitle()
        MusicQuery.playPause()
        // 延迟同步真实状态
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.pollNow()
        }
    }

    @objc private func nextTrack() {
        MusicQuery.nextTrack()
        lastTrackKey = ""
        lyricsResult = .none
        lyricsSource = "正在切换…"
        currentError = ""
        updateMenuStatus()
        updateStatusBarTitle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.pollNow()
        }
    }

    @objc private func previousTrack() {
        MusicQuery.previousTrack()
        lastTrackKey = ""
        lyricsResult = .none
        lyricsSource = "正在切换…"
        currentError = ""
        updateMenuStatus()
        updateStatusBarTitle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.pollNow()
        }
    }

    @objc private func refreshLyrics() {
        lastTrackKey = ""
        pollNow()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    private func formatTime(_ t: TimeInterval) -> String {
        guard t >= 0, !t.isNaN, !t.isInfinite else { return "00:00" }
        let m = Int(t) / 60; let s = Int(t) % 60
        return String(format: "%02d:%02d", m, s)
    }
}
