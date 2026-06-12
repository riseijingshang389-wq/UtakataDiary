import Foundation
import WidgetKit

struct LatestTankaWidgetData: Identifiable, Codable, Equatable {
    let id: String
    let tanka: String
    let date: Date

    static let sample = LatestTankaWidgetData(
        id: "sample",
        tanka: "雨あがる\n駅前の光\nまだ淡く\nもう少しだけ\n遠回りする",
        date: Date()
    )
}

enum LatestTankaWidgetStore {
    static let appGroupIdentifier = "group.com.risei.utakatadiary"
    static let widgetKind = "UtakataTankaWidget"

    private static let latestTankaKey = "latestTankaWidgetData"
    private static let allTankaKey = "allTankaWidgetData"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }

    static func save(date: Date, upperPhrase: [String], lowerPhrase: String) {
        let lines = Array(upperPhrase.prefix(3)) + lowerPhrase.tankaWidgetLowerLines()
        let tanka = lines.joined(separator: "\n")
        let data = LatestTankaWidgetData(
            id: stableID(date: date, tanka: tanka),
            tanka: tanka,
            date: date
        )
        save(data)
    }

    static func save(_ data: LatestTankaWidgetData) {
        var all = loadAll()
        all.removeAll { $0.id == data.id }
        all.insert(data, at: 0)
        saveAll(all, reload: false)

        guard let encoded = try? JSONEncoder().encode(data) else { return }
        defaults.set(encoded, forKey: latestTankaKey)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }

    static func load() -> LatestTankaWidgetData? {
        guard
            let encoded = defaults.data(forKey: latestTankaKey),
            let data = try? JSONDecoder().decode(LatestTankaWidgetData.self, from: encoded)
        else {
            return nil
        }
        return data
    }

    static func saveAll(_ data: [LatestTankaWidgetData], reload: Bool = true) {
        let sorted = data.sorted { $0.date > $1.date }
        guard let encoded = try? JSONEncoder().encode(sorted) else { return }
        defaults.set(encoded, forKey: allTankaKey)

        if let latest = sorted.first, let latestEncoded = try? JSONEncoder().encode(latest) {
            defaults.set(latestEncoded, forKey: latestTankaKey)
        }

        if reload {
            WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
        }
    }

    static func loadAll() -> [LatestTankaWidgetData] {
        guard
            let encoded = defaults.data(forKey: allTankaKey),
            let data = try? JSONDecoder().decode([LatestTankaWidgetData].self, from: encoded),
            !data.isEmpty
        else {
            return load().map { [$0] } ?? []
        }
        return data
    }

    static func memoryMoment(count: Int, now: Date = Date()) -> [LatestTankaWidgetData] {
        let all = loadAll()
        guard !all.isEmpty else { return [.sample] }

        let calendar = Calendar.current
        let anniversary = all.filter { data in
            let dataComponents = calendar.dateComponents([.month, .day, .year], from: data.date)
            let nowComponents = calendar.dateComponents([.month, .day, .year], from: now)
            guard
                dataComponents.month == nowComponents.month,
                dataComponents.day == nowComponents.day,
                let dataYear = dataComponents.year,
                let nowYear = nowComponents.year
            else {
                return false
            }
            return dataYear < nowYear
        }

        let pool = anniversary.isEmpty ? all : anniversary
        let seedSource = "\(Int(now.timeIntervalSince1970 / 1800))-\(pool.map(\.id).joined())"
        let seed = stableSeed(seedSource)
        return Array(shuffled(pool, seed: seed).prefix(max(count, 1)))
    }

    static func yearsAgoText(for date: Date, now: Date = Date()) -> String {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let nowComponents = calendar.dateComponents([.year, .month, .day], from: now)

        if
            dateComponents.month == nowComponents.month,
            dateComponents.day == nowComponents.day,
            let dateYear = dateComponents.year,
            let nowYear = nowComponents.year,
            nowYear > dateYear
        {
            return "\(nowYear - dateYear)年前の今日"
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }

    private static func stableID(date: Date, tanka: String) -> String {
        "\(Int(date.timeIntervalSince1970 * 1000))-\(abs(stableSeed(tanka)))"
    }

    private static func shuffled(_ data: [LatestTankaWidgetData], seed: Int) -> [LatestTankaWidgetData] {
        data.enumerated()
            .map { index, value in
                (value, abs(seed &+ index &* 1103515245) % 1_000_003)
            }
            .sorted { $0.1 < $1.1 }
            .map(\.0)
    }

    private static func stableSeed(_ text: String) -> Int {
        text.unicodeScalars.reduce(5381) { partial, scalar in
            ((partial << 5) &+ partial) &+ Int(scalar.value)
        }
    }
}

extension String {
    func tankaWidgetLowerLines() -> [String] {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.contains("\n") {
            return trimmed
                .split(separator: "\n", omittingEmptySubsequences: true)
                .map(String.init)
                .prefix(2)
                .map { $0 }
        }

        if trimmed.contains(" ") || trimmed.contains("　") {
            return trimmed
                .split { $0 == " " || $0 == "　" }
                .map(String.init)
                .prefix(2)
                .map { $0 }
        }

        guard !trimmed.isEmpty else { return [] }
        let midpoint = max(1, trimmed.count / 2)
        let splitIndex = trimmed.index(trimmed.startIndex, offsetBy: midpoint)
        return [String(trimmed[..<splitIndex]), String(trimmed[splitIndex...])]
    }
}
