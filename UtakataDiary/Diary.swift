import SwiftUI
import PhotosUI
import UIKit

struct TodayView: View {
    @Binding var savedCards: [DiaryCard]
    let onDiaryCreated: (Date) -> Void
    @State private var showingComposer = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    HeaderView(title: "日記", subtitle: Date.now.japaneseMonthDay)

                    Button {
                        showingComposer = true
                    } label: {
                        CreateDiaryEntryCard()
                    }
                    .buttonStyle(.plain)

                    DiaryMonthOverview(cards: savedCards) {
                        showingComposer = true
                    }

                    if let latestCard = savedCards.first {
                        VStack(alignment: .leading, spacing: 12) {
                            RetroRibbonLabel(text: "最新の日記", tint: Color.meijiRed)
                                .padding(.leading, 2)

                            MemoryPreviewCard(card: latestCard)
                        }
                    } else {
                        EmptyDiaryHint()
                    }

                    Spacer(minLength: 190)
                }
                .padding(.horizontal, 22)
                .padding(.top, 20)
                .padding(.bottom, 84)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingComposer) {
                DiaryComposerView { card in
                    if !savedCards.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: card.date) }) {
                        savedCards.insert(card, at: 0)
                    }
                    onDiaryCreated(card.date)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

struct CreateDiaryEntryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .center, spacing: 18) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: 0xF8C9C7), Color.retroRose, Color.meijiRed],
                                center: .topLeading,
                                startRadius: 3,
                                endRadius: 48
                            )
                        )
                        .frame(width: 72, height: 72)
                        .overlay(
                            Circle()
                                .stroke(Color.retroGold.opacity(0.72), lineWidth: 1.1)
                                .padding(5)
                        )
                        .shadow(color: Color.meijiRed.opacity(0.22), radius: 18, x: 0, y: 9)

                    Image(systemName: "plus")
                        .font(.system(size: 31, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 9) {
                    RetroRibbonLabel(text: "日記を作成", tint: Color.meijiRed)
                    Text("写真を選ぶ / 撮る → 上の句 → 下の句 → 一枚の札へ")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.secondaryText)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(alignment: .top, spacing: 9) {
                FlowChip(number: "1", title: "写真")
                FlowLine()
                FlowChip(number: "2", title: "上の句")
                FlowLine()
                FlowChip(number: "3", title: "下の句")
                FlowLine()
                FlowChip(number: "4", title: "札")
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 26)
        .background {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: 0xFFF1E8).opacity(0.94),
                        Color(hex: 0xF6D7D9).opacity(0.82),
                        Color(hex: 0xEAD6BF).opacity(0.88)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                TaishoCheckPattern(color: Color.meijiRed.opacity(0.055), tile: 22)
                WashiPattern()
                    .opacity(0.26)
                WagasaArc()
                    .stroke(Color.meijiRed.opacity(0.16), lineWidth: 1)
                    .frame(width: 180, height: 180)
                    .offset(x: 120, y: -42)
                SakuraPetalShape()
                    .fill(Color.retroRose.opacity(0.28))
                    .frame(width: 18, height: 26)
                    .rotationEffect(.degrees(-24))
                    .offset(x: 112, y: 56)
                SakuraPetalShape()
                    .fill(Color(hex: 0xFFE5E8).opacity(0.42))
                    .frame(width: 13, height: 20)
                    .rotationEffect(.degrees(28))
                    .offset(x: -118, y: -44)
                RetroCornerOrnaments(color: Color.meijiRed.opacity(0.42))
                    .padding(10)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.meijiRed.opacity(0.48), lineWidth: 1.2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.retroGold.opacity(0.48), lineWidth: 0.9)
                .padding(7)
        )
    }
}

struct DiaryMonthOverview: View {
    let cards: [DiaryCard]
    let onAdd: () -> Void

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ja_JP")
        return calendar
    }

    private var days: [Date] {
        let now = Date.now
        guard
            let interval = calendar.dateInterval(of: .month, for: now),
            let daysRange = calendar.range(of: .day, in: .month, for: now)
        else { return [] }

        return daysRange.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: interval.start)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    RetroRibbonLabel(text: "今月の札", tint: Color.meijiBlue)
                    Text("日記を作った日だけ、光が灯ります")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.secondaryText)
                }

                Spacer()

                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Color.meijiRed, in: TaishoBadgeShape())
                        .overlay(TaishoBadgeShape().stroke(Color.retroGold.opacity(0.72), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 7), count: 7), spacing: 9) {
                ForEach(["日", "月", "火", "水", "木", "金", "土"], id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(weekday == "日" ? Color.meijiRed.opacity(0.72) : Color.secondaryText.opacity(0.74))
                        .frame(height: 22)
                        .frame(maxWidth: .infinity)
                }

                ForEach(Array(calendarCells.enumerated()), id: \.offset) { _, day in
                    if let day {
                        let hasCard = cards.contains { calendar.isDate($0.date, inSameDayAs: day) }
                        DiaryCalendarDayCell(
                            dayNumber: calendar.component(.day, from: day),
                            hasCard: hasCard,
                            symbol: calendarSymbol(for: day)
                        )
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
        .padding(20)
        .taishoPanel(tint: Color.meijiBlue)
    }

    private var calendarCells: [Date?] {
        guard let firstDay = days.first else { return [] }
        let leadingBlanks = calendar.component(.weekday, from: firstDay) - 1
        return Array(repeating: nil, count: leadingBlanks) + days.map(Optional.some)
    }

    private func calendarSymbol(for day: Date) -> String {
        switch calendar.component(.day, from: day) % 4 {
        case 0: return "sun.max.fill"
        case 1: return "wind"
        case 2: return "leaf.fill"
        default: return "drop.fill"
        }
    }
}

struct FlowChip: View {
    let number: String
    let title: String

    var body: some View {
        VStack(spacing: 7) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: 0xFFF3D9), Color(hex: 0xEBC7B1), Color.retroRose.opacity(0.86)],
                            center: .topLeading,
                            startRadius: 2,
                            endRadius: 22
                        )
                    )
                    .shadow(color: Color.retroRose.opacity(0.17), radius: 8, x: 0, y: 4)

                Circle()
                    .stroke(Color.retroGold.opacity(0.72), lineWidth: 0.9)
                    .padding(3)

                Text(number)
                    .font(.caption.monospacedDigit().weight(.black))
                    .foregroundStyle(Color.meijiBlue)
            }
            .frame(width: 34, height: 34)

            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.primaryText.opacity(0.82))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FlowLine: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.caption2.weight(.black))
            .foregroundStyle(Color.retroGold.opacity(0.82))
            .frame(width: 10, height: 34)
    }
}

struct DiaryCalendarDayCell: View {
    let dayNumber: Int
    let hasCard: Bool
    let symbol: String

    var body: some View {
        VStack(spacing: 3) {
            Text("\(dayNumber)")
                .font(.caption.monospacedDigit().weight(hasCard ? .bold : .semibold))
                .foregroundStyle(hasCard ? Color.primaryText : Color.secondaryText.opacity(0.8))
                .frame(height: 17)

            if hasCard {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: 0xFFF0BA).opacity(0.98),
                                    Color.retroRose.opacity(0.58),
                                    Color.meijiRed.opacity(0.1)
                                ],
                                center: .center,
                                startRadius: 1,
                                endRadius: 15
                            )
                        )
                        .frame(width: 24, height: 24)
                        .shadow(color: Color.meijiRed.opacity(0.22), radius: 8, x: 0, y: 3)

                    Image(systemName: symbol)
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundStyle(Color.meijiRed.opacity(0.86))
                }
            } else {
                Circle()
                    .fill(Color.primaryText.opacity(0.08))
                    .frame(width: 4, height: 4)
                    .padding(.top, 5)
            }
        }
        .frame(height: 40)
        .frame(maxWidth: .infinity)
        .background(
            hasCard ? Color.retroPaper.opacity(0.52) : Color.retroPaper.opacity(0.28),
            in: RoundedRectangle(cornerRadius: 7, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(hasCard ? Color.retroGold.opacity(0.34) : Color.primaryText.opacity(0.08), lineWidth: 0.8)
        )
    }
}

struct EmptyDiaryHint: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RetroRibbonLabel(text: "最初の一枚を作りましょう", tint: Color.meijiRed)
            Text("写真と短歌が、現代版百人一首のカードとしてメモリーに残ります。")
                .font(.subheadline)
                .foregroundStyle(Color.secondaryText)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .taishoPanel(tint: Color.meijiRed)
    }
}

struct DiaryComposerView: View {
    let onCreate: (DiaryCard) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var factText = ""
    @State private var selectedTone = DiaryTone.joy
    @State private var selectedLowerIndex = 0
    @State private var isStoring = false
    @State private var sparkleBurst = false

    private var currentLowerPhrase: String {
        selectedTone.lowerOptions[safe: selectedLowerIndex] ?? selectedTone.lowerOptions[0]
    }

    private var generatedUpperPhrase: [String] {
        DiaryFactPhraseGenerator.upperPhrase(from: factText, tone: selectedTone)
    }

    private var canStore: Bool {
        !factText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            AppBackground()
            OmikujiPreDrawFantasyLayer()
                .opacity(0.72)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    HeaderView(title: "日記を作成", subtitle: "5秒で一首")

                    FactInputStep(factText: $factText)

                    TonePickerStep(selectedTone: $selectedTone, selectedLowerIndex: $selectedLowerIndex)

                    LowerPhraseSlotStep(
                        tone: selectedTone,
                        selectedIndex: $selectedLowerIndex
                    )

                    if canStore {
                        CompletedTankaStep(
                            upperPhrase: generatedUpperPhrase,
                            lowerPhrase: currentLowerPhrase,
                            mood: selectedTone.mood,
                            isStoring: isStoring
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))

                        Button {
                            storeCard()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "archivebox.fill")
                                Text("日記を棚に納める")
                            }
                            .font(.headline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.white)
                        .background(Color.meijiRed, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.retroGold.opacity(0.48), lineWidth: 1))
                        .shadow(color: Color.meijiRed.opacity(0.22), radius: 14, x: 0, y: 8)
                        .disabled(isStoring)
                        .padding(.top, 2)
                    }

                    Color.clear
                        .frame(height: 1)
                    .padding(.bottom, 110)
                }
                .padding(.horizontal, 22)
                .padding(.top, 22)
            }

            if sparkleBurst {
                DiaryStoreSparkleBurst()
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
        }
    }

    private func storeCard() {
        guard canStore, !isStoring else { return }

        withAnimation(.spring(response: 0.58, dampingFraction: 0.72)) {
            isStoring = true
            sparkleBurst = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.68) {
            onCreate(makeCard())
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.02) {
            dismiss()
        }
    }

    private func makeCard() -> DiaryCard {
        DiaryCard(
            date: .now,
            upperPhrase: generatedUpperPhrase,
            lowerPhrase: currentLowerPhrase,
            mood: selectedTone.mood,
            placeHint: factText.trimmingCharacters(in: .whitespacesAndNewlines),
            photoData: nil
        )
    }
}

enum DiaryTone: String, CaseIterable, Hashable {
    case joy = "喜"
    case sorrow = "憂"
    case calm = "穏"
    case anger = "怒"

    var title: String {
        switch self {
        case .joy: return "うれし"
        case .sorrow: return "もの憂げ"
        case .calm: return "やわらぎ"
        case .anger: return "むっと"
        }
    }

    var tint: Color {
        switch self {
        case .joy: return Color.meijiRed
        case .sorrow: return Color.meijiBlue
        case .calm: return Color.retroSage
        case .anger: return Color(hex: 0x9A513E)
        }
    }

    var mood: CardMood {
        switch self {
        case .joy: return .dawn
        case .sorrow: return .night
        case .calm: return .rain
        case .anger: return .evening
        }
    }

    var lowerOptions: [String] {
        switch self {
        case .joy:
            return [
                "ときめき抱いて 星がほどける",
                "笑みをかくして 夜へしまう",
                "胸の灯だけを そっと連れて"
            ]
        case .sorrow:
            return [
                "憂いをのせて 夜が更ける",
                "ため息ひとつ 灯が揺れる",
                "言えないままに 月へ預ける"
            ]
        case .calm:
            return [
                "静かな息に 明日が香る",
                "湯気のむこうで 心ほどける",
                "やさしい影を 袖にしまって"
            ]
        case .anger:
            return [
                "赤きこころを 風に逃がして",
                "むっとしたまま 星を数える",
                "尖った言葉を 夜へほどいて"
            ]
        }
    }
}

enum DiaryFactPhraseGenerator {
    static func upperPhrase(from fact: String, tone: DiaryTone) -> [String] {
        let cleaned = fact
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "　", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleaned.isEmpty else {
            return ["ひとことを", "入れるだけで", "札になる"]
        }

        let factLine = cleaned.shortPoemLine(limit: 8)
        let bridge: String
        let afterglow: String

        switch tone {
        case .joy:
            bridge = "今日の余韻に"
            afterglow = "光さす"
        case .sorrow:
            bridge = "こころの隅で"
            afterglow = "雨が降る"
        case .calm:
            bridge = "湯気のむこうに"
            afterglow = "風やわし"
        case .anger:
            bridge = "胸の火照りを"
            afterglow = "夜へ置く"
        }

        return [factLine, bridge, afterglow]
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension String {
    func shortPoemLine(limit: Int) -> String {
        let compacted = replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "　", with: "")
        guard compacted.count > limit else { return compacted }
        return String(compacted.prefix(max(1, limit - 1))) + "…"
    }
}

struct QuickDiaryIntro: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bolt.heart.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.retroGold)
                .frame(width: 38, height: 38)
                .background(Color.meijiRed.opacity(0.88), in: Circle())
                .overlay(Circle().stroke(Color(hex: 0xFFF3C8).opacity(0.7), lineWidth: 1))

            VStack(alignment: .leading, spacing: 4) {
                Text("1行だけで、今日が札になる")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.primaryText)
                Text("ボソッと書いて、感情を押すだけ。")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.secondaryText)
            }
        }
        .padding(16)
        .background(Color(hex: 0xFFF8EA).opacity(0.62), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.retroGold.opacity(0.28), lineWidth: 1))
    }
}

struct FactInputStep: View {
    @Binding var factText: String

    var body: some View {
        DiaryFormSection {
            StepSectionTitle(number: "1", title: "今日の事実")

            TextField("例：スタバ新作飲んだ", text: $factText)
                .textFieldStyle(.plain)
                .font(.body)
                .foregroundStyle(Color.primaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 15)
                .background(Color(hex: 0xFFF9F2).opacity(0.9), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.retroGold.opacity(0.28), lineWidth: 0.8))
        }
    }
}

struct UpperPhrasePreview: View {
    let lines: [String]
    let accent: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ForEach(Array(lines.prefix(3).enumerated()).reversed(), id: \.offset) { index, line in
                VerticalPoemLine(
                    text: line,
                    isLowerPhrase: false,
                    accent: accent,
                    compact: false,
                    isOpeningLine: index == 0
                )
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 20)
        .background(Color(hex: 0xFFF8EA).opacity(0.66), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.retroGold.opacity(0.32), lineWidth: 0.9))
    }
}

struct DiaryFormSection<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content
        }
        .padding(16)
        .background {
            ZStack {
                Color(hex: 0xFFF9F2).opacity(0.9)
                WashiPattern()
                    .opacity(0.11)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.meijiRed.opacity(0.22), lineWidth: 0.8))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.retroGold.opacity(0.22), lineWidth: 0.7).padding(4))
    }
}

struct TonePickerStep: View {
    @Binding var selectedTone: DiaryTone
    @Binding var selectedLowerIndex: Int

    var body: some View {
        DiaryFormSection {
            StepSectionTitle(number: "2", title: "今のこころ")

            Picker("今のこころ", selection: $selectedTone) {
                ForEach(DiaryTone.allCases, id: \.self) { tone in
                    Text(tone.rawValue).tag(tone)
                }
            }
            .pickerStyle(.segmented)
            .tint(Color.meijiRed)
            .onChange(of: selectedTone) { _, _ in
                selectedLowerIndex = 0
            }
        }
    }
}

struct ToneStampButton: View {
    let tone: DiaryTone
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                PlumBlossom()
                    .fill(isSelected ? tone.tint : Color(hex: 0xFFF1DE).opacity(0.92))
                    .frame(width: 44, height: 44)
                    .shadow(color: tone.tint.opacity(isSelected ? 0.24 : 0.08), radius: 8, x: 0, y: 4)

                Text(tone.rawValue)
                    .font(.system(size: 21, weight: .black, design: .serif))
                    .foregroundStyle(isSelected ? Color.retroPaper : tone.tint)
            }

            Text(tone.title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(isSelected ? tone.tint : Color.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(isSelected ? Color(hex: 0xFFF8EA).opacity(0.78) : Color(hex: 0xFFF8EA).opacity(0.38), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Color.retroGold.opacity(0.62) : Color.primaryText.opacity(0.09), lineWidth: 1))
    }
}

struct LowerPhraseSlotStep: View {
    let tone: DiaryTone
    @Binding var selectedIndex: Int

    var body: some View {
        DiaryFormSection {
            StepSectionTitle(number: "3", title: "下の句を選ぶ")

            VStack(spacing: 0) {
                ForEach(Array(tone.lowerOptions.enumerated()), id: \.offset) { index, phrase in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            selectedIndex = index
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Text(phrase)
                                .font(.body)
                                .foregroundStyle(Color.primaryText)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            if selectedIndex == index {
                                Image(systemName: "checkmark")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Color.meijiRed)
                            }
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if index < tone.lowerOptions.count - 1 {
                        Divider()
                            .padding(.leading, 14)
                    }
                }
            }
            .background(Color(hex: 0xFFF9F2).opacity(0.9), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.retroGold.opacity(0.24), lineWidth: 0.8))
        }
    }
}

struct LowerPhraseTanzaku: View {
    let phrase: String
    let accent: Color
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            ForEach(Array(phrase.tankaLowerLines().enumerated()).reversed(), id: \.offset) { _, line in
                VerticalPoemLine(text: line, isLowerPhrase: true, accent: accent, compact: true)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 132, alignment: .center)
        .padding(.vertical, 12)
        .background {
            ZStack {
                LinearGradient(colors: [Color(hex: 0xFFF8EA), Color(hex: 0xF3DFBD), accent.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                WashiPattern()
                    .opacity(0.2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(isSelected ? accent.opacity(0.78) : Color.retroGold.opacity(0.28), lineWidth: isSelected ? 1.5 : 0.9))
        .overlay(alignment: .top) {
            Circle()
                .fill(isSelected ? Color.retroGold : Color.primaryText.opacity(0.18))
                .frame(width: 8, height: 8)
                .offset(y: 7)
        }
        .scaleEffect(isSelected ? 1.03 : 0.98)
    }
}

struct CompletedTankaStep: View {
    let upperPhrase: [String]
    let lowerPhrase: String
    let mood: CardMood
    let isStoring: Bool

    var body: some View {
        DiaryFormSection {
            StepSectionTitle(number: "4", title: "短歌日記の完成")

            HStack {
                Spacer()
                TankaOmikujiPreviewCard(
                    upperPhrase: upperPhrase,
                    lowerPhrase: lowerPhrase,
                    accent: mood.accent
                )
                .frame(width: 232, height: 358)
                .scaleEffect(isStoring ? 0.42 : 1)
                .offset(x: isStoring ? 92 : 0, y: isStoring ? 142 : 0)
                .rotationEffect(.degrees(isStoring ? 8 : 0))
                .opacity(isStoring ? 0.28 : 1)
                Spacer()
            }

            HStack(spacing: 8) {
                Image(systemName: "archivebox.fill")
                Text("名前札棚へ、すっと格納")
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.secondaryText)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

struct TankaOmikujiPreviewCard: View {
    let upperPhrase: [String]
    let lowerPhrase: String
    let accent: Color

    private var allLines: [String] {
        Array(upperPhrase.prefix(3)) + lowerPhrase.tankaLowerLines()
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0xFFF8EA), Color(hex: 0xF4DFBE), accent.opacity(0.16)],
                startPoint: .top,
                endPoint: .bottom
            )

            WashiPattern()
                .opacity(0.18)

            TaishoCheckPattern(color: Color.meijiRed.opacity(0.025), tile: 24)

            OrnateOmikujiBorder()
                .stroke(Color.primaryText.opacity(0.46), lineWidth: 1)
                .padding(10)

            OrnateOmikujiBorder()
                .stroke(Color.retroGold.opacity(0.5), lineWidth: 0.8)
                .padding(18)

            HStack(alignment: .top, spacing: 8) {
                ForEach(Array(allLines.enumerated()).reversed(), id: \.offset) { index, line in
                    VerticalPoemLine(
                        text: line,
                        isLowerPhrase: index >= 3,
                        accent: accent,
                        compact: false,
                        isOpeningLine: index == 0
                    )
                }
            }
            .padding(.vertical, 44)
            .padding(.horizontal, 30)

            VStack {
                Text("うたかた日記")
                    .font(UtakataFontStyle.retroMincho(size: 14, weight: .semibold))
                    .foregroundStyle(Color.primaryText.opacity(0.8))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color(hex: 0xFFF9F2).opacity(0.82), in: Capsule())
                    .overlay(Capsule().stroke(Color.retroGold.opacity(0.36), lineWidth: 0.8))
                Spacer()
            }
            .padding(.top, 18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primaryText.opacity(0.4), lineWidth: 1.1))
        .shadow(color: accent.opacity(0.18), radius: 16, x: 0, y: 10)
    }
}

struct DiaryStoreSparkleBurst: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<28, id: \.self) { index in
                    Image(systemName: index.isMultiple(of: 3) ? "sparkles" : "sparkle")
                        .font(.system(size: CGFloat(11 + (index % 5) * 4), weight: .bold))
                        .foregroundStyle(index.isMultiple(of: 2) ? Color.retroGold : Color(hex: 0xF3A8B7))
                        .position(
                            x: proxy.size.width * sparklePositions[index % sparklePositions.count].0,
                            y: proxy.size.height * sparklePositions[index % sparklePositions.count].1
                        )
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .background(Color(hex: 0xFFF8EA).opacity(0.12))
        }
    }

    private var sparklePositions: [(CGFloat, CGFloat)] {
        [
            (0.18, 0.18), (0.32, 0.14), (0.70, 0.16), (0.84, 0.24),
            (0.22, 0.34), (0.46, 0.30), (0.66, 0.36), (0.88, 0.46),
            (0.12, 0.52), (0.35, 0.55), (0.58, 0.50), (0.78, 0.62),
            (0.26, 0.72), (0.48, 0.78), (0.68, 0.76), (0.90, 0.82)
        ]
    }
}

extension View {
    func romanticStepPanel(tint: Color) -> some View {
        background {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: 0xFFF1E8).opacity(0.88),
                        Color(hex: 0xF7D3D9).opacity(0.62),
                        Color(hex: 0xF9E8C4).opacity(0.64)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                TaishoCheckPattern(color: tint.opacity(0.035), tile: 22)
                WashiPattern()
                    .opacity(0.18)
                OmikujiRibbonLine()
                    .stroke(Color.retroGold.opacity(0.16), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                    .rotationEffect(.degrees(-8))
                    .offset(y: -20)
                RetroCornerOrnaments(color: tint.opacity(0.24))
                    .padding(10)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(tint.opacity(0.34), lineWidth: 1.1))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.retroGold.opacity(0.34), lineWidth: 0.8).padding(7))
    }
}

enum DiaryEmotion: String, CaseIterable, Hashable {
    case joy = "嬉しい"
    case fun = "楽しい"
    case relieved = "安心"
    case moved = "じんとした"
    case lonely = "寂しい"
    case tired = "疲れた"
    case bittersweet = "切ない"
    case hopeful = "楽しみ"

    var lowerPhrase: String {
        switch self {
        case .joy:
            return "うれしさそっと 袖にしまって"
        case .fun:
            return "たのしさだけが 足音になる"
        case .relieved:
            return "やすらぐ胸に 灯をともして"
        case .moved:
            return "じんとしたまま 夜へほどける"
        case .lonely:
            return "さみしさ連れて 月まで歩く"
        case .tired:
            return "つかれた今日を 湯気にほどいて"
        case .bittersweet:
            return "せつなさひとつ 風へ預けて"
        case .hopeful:
            return "明日の気配 胸に灯して"
        }
    }

    var tint: Color {
        switch self {
        case .joy: return Color.meijiRed
        case .fun: return Color.retroRose
        case .relieved: return Color.retroSage
        case .moved: return Color.retroGold
        case .lonely: return Color.meijiBlue
        case .tired: return Color.secondaryText
        case .bittersweet: return Color(hex: 0x8B5E72)
        case .hopeful: return Color(hex: 0x8EA18C)
        }
    }

    var symbol: String {
        switch self {
        case .joy: return "heart.fill"
        case .fun: return "sparkles"
        case .relieved: return "leaf.fill"
        case .moved: return "drop.fill"
        case .lonely: return "moon.fill"
        case .tired: return "cloud.fill"
        case .bittersweet: return "wind"
        case .hopeful: return "sunrise.fill"
        }
    }
}

struct EmotionChoiceChip: View {
    let emotion: DiaryEmotion
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: emotion.symbol)
                    .font(.caption.weight(.bold))
                Text(emotion.rawValue)
                    .font(.subheadline.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(isSelected ? Color.retroPaper : Color.primaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 10)
            .background(
                isSelected ? emotion.tint : Color.retroPaper.opacity(0.68),
                in: RoundedRectangle(cornerRadius: 6, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(isSelected ? Color.retroGold.opacity(0.72) : emotion.tint.opacity(0.28), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct FinishedCardView: View {
    let card: DiaryCard
    let onSave: (DiaryCard) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var didSave = false

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 24) {
                Capsule()
                    .fill(Color.primaryText.opacity(0.14))
                    .frame(width: 42, height: 5)
                    .padding(.top, 10)

                PoemCardView(
                    upperPhrase: card.upperPhrase,
                    lowerPhrase: card.lowerPhrase,
                    mood: card.mood,
                    compact: false,
                    photoData: card.photoData
                )
                .aspectRatio(9 / 16, contentMode: .fit)
                .padding(.horizontal, 46)
                .shadow(color: .black.opacity(0.12), radius: 30, x: 0, y: 18)

                HStack(spacing: 12) {
                    Button {
                        onSave(card)
                        didSave = true
                    } label: {
                        Label(didSave ? "保存済み" : "保存", systemImage: didSave ? "checkmark" : "tray.and.arrow.down")
                    }
                    .buttonStyle(.softPill)

                    Button {
                        didSave = true
                    } label: {
                        Label("ストーリー共有", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.softPill)
                }

                Button("書き直す") {
                    dismiss()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.secondaryText)

                Spacer(minLength: 10)
            }
            .padding(.horizontal, 20)
        }
    }
}

struct PhraseChoiceButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.utakataAccent : Color.secondaryText.opacity(0.45))
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.primaryText)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 8)
            }
            .padding(18)
            .background(
                isSelected ? Color.utakataAccent.opacity(0.16) : Color.cardFill,
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? Color.utakataAccent.opacity(0.65) : .white.opacity(0.7), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct CustomLowerPhraseField: View {
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Label("自分で書く", systemImage: "pencil.line")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.secondaryText)

            TextField("例：何もない今日を そっと抱える", text: $text, axis: .vertical)
                .font(.headline)
                .foregroundStyle(Color.primaryText)
                .lineLimit(2...4)
                .padding(16)
                .background(Color.white.opacity(0.48), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(text.isEmpty ? .white.opacity(0.68) : Color.utakataAccent.opacity(0.55), lineWidth: 1)
                )
        }
        .padding(16)
        .background(Color.cardFill, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.72), lineWidth: 1)
        )
    }
}

struct DiarySourcePicker: View {
    let photoData: Data?
    @Binding var selectedItem: PhotosPickerItem?
    let onCameraTap: () -> Void

    private var selectedImage: Image? {
        guard
            let photoData,
            let uiImage = UIImage(data: photoData)
        else { return nil }

        return Image(uiImage: uiImage)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            StepSectionTitle(number: "1", title: "写真を選ぶ / 撮る")

            HStack(spacing: 12) {
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    SourceActionTile(title: "写真を選択", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(.plain)

                Button(action: onCameraTap) {
                    SourceActionTile(title: "カメラで撮影", systemImage: "camera")
                }
                .buttonStyle(.plain)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.retroPaper.opacity(0.56))
                TaishoCheckPattern(color: Color.meijiBlue.opacity(0.08), tile: 18)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                if let selectedImage {
                    selectedImage
                        .resizable()
                        .scaledToFill()
                        .overlay(
                            LinearGradient(colors: [.clear, .black.opacity(0.18)], startPoint: .top, endPoint: .bottom)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(Color.utakataAccent)
                        Text("写真を入れると、上の句が表示されます")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.secondaryText)
                    }
                }
            }
            .frame(height: 226)
            .clipped()
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.meijiBlue.opacity(0.42), lineWidth: 1)
            )
        }
        .padding(18)
        .taishoPanel(tint: Color.meijiBlue)
    }
}

struct StepSectionTitle: View {
    let number: String
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            Text(number)
                .font(.caption.monospacedDigit().weight(.bold))
                .foregroundStyle(Color.retroPaper)
                .frame(width: 26, height: 26)
                .background(Color.meijiRed, in: TaishoBadgeShape())
                .overlay(TaishoBadgeShape().stroke(Color.retroGold.opacity(0.62), lineWidth: 1))

            Text(title)
                .font(.system(size: 20, weight: .semibold, design: .serif))
                .foregroundStyle(Color.primaryText)
        }
    }
}

struct SourceActionTile: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.headline.weight(.bold))
            Text(title)
                .font(.subheadline.weight(.bold))
        }
        .foregroundStyle(Color.primaryText)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.retroPaper.opacity(0.72), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .stroke(Color.primaryText.opacity(0.28), lineWidth: 1)
        )
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImage: onImage, onCancel: onCancel)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImage: (UIImage) -> Void
        let onCancel: () -> Void

        init(onImage: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onImage = onImage
            self.onCancel = onCancel
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImage(image)
            } else {
                onCancel()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
    }
}
