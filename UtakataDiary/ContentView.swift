import SwiftUI
import PhotosUI
import CoreImage
import UIKit
import ImageIO
import CloudKit

struct DiaryCard: Identifiable, Hashable, Codable {
    let id: UUID
    let date: Date
    let upperPhrase: [String]
    let lowerPhrase: String
    let mood: CardMood
    let placeHint: String
    let photoData: Data?

    init(
        id: UUID = UUID(),
        date: Date,
        upperPhrase: [String],
        lowerPhrase: String,
        mood: CardMood,
        placeHint: String,
        photoData: Data?
    ) {
        self.id = id
        self.date = date
        self.upperPhrase = upperPhrase
        self.lowerPhrase = lowerPhrase
        self.mood = mood
        self.placeHint = placeHint
        self.photoData = photoData
    }
}

enum CardMood: String, CaseIterable, Hashable, Codable {
    case dawn, rain, evening, night

    var gradient: [Color] {
        switch self {
        case .dawn:
            return [Color.retroPaper, Color(hex: 0xF3D6B8), Color(hex: 0xD9C0D7)]
        case .rain:
            return [Color.retroPaper, Color(hex: 0xD7DDC7), Color(hex: 0xB8CAD0)]
        case .evening:
            return [Color(hex: 0xF4DFC1), Color(hex: 0xD98273), Color(hex: 0x334F65)]
        case .night:
            return [Color(hex: 0xEFE5D4), Color(hex: 0x9B91B8), Color(hex: 0x263E56)]
        }
    }

    var accent: Color {
        switch self {
        case .dawn: return Color.retroRose
        case .rain: return Color.retroSage
        case .evening: return Color.meijiRed
        case .night: return Color.meijiBlue
        }
    }
}

enum AppTab: String, CaseIterable {
    case today = "日記"
    case dummy = "作成"
    case memory = "思い出"

    var systemImage: String {
        switch self {
        case .today: return "house.fill"
        case .dummy: return "plus"
        case .memory: return "books.vertical.fill"
        }
    }

    var tabTitle: String {
        switch self {
        case .today: return "ホーム"
        case .dummy: return ""
        case .memory: return "思い出"
        }
    }
}

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var selectedTab: AppTab = .today
    @State private var savedCards: [DiaryCard] = DiaryCard.samples

    var body: some View {
        ZStack {
            if hasSeenOnboarding {
                MainTabView(selectedTab: $selectedTab, savedCards: $savedCards)
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                OnboardingView {
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.9)) {
                        hasSeenOnboarding = true
                    }
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            NotificationManager.refreshDailyReminderIfNeeded()
        }
    }
}

struct OnboardingView: View {
    let onStart: () -> Void
    @State private var permissionStep = 0

    private let permissions = [
        ("写真", "今日の光や場所の気配から、上の句を浮かべます。", "photo.on.rectangle"),
        ("位置情報", "駅前、川沿い、家の近く。言葉にしない背景をそっと拾います。", "location"),
        ("音楽", "その日に聴いていた曲の余韻を、札の色に混ぜます。", "music.note")
    ]

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 30) {
                Spacer(minLength: 30)

                VStack(spacing: 14) {
                    Text("うたかた日記")
                        .font(.system(size: 40, weight: .semibold, design: .serif))
                        .foregroundStyle(Color.primaryText)

                    Text("写真と音楽から\n今日の上の句が浮かびます")
                        .font(.title3.weight(.medium))
                        .multilineTextAlignment(.center)
                        .lineSpacing(7)
                        .foregroundStyle(Color.secondaryText)
                }

                ZStack {
                    FloatingBubble(offset: CGSize(width: -90, height: -78), size: 76, opacity: 0.26)
                    FloatingBubble(offset: CGSize(width: 104, height: 70), size: 106, opacity: 0.2)

                    PoemCardView(
                        upperPhrase: ["朝の窓", "まだ名のない日", "ひかり満つ"],
                        lowerPhrase: "手のひらだけが 先に目覚める",
                        mood: .dawn,
                        compact: false,
                        photoData: nil,
                        heroPreview: true
                    )
                    .frame(width: 252, height: 392)
                    .rotationEffect(.degrees(-1.2))
                }
                .frame(height: 404)

                PermissionCard(
                    title: permissions[permissionStep].0,
                    message: permissions[permissionStep].1,
                    systemImage: permissions[permissionStep].2
                )

                Button {
                    if permissionStep < permissions.count - 1 {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                            permissionStep += 1
                        }
                    } else {
                        onStart()
                    }
                } label: {
                    Text(permissionStep == permissions.count - 1 ? "はじめる" : "次へ")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.utakataPrimary)

                Text("必要なものだけ、あとで変更できます")
                    .font(.footnote)
                    .foregroundStyle(Color.secondaryText.opacity(0.78))

                Spacer(minLength: 22)
            }
            .padding(.horizontal, 26)
        }
    }
}

struct MainTabView: View {
    @Binding var selectedTab: AppTab
    @Binding var savedCards: [DiaryCard]
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var mikujiGateway = MikujiGateway.shared
    @AppStorage("lastDiaryCreatedAt") private var lastDiaryCreatedAt = 0.0
    @AppStorage("utakataICloudSyncEnabled") private var iCloudSyncEnabled = false
    @State private var showingMorningOmikuji = false
    @State private var showingSettings = false
    @State private var showingComposer = false
    @State private var isCloudSyncing = false

    var body: some View {
        ZStack {
            AppBackground()

            TabView(selection: $selectedTab) {
                TodayView(
                    savedCards: $savedCards,
                    showsCreateButton: false,
                    canDrawMikuji: mikujiGateway.canDraw,
                    isMikujiDrawnToday: mikujiGateway.isDrawnToday,
                    mikujiStreak: mikujiGateway.streakCount,
                    onOpenSettings: openSettings,
                    onOpenMikuji: openMikuji
                ) { date in
                    lastDiaryCreatedAt = date.timeIntervalSince1970
                    mikujiGateway.markDiaryWritten(date)
                }
                .tabItem {
                    Label(AppTab.today.tabTitle, systemImage: AppTab.today.systemImage)
                }
                .tag(AppTab.today)
                
                Color.clear
                    .tabItem {
                        Label(AppTab.dummy.tabTitle, systemImage: AppTab.dummy.systemImage)
                    }
                    .tag(AppTab.dummy)
                
                MemoryView(
                    cards: savedCards,
                    showsCreateButton: false,
                    onOpenSettings: openSettings,
                    onCreateDiary: addDiaryCard
                )
                .tabItem {
                    Label(AppTab.memory.tabTitle, systemImage: AppTab.memory.systemImage)
                }
                .tag(AppTab.memory)
            }
            .tint(Color.meijiRed)
            .toolbarBackground(Color(hex: 0xFFF9F2).opacity(0.96), for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarColorScheme(.light, for: .tabBar)

        }
        .onAppear {
            mikujiGateway.refresh(cards: savedCards)
            refreshWidgetMemories()
            syncFromCloudIfNeeded(uploadLocalAfterFetch: false)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                mikujiGateway.refresh(cards: savedCards)
                refreshWidgetMemories()
                syncFromCloudIfNeeded(uploadLocalAfterFetch: false)
            }
        }
        .onChange(of: savedCards) { _, cards in
            mikujiGateway.refresh(cards: cards)
        }
        .onChange(of: selectedTab) { old, new in
            if new == .dummy {
                selectedTab = old
                showingComposer = true
            }
        }
        .onChange(of: iCloudSyncEnabled) { _, isEnabled in
            if isEnabled {
                syncFromCloudIfNeeded(uploadLocalAfterFetch: true)
            }
        }
        .fullScreenCover(isPresented: $showingMorningOmikuji) {
            MorningOmikujiDrawView {
                showingMorningOmikuji = false
            }
        }
        .sheet(isPresented: $showingSettings) {
            Setting()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingComposer) {
            DiaryComposerView { card in
                addDiaryCard(card)
                selectedTab = .today
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private func openSettings() {
        showingSettings = true
    }

    private func openMikuji() {
        guard mikujiGateway.canDraw else { return }
        mikujiGateway.markMikujiDrawn()
        showingMorningOmikuji = true
    }

    private func addDiaryCard(_ card: DiaryCard) {
        savedCards.insert(card, at: 0)
        refreshWidgetMemories()
        lastDiaryCreatedAt = card.date.timeIntervalSince1970
        mikujiGateway.markDiaryWritten(card.date)
        saveToCloudIfNeeded(card)
    }

    private func saveToCloudIfNeeded(_ card: DiaryCard) {
        guard iCloudSyncEnabled else { return }

        Task {
            do {
                try await DiaryCloudSyncManager.shared.save(card: card)
            } catch {
                print("iCloud sync save failed:", error.localizedDescription)
            }
        }
    }

    private func syncFromCloudIfNeeded(uploadLocalAfterFetch: Bool) {
        guard iCloudSyncEnabled, !isCloudSyncing else { return }
        isCloudSyncing = true

        Task {
            do {
                let cloudCards = try await DiaryCloudSyncManager.shared.fetchCards()
                await MainActor.run {
                    mergeCloudCards(cloudCards)
                }

                if uploadLocalAfterFetch {
                    let cardsToUpload = await MainActor.run { savedCards }
                    try await DiaryCloudSyncManager.shared.save(cards: cardsToUpload)
                }
            } catch {
                print("iCloud sync fetch failed:", error.localizedDescription)
            }

            await MainActor.run {
                isCloudSyncing = false
            }
        }
    }

    private func mergeCloudCards(_ cloudCards: [DiaryCard]) {
        guard !cloudCards.isEmpty else { return }

        var cardsByID = Dictionary(uniqueKeysWithValues: savedCards.map { ($0.id, $0) })
        for card in cloudCards {
            cardsByID[card.id] = card
        }

        savedCards = cardsByID.values.sorted { $0.date > $1.date }
        refreshWidgetMemories()
        mikujiGateway.refresh(cards: savedCards)
    }

    private func refreshWidgetMemories() {
        let widgetData = savedCards.map { card in
            LatestTankaWidgetData(
                id: card.id.uuidString,
                tanka: (Array(card.upperPhrase.prefix(3)) + card.lowerPhrase.tankaWidgetLowerLines()).joined(separator: "\n"),
                date: card.date
            )
        }
        LatestTankaWidgetStore.saveAll(widgetData)
    }
}

final class DiaryCloudSyncManager {
    static let shared = DiaryCloudSyncManager()

    private let database = CKContainer.default().privateCloudDatabase
    private let recordType = "DiaryCard"

    private enum Field {
        static let date = "date"
        static let upperPhraseData = "upperPhraseData"
        static let lowerPhrase = "lowerPhrase"
        static let mood = "mood"
        static let placeHint = "placeHint"
        static let photoAsset = "photoAsset"
        static let updatedAt = "updatedAt"
    }

    private init() {}

    func fetchCards() async throws -> [DiaryCard] {
        let status = try await CKContainer.default().accountStatus()
        guard status == .available else {
            throw DiaryCloudSyncError.iCloudUnavailable
        }

        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: Field.date, ascending: false)]

        return try await withCheckedThrowingContinuation { continuation in
            var fetchedRecords: [CKRecord] = []
            let operation = CKQueryOperation(query: query)
            operation.resultsLimit = 200
            operation.recordMatchedBlock = { _, result in
                if case .success(let record) = result {
                    fetchedRecords.append(record)
                }
            }
            operation.queryResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume(returning: fetchedRecords.compactMap(Self.card(from:)))
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }

            database.add(operation)
        }
    }

    func save(cards: [DiaryCard]) async throws {
        for card in cards {
            try await save(card: card)
        }
    }

    func save(card: DiaryCard) async throws {
        let status = try await CKContainer.default().accountStatus()
        guard status == .available else {
            throw DiaryCloudSyncError.iCloudUnavailable
        }

        let record = try Self.record(from: card, recordType: recordType)
        _ = try await database.save(record)
    }

    private static func record(from card: DiaryCard, recordType: String) throws -> CKRecord {
        let recordID = CKRecord.ID(recordName: card.id.uuidString)
        let record = CKRecord(recordType: recordType, recordID: recordID)
        record[Field.date] = card.date as CKRecordValue
        record[Field.upperPhraseData] = try JSONEncoder().encode(card.upperPhrase) as CKRecordValue
        record[Field.lowerPhrase] = card.lowerPhrase as CKRecordValue
        record[Field.mood] = card.mood.rawValue as CKRecordValue
        record[Field.placeHint] = card.placeHint as CKRecordValue
        record[Field.updatedAt] = Date() as CKRecordValue

        if let photoData = card.photoData {
            let fileURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("utakata-\(card.id.uuidString).jpg")
            try photoData.write(to: fileURL, options: [.atomic])
            record[Field.photoAsset] = CKAsset(fileURL: fileURL)
        }

        return record
    }

    private static func card(from record: CKRecord) -> DiaryCard? {
        guard
            let id = UUID(uuidString: record.recordID.recordName),
            let date = record[Field.date] as? Date,
            let upperPhraseData = record[Field.upperPhraseData] as? Data,
            let upperPhrase = try? JSONDecoder().decode([String].self, from: upperPhraseData),
            let lowerPhrase = record[Field.lowerPhrase] as? String,
            let moodRaw = record[Field.mood] as? String,
            let mood = CardMood(rawValue: moodRaw),
            let placeHint = record[Field.placeHint] as? String
        else {
            return nil
        }

        let photoData: Data?
        if
            let asset = record[Field.photoAsset] as? CKAsset,
            let fileURL = asset.fileURL
        {
            photoData = try? Data(contentsOf: fileURL)
        } else {
            photoData = nil
        }

        return DiaryCard(
            id: id,
            date: date,
            upperPhrase: upperPhrase,
            lowerPhrase: lowerPhrase,
            mood: mood,
            placeHint: placeHint,
            photoData: photoData
        )
    }
}

enum DiaryCloudSyncError: LocalizedError {
    case iCloudUnavailable

    var errorDescription: String? {
        "iCloudにサインインしていないか、CloudKitを利用できません。"
    }
}

struct QuietLoggingNote: View {
    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: "moon.zzz")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color(hex: 0x65779A))
                .frame(width: 40, height: 40)
                .background(.white.opacity(0.55), in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text("夜は、ゲームにしない")
                    .font(.headline)
                    .foregroundStyle(Color.primaryText)
                Text("選ぶだけで一日を結晶化して、そのまま眠れるように。")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color.cardFill, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.72), lineWidth: 1)
        )
    }
}

struct PhotoColorMetrics {
    let brightness: CGFloat
    let warmth: CGFloat
    let saturation: CGFloat
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
}

struct PhotoPhraseContext {
    let metrics: PhotoColorMetrics
    let capturedDate: Date?
    let width: CGFloat
    let height: CGFloat
    let hasGPS: Bool

    var hour: Int {
        Calendar.current.component(.hour, from: capturedDate ?? .now)
    }

    var timeLine: String {
        switch hour {
        case 5..<8: return "明け方の"
        case 8..<11: return "\(hour)時の朝"
        case 11..<15: return "\(hour)時の陽"
        case 15..<17: return "\(hour)時すぎ"
        case 17..<19: return "夕暮れの"
        case 19..<24: return "夜\(hour)時"
        default: return "深夜\(hour)時"
        }
    }

    var subjectLine: String {
        let isPortrait = height >= width * 1.12
        let isWide = width >= height * 1.18

        if metrics.blue > metrics.red + 0.06 && metrics.blue > metrics.green + 0.02 && metrics.brightness > 0.46 {
            return isPortrait ? "縦に空あり" : "空の余白に"
        }

        if metrics.green > metrics.red + 0.04 && metrics.green > metrics.blue + 0.02 && metrics.saturation > 0.08 {
            return "緑の気配"
        }

        if metrics.warmth > 0.07 && metrics.brightness > 0.42 {
            return "ぬくい色して"
        }

        if metrics.brightness < 0.32 {
            return hasGPS ? "街灯ひとつ" : "部屋の灯り"
        }

        if metrics.saturation > 0.2 {
            return "色濃く残る"
        }

        if isWide {
            return "横長の景"
        }

        if isPortrait {
            return "縦の光を"
        }

        return "淡い輪郭"
    }

    var feelingLine: String {
        if hasGPS && metrics.brightness < 0.42 {
            return "帰り道"
        }

        if metrics.brightness > 0.68 {
            return "手にほどけ"
        }

        if metrics.brightness < 0.38 {
            return "胸に置く"
        }

        if metrics.warmth > 0.07 {
            return "やわらかく"
        }

        if metrics.blue > metrics.red + 0.06 {
            return "息を置く"
        }

        if metrics.green > metrics.red + 0.04 {
            return "風がいる"
        }

        return "今日残る"
    }

    var phraseLines: [String] {
        if metrics.brightness < 0.34 {
            if metrics.blue > metrics.red + 0.04 {
                return ["夜青く", "影の輪郭", "息ひそめ"]
            }
            return hasGPS ? ["夜の道", "灯りひとつ", "胸に置く"] : ["部屋の灯", "静かな影に", "息を置く"]
        }

        if metrics.blue > metrics.red + 0.06 && metrics.blue > metrics.green + 0.02 && metrics.brightness > 0.46 {
            if metrics.saturation < 0.12 {
                return ["薄青の", "空に今日だけ", "透けてゆく"]
            }
            return height >= width * 1.12 ? ["空たかく", "縦の余白に", "風ひかる"] : ["午後の空", "青のひろがり", "雲ほどけ"]
        }

        if metrics.green > metrics.red + 0.04 && metrics.green > metrics.blue + 0.02 && metrics.saturation > 0.08 {
            return metrics.brightness > 0.58 ? ["葉の透けて", "風の居場所を", "見つけたり"] : ["深みどり", "影のすきまに", "風がいる"]
        }

        if metrics.warmth > 0.08 && metrics.brightness > 0.42 {
            if hour >= 16 {
                return ["夕映えに", "街の輪郭", "ほどけゆく"]
            }
            return metrics.saturation > 0.16 ? ["赤み差す", "今日の温度が", "頬にくる"] : ["ぬくい陽が", "指先まで", "染めていく"]
        }

        if metrics.brightness > 0.68 {
            return ["白い光", "まぶたの裏へ", "こぼれくる"]
        }

        if metrics.saturation > 0.2 {
            return metrics.red > metrics.blue ? ["色の粒", "今日の熱だけ", "抱いている"] : ["彩る景", "記憶の端で", "また光る"]
        }

        if width >= height * 1.18 {
            return ["横顔の", "景色をそっと", "持ち帰る"]
        }

        if height >= width * 1.18 {
            return ["縦長の", "光を胸に", "しまいこむ"]
        }

        return ["淡い景", "名もない今日が", "息をする"]
    }
}

enum EmoFilter {
    case paleLight, amberFilm, blueHour, deepNight, greenAir, vividMemory, softWashi

    var name: String {
        switch self {
        case .paleLight: return "淡光"
        case .amberFilm: return "琥珀"
        case .blueHour: return "青時"
        case .deepNight: return "夜香"
        case .greenAir: return "若葉"
        case .vividMemory: return "彩憶"
        case .softWashi: return "和紙"
        }
    }

    var tint: Color {
        switch self {
        case .paleLight: return Color(hex: 0xF3DCC7)
        case .amberFilm: return Color(hex: 0xD8A05F)
        case .blueHour: return Color(hex: 0x667FA6)
        case .deepNight: return Color(hex: 0x3F4B66)
        case .greenAir: return Color(hex: 0x7EA08A)
        case .vividMemory: return Color(hex: 0xC5766B)
        case .softWashi: return Color(hex: 0xBFAE99)
        }
    }

    var saturation: Double {
        switch self {
        case .paleLight: return 0.82
        case .amberFilm: return 0.92
        case .blueHour: return 0.78
        case .deepNight: return 0.72
        case .greenAir: return 0.9
        case .vividMemory: return 1.12
        case .softWashi: return 0.72
        }
    }

    var contrast: Double {
        switch self {
        case .deepNight: return 1.08
        case .vividMemory: return 1.06
        default: return 0.96
        }
    }

    var brightness: Double {
        switch self {
        case .paleLight: return 0.04
        case .amberFilm: return 0.02
        case .blueHour: return -0.01
        case .deepNight: return -0.03
        case .greenAir: return 0.02
        case .vividMemory: return 0
        case .softWashi: return 0.05
        }
    }

    static func choose(from metrics: PhotoColorMetrics) -> EmoFilter {
        if metrics.brightness < 0.34 {
            return .deepNight
        }

        if metrics.blue > metrics.red + 0.06 && metrics.blue > metrics.green + 0.02 {
            return .blueHour
        }

        if metrics.green > metrics.red + 0.04 && metrics.green > metrics.blue + 0.02 {
            return .greenAir
        }

        if metrics.warmth > 0.07 {
            return .amberFilm
        }

        if metrics.saturation > 0.2 {
            return .vividMemory
        }

        if metrics.brightness > 0.64 {
            return .paleLight
        }

        return .softWashi
    }
}

enum PhotoPhraseGenerator {
    static func description(from data: Data?) -> String? {
        guard
            let data,
            let image = UIImage(data: data)
        else { return nil }

        let metrics = image.colorMetrics()
        var tags: [String] = []

        if metrics.brightness < 0.36 {
            tags.append("暗めの写真")
            tags.append("夜の気配")
        } else if metrics.brightness > 0.66 {
            tags.append("明るい写真")
            tags.append("淡い光")
        } else {
            tags.append("やわらかな明るさ")
        }

        if metrics.warmth > 0.07 {
            tags.append("琥珀色")
            tags.append("夕方のような温度")
        } else if metrics.blue > metrics.red + 0.06 && metrics.blue > metrics.green + 0.02 {
            tags.append("青みのある空気")
            tags.append("雨上がりのような静けさ")
        } else if metrics.green > metrics.red + 0.04 && metrics.green > metrics.blue + 0.02 {
            tags.append("緑の気配")
            tags.append("風を感じる色")
        }

        if metrics.saturation > 0.2 {
            tags.append("印象の強い色")
        } else {
            tags.append("淡い色調")
        }

        if let date = capturedDate(from: data) {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.dateFormat = "H時頃に撮られた写真"
            tags.append(formatter.string(from: date))
        }

        if hasGPS(from: data) {
            tags.append("位置情報あり")
        }

        return Array(Set(tags)).sorted().joined(separator: "、")
    }

    static func upperPhrase(from data: Data) -> [String] {
        guard let image = UIImage(data: data) else {
            return ["光ひとつ", "今日の奥から", "立ちのぼる"]
        }

        let context = PhotoPhraseContext(
            metrics: image.colorMetrics(),
            capturedDate: capturedDate(from: data),
            width: image.size.width,
            height: image.size.height,
            hasGPS: hasGPS(from: data)
        )

        return context.phraseLines
    }

    static func mood(from data: Data) -> CardMood {
        guard let image = UIImage(data: data) else {
            return .dawn
        }

        let metrics = image.colorMetrics()

        if metrics.brightness < 0.36 {
            return .night
        }

        if metrics.blue > metrics.red + 0.06 && metrics.blue > metrics.green + 0.02 {
            return .rain
        }

        if metrics.warmth > 0.07 {
            return .evening
        }

        return .dawn
    }

    private static func imageProperties(from data: Data) -> [CFString: Any]? {
        guard
            let source = CGImageSourceCreateWithData(data as CFData, nil),
            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        else { return nil }

        return properties
    }

    private static func capturedDate(from data: Data) -> Date? {
        guard let properties = imageProperties(from: data) else {
            return nil
        }

        let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any]
        let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any]

        let rawDate = exif?[kCGImagePropertyExifDateTimeOriginal] as? String
            ?? exif?[kCGImagePropertyExifDateTimeDigitized] as? String
            ?? tiff?[kCGImagePropertyTIFFDateTime] as? String

        guard let rawDate else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter.date(from: rawDate)
    }

    private static func hasGPS(from data: Data) -> Bool {
        guard let properties = imageProperties(from: data) else {
            return false
        }

        return properties[kCGImagePropertyGPSDictionary] != nil
    }
}

private extension UIImage {
    func colorMetrics() -> PhotoColorMetrics {
        guard let inputImage = CIImage(image: self) else {
            return PhotoColorMetrics(brightness: 0.55, warmth: 0, saturation: 0.12, red: 0.55, green: 0.55, blue: 0.55)
        }

        let extentVector = CIVector(
            x: inputImage.extent.origin.x,
            y: inputImage.extent.origin.y,
            z: inputImage.extent.size.width,
            w: inputImage.extent.size.height
        )

        guard
            let filter = CIFilter(name: "CIAreaAverage", parameters: [
                kCIInputImageKey: inputImage,
                kCIInputExtentKey: extentVector
            ]),
            let outputImage = filter.outputImage
        else {
            return PhotoColorMetrics(brightness: 0.55, warmth: 0, saturation: 0.12, red: 0.55, green: 0.55, blue: 0.55)
        }

        var bitmap = [UInt8](repeating: 0, count: 4)
        CIContext(options: [.workingColorSpace: NSNull()]).render(
            outputImage,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: nil
        )

        let red = CGFloat(bitmap[0]) / 255
        let green = CGFloat(bitmap[1]) / 255
        let blue = CGFloat(bitmap[2]) / 255
        let brightness = (red + green + blue) / 3
        let warmth = red - blue
        let saturation = max(red, green, blue) - min(red, green, blue)

        return PhotoColorMetrics(
            brightness: brightness,
            warmth: warmth,
            saturation: saturation,
            red: red,
            green: green,
            blue: blue
        )
    }
}

struct PoemCardView: View {
    let upperPhrase: [String]
    let lowerPhrase: String
    let mood: CardMood
    let compact: Bool
    let photoData: Data?
    var heroPreview = false
    @AppStorage("utakataFontStyle") private var fontStyleRaw = UtakataFontStyle.mincho.rawValue

    private var emoFilter: EmoFilter? {
        guard
            let photoData,
            let uiImage = UIImage(data: photoData)
        else { return nil }

        return EmoFilter.choose(from: uiImage.colorMetrics())
    }

    private var selectedImage: Image? {
        guard
            let photoData,
            let uiImage = UIImage(data: photoData)
        else { return nil }

        return Image(uiImage: uiImage)
    }

    var body: some View {
        GeometryReader { proxy in
            let edge = compact ? proxy.size.width * 0.045 : proxy.size.width * 0.055
            let bottom = compact ? proxy.size.height * 0.15 : proxy.size.height * 0.17
            let photoHeight = proxy.size.height - bottom - edge * 1.4
            let textInset = heroPreview ? 18.0 : (compact ? 9.0 : 14.0)
            let poemPanelWidth = min(proxy.size.width * (heroPreview ? 0.42 : (compact ? 0.42 : 0.38)), heroPreview ? 112 : (compact ? 96 : 126))
            let poemPanelHeight = max(56, photoHeight - textInset * 2)

            ZStack {
                RoundedRectangle(cornerRadius: compact ? 10 : 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: 0xFFF8EA),
                                Color(hex: 0xF5E4C8),
                                mood.accent.opacity(0.13)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                WagasaArc()
                    .stroke(Color.meijiRed.opacity(0.055), lineWidth: compact ? 0.8 : 1.1)
                    .frame(width: proxy.size.width * 0.9, height: proxy.size.width * 0.9)
                    .rotationEffect(.degrees(-18))
                    .offset(x: proxy.size.width * 0.25, y: -proxy.size.height * 0.32)

                SakuraPetalShape()
                    .fill(Color.retroRose.opacity(0.055))
                    .frame(width: proxy.size.width * 0.18, height: proxy.size.width * 0.26)
                    .rotationEffect(.degrees(22))
                    .offset(x: -proxy.size.width * 0.32, y: proxy.size.height * 0.32)

                VStack(spacing: 0) {
                    ZStack(alignment: .topTrailing) {
                        photoLayer
                            .frame(height: photoHeight)
                            .clipShape(RoundedRectangle(cornerRadius: compact ? 5 : 7, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: compact ? 5 : 7, style: .continuous)
                                    .stroke(Color.primaryText.opacity(0.16), lineWidth: 0.8)
                            )

                        LinearGradient(
                            colors: [.clear, .black.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .clipShape(RoundedRectangle(cornerRadius: compact ? 5 : 7, style: .continuous))
                        .allowsHitTesting(false)

                        ZStack {
                            RoundedRectangle(cornerRadius: compact ? 8 : 11, style: .continuous)
                                .fill(Color(hex: 0xFFF8EA).opacity(compact ? 0.74 : 0.68))
                                .background(.ultraThinMaterial.opacity(compact ? 0.18 : 0.14), in: RoundedRectangle(cornerRadius: compact ? 8 : 11, style: .continuous))
                                .overlay(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: 0xFFFDF5).opacity(0.42),
                                            Color(hex: 0xF4E4CB).opacity(0.20),
                                            mood.accent.opacity(0.08)
                                        ],
                                        startPoint: .topTrailing,
                                        endPoint: .bottomLeading
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: compact ? 8 : 11, style: .continuous))
                                )

                            VerticalTankaView(
                                upperPhrase: upperPhrase,
                                lowerPhrase: lowerPhrase,
                                accent: mood.accent,
                                compact: compact
                            )
                            .padding(.horizontal, heroPreview ? 7 : (compact ? 3 : 5))
                            .padding(.vertical, heroPreview ? 9 : (compact ? 5 : 7))
                        }
                        .frame(width: poemPanelWidth, height: poemPanelHeight, alignment: .center)
                        .overlay(
                            RoundedRectangle(cornerRadius: compact ? 8 : 11, style: .continuous)
                                .stroke(Color.retroGold.opacity(0.40), lineWidth: 0.8)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: compact ? 5 : 8, style: .continuous)
                                .stroke(Color(hex: 0xFFFDF5).opacity(0.34), lineWidth: 0.6)
                                .padding(3)
                        )
                        .padding(.top, textInset)
                        .padding(.trailing, textInset)
                        .clipped()
                    }

                    HStack(alignment: .center, spacing: 10) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(Date.now.karutaDay)
                                .font(.caption2.monospacedDigit().weight(.bold))
                                .foregroundStyle((emoFilter?.tint ?? mood.accent).opacity(0.9))
                            Text(photoData == nil ? "写真を選ぶと短歌が浮かびます" : "今日をしまう一枚")
                                .font(currentFont.font(size: compact ? 11 : 13, weight: .semibold))
                                .foregroundStyle(Color.primaryText.opacity(0.82))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }

                        Spacer(minLength: 6)

                        Text(photoData == nil ? "未選択" : (emoFilter?.name ?? "和紙"))
                            .font(.caption2.weight(.black))
                            .foregroundStyle(Color.retroPaper)
                            .padding(.horizontal, compact ? 8 : 10)
                            .padding(.vertical, 5)
                            .background((emoFilter?.tint ?? mood.accent).opacity(0.92), in: RoundedRectangle(cornerRadius: 3, style: .continuous))
                    }
                    .frame(height: bottom)
                    .padding(.horizontal, compact ? 6 : 9)
                }
                .padding(edge)
            }
            .overlay(
                RoundedRectangle(cornerRadius: compact ? 10 : 14, style: .continuous)
                    .stroke(Color.primaryText.opacity(0.22), lineWidth: compact ? 0.9 : 1.1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: compact ? 6 : 9, style: .continuous)
                    .stroke(Color.retroGold.opacity(compact ? 0.35 : 0.48), lineWidth: compact ? 0.8 : 1)
                    .padding(compact ? 7 : 10)
            )
            .overlay(
                RetroCornerOrnaments(color: mood.accent.opacity(compact ? 0.28 : 0.36))
                    .padding(compact ? 8 : 12)
            )
            .shadow(color: Color(hex: 0x4B362B).opacity(0.18), radius: compact ? 16 : 24, x: 0, y: compact ? 9 : 16)
        }
    }

    private var currentFont: UtakataFontStyle {
        UtakataFontStyle(rawValue: fontStyleRaw) ?? .mincho
    }

    private var photoLayer: some View {
        ZStack {
            if let selectedImage {
                selectedImage
                    .resizable()
                    .scaledToFill()
                    .saturation(emoFilter?.saturation ?? 1)
                    .contrast(max(1.02, emoFilter?.contrast ?? 1.02))
                    .brightness((emoFilter?.brightness ?? 0) * 0.45)
                    .overlay(
                        (emoFilter?.tint ?? mood.accent)
                            .opacity(0.08)
                            .blendMode(.softLight)
                    )
            } else {
                LinearGradient(colors: mood.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                WashiPattern()
                    .opacity(0.22)
            }
        }
    }
}

struct VerticalTankaView: View {
    let upperPhrase: [String]
    let lowerPhrase: String
    let accent: Color
    let compact: Bool

    private var lines: [String] {
        var result = Array(upperPhrase.prefix(3))
        result.append(contentsOf: lowerPhrase.tankaLowerLines())

        while result.count < 5 {
            result.append("")
        }

        return Array(result.prefix(5))
    }

    var body: some View {
        GeometryReader { proxy in
            let normalizedLines = lines.map { $0.normalizedVerticalPoemText }
            let maxCount = max(normalizedLines.map(\.count).max() ?? 1, 1)
            let verticalPadding = compact ? 6.0 : 8.0
            let characterSpacing = compact ? 1.0 : 1.5
            let availableHeight = max(34, proxy.size.height - verticalPadding * 2)
            let fittedFontSize = min(
                compact ? 12.0 : 15.0,
                max(compact ? 8.0 : 10.0, (availableHeight - CGFloat(maxCount - 1) * characterSpacing) / CGFloat(maxCount))
            )

            HStack(alignment: .top, spacing: compact ? 3 : 5) {
                ForEach(Array(lines.enumerated()).reversed(), id: \.offset) { index, line in
                    VerticalPoemLine(
                        text: line,
                        isLowerPhrase: index >= 3,
                        accent: accent,
                        compact: compact,
                        fontSize: fittedFontSize
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

struct VerticalPoemLine: View {
    let text: String
    let isLowerPhrase: Bool
    let accent: Color
    let compact: Bool
    var fontSize: CGFloat? = nil
    @AppStorage("utakataFontStyle") private var fontStyleRaw = UtakataFontStyle.mincho.rawValue

    var body: some View {
        let characters = Array(text.normalizedVerticalPoemText.enumerated())

        VStack(spacing: compact ? 1.0 : 1.5) {
            ForEach(characters, id: \.offset) { _, character in
                Text(String(character))
                    .font(currentFont.font(size: effectiveFontSize, weight: .medium))
                    .foregroundStyle(isLowerPhrase ? Color.primaryText.opacity(0.86) : Color.primaryText)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                    .allowsTightening(true)
            }
        }
        .frame(width: compact ? 15 : 19, alignment: .top)
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.vertical, compact ? 3 : 4)
        .background(
            isLowerPhrase ? accent.opacity(0.07) : Color.clear,
            in: Capsule()
        )
        .clipped()
    }

    private var currentFont: UtakataFontStyle {
        UtakataFontStyle(rawValue: fontStyleRaw) ?? .mincho
    }

    private var effectiveFontSize: CGFloat {
        fontSize ?? (compact ? 12 : 15)
    }
}

private extension String {
    var normalizedVerticalPoemText: String {
        replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "　", with: "")
            .replacingOccurrences(of: "\n", with: "")
    }
}

struct HeaderView: View {
    let title: String
    let subtitle: String
    @AppStorage("utakataFontStyle") private var fontStyleRaw = UtakataFontStyle.mincho.rawValue

    var body: some View {
        HStack {
            Spacer(minLength: 0)

            HStack(spacing: 8) {
                if title == "設定" {
                    Image(systemName: "gearshape")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.meijiRed.opacity(0.9))
                }

                Text(title)
                    .font(currentFont.font(size: 32, weight: .semibold))
                    .foregroundStyle(Color.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            .padding(.bottom, 8)
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [.clear, Color.retroGold.opacity(0.72), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 118, height: 1)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }

    private var currentFont: UtakataFontStyle {
        UtakataFontStyle(rawValue: fontStyleRaw) ?? .mincho
    }
}

struct ScreenHeaderWithSettings: View {
    let title: String
    let subtitle: String
    let onOpenSettings: () -> Void
    var canDrawMikuji = false
    var isMikujiDrawnToday = false
    var mikujiStreak = 0
    var onOpenMikuji: () -> Void = {}

    var body: some View {
        ZStack {
            HeaderView(title: title, subtitle: subtitle)

            HStack {
                Spacer()
                if title == "日記" {
                    MikujiShortcutButton(
                        canDraw: canDrawMikuji,
                        isDrawnToday: isMikujiDrawnToday,
                        streakCount: mikujiStreak,
                        action: onOpenMikuji
                    )
                }
                SettingsShortcutButton(action: onOpenSettings)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct MikujiShortcutButton: View {
    let canDraw: Bool
    let isDrawnToday: Bool
    let streakCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(Color(hex: 0xFFF9F2).opacity(canDraw ? 0.94 : (isDrawnToday ? 0.72 : 0.64)))
                    .frame(width: 42, height: 42)
                    .overlay(Circle().stroke(Color.meijiRed.opacity(canDraw ? 0.32 : (isDrawnToday ? 0.18 : 0.14)), lineWidth: 0.9))
                    .overlay(Circle().stroke(Color.retroGold.opacity(canDraw ? 0.42 : (isDrawnToday ? 0.30 : 0.20)), lineWidth: 0.7).padding(4))
                    .shadow(color: Color.meijiRed.opacity(canDraw ? 0.14 : (isDrawnToday ? 0.06 : 0.04)), radius: 10, x: 0, y: 5)

                Image(systemName: "scroll.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(canDraw ? Color.meijiRed : (isDrawnToday ? Color.meijiRed.opacity(0.42) : Color.secondaryText.opacity(0.42)))

                if canDraw {
                    Circle()
                        .fill(Color.meijiRed)
                        .frame(width: 9, height: 9)
                        .overlay(Circle().stroke(Color(hex: 0xFFF9F2), lineWidth: 1.6))
                        .offset(x: 1, y: -1)
                }
            }
            .overlay(alignment: .bottom) {
                if streakCount > 0 && (canDraw || isDrawnToday) {
                    Text("×\(max(streakCount, 1))")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(canDraw ? Color.retroPaper : Color.primaryText.opacity(0.62))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(canDraw ? Color.meijiRed.opacity(0.92) : Color(hex: 0xFFF9F2).opacity(0.86), in: Capsule())
                        .overlay(Capsule().stroke(Color.retroGold.opacity(canDraw ? 0.45 : 0.34), lineWidth: 0.7))
                        .offset(y: 12)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!canDraw)
        .opacity(canDraw ? 1 : (isDrawnToday ? 0.58 : 0.78))
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        if canDraw {
            return "うたかたみくじを引く"
        }

        if isDrawnToday {
            return "今日のうたかたみくじは引き終わりました"
        }

        return "うたかたみくじは明日の朝に開きます"
    }
}

struct SettingsShortcutButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(hex: 0xFFF9F2).opacity(0.88))
                    .frame(width: 42, height: 42)
                    .overlay(Circle().stroke(Color.meijiRed.opacity(0.28), lineWidth: 0.9))
                    .overlay(Circle().stroke(Color.retroGold.opacity(0.34), lineWidth: 0.7).padding(4))
                    .shadow(color: Color.meijiRed.opacity(0.10), radius: 10, x: 0, y: 5)

                Image(systemName: "gearshape.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.meijiRed)

                PlumBlossom()
                    .fill(Color.retroGold.opacity(0.78))
                    .frame(width: 10, height: 10)
                    .offset(x: 13, y: -13)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("設定を開く")
    }
}

struct CalendarDayCell: View {
    let day: Int
    let isSaved: Bool
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Text("\(day)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(isSelected ? Color.white : Color.primaryText)
                Circle()
                    .fill(isSaved ? (isSelected ? .white : Color.utakataAccent) : .clear)
                    .frame(width: 5, height: 5)
            }
            .frame(height: 48)
            .frame(maxWidth: .infinity)
            .background(
                isSelected ? Color.utakataAccent : Color.white.opacity(isSaved ? 0.55 : 0.22),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }
}

struct PhotoIntakeCard: View {
    let photoData: Data?
    @Binding var selectedItem: PhotosPickerItem?

    private var selectedImage: Image? {
        guard
            let photoData,
            let uiImage = UIImage(data: photoData)
        else { return nil }

        return Image(uiImage: uiImage)
    }

    var body: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(LinearGradient(colors: [Color(hex: 0xF8E3D1), Color(hex: 0xDDECE4)], startPoint: .topLeading, endPoint: .bottomTrailing))

                    if let selectedImage {
                        selectedImage
                            .resizable()
                            .scaledToFill()
                            .overlay(.black.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    } else {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(Color.utakataAccent)
                    }
                }
                .frame(width: 74, height: 74)
                .clipped()

                VStack(alignment: .leading, spacing: 6) {
                    Text(photoData == nil ? "写真を一枚えらぶ" : "写真を差し替える")
                        .font(.headline)
                        .foregroundStyle(Color.primaryText)
                    Text(photoData == nil ? "その日の光を、札の奥にそっと滲ませます" : "この写真の気配で今日の札を作ります")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Color.secondaryText.opacity(0.6))
            }
            .padding(14)
            .background(Color.cardFill, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(.white.opacity(0.72), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 6) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 17, weight: .medium))
                            .symbolRenderingMode(.hierarchical)
                        Text(tab.tabTitle)
                            .font(UtakataFontStyle.rounded(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(selectedTab == tab ? Color.retroPaper : Color.primaryText.opacity(0.64))
                    .frame(width: 126)
                    .padding(.vertical, 13)
                    .background(
                        selectedTab == tab
                        ? LinearGradient(
                            colors: [Color.meijiRed, Color(hex: 0xC66F7A)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [.clear, .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Capsule(style: .continuous)
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(selectedTab == tab ? Color.retroGold.opacity(0.58) : Color.clear, lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background {
            ZStack {
                Color(hex: 0xFFF9F2).opacity(0.94)
                WashiPattern()
                    .opacity(0.14)
                LinearGradient(
                    colors: [Color.white.opacity(0.42), Color.retroPaper.opacity(0.38)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .clipShape(Capsule(style: .continuous))
        }
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.retroGold.opacity(0.42), lineWidth: 1.0)
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color.meijiRed.opacity(0.16), lineWidth: 0.8)
                .padding(5)
        )
        .shadow(color: .black.opacity(0.12), radius: 22, x: 0, y: 10)
        .shadow(color: Color.meijiRed.opacity(0.08), radius: 12, x: 0, y: 5)
        .padding(.bottom, 16)
    }
}

struct FloatingDiaryActionButton: View {
    let action: () -> Void
    @GestureState private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0xFFF9F2), Color.retroPaper],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .overlay(Circle().stroke(Color.meijiRed.opacity(0.34), lineWidth: 1.0))
                    .overlay(Circle().stroke(Color.retroGold.opacity(0.46), lineWidth: 0.8).padding(5))

                Image(systemName: "square.and.pencil")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color.meijiRed)

                PlumBlossom()
                    .fill(Color.retroGold.opacity(0.82))
                    .frame(width: 11, height: 11)
                    .offset(x: 18, y: -18)
            }
            .scaleEffect(isPressed ? 0.92 : 1)
            .shadow(color: Color.meijiRed.opacity(isPressed ? 0.10 : 0.22), radius: isPressed ? 8 : 16, x: 0, y: isPressed ? 4 : 9)
            .animation(.spring(response: 0.22, dampingFraction: 0.68), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .updating($isPressed) { _, state, _ in
                    state = true
                }
        )
        .accessibilityLabel("日記を作成")
    }
}

struct PermissionCard: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.utakataAccent)
                .frame(width: 42, height: 42)
                .background(.white.opacity(0.58), in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.primaryText)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .background(Color.cardFill, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.75), lineWidth: 1)
        )
    }
}

struct AppBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: 0xF3D8D7),
                    Color(hex: 0xF9EBD7),
                    Color(hex: 0xDCC3B8),
                    Color(hex: 0xC9DCE1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RetroPaperTexture()

            TaishoCheckPattern(color: Color.meijiRed.opacity(0.04), tile: 34)

            RetroBrickTownSilhouette()
                .opacity(0.16)

            RomanceDreamLayer()

            RadialGradient(colors: [Color.retroRose.opacity(0.24), .clear], center: .topTrailing, startRadius: 10, endRadius: 280)

            RadialGradient(colors: [Color.meijiBlue.opacity(0.14), .clear], center: .bottomLeading, startRadius: 12, endRadius: 320)

            VintagePostcardBorder()
                .padding(.horizontal, 10)
                .padding(.vertical, 12)
        }
        .ignoresSafeArea()
    }
}

struct RetroBrickTownSilhouette: View {
    var body: some View {
        GeometryReader { proxy in
            let baseY = proxy.size.height * 0.76

            ZStack(alignment: .bottom) {
                ForEach(0..<8, id: \.self) { index in
                    let width = proxy.size.width / 7.5
                    let height = CGFloat([86, 122, 96, 148, 112, 132, 90, 116][index])

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.primaryText.opacity(index.isMultiple(of: 2) ? 0.12 : 0.09))
                        .frame(width: width, height: height)
                        .overlay {
                            VStack(spacing: 8) {
                                ForEach(0..<4, id: \.self) { _ in
                                    HStack(spacing: 8) {
                                        ForEach(0..<2, id: \.self) { _ in
                                            RoundedRectangle(cornerRadius: 1.5)
                                                .fill(Color.retroPaper.opacity(0.32))
                                                .frame(width: 9, height: 14)
                                        }
                                    }
                                }
                            }
                            .padding(.top, 14)
                        }
                        .offset(x: (CGFloat(index) - 3.5) * width * 0.92, y: baseY - proxy.size.height / 2)
                }

                Rectangle()
                    .fill(Color.primaryText.opacity(0.08))
                    .frame(height: 1)
                    .offset(y: baseY - proxy.size.height / 2)
            }
            .blur(radius: 0.25)
        }
        .allowsHitTesting(false)
    }
}

struct VintagePostcardBorder: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.retroGold.opacity(0.34), lineWidth: 1)

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.meijiRed.opacity(0.14), lineWidth: 0.8)
                .padding(7)

            GeometryReader { proxy in
                ForEach(0..<4, id: \.self) { index in
                    SakuraPetalShape()
                        .fill(Color.retroRose.opacity(0.18))
                        .frame(width: 18, height: 26)
                        .rotationEffect(.degrees(Double(index) * 92 + 18))
                        .position(cornerPosition(index, in: proxy.size))
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func cornerPosition(_ index: Int, in size: CGSize) -> CGPoint {
        let inset: CGFloat = 28
        switch index {
        case 0: return CGPoint(x: inset, y: inset)
        case 1: return CGPoint(x: size.width - inset, y: inset)
        case 2: return CGPoint(x: inset, y: size.height - inset)
        default: return CGPoint(x: size.width - inset, y: size.height - inset)
        }
    }
}

struct RomanceDreamLayer: View {
    private let petals: [(x: CGFloat, y: CGFloat, size: CGFloat, angle: Double, opacity: Double)] = [
        (0.14, 0.12, 19, -22, 0.42),
        (0.82, 0.16, 24, 18, 0.34),
        (0.25, 0.33, 14, 35, 0.30),
        (0.72, 0.42, 17, -18, 0.28),
        (0.09, 0.68, 22, 24, 0.26),
        (0.88, 0.78, 15, -32, 0.30)
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                SoftWindowGrid()
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
                    .frame(width: proxy.size.width * 0.72, height: proxy.size.height * 0.22)
                    .offset(x: -proxy.size.width * 0.04, y: -proxy.size.height * 0.36)
                    .blur(radius: 0.2)

                WagasaArc()
                    .stroke(Color.meijiRed.opacity(0.18), lineWidth: 1.2)
                    .frame(width: proxy.size.width * 0.62, height: proxy.size.width * 0.62)
                    .offset(x: proxy.size.width * 0.33, y: -proxy.size.height * 0.24)

                ForEach(Array(petals.enumerated()), id: \.offset) { _, petal in
                    SakuraPetalShape()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: 0xFFE5E8).opacity(petal.opacity), Color.retroRose.opacity(petal.opacity * 0.92)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: petal.size, height: petal.size * 1.5)
                        .rotationEffect(.degrees(petal.angle))
                        .position(x: proxy.size.width * petal.x, y: proxy.size.height * petal.y)
                        .blur(radius: 0.15)
                }

                Path { path in
                    path.move(to: CGPoint(x: proxy.size.width * 0.05, y: proxy.size.height * 0.2))
                    path.addCurve(
                        to: CGPoint(x: proxy.size.width * 0.92, y: proxy.size.height * 0.1),
                        control1: CGPoint(x: proxy.size.width * 0.28, y: proxy.size.height * 0.08),
                        control2: CGPoint(x: proxy.size.width * 0.64, y: proxy.size.height * 0.24)
                    )
                }
                .stroke(Color.meijiRed.opacity(0.13), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
            }
            .allowsHitTesting(false)
        }
    }
}

struct SakuraPetalShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addCurve(to: CGPoint(x: rect.maxX, y: rect.midY), control1: CGPoint(x: rect.maxX * 0.92, y: rect.minY + rect.height * 0.12), control2: CGPoint(x: rect.maxX, y: rect.midY * 0.72))
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY), control1: CGPoint(x: rect.maxX * 0.94, y: rect.maxY * 0.72), control2: CGPoint(x: rect.midX + rect.width * 0.16, y: rect.maxY * 0.92))
        path.addCurve(to: CGPoint(x: rect.minX, y: rect.midY), control1: CGPoint(x: rect.midX - rect.width * 0.16, y: rect.maxY * 0.92), control2: CGPoint(x: rect.minX + rect.width * 0.06, y: rect.maxY * 0.72))
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.minY), control1: CGPoint(x: rect.minX, y: rect.midY * 0.72), control2: CGPoint(x: rect.maxX * 0.08, y: rect.minY + rect.height * 0.12))
        path.closeSubpath()
        return path
    }
}

struct WagasaArc: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        let radius = rect.width * 0.52

        path.addArc(center: center, radius: radius, startAngle: .degrees(205), endAngle: .degrees(335), clockwise: false)
        for index in 0...8 {
            let angle = (205 + Double(index) * 130 / 8) * .pi / 180
            let end = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            path.move(to: center)
            path.addLine(to: end)
        }

        return path
    }
}

struct SoftWindowGrid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let columns = 5
        let rows = 3

        for column in 0...columns {
            let x = rect.minX + rect.width * CGFloat(column) / CGFloat(columns)
            path.move(to: CGPoint(x: x, y: rect.minY))
            path.addLine(to: CGPoint(x: x, y: rect.maxY))
        }

        for row in 0...rows {
            let y = rect.minY + rect.height * CGFloat(row) / CGFloat(rows)
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }

        return path
    }
}

struct TaishoCheckPattern: View {
    let color: Color
    let tile: CGFloat

    var body: some View {
        Canvas { context, size in
            var x: CGFloat = 0
            var column = 0
            while x < size.width {
                var y: CGFloat = 0
                var row = 0
                while y < size.height {
                    if (row + column).isMultiple(of: 2) {
                        let rect = CGRect(x: x, y: y, width: tile, height: tile)
                        context.fill(Path(rect), with: .color(color))
                    }
                    y += tile
                    row += 1
                }
                x += tile
                column += 1
            }
        }
        .allowsHitTesting(false)
    }
}

struct TaishoBadgeShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cut = min(rect.width, rect.height) * 0.18
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + cut, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + cut), control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cut))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - cut, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + cut, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - cut), control: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cut))
        path.addQuadCurve(to: CGPoint(x: rect.minX + cut, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

struct RetroRibbonLabel: View {
    let text: String
    let tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Color.retroGold.opacity(0.75))
                .frame(width: 18, height: 1)
            Text(text)
                .font(.system(size: 18, weight: .semibold, design: .serif))
                .foregroundStyle(Color.retroPaper)
            Rectangle()
                .fill(Color.retroGold.opacity(0.75))
                .frame(width: 18, height: 1)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 7)
        .background(tint, in: TicketButtonShape())
        .overlay(TicketButtonShape().stroke(Color.retroGold.opacity(0.68), lineWidth: 1))
    }
}

struct TaishoPanelModifier: ViewModifier {
    let tint: Color

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    Color.cardFill
                    WashiPattern()
                        .opacity(0.18)
                    TaishoCheckPattern(color: tint.opacity(0.045), tile: 24)
                    RetroCornerOrnaments(color: tint.opacity(0.36))
                        .padding(9)
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.primaryText.opacity(0.38), lineWidth: 1.1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(tint.opacity(0.36), lineWidth: 0.9)
                    .padding(6)
            )
    }
}

extension View {
    func taishoPanel(tint: Color) -> some View {
        modifier(TaishoPanelModifier(tint: tint))
    }
}

struct RetroPaperTexture: View {
    var body: some View {
        Canvas { context, size in
            for index in 0..<220 {
                let x = CGFloat((index * 47) % 997) / 997 * size.width
                let y = CGFloat((index * 83) % 991) / 991 * size.height
                let radius = CGFloat((index % 4) + 1) * 0.55
                let color = index.isMultiple(of: 3) ? Color(hex: 0x7B5C3F).opacity(0.08) : Color.white.opacity(0.12)
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: radius, height: radius)), with: .color(color))
            }
        }
        .allowsHitTesting(false)
    }
}

struct RetroCornerOrnaments: View {
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height) * 0.14
            ZStack {
                ornament
                    .frame(width: size, height: size)
                    .position(x: size / 2, y: size / 2)
                ornament
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(90))
                    .position(x: proxy.size.width - size / 2, y: size / 2)
                ornament
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(270))
                    .position(x: size / 2, y: proxy.size.height - size / 2)
                ornament
                    .frame(width: size, height: size)
                    .rotationEffect(.degrees(180))
                    .position(x: proxy.size.width - size / 2, y: proxy.size.height - size / 2)
            }
        }
        .allowsHitTesting(false)
    }

    private var ornament: some View {
        ZStack(alignment: .topLeading) {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 24, y: 0))
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: 24))
                path.move(to: CGPoint(x: 6, y: 6))
                path.addQuadCurve(to: CGPoint(x: 22, y: 10), control: CGPoint(x: 14, y: 2))
                path.move(to: CGPoint(x: 6, y: 6))
                path.addQuadCurve(to: CGPoint(x: 10, y: 22), control: CGPoint(x: 2, y: 14))
            }
            .stroke(color, lineWidth: 1.2)
        }
    }
}

struct FloatingBubble: View {
    let offset: CGSize
    let size: CGFloat
    let opacity: Double

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [.white.opacity(opacity + 0.18), .white.opacity(opacity), .clear],
                    center: .center,
                    startRadius: 2,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
            .offset(offset)
            .allowsHitTesting(false)
    }
}

struct UtakataPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(
                LinearGradient(colors: [Color.meijiRed, Color(hex: 0x7E2E2F)], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: TicketButtonShape()
            )
            .overlay(
                TicketButtonShape()
                    .stroke(Color.retroGold.opacity(0.72), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .shadow(color: Color.meijiRed.opacity(0.22), radius: 16, x: 0, y: 8)
    }
}

struct SoftPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.primaryText)
            .padding(.horizontal, 15)
            .padding(.vertical, 12)
            .background(Color.retroPaper.opacity(0.72), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(Color.primaryText.opacity(0.32), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

extension ButtonStyle where Self == UtakataPrimaryButtonStyle {
    static var utakataPrimary: UtakataPrimaryButtonStyle { UtakataPrimaryButtonStyle() }
}

extension ButtonStyle where Self == SoftPillButtonStyle {
    static var softPill: SoftPillButtonStyle { SoftPillButtonStyle() }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }

    static let primaryText = Color(hex: 0x33231F)
    static let secondaryText = Color(hex: 0x715D4A)
    static let utakataAccent = Color(hex: 0xB84343)
    static let cardFill = Color(hex: 0xF4E7D0).opacity(0.72)
    static let retroPaper = Color(hex: 0xF3E5CB)
    static let retroGold = Color(hex: 0xB59A62)
    static let meijiRed = Color(hex: 0xA93535)
    static let meijiBlue = Color(hex: 0x294E63)
    static let retroRose = Color(hex: 0xC36C78)
    static let retroSage = Color(hex: 0x76866A)
}

extension Date {
    var japaneseMonthDay: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: self)
    }

    var memoryTitle: String {
        "\(japaneseMonthDay)の札"
    }

    var karutaDay: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M.d"
        return formatter.string(from: self)
    }
}

extension String {
    func tankaLowerLines() -> [String] {
        let normalized = replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "　", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let words = normalized.split(separator: " ").map(String.init)

        if words.count >= 2 {
            let first = words.dropLast().joined()
            let second = words.last ?? ""
            return [first, second]
        }

        guard !normalized.isEmpty else {
            return ["", ""]
        }

        let characters = Array(normalized)
        let splitIndex = min(max(3, characters.count / 2), max(3, characters.count - 1))
        let first = String(characters.prefix(splitIndex))
        let second = String(characters.dropFirst(splitIndex))

        return [first, second.isEmpty ? " " : second]
    }
}

extension DiaryCard {
    static let samples: [DiaryCard] = [
        DiaryCard(
            date: Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 22)) ?? .now,
            upperPhrase: ["夕暮れの", "駅の硝子に", "雲ながれ"],
            lowerPhrase: "言えなかった名を そっとしまう",
            mood: .evening,
            placeHint: "駅",
            photoData: nil
        ),
        DiaryCard(
            date: Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 16)) ?? .now,
            upperPhrase: ["夜の道", "自販機だけが", "春を知る"],
            lowerPhrase: "缶のぬくみで 今日をたたむ",
            mood: .night,
            placeHint: "夜道",
            photoData: nil
        ),
        DiaryCard(
            date: Calendar.current.date(from: DateComponents(year: 2026, month: 5, day: 8)) ?? .now,
            upperPhrase: ["雨あがる", "駅前の光", "まだ淡く"],
            lowerPhrase: "もう少しだけ遠回りする",
            mood: .rain,
            placeHint: "駅前",
            photoData: nil
        )
    ]
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
