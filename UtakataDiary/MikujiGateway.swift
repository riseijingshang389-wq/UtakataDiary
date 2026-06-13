import Foundation

@MainActor
final class MikujiGateway: ObservableObject {
    static let shared = MikujiGateway()

    private let calendar: Calendar
    private let defaults: UserDefaults

    @Published private(set) var canDraw = false
    @Published private(set) var isDrawnToday = false
    @Published private(set) var streakCount = 0

    private enum Key {
        static let lastDiaryDate = "lastDiaryCreatedAt"
        static let lastMikujiDate = "lastMikujiDrawnAt"
    }

    init(
        calendar: Calendar = .current,
        defaults: UserDefaults = .standard
    ) {
        self.calendar = calendar
        self.defaults = defaults
    }

    func refresh(cards: [DiaryCard], now: Date = Date()) {
        isDrawnToday = hasDrawnToday(now: now)
        canDraw = canDrawMikuji(now: now)
        streakCount = continuousDiaryStreak(from: cards, now: now)
    }

    func markDiaryWritten(_ date: Date) {
        defaults.set(date.timeIntervalSince1970, forKey: Key.lastDiaryDate)
        isDrawnToday = hasDrawnToday()
        canDraw = canDrawMikuji()
    }

    func markMikujiDrawn(now: Date = Date()) {
        defaults.set(calendar.startOfDay(for: now).timeIntervalSince1970, forKey: Key.lastMikujiDate)
        isDrawnToday = true
        canDraw = canDrawMikuji(now: now)
    }

    func canDrawMikuji(now: Date = Date()) -> Bool {
        let today = calendar.startOfDay(for: now)
        let fiveAM = calendar.date(bySettingHour: 5, minute: 0, second: 0, of: today) ?? today

        guard now >= fiveAM else { return false }
        guard let lastDiaryDay = storedDay(for: Key.lastDiaryDate) else { return false }
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return false }

        let hasWrittenYesterday = lastDiaryDay == yesterday
        let hasNotDrawnToday = storedDay(for: Key.lastMikujiDate) != today

        return hasWrittenYesterday && hasNotDrawnToday
    }

    func hasDrawnToday(now: Date = Date()) -> Bool {
        storedDay(for: Key.lastMikujiDate) == calendar.startOfDay(for: now)
    }

    private func storedDay(for key: String) -> Date? {
        let interval = defaults.double(forKey: key)
        guard interval > 0 else { return nil }
        return calendar.startOfDay(for: Date(timeIntervalSince1970: interval))
    }

    private func continuousDiaryStreak(from cards: [DiaryCard], now: Date) -> Int {
        let diaryDays = Set(cards.map { calendar.startOfDay(for: $0.date) })
        guard !diaryDays.isEmpty else { return 0 }

        let today = calendar.startOfDay(for: now)
        var cursor = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        var streak = 0

        while diaryDays.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }

        return streak
    }
}
