import Foundation

struct LyricLine: Equatable {
    let time: TimeInterval
    let text: String
}

enum LRC {
    static func parse(_ raw: String) -> [LyricLine] {
        var lines: [LyricLine] = []
        let pattern = #"\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        for rawLine in raw.components(separatedBy: .newlines) {
            let nsLine = rawLine as NSString
            let matches = regex.matches(in: rawLine, range: NSRange(location: 0, length: nsLine.length))
            guard !matches.isEmpty else { continue }
            let last = matches.last!
            let textStart = last.range.location + last.range.length
            let text = nsLine.substring(from: textStart).trimmingCharacters(in: .whitespacesAndNewlines)
            for m in matches {
                let mm = Double(nsLine.substring(with: m.range(at: 1))) ?? 0
                let ss = Double(nsLine.substring(with: m.range(at: 2))) ?? 0
                var frac: Double = 0
                let fracRange = m.range(at: 3)
                if fracRange.location != NSNotFound, fracRange.length > 0 {
                    let f = nsLine.substring(with: fracRange)
                    if let fv = Double(f) { frac = fv / pow(10, Double(f.count)) }
                }
                lines.append(LyricLine(time: mm * 60 + ss + frac, text: text))
            }
        }
        lines.sort { $0.time < $1.time }
        return lines
    }

    static func index(for lines: [LyricLine], at position: TimeInterval) -> Int {
        guard !lines.isEmpty else { return 0 }
        var lo = 0, hi = lines.count - 1, ans = 0
        while lo <= hi {
            let mid = (lo + hi) / 2
            if lines[mid].time <= position { ans = mid; lo = mid + 1 }
            else { hi = mid - 1 }
        }
        return ans
    }
}
