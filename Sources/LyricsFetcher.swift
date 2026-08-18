import Foundation

enum LyricsResult: Equatable {
    case timed([LyricLine])
    case plain(String)
    case none
}

enum LyricsFetcher {
    static func fetch(info: NowPlayingInfo, completion: @escaping (LyricsResult, String) -> Void) {
        // 1. Music 内置积词（AppleScript 同步调用，无网络开销）
        let builtin = MusicQuery.builtinLyrics()
        if let error = builtin.error, error.contains("not allowed") || error.contains("1743") {
            completion(.none, "权限未授权：请在 系统设置 → 隐私与安全性 → 自动化 中允许本 App 控制「音乐」")
            return
        }
        if let lyrics = builtin.lyrics, !lyrics.isEmpty {
            let lines = LRC.parse(lyrics)
            if !lines.isEmpty {
                completion(.timed(lines), "Music 内置积词")
            } else {
                completion(.plain(lyrics), "Music 内置积词（无时间轴）")
            }
            return
        }

        // 2. 在线积词回退
        guard info.isValid else {
            completion(.none, "请在「音乐」App 中开始播放")
            return
        }

        QQMusic.search(song: info.title, artist: info.artist) { mid in
            guard let mid = mid else {
                completion(.none, "在线积词未找到: \(info.title)")
                return
            }
            QQMusic.fetchLyric(songMid: mid) { lrc in
                guard let lrc = lrc else {
                    completion(.none, "在线积词未找到: \(info.title)")
                    return
                }
                let lines = LRC.parse(lrc)
                if !lines.isEmpty {
                    completion(.timed(lines), "QQ 音乐积词")
                } else {
                    completion(.plain(lrc), "QQ 音乐积词（无时间轴）")
                }
            }
        }
    }
}
