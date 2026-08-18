import Foundation

// 基于 QQ 音乐的在线积词源：先搜索拿到正版 songmid，再拉取 LRC 积词。
enum QQMusic {
    static func search(song: String, artist: String, completion: @escaping (String?) -> Void) {
        let query = ([song, artist].filter { !$0.isEmpty }).joined(separator: " ")
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://c.y.qq.com/soso/fcgi-bin/client_search_cp?format=json&p=1&n=10&w=\(encoded)") else {
            completion(nil); return
        }
        var req = URLRequest(url: url)
        req.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        req.setValue("https://y.qq.com", forHTTPHeaderField: "Referer")
        req.timeoutInterval = 15

        URLSession.shared.dataTask(with: req) { data, _, error in
            guard let data = data, error == nil,
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let dataObj = obj["data"] as? [String: Any],
                  let songObj = dataObj["song"] as? [String: Any],
                  let list = songObj["list"] as? [[String: Any]] else {
                completion(nil); return
            }
            let songL = song.lowercased()
            let artistL = artist.lowercased()
            var best: (score: Int, mid: String)? = nil
            for item in list {
                guard let mid = item["songmid"] as? String else { continue }
                let name = (item["songname"] as? String) ?? ""
                let nameL = name.lowercased()
                var score = 0
                if nameL == songL { score += 100 }
                else if nameL.contains(songL) || songL.contains(nameL) { score += 50 }
                if let singers = item["singer"] as? [[String: Any]] {
                    let names = singers.compactMap { $0["name"] as? String }.map { $0.lowercased() }
                    if names.contains(artistL) { score += 30 }
                    else if names.contains(where: { artistL.contains($0) || $0.contains(artistL) }) { score += 15 }
                }
                if score > (best?.score ?? -1) { best = (score, mid) }
            }
            completion(best?.mid)
        }.resume()
    }

    static func fetchLyric(songMid: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "https://c.y.qq.com/lyric/fcgi-bin/fcg_query_lyric_new.fcg?songmid=\(songMid)&format=json&nobase64=1") else {
            completion(nil); return
        }
        var req = URLRequest(url: url)
        req.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        req.setValue("https://y.qq.com/portal/player.html", forHTTPHeaderField: "Referer")
        req.timeoutInterval = 15

        URLSession.shared.dataTask(with: req) { data, _, error in
            guard let data = data, error == nil,
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let ret = obj["retcode"] as? Int, ret == 0,
                  let lyric = obj["lyric"] as? String, !lyric.isEmpty else {
                completion(nil); return
            }
            completion(lyric)
        }.resume()
    }
}
