import Foundation

struct NowPlayingInfo {
    var title = ""
    var artist = ""
    var album = ""
    var duration: TimeInterval = 0
    var position: TimeInterval = 0
    var state = ""
    var isPlaying: Bool { state == "playing" }
    var isValid: Bool { !title.isEmpty }
    var trackKey: String { title + "\u{1F}" + artist }
}

enum AppleScript {
    static func run(_ script: String) -> (output: String?, error: String?) {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        p.arguments = ["-e", script]
        let out = Pipe()
        let err = Pipe()
        p.standardOutput = out
        p.standardError = err
        do { try p.run() } catch { return (nil, "启动失败: \(error.localizedDescription)") }
        p.waitUntilExit()
        let outData = out.fileHandleForReading.readDataToEndOfFile()
        let errData = err.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let errorText = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        if p.terminationStatus != 0 {
            return (nil, errorText?.isEmpty == false ? errorText : "osascript 退出码 \(p.terminationStatus)")
        }
        return (output, nil)
    }
}

enum MusicQuery {
    static func nowPlayingInfo() -> (info: NowPlayingInfo, error: String?) {
        let script = """
        tell application "Music"
            try
                set t to current track
                set trackName to name of t
                set artistName to artist of t
                set albumName to album of t
                set trackDuration to duration of t
                if trackDuration is missing value then set trackDuration to 0
                set pos to player position
                set playState to (player state as string)
                return trackName & tab & artistName & tab & albumName & tab & (trackDuration as string) & tab & (pos as string) & tab & playState
            on error
                return "__ERROR__"
            end try
        end tell
        """
        let (output, error) = AppleScript.run(script)
        if let error = error { return (NowPlayingInfo(), error) }
        guard let output = output, output != "__ERROR__" else {
            return (NowPlayingInfo(), "无法读取当前播放状态")
        }
        let parts = output.components(separatedBy: "\t")
        guard parts.count >= 6 else { return (NowPlayingInfo(), "解析失败: \(output)") }
        var info = NowPlayingInfo()
        info.title = parts[0]
        info.artist = parts[1]
        info.album = parts[2]
        info.duration = TimeInterval(parts[3]) ?? 0
        info.position = TimeInterval(parts[4]) ?? 0
        info.state = parts[5]
        return (info, nil)
    }

    static func builtinLyrics() -> (lyrics: String?, error: String?) {
        let script = """
        tell application "Music"
            try
                set t to current track
                set l to lyrics of t
                if l is missing value then return ""
                return l
            on error
                return "__ERROR__"
            end try
        end tell
        """
        let (output, error) = AppleScript.run(script)
        if let error = error { return (nil, error) }
        guard let output = output, output != "__ERROR__" else { return (nil, "读取内置积词失败") }
        return (output.isEmpty ? nil : output, nil)
    }

    // MARK: - 播放控制

    /// 播放 / 暂停切换
    @discardableResult
    static func playPause() -> String? {
        let script = """
        tell application "Music"
            playpause
        end tell
        """
        return AppleScript.run(script).error
    }

    /// 下一首
    @discardableResult
    static func nextTrack() -> String? {
        let script = """
        tell application "Music"
            next track
        end tell
        """
        return AppleScript.run(script).error
    }

    /// 上一首
    @discardableResult
    static func previousTrack() -> String? {
        let script = """
        tell application "Music"
            previous track
        end tell
        """
        return AppleScript.run(script).error
    }
}
