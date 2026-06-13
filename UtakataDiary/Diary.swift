import SwiftUI
import PhotosUI
import UIKit
import ImageIO
import CoreLocation
#if canImport(WeatherKit)
import WeatherKit
#endif
#if canImport(MusicKit)
import MusicKit
#endif

struct TodayView: View {
    @Binding var savedCards: [DiaryCard]
    var showsCreateButton = true
    var canDrawMikuji = false
    var isMikujiDrawnToday = false
    var mikujiStreak = 0
    let onOpenSettings: () -> Void
    var onOpenMikuji: () -> Void = {}
    let onDiaryCreated: (Date) -> Void
    @State private var showingComposer = false
    @State private var selectedDate = Date.now
    @State private var visibleMonth = Date.now

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ja_JP")
        return calendar
    }

    private var selectedCards: [DiaryCard] {
        savedCards.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                OmikujiPreDrawFantasyLayer()
                    .opacity(0.52)
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        ScreenHeaderWithSettings(
                            title: "日記",
                            subtitle: "カレンダー",
                            onOpenSettings: onOpenSettings,
                            canDrawMikuji: canDrawMikuji,
                            isMikujiDrawnToday: isMikujiDrawnToday,
                            mikujiStreak: mikujiStreak,
                            onOpenMikuji: onOpenMikuji
                        )
                            .padding(.top, 4)

                        DiaryCalendarBoard(
                            cards: savedCards,
                            visibleMonth: $visibleMonth,
                            selectedDate: $selectedDate
                        )

                        DiarySelectedDayLog(
                            date: selectedDate,
                            cards: selectedCards
                        ) {
                            showingComposer = true
                        }

                        Spacer(minLength: 170)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 112)
                }

                if showsCreateButton {
                    FloatingDiaryActionButton {
                        showingComposer = true
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 88)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingComposer) {
                DiaryComposerView { card in
                    savedCards.insert(card, at: 0)
                    LatestTankaWidgetStore.save(date: card.date, upperPhrase: card.upperPhrase, lowerPhrase: card.lowerPhrase)
                    selectedDate = card.date
                    visibleMonth = card.date
                    onDiaryCreated(card.date)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }
}

struct DiaryCalendarBoard: View {
    let cards: [DiaryCard]
    @Binding var visibleMonth: Date
    @Binding var selectedDate: Date

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ja_JP")
        return calendar
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: visibleMonth)
    }

    var body: some View {
        VStack(spacing: 13) {
            HStack {
                Button {
                    moveMonth(-1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.meijiRed.opacity(0.78))
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)

                Spacer()

                Text(monthTitle)
                    .font(UtakataFontStyle.rounded(size: 22, weight: .semibold))
                    .foregroundStyle(Color.primaryText)

                Spacer()

                Button {
                    moveMonth(1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.meijiRed.opacity(0.78))
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 9) {
                ForEach(["月", "火", "水", "木", "金", "土", "日"], id: \.self) { weekday in
                    Text(weekday)
                        .font(UtakataFontStyle.rounded(size: 13, weight: .semibold))
                        .foregroundStyle(Color.secondaryText.opacity(0.86))
                        .frame(maxWidth: .infinity)
                }

                ForEach(calendarCells, id: \.self) { date in
                    let hasCard = cards.contains { calendar.isDate($0.date, inSameDayAs: date) }
                    DiaryLargeCalendarDayCell(
                        date: date,
                        belongsToVisibleMonth: calendar.isDate(date, equalTo: visibleMonth, toGranularity: .month),
                        hasCard: hasCard,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        symbol: calendarSymbol(for: date)
                    ) {
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                            selectedDate = date
                            if !calendar.isDate(date, equalTo: visibleMonth, toGranularity: .month) {
                                visibleMonth = date
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 14)
        .padding(.bottom, 16)
        .background {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: 0xFFF9F1).opacity(0.92), Color(hex: 0xF8E3D6).opacity(0.82)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                WashiPattern()
                    .opacity(0.18)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.meijiRed.opacity(0.24), lineWidth: 1.0))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.retroGold.opacity(0.34), lineWidth: 0.8).padding(6))
        .shadow(color: Color.meijiRed.opacity(0.08), radius: 18, x: 0, y: 8)
    }

    private var calendarCells: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: visibleMonth) else { return [] }
        let firstDay = monthInterval.start
        let weekday = calendar.component(.weekday, from: firstDay)
        let mondayBasedOffset = (weekday + 5) % 7
        let gridStart = calendar.date(byAdding: .day, value: -mondayBasedOffset, to: firstDay) ?? firstDay
        return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: gridStart) }
    }

    private func moveMonth(_ value: Int) {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
            visibleMonth = calendar.date(byAdding: .month, value: value, to: visibleMonth) ?? visibleMonth
            selectedDate = calendar.dateInterval(of: .month, for: visibleMonth)?.start ?? visibleMonth
        }
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

struct DiaryLargeCalendarDayCell: View {
    let date: Date
    let belongsToVisibleMonth: Bool
    let hasCard: Bool
    let isSelected: Bool
    let symbol: String
    let action: () -> Void

    private var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Text("\(dayNumber)")
                    .font(UtakataFontStyle.rounded(size: 17, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(textColor)
                    .monospacedDigit()

                if hasCard {
                    Image(systemName: symbol)
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundStyle(isSelected ? Color.retroPaper : Color.meijiRed.opacity(0.82))
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 8, height: 8)
                }
            }
            .frame(height: 40)
            .frame(maxWidth: .infinity)
            .background {
                if isSelected {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: 0xFAD7D9), Color.retroRose.opacity(0.72), Color.meijiRed.opacity(0.38)],
                                center: .topLeading,
                                startRadius: 4,
                                endRadius: 34
                            )
                        )
                        .frame(width: 40, height: 40)
                } else if hasCard {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: 0xFFF3C8), Color.retroGold.opacity(0.34), .clear],
                                center: .center,
                                startRadius: 2,
                                endRadius: 28
                            )
                        )
                        .frame(width: 32, height: 32)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(dayNumber)日")
    }

    private var textColor: Color {
        if isSelected { return Color.retroPaper }
        return belongsToVisibleMonth ? Color.primaryText : Color.secondaryText.opacity(0.54)
    }
}

struct DiarySelectedDayLog: View {
    let date: Date
    let cards: [DiaryCard]
    let onCreate: () -> Void

    private var firstCard: DiaryCard? { cards.first }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(date.japaneseMonthDay)
                        .font(UtakataFontStyle.retroMincho(size: 23, weight: .semibold))
                        .foregroundStyle(Color.primaryText)
                    Text(cards.isEmpty ? "投稿がありません" : "\(cards.count)枚のうたかた")
                        .font(UtakataFontStyle.rounded(size: 13, weight: .medium))
                        .foregroundStyle(Color.secondaryText)
                }

                Spacer()

                if cards.isEmpty {
                    Button(action: onCreate) {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color.retroPaper)
                            .frame(width: 36, height: 36)
                            .background(Color.meijiRed, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }

            if !cards.isEmpty {
                VStack(spacing: 12) {
                    ForEach(cards) { card in
                        MemoryPreviewCard(card: card)
                    }
                }
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Color.meijiRed.opacity(0.72))
                    Text("この日の光や気持ちは、まだ札になっていません。")
                        .font(UtakataFontStyle.rounded(size: 14, weight: .medium))
                        .foregroundStyle(Color.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 34)
                .background(Color.retroPaper.opacity(0.44), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.retroGold.opacity(0.28), lineWidth: 0.9))
            }
        }
        .padding(18)
        .taishoPanel(tint: firstCard?.mood.accent ?? Color.meijiRed)
    }
}

struct LegacyDiaryHome: View {
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
                    savedCards.insert(card, at: 0)
                    LatestTankaWidgetStore.save(date: card.date, upperPhrase: card.upperPhrase, lowerPhrase: card.lowerPhrase)
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
                    Text("写真を選択 / 撮る → 上の句 → 下の句 → 一枚の札へ")
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
            Text("写真と短歌が、現代版百人一首のカードとして思い出に残ります。")
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
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var photoTakenAt: Date?
    @State private var showingCamera = false
    @State private var showingPhotoLibrary = false
    @State private var mode = DiaryComposerMode.ai
    @State private var factText = ""
    @State private var manualUpperText = ""
    @State private var manualLowerText = ""
    @State private var manualHint: String?
    @State private var selectedTone = DiaryTone.joy
    @State private var selectedAILowerIndex = 0
    @State private var aiCustomLowerText = ""
    @State private var selectedLowerFirstIndex = 0
    @State private var selectedLowerSecondIndex = 0
    @State private var isStoring = false
    @State private var sparkleBurst = false
    @State private var ambientContext = AmbientAIContext()
    @State private var composerNotice: ComposerNotice?
    @State private var generationSeed = UUID()
    @State private var shareImage: UtakataShareImagePayload?
    @State private var isPreparingShareImage = false

    private var aiSuggestionRequest: AISuggestionRequest {
        AISuggestionRequest(
            photoDescription: PhotoPhraseGenerator.description(from: photoData),
            factInput: factText,
            mood: selectedTone,
            weatherKeyword: ambientContext.weatherKeyword,
            musicMood: ambientContext.musicMood,
            photoTakenAt: photoTakenAt,
            generationSeed: generationSeed
        )
    }

    private var aiGenerationState: AIComposerGenerationState {
        AIComposerSuggestion.generate(request: aiSuggestionRequest)
    }

    private var aiLowerSuggestions: [String] {
        switch aiGenerationState {
        case .success(let suggestion):
            return suggestion.lowerOptions
        case .failure:
            return AIComposerSuggestion.fallback.lowerOptions
        }
    }

    private var selectedAILowerPhrase: String {
        if selectedAILowerIndex == aiLowerSuggestions.count {
            return aiCustomLowerText.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return aiLowerSuggestions[safe: selectedAILowerIndex] ?? aiLowerSuggestions[0]
    }

    private var currentLowerPhrase: String {
        selectedAILowerPhrase
    }

    private var effectiveLowerPhrase: String {
        switch mode {
        case .ai:
            return currentLowerPhrase
        case .manual:
            return manualLowerText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private var generatedUpperPhrase: [String] {
        switch aiGenerationState {
        case .success(let suggestion):
            return suggestion.upperPhrase
        case .failure:
            return AIComposerSuggestion.fallback.upperPhrase
        }
    }

    private var effectiveUpperPhrase: [String] {
        switch mode {
        case .ai:
            return generatedUpperPhrase
        case .manual:
            return DiaryManualPhraseFormatter.upperLines(from: manualUpperText)
        }
    }

    private var canStore: Bool {
        switch mode {
        case .ai:
            return !factText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !effectiveLowerPhrase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .manual:
            return !manualUpperText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !manualLowerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var body: some View {
        ZStack {
            AppBackground()
            OmikujiPreDrawFantasyLayer()
                .opacity(0.72)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    HeaderView(title: "日記を作成", subtitle: "5秒で一首")

                    HStack(alignment: .center, spacing: 12) {
                        DiaryComposerModeSwitcher(mode: $mode)

                        DiaryPhotoMenuButton(
                            photoData: photoData,
                            onCameraTap: { showingCamera = true },
                            onLibraryTap: { showingPhotoLibrary = true }
                        )
                    }

                    LetterPaperDivider()
                        .padding(.vertical, 2)

                    if let composerNotice {
                        ComposerNoticeView(notice: composerNotice) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                self.composerNotice = nil
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    if case .failure = aiGenerationState, mode == .ai, !factText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        ComposerNoticeView(
                            notice: ComposerNotice(
                                title: "今は短歌が詠めません",
                                message: "通信や解析の調子が悪い時は、少し時間をおいてもう一度試してください。入力した内容はそのまま残ります。",
                                symbol: "sparkles"
                            )
                        )
                    }

                    if mode == .ai {
                        FactInputStep(factText: $factText)
                    } else {
                        ManualTextAreaStep(
                            number: "1",
                            title: "上の句を紡ぐ",
                            placeholder: "例：夕暮れの駅で、雨あがりの光を見た",
                            text: $manualUpperText,
                            hint: manualHint,
                            onHint: showManualHint
                        )
                    }

                    TonePickerStep(
                        selectedTone: $selectedTone,
                        selectedLowerFirstIndex: $selectedLowerFirstIndex,
                        selectedLowerSecondIndex: $selectedLowerSecondIndex
                    )

                    if mode == .ai {
                        AITankaFlowStep(
                            tone: selectedTone,
                            upperLines: generatedUpperPhrase,
                            lowerOptions: aiLowerSuggestions,
                            selectedLowerIndex: $selectedAILowerIndex,
                            customLowerText: $aiCustomLowerText
                        )
                    } else {
                        ManualTextAreaStep(
                            number: "3",
                            title: "下の句を入力する",
                            placeholder: "例：手紙を綴るように 今日をしまう",
                            text: $manualLowerText,
                            hint: manualHint,
                            onHint: showManualHint
                        )
                    }

                    if canStore {
                        CompletedTankaStep(
                            upperPhrase: effectiveUpperPhrase,
                            lowerPhrase: effectiveLowerPhrase,
                            mood: selectedTone.mood,
                            photoData: photoData,
                            weatherEffect: ambientContext.weatherEffect,
                            isStoring: isStoring
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))

                        Button {
                            storeCard()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "archivebox.fill")
                                Text("この札を保存する")
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

                        if let shareImage {
                            ShareLink(
                                item: shareImage,
                                preview: SharePreview(
                                    "うたかたの一筆箋",
                                    image: Image(uiImage: UIImage(data: shareImage.pngData) ?? UIImage())
                                )
                            ) {
                                HStack(spacing: 10) {
                                    Image(systemName: "square.and.arrow.up.fill")
                                    Text("シェア先を選ぶ")
                                }
                                .utakataFont(style: .button)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.white)
                            .background(Color.meijiRed, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.retroGold.opacity(0.48), lineWidth: 1))
                            .transition(.opacity.combined(with: .scale(scale: 0.98)))
                        } else {
                            Button {
                                prepareShareImage()
                            } label: {
                                HStack(spacing: 10) {
                                    if isPreparingShareImage {
                                        ProgressView()
                                            .tint(Color.meijiRed)
                                    } else {
                                        Image(systemName: "square.and.arrow.up")
                                    }
                                    Text(isPreparingShareImage ? "一筆箋を準備中..." : "うたかたの一筆箋を作る")
                                }
                                .utakataFont(style: .button)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(Color.meijiRed)
                            .background(Color(hex: 0xFFF9F2).opacity(0.82), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.retroGold.opacity(0.42), lineWidth: 1))
                            .disabled(isStoring || isPreparingShareImage)
                        }
                    }

                    Color.clear
                        .frame(height: 1)
                    .padding(.bottom, 110)
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
            }

            if sparkleBurst {
                DiaryStoreSparkleBurst()
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                do {
                    guard let data = try await newItem?.loadTransferable(type: Data.self) else { return }
                    let takenAt = PhotoCaptureDateReader.captureDate(from: data)
                    guard let resizedData = UIImage.diaryStorageJPEGData(from: data) else {
                        await MainActor.run {
                            showComposerNotice(
                                title: "写真を読み込めませんでした",
                                message: "別の写真を選ぶか、少し時間をおいてもう一度試してください。",
                                symbol: "photo"
                            )
                        }
                        return
                    }

                    await MainActor.run {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            photoData = resizedData
                            photoTakenAt = takenAt
                            generationSeed = UUID()
                            composerNotice = nil
                        }
                    }
                } catch {
                    await MainActor.run {
                        showComposerNotice(
                            title: "写真を読み込めませんでした",
                            message: "写真ライブラリの状態を確認して、もう一度試してください。",
                            symbol: "photo"
                        )
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker { image in
                photoData = image.diaryStorageJPEGData()
                photoTakenAt = Date()
                generationSeed = UUID()
                showingCamera = false
            } onCancel: {
                showingCamera = false
            }
            .ignoresSafeArea()
        }
        .photosPicker(
            isPresented: $showingPhotoLibrary,
            selection: $selectedPhotoItem,
            matching: .images
        )
        .task {
            ambientContext = await ContextManager.shared.currentContext()
        }
    }

    private func showComposerNotice(title: String, message: String, symbol: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            composerNotice = ComposerNotice(title: title, message: message, symbol: symbol)
        }
    }

    private func showManualHint() {
        withAnimation(.easeInOut(duration: 0.2)) {
            manualHint = DiaryManualHintGenerator.hint(
                upperText: manualUpperText,
                factText: factText,
                tone: selectedTone,
                hasPhoto: photoData != nil
            )
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

    private func prepareShareImage() {
        guard !isPreparingShareImage else { return }

        shareImage = nil
        isPreparingShareImage = true

        Task {
            await Task.yield()

            guard let image = UtakataLetterShareRenderer.render(
                upperPhrase: effectiveUpperPhrase,
                lowerPhrase: effectiveLowerPhrase,
                mood: selectedTone.mood,
                photoData: photoData,
                weatherEffect: ambientContext.weatherEffect
            ),
            let pngData = image.pngData(),
            !pngData.isEmpty else {
                await MainActor.run {
                    isPreparingShareImage = false
                    showComposerNotice(
                        title: "一筆箋を作れませんでした",
                        message: "画像の生成に失敗しました。少し時間をおいて、もう一度試してください。",
                        symbol: "square.and.arrow.up"
                    )
                }
                return
            }

            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.22)) {
                    isPreparingShareImage = false
                    shareImage = UtakataShareImagePayload(pngData: pngData)
                    composerNotice = nil
                }
            }
        }
    }

    private func makeCard() -> DiaryCard {
        DiaryCard(
            date: .now,
            upperPhrase: effectiveUpperPhrase,
            lowerPhrase: effectiveLowerPhrase,
            mood: selectedTone.mood,
            placeHint: mode == .ai
                ? factText.trimmingCharacters(in: .whitespacesAndNewlines)
                : manualUpperText.trimmingCharacters(in: .whitespacesAndNewlines),
            photoData: photoData
        )
    }
}

struct ComposerNotice: Equatable {
    let title: String
    let message: String
    let symbol: String
}

struct ComposerNoticeView: View {
    let notice: ComposerNotice
    var onDismiss: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: notice.symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.meijiRed)
                .frame(width: 30, height: 30)
                .background(Color.retroPaper.opacity(0.72), in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(notice.title)
                    .font(UtakataFontStyle.rounded(size: 14, weight: .semibold))
                    .foregroundStyle(Color.primaryText)

                Text(notice.message)
                    .font(UtakataFontStyle.rounded(size: 12, weight: .regular))
                    .foregroundStyle(Color.secondaryText)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.secondaryText.opacity(0.72))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("メッセージを閉じる")
            }
        }
        .padding(14)
        .background(Color(hex: 0xFFF9F2).opacity(0.88), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.meijiRed.opacity(0.18), lineWidth: 0.8))
        .overlay(RoundedRectangle(cornerRadius: 11).stroke(Color.retroGold.opacity(0.24), lineWidth: 0.7).padding(5))
        .shadow(color: Color.meijiRed.opacity(0.08), radius: 10, x: 0, y: 5)
    }
}

enum DiaryComposerMode: String, CaseIterable, Hashable {
    case ai
    case manual

    var title: String {
        switch self {
        case .ai: return "おまかせ（AI）"
        case .manual: return "じぶん綴り（手書き）"
        }
    }
}

struct DiaryComposerModeSwitcher: View {
    @Binding var mode: DiaryComposerMode

    var body: some View {
        HStack(spacing: 0) {
            ForEach(DiaryComposerMode.allCases, id: \.self) { item in
                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                        mode = item
                    }
                } label: {
                    Text(item.title)
                        .font(UtakataFontStyle.rounded(size: 14, weight: .semibold))
                        .foregroundStyle(mode == item ? Color.retroPaper : Color.primaryText.opacity(0.76))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            mode == item
                            ? LinearGradient(
                                colors: [Color.meijiRed, Color.retroRose],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.clear, Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(5)
        .background {
            ZStack {
                Color(hex: 0xFFF9F2).opacity(0.86)
                WashiPattern()
                    .opacity(0.10)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.meijiRed.opacity(0.22), lineWidth: 0.8))
        .overlay(RoundedRectangle(cornerRadius: 11).stroke(Color.retroGold.opacity(0.26), lineWidth: 0.7).padding(4))
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

    var lowerFirstOptions: [String] {
        switch self {
        case .joy:
            return [
                "ときめき抱いて",
                "笑みをかくして",
                "胸の灯だけを"
            ]
        case .sorrow:
            return [
                "憂いをのせて",
                "ため息ひとつ",
                "言えないままに"
            ]
        case .calm:
            return [
                "静かな息に",
                "湯気のむこうで",
                "やさしい影を"
            ]
        case .anger:
            return [
                "赤きこころを",
                "むっとしたまま",
                "尖った言葉を"
            ]
        }
    }

    func lowerSecondOptions(for firstIndex: Int) -> [String] {
        switch self {
        case .joy:
            return [
                ["星がほどける", "夜へしまう", "そっと連れて"],
                ["夜へしまう", "星がほどける", "そっと連れて"],
                ["そっと連れて", "夜へしまう", "星がほどける"]
            ][safe: firstIndex] ?? ["星がほどける", "夜へしまう", "そっと連れて"]
        case .sorrow:
            return [
                ["夜が更ける", "灯が揺れる", "月へ預ける"],
                ["灯が揺れる", "夜が更ける", "月へ預ける"],
                ["月へ預ける", "灯が揺れる", "夜が更ける"]
            ][safe: firstIndex] ?? ["夜が更ける", "灯が揺れる", "月へ預ける"]
        case .calm:
            return [
                ["明日が香る", "心ほどける", "袖にしまって"],
                ["心ほどける", "明日が香る", "袖にしまって"],
                ["袖にしまって", "心ほどける", "明日が香る"]
            ][safe: firstIndex] ?? ["明日が香る", "心ほどける", "袖にしまって"]
        case .anger:
            return [
                ["風に逃がして", "星を数える", "夜へほどいて"],
                ["星を数える", "風に逃がして", "夜へほどいて"],
                ["夜へほどいて", "星を数える", "風に逃がして"]
            ][safe: firstIndex] ?? ["風に逃がして", "星を数える", "夜へほどいて"]
        }
    }

    var lowerOptions: [String] {
        lowerFirstOptions.enumerated().map { index, first in
            "\(first) \(lowerSecondOptions(for: index)[0])"
        }
    }
}

enum DiaryFactPhraseGenerator {
    static func upperPhrase(request: AISuggestionRequest) -> [String] {
        DynamicTankaPhraseEngine.generate(request: request).upperPhrase
    }

    static func upperPhrase(from fact: String, tone: DiaryTone) -> [String] {
        upperPhrase(from: fact, tone: tone, photoDescription: nil)
    }

    static func upperPhrase(from fact: String, tone: DiaryTone, photoDescription: String?) -> [String] {
        let request = AISuggestionRequest(
            photoDescription: photoDescription,
            factInput: fact,
            mood: tone,
            weatherKeyword: "未取得",
            musicMood: "未取得",
            photoTakenAt: nil,
            generationSeed: UUID()
        )
        return DynamicTankaPhraseEngine.generate(request: request).upperPhrase
    }
}

struct DynamicTankaSuggestion {
    let upperPhrase: [String]
    let lowerOptions: [String]
}

enum DynamicTankaPhraseEngine {
    private enum TimeTone: String {
        case morning
        case daytime
        case evening
        case night
    }

    private struct PhraseBank {
        let upperPhrases: [String]
        let middlePhrases: [String]
        let lowerPhrases: [String]
        let lowerFirst: [String]
        let lowerSecond: [String]
    }

    static func generate(request: AISuggestionRequest) -> DynamicTankaSuggestion {
        let timeTone = timeTone(from: request.photoTakenAt ?? Date())
        let source = [
            request.photoDescription ?? "",
            request.factInput,
            request.weatherKeyword,
            request.musicMood,
            request.mood.rawValue,
            request.generationSeed.uuidString,
            timeTone.rawValue
        ].joined(separator: "|")
        let seed = stableSeed(from: source)
        let keyword = sceneKeyword(from: request)
        let bank = phraseBank(for: timeTone, mood: request.mood, keyword: keyword)

        let upper = pick(from: bank.upperPhrases, seed: seed, salt: 1)
        let middle = pick(from: bank.middlePhrases, seed: seed, salt: 2)
        let lower = pick(from: bank.lowerPhrases, seed: seed, salt: 3)

        let lowerOptions = (0..<3).map { index in
            let first = pick(from: bank.lowerFirst, seed: seed, salt: 10 + index * 2)
            let second = pick(from: bank.lowerSecond, seed: seed, salt: 11 + index * 2)
            return "\(first) \(second)"
        }

        return DynamicTankaSuggestion(
            upperPhrase: [upper, middle, lower],
            lowerOptions: lowerOptions
        )
    }

    private static func phraseBank(for timeTone: TimeTone, mood: DiaryTone, keyword: String) -> PhraseBank {
        let moodUpper: [String]
        let moodMiddle: [String]
        let moodLower: [String]
        let lowerFirst: [String]
        let lowerSecond: [String]

        switch mood {
        case .joy:
            moodUpper = ["笑みひとつ", "胸の奥", "\(keyword)きらり"]
            moodMiddle = ["小さな光", "今日は少し", "弾む足音"]
            moodLower = ["花のよう", "星がほどけ", "頬に灯る"]
            lowerFirst = ["うれしい余韻", "笑った声を", "胸の灯だけ"]
            lowerSecond = ["袖にしまって", "夜へ連れてく", "花へほどける"]
        case .sorrow:
            moodUpper = ["ため息を", "\(keyword)かすむ", "言えぬまま"]
            moodMiddle = ["窓辺にそっと", "静かな影が", "胸に残って"]
            moodLower = ["月へゆく", "夜に沈む", "灯がにじむ"]
            lowerFirst = ["さみしい気持ち", "泣けない夜を", "言えない言葉"]
            lowerSecond = ["月が聞いてる", "そっと抱きしめ", "夜へ預ける"]
        case .calm:
            moodUpper = ["息ひとつ", "\(keyword)やわく", "今日の端"]
            moodMiddle = ["湯気のむこう", "静けさだけが", "風にほどけて"]
            moodLower = ["ここにある", "ほどけてく", "明日へ向く"]
            lowerFirst = ["安心ひとつ", "静かな今日を", "やさしい影を"]
            lowerSecond = ["胸に灯して", "そっとたたんで", "袖にしまって"]
        case .anger:
            moodUpper = ["熱ひとつ", "\(keyword)赤く", "むっとして"]
            moodMiddle = ["言葉の角を", "胸の火だけを", "風に預けて"]
            moodLower = ["夜を待つ", "ほどいてく", "息をする"]
            lowerFirst = ["怒ったわたし", "言葉の熱を", "尖った気持ち"]
            lowerSecond = ["ちゃんと守ろう", "風に逃がして", "夜へほどいて"]
        }

        switch timeTone {
        case .morning:
            return PhraseBank(
                upperPhrases: ["朝の窓", "白い息", "光さす", "\(keyword)ひかる"] + moodUpper,
                middlePhrases: ["まだ名のない日", "カーテン揺れて", "新しい風"] + moodMiddle,
                lowerPhrases: ["希望めく", "そっと始まる", "空がほどける"] + moodLower,
                lowerFirst: ["今日のはじまり", "明るいほうへ", "まぶしい予感"] + lowerFirst,
                lowerSecond: ["靴を鳴らして", "そっと歩き出す", "胸にしまって"] + lowerSecond
            )
        case .daytime:
            return PhraseBank(
                upperPhrases: ["昼の街", "風わたり", "陽のにおい", "\(keyword)映す"] + moodUpper,
                middlePhrases: ["人波のなか", "眩しさのなか", "少し背伸びで"] + moodMiddle,
                lowerPhrases: ["影が揺れ", "声が残る", "空へ抜ける"] + moodLower,
                lowerFirst: ["今日のまんなか", "光の粒を", "歩いた跡を"] + lowerFirst,
                lowerSecond: ["手のひらに置く", "そっと抱えて", "午後へ流して"] + lowerSecond
            )
        case .evening:
            return PhraseBank(
                upperPhrases: ["夕暮れに", "帰り道", "茜さす", "\(keyword)染まる"] + moodUpper,
                middlePhrases: ["影が伸びゆく", "街灯ひとつ", "一日ほどけ"] + moodMiddle,
                lowerPhrases: ["胸に灯る", "夜へ渡る", "頬を照らす"] + moodLower,
                lowerFirst: ["今日の終わりを", "夕日の端で", "言葉の残り"] + lowerFirst,
                lowerSecond: ["そっとたたんで", "夜へ手渡す", "胸にしまおう"] + lowerSecond
            )
        case .night:
            return PhraseBank(
                upperPhrases: ["夜の窓", "月あかり", "眠る街", "\(keyword)しずか"] + moodUpper,
                middlePhrases: ["今日をほどいて", "灯りを落とし", "まぶたの裏に"] + moodMiddle,
                lowerPhrases: ["夢へゆく", "息を休める", "星がにじむ"] + moodLower,
                lowerFirst: ["おつかれさまと", "夜のしじまに", "今日のわたしを"] + lowerFirst,
                lowerSecond: ["自分へ言おう", "そっと預ける", "やさしく眠る"] + lowerSecond
            )
        }
    }

    private static func timeTone(from date: Date) -> TimeTone {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<11: return .morning
        case 11..<16: return .daytime
        case 16..<20: return .evening
        default: return .night
        }
    }

    private static func sceneKeyword(from request: AISuggestionRequest) -> String {
        let source = [
            request.photoDescription ?? "",
            request.factInput,
            request.weatherKeyword
        ].joined(separator: " ")

        if source.contains("駅") || source.contains("電車") { return "駅の灯" }
        if source.contains("空") || source.contains("雲") || source.contains("青") { return "空" }
        if source.contains("雨") || source.contains("濡") { return "雨粒" }
        if source.contains("花") || source.contains("桜") { return "花びら" }
        if source.contains("海") || source.contains("川") { return "水面" }
        if source.contains("学校") || source.contains("授業") { return "教室" }
        if source.contains("カフェ") || source.contains("喫茶") { return "珈琲" }
        if source.contains("家") || source.contains("部屋") { return "部屋の灯" }
        if let keyword = request.concreteKeywords.first {
            return keyword.shortPoemLine(limit: 5)
        }
        return request.mood.defaultImageWord
    }

    private static func pick(from phrases: [String], seed: Int, salt: Int) -> String {
        guard !phrases.isEmpty else { return "" }
        let index = abs(seed &+ salt &* 31) % phrases.count
        return phrases[index]
    }

    private static func stableSeed(from text: String) -> Int {
        text.unicodeScalars.reduce(5381) { partial, scalar in
            ((partial << 5) &+ partial) &+ Int(scalar.value)
        }
    }
}

enum PhotoCaptureDateReader {
    static func captureDate(from data: Data) -> Date? {
        guard
            let source = CGImageSourceCreateWithData(data as CFData, nil),
            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        else {
            return nil
        }

        let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any]
        let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any]
        let candidates = [
            exif?[kCGImagePropertyExifDateTimeOriginal] as? String,
            exif?[kCGImagePropertyExifDateTimeDigitized] as? String,
            tiff?[kCGImagePropertyTIFFDateTime] as? String
        ].compactMap { $0 }

        for candidate in candidates {
            if let date = exifDateFormatter.date(from: candidate) {
                return date
            }
        }

        return nil
    }

    private static let exifDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter
    }()
}

enum WeatherVisualEffect: String, Hashable {
    case none
    case sunlight
    case rain
    case cloud
    case snow
    case night
}

struct AmbientAIContext: Equatable {
    var weatherKeyword: String = "未取得"
    var musicMood: String = "未取得"
    var weatherEffect: WeatherVisualEffect = .none
}

final class ContextManager: NSObject, CLLocationManagerDelegate {
    static let shared = ContextManager()

    private let locationManager = CLLocationManager()

    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }

    func currentContext() async -> AmbientAIContext {
        async let weather = weatherContext()
        async let music = fetchMusicInfo()
        let weatherResult = await weather
        return AmbientAIContext(
            weatherKeyword: weatherResult.keyword,
            musicMood: await music,
            weatherEffect: weatherResult.effect
        )
    }

    func fetchWeatherInfo() async -> String {
        await weatherContext().keyword
    }

    func fetchMusicInfo() async -> String {
        #if canImport(MusicKit)
        let status = await MusicAuthorization.request()
        guard status == .authorized else {
            return "未取得"
        }

        switch ApplicationMusicPlayer.shared.state.playbackStatus {
        case .playing:
            return "再生中の音楽：流れるような雰囲気"
        case .paused:
            return "一時停止中の音楽：静かな余韻"
        case .stopped:
            return "未取得"
        default:
            return "音楽の気配：淡い余韻"
        }
        #else
        return "未取得"
        #endif
    }

    private func weatherContext() async -> (keyword: String, effect: WeatherVisualEffect) {
        guard CLLocationManager.locationServicesEnabled() else {
            return ("未取得", .none)
        }

        await MainActor.run {
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestWhenInUseAuthorization()
            }
            locationManager.requestLocation()
        }

        try? await Task.sleep(nanoseconds: 450_000_000)

        guard let location = await MainActor.run(body: { locationManager.location }) else {
            return ("未取得", .none)
        }

        #if canImport(WeatherKit)
        do {
            let weather = try await WeatherService.shared.weather(for: location)
            let rawCondition = String(describing: weather.currentWeather.condition)
            return (weatherKeyword(from: rawCondition), weatherEffect(from: rawCondition))
        } catch {
            return ("未取得", .none)
        }
        #else
        return ("未取得", .none)
        #endif
    }

    private func weatherKeyword(from rawCondition: String) -> String {
        let lowercased = rawCondition.lowercased()
        if lowercased.contains("rain") || rawCondition.contains("雨") {
            return "雨の気配"
        }
        if lowercased.contains("snow") || rawCondition.contains("雪") {
            return "雪あかり"
        }
        if lowercased.contains("cloud") || rawCondition.contains("曇") {
            return "薄曇り"
        }
        if lowercased.contains("clear") || lowercased.contains("sun") || rawCondition.contains("晴") {
            return "陽だまり"
        }
        return rawCondition.isEmpty ? "未取得" : rawCondition
    }

    private func weatherEffect(from rawCondition: String) -> WeatherVisualEffect {
        let lowercased = rawCondition.lowercased()
        if lowercased.contains("rain") || rawCondition.contains("雨") {
            return .rain
        }
        if lowercased.contains("snow") || rawCondition.contains("雪") {
            return .snow
        }
        if lowercased.contains("cloud") || rawCondition.contains("曇") {
            return .cloud
        }
        if lowercased.contains("clear") || lowercased.contains("sun") || rawCondition.contains("晴") {
            return .sunlight
        }
        return .none
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {}
}

struct AISuggestionRequest {
    let photoDescription: String?
    let factInput: String
    let mood: DiaryTone
    let weatherKeyword: String
    let musicMood: String
    let photoTakenAt: Date?
    let generationSeed: UUID

    init(
        photoDescription: String?,
        factInput: String,
        mood: DiaryTone,
        weatherKeyword: String,
        musicMood: String,
        photoTakenAt: Date? = nil,
        generationSeed: UUID = UUID()
    ) {
        self.photoDescription = photoDescription
        self.factInput = factInput
        self.mood = mood
        self.weatherKeyword = weatherKeyword
        self.musicMood = musicMood
        self.photoTakenAt = photoTakenAt
        self.generationSeed = generationSeed
    }

    var systemPrompt: String {
        """
        あなたは、日記を書く人の心にそっと寄り添う、親しみやすい短歌の語り手です。
        難解な歌人のように格調高くしすぎず、今の自分の気持ちがそのまま少し美しく残る短歌を提案してください。

        【素材】
        - 写真の内容: \(photoDescription ?? "写真情報なし")
        - 天気(WeatherKit): \(weatherKeyword)
        - 音楽(MusicKit): \(musicMood)
        - ユーザーが選んだ心持ち: \(mood.rawValue)（\(mood.title)）

        【制約事項】
        1. 接続禁止：日記本文の語句をそのまま末尾に接続して短歌にしないでください。
        2. リライト：日記本文の事実と気持ちを汲み取り、全体を詩的な表現へ書き換えてください。
        3. 言葉選び：現代的で分かりやすい言葉を使ってください。
        4. 感情：嬉しい、寂しい、不安、幸せ、疲れた、安心した、などの感情をそのまま表現して構いません。
        5. 構成：基本は5-7-5-7-7のリズムを目指しますが、文脈の自然さを優先してください。多少の字余り・字足らずがあっても、声に出して心地よいものを採用してください。
        6. 天気と音楽：必須要素ではなく素材として扱ってください。晴れなら少し明るく、雨なら静かに、音楽があるなら余韻を少し混ぜる程度で十分です。
        7. 上の句生成：写真、日記本文、心持ちを踏まえ、事実に基づいた上の句（5-7-5）を自動生成してください。
        8. 下の句生成：ユーザーが選べるように、感情ベースの下の句（7-7）候補を複数提示してください。
        9. 出力：上の句3句と、下の句候補を分けて出力してください。ユーザー入力を無理に繋げず、短歌としてふさわしい言葉に再構築してください。

        【日記本文】
        \(factInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "入力なし" : factInput)

        【出力の方向性】
        例：「お腹痛い」なら、
        お腹痛い　薬を飲んで　眠ろうか　外は夕暮れ　月がぼんやり
        のように、親しみやすく、少しだけ余韻のある表現にしてください。
        """
    }

    var concreteKeywords: [String] {
        let factWords = factInput
            .components(separatedBy: CharacterSet(charactersIn: " 、。,.!！?？/　\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count >= 2 }

        let photoWords = (photoDescription ?? "")
            .components(separatedBy: CharacterSet(charactersIn: "、, /"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return Array((factWords + photoWords).prefix(5))
    }
}

struct AIComposerSuggestion: Equatable {
    let upperPhrase: [String]
    let lowerOptions: [String]

    static let fallback = AIComposerSuggestion(
        upperPhrase: ["ひとことを", "入れるだけで", "札になる"],
        lowerOptions: [
            "今はゆっくり 息をしてみる",
            "今日の余白を そっとたたんで",
            "またあと少し 言葉を待とう"
        ]
    )

    static func generate(request: AISuggestionRequest) -> AIComposerGenerationState {
        do {
            let upperPhrase = DiaryFactPhraseGenerator.upperPhrase(request: request)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            let lowerOptions = AILowerPhraseGenerator.options(request: request)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            guard upperPhrase.count >= 3, !lowerOptions.isEmpty else {
                throw AIComposerGenerationError.emptySuggestion
            }

            return .success(
                AIComposerSuggestion(
                    upperPhrase: Array(upperPhrase.prefix(3)),
                    lowerOptions: Array(lowerOptions.prefix(3))
                )
            )
        } catch {
            return .failure(error.localizedDescription)
        }
    }
}

enum AIComposerGenerationState: Equatable {
    case success(AIComposerSuggestion)
    case failure(String)
}

enum AIComposerGenerationError: LocalizedError {
    case emptySuggestion

    var errorDescription: String? {
        "短歌候補を生成できませんでした。"
    }
}

enum AILowerPhraseGenerator {
    static func options(request: AISuggestionRequest) -> [String] {
        DynamicTankaPhraseEngine.generate(request: request).lowerOptions
    }
}

struct TankaRewriteSuggestion: Identifiable, Equatable {
    let title: String
    let moodNote: String
    let lines: [String]

    var id: String { title }

    var upperLines: [String] {
        Array(lines.prefix(3))
    }

    var lowerPhrase: String {
        Array(lines.dropFirst(3).prefix(2)).joined(separator: " ")
    }

    static func makeThree(request: AISuggestionRequest) -> [TankaRewriteSuggestion] {
        let scene = sceneSeed(from: request)
        let weather = request.weatherKeyword == "未取得" ? scene.weatherWord : request.weatherKeyword
        let music = request.musicMood == "未取得" ? scene.soundWord : request.musicMood

        switch request.mood {
        case .joy:
            return [
                TankaRewriteSuggestion(
                    title: "きらめき",
                    moodNote: "明るく、少し弾む",
                    lines: ["帰り道", "胸の小箱に", "灯がともる", "\(scene.object)さえ", "星に見えてる"]
                ),
                TankaRewriteSuggestion(
                    title: "やさしい余韻",
                    moodNote: "静かにうれしい",
                    lines: ["今日のこと", "\(weather)に", "ほどけてく", "笑った声を", "袖にしまった"]
                ),
                TankaRewriteSuggestion(
                    title: "ハイカラ",
                    moodNote: "少し甘く華やか",
                    lines: ["窓あかり", "\(scene.place)の先で", "揺れている", "\(music.shortPoemLine(limit: 7))", "花のリズムで"]
                )
            ]
        case .sorrow:
            return [
                TankaRewriteSuggestion(
                    title: "雨音",
                    moodNote: "寂しさをやわらかく",
                    lines: ["言えぬまま", "小さなため息", "ほどけてく", "\(scene.object)の影", "夜に預ける"]
                ),
                TankaRewriteSuggestion(
                    title: "月明かり",
                    moodNote: "切なさを残す",
                    lines: ["うつむいて", "\(weather)の道を", "歩いてる", "さみしい気持ち", "月が聞いてる"]
                ),
                TankaRewriteSuggestion(
                    title: "手紙",
                    moodNote: "自分に寄り添う",
                    lines: ["疲れたね", "声に出さずに", "書いてみる", "\(scene.place)の灯", "まだあたたかい"]
                )
            ]
        case .calm:
            return [
                TankaRewriteSuggestion(
                    title: "余白",
                    moodNote: "穏やかで澄んだ",
                    lines: ["ひと息を", "\(scene.place)の隅に", "置いてみる", "\(weather)の午後", "心ほどける"]
                ),
                TankaRewriteSuggestion(
                    title: "湯気",
                    moodNote: "生活の温度",
                    lines: ["何気ない", "今日の輪郭", "なぞりつつ", "\(scene.object)みたいに", "やさしく眠る"]
                ),
                TankaRewriteSuggestion(
                    title: "静かな音",
                    moodNote: "音楽の余韻",
                    lines: ["ゆっくりと", "\(music.shortPoemLine(limit: 7))", "遠ざかる", "明日のわたし", "少し軽くて"]
                )
            ]
        case .anger:
            return [
                TankaRewriteSuggestion(
                    title: "夜風",
                    moodNote: "熱を逃がす",
                    lines: ["むっとした", "胸の火照りを", "ほどく夜", "\(scene.object)越しに", "風を入れよう"]
                ),
                TankaRewriteSuggestion(
                    title: "朱色",
                    moodNote: "強さを残す",
                    lines: ["言葉には", "できないままの", "赤い棘", "\(scene.place)の灯", "明日へ逃がす"]
                ),
                TankaRewriteSuggestion(
                    title: "整える",
                    moodNote: "落ち着きを取り戻す",
                    lines: ["深呼吸", "\(weather)の下で", "目を閉じる", "怒ったわたし", "ちゃんと守ろう"]
                )
            ]
        }
    }

    private static func sceneSeed(from request: AISuggestionRequest) -> (object: String, place: String, weatherWord: String, soundWord: String) {
        let source = [
            request.factInput,
            request.photoDescription ?? "",
            request.weatherKeyword,
            request.musicMood
        ].joined(separator: " ")

        let object: String
        if source.contains("雨") {
            object = "濡れた傘"
        } else if source.contains("空") || source.contains("晴") {
            object = "淡い空"
        } else if source.contains("写真") || source.contains("光") {
            object = "写真の光"
        } else if source.contains("音") || source.contains("曲") || source.contains("音楽") {
            object = "歌の余韻"
        } else if source.contains("疲") || source.contains("眠") {
            object = "白い枕"
        } else {
            object = "小さな灯"
        }

        let place: String
        if source.contains("駅") {
            place = "駅のホーム"
        } else if source.contains("学校") || source.contains("授業") {
            place = "教室"
        } else if source.contains("家") || source.contains("部屋") {
            place = "部屋"
        } else if source.contains("カフェ") || source.contains("喫茶") {
            place = "喫茶店"
        } else {
            place = "帰り道"
        }

        let weatherWord: String
        if source.contains("雨") {
            weatherWord = "雨音"
        } else if source.contains("晴") || source.contains("陽") {
            weatherWord = "陽だまり"
        } else if source.contains("曇") {
            weatherWord = "曇り空"
        } else {
            weatherWord = "夜風"
        }

        let soundWord = source.contains("再生中") || source.contains("音楽") ? "流れる歌" : "静かな音"
        return (object, place, weatherWord, soundWord)
    }
}

struct LowerPhraseSuggestion {
    let firstOptions: [String]
    let secondOptionSets: [[String]]

    func secondOptions(for firstIndex: Int) -> [String] {
        secondOptionSets[safe: firstIndex] ?? secondOptionSets.first ?? ["今日をしまう", "胸に残して", "夜へ預ける"]
    }

    static func make(request: AISuggestionRequest) -> LowerPhraseSuggestion {
        let keyword = request.concreteKeywords.first ?? request.mood.defaultKeyword
        let photoKeyword = request.concreteKeywords.dropFirst().first ?? request.mood.defaultImageWord

        switch request.mood {
        case .joy:
            return LowerPhraseSuggestion(
                firstOptions: [
                    "\(keyword.shortPoemLine(limit: 5))を抱いて",
                    "笑みをかくして",
                    "\(photoKeyword.shortPoemLine(limit: 5))の光"
                ],
                secondOptionSets: [
                    ["星がほどける", "夜へしまう", "胸に灯して"],
                    ["今日をしまう", "帰り道まで", "そっと連れて"],
                    ["胸に残して", "明日へ渡す", "頬にひかる"]
                ]
            )
        case .sorrow:
            return LowerPhraseSuggestion(
                firstOptions: [
                    "\(keyword.shortPoemLine(limit: 5))を抱いて",
                    "ため息ひとつ",
                    "\(photoKeyword.shortPoemLine(limit: 5))の影"
                ],
                secondOptionSets: [
                    ["月へ預ける", "夜が更ける", "灯が揺れる"],
                    ["灯が揺れる", "胸にしまう", "雨へほどく"],
                    ["夜へ沈める", "袖にしまって", "声をなくす"]
                ]
            )
        case .calm:
            return LowerPhraseSuggestion(
                firstOptions: [
                    "\(keyword.shortPoemLine(limit: 5))を眺め",
                    "静かな息に",
                    "\(photoKeyword.shortPoemLine(limit: 5))の風"
                ],
                secondOptionSets: [
                    ["心ほどける", "明日が香る", "午後が眠る"],
                    ["明日が香る", "袖にしまって", "湯気に溶ける"],
                    ["そっと流れる", "今日をほどく", "余白ひらく"]
                ]
            )
        case .anger:
            return LowerPhraseSuggestion(
                firstOptions: [
                    "\(keyword.shortPoemLine(limit: 5))をほどき",
                    "赤きこころを",
                    "\(photoKeyword.shortPoemLine(limit: 5))の夜"
                ],
                secondOptionSets: [
                    ["風に逃がして", "夜へほどいて", "星を数える"],
                    ["夜へほどいて", "胸を冷ます", "言葉を置く"],
                    ["息をととのえ", "明日へ逃がす", "影をしまう"]
                ]
            )
        }
    }
}

private extension DiaryTone {
    var defaultKeyword: String {
        switch self {
        case .joy: return "ときめき"
        case .sorrow: return "ため息"
        case .calm: return "静けさ"
        case .anger: return "胸の火"
        }
    }

    var defaultImageWord: String {
        switch self {
        case .joy: return "淡い光"
        case .sorrow: return "月影"
        case .calm: return "風"
        case .anger: return "夜"
        }
    }
}

enum DiaryManualPhraseFormatter {
    static func upperLines(from text: String) -> [String] {
        let lines = text
            .replacingOccurrences(of: "　", with: " ")
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if lines.count >= 3 {
            return Array(lines.prefix(3)).map { $0.shortPoemLine(limit: 9) }
        }

        let compacted = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "　", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !compacted.isEmpty else {
            return ["上の句を", "ここに紡いで", "札にする"]
        }

        if lines.count == 2 {
            return [lines[0].shortPoemLine(limit: 9), lines[1].shortPoemLine(limit: 9), "今日残る"]
        }

        let characters = Array(compacted.replacingOccurrences(of: " ", with: ""))
        let firstEnd = min(5, characters.count)
        let secondEnd = min(firstEnd + 7, characters.count)
        let first = String(characters.prefix(firstEnd))
        let second = String(characters.dropFirst(firstEnd).prefix(max(0, secondEnd - firstEnd)))
        let third = String(characters.dropFirst(secondEnd))

        return [
            first.isEmpty ? "ひとことを" : first.shortPoemLine(limit: 9),
            second.isEmpty ? "胸にしまって" : second.shortPoemLine(limit: 9),
            third.isEmpty ? "今日残る" : third.shortPoemLine(limit: 9)
        ]
    }
}

enum DiaryManualHintGenerator {
    static func hint(upperText: String, factText: String, tone: DiaryTone, hasPhoto: Bool) -> String {
        let source = (upperText.isEmpty ? factText : upperText)
        let normalized = source.replacingOccurrences(of: "　", with: " ")

        if normalized.contains("雨") {
            return "雨粒、硝子、濡れた街灯"
        }
        if normalized.contains("空") || normalized.contains("雲") {
            return "薄青、雲ほどけ、風の余白"
        }
        if normalized.contains("駅") || normalized.contains("電車") {
            return "改札、夕灯、ホームの余韻"
        }
        if normalized.contains("夜") {
            return "月影、部屋の灯、言えない余白"
        }
        if hasPhoto {
            return "写真の端に残った、淡い光"
        }

        switch tone {
        case .joy:
            return "小さな祝福、胸の灯、帰り道"
        case .sorrow:
            return "ため息、月の影、静かな袖"
        case .calm:
            return "湯気、やわらかな風、午後の余白"
        case .anger:
            return "赤い頬、ほどける言葉、夜風"
        }
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

            TextField("今日あった事実をボソッと1行…", text: $factText)
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

struct ManualTextAreaStep: View {
    let number: String
    let title: String
    let placeholder: String
    @Binding var text: String
    let hint: String?
    let onHint: () -> Void

    var body: some View {
        DiaryFormSection {
            HStack(alignment: .center, spacing: 10) {
                StepSectionTitle(number: number, title: title)

                Spacer(minLength: 8)

                Button(action: onHint) {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                            .font(.caption.weight(.bold))
                        Text("言葉が降りてこない時（AIヒント）")
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                    .font(UtakataFontStyle.rounded(size: 11, weight: .semibold))
                    .foregroundStyle(Color.meijiRed)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color(hex: 0xFFF2E6).opacity(0.82), in: Capsule())
                    .overlay(Capsule().stroke(Color.retroGold.opacity(0.32), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .font(UtakataFontStyle.rounded(size: 15, weight: .regular))
                    .foregroundStyle(Color.primaryText)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 9)
                    .frame(minHeight: 118)

                if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(placeholder)
                        .font(UtakataFontStyle.rounded(size: 14, weight: .medium))
                        .foregroundStyle(Color.secondaryText.opacity(0.62))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                }
            }
            .background(Color(hex: 0xFFF9F2).opacity(0.9), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.retroGold.opacity(0.28), lineWidth: 0.8))

            if let hint {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "quote.opening")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.retroGold)
                    Text(hint)
                        .font(UtakataFontStyle.handLetter(size: 14, weight: .regular))
                        .foregroundStyle(Color.primaryText.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.retroPaper.opacity(0.55), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.meijiRed.opacity(0.16), lineWidth: 0.8))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
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
                    fontSize: 15
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
    @Binding var selectedLowerFirstIndex: Int
    @Binding var selectedLowerSecondIndex: Int

    var body: some View {
        DiaryFormSection {
            StepSectionTitle(number: "2", title: "今のこころ")

            HStack(spacing: 8) {
                ForEach(DiaryTone.allCases, id: \.self) { tone in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            selectedTone = tone
                            selectedLowerFirstIndex = 0
                            selectedLowerSecondIndex = 0
                        }
                    } label: {
                        ToneSegmentButton(tone: tone, isSelected: selectedTone == tone)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(Color(hex: 0xFFF9F2).opacity(0.86), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.retroGold.opacity(0.28), lineWidth: 0.8))
        }
    }
}

struct ToneSegmentButton: View {
    let tone: DiaryTone
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                PlumBlossom()
                    .fill(isSelected ? Color.retroPaper.opacity(0.96) : tone.tint.opacity(0.18))
                    .frame(width: 22, height: 22)
                    .shadow(color: tone.tint.opacity(isSelected ? 0.24 : 0.08), radius: 8, x: 0, y: 4)

                Text(tone.rawValue)
                    .font(UtakataFontStyle.retroMincho(size: 16, weight: .regular))
                    .foregroundStyle(isSelected ? tone.tint : Color.primaryText.opacity(0.72))
            }

            Text(tone.title)
                .font(UtakataFontStyle.rounded(size: 10, weight: .semibold))
                .foregroundStyle(isSelected ? Color.retroPaper : Color.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(
            isSelected
            ? LinearGradient(colors: [Color.meijiRed, tone.tint], startPoint: .topLeading, endPoint: .bottomTrailing)
            : LinearGradient(colors: [Color.clear, Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 11, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 11).stroke(isSelected ? Color.retroGold.opacity(0.58) : Color.primaryText.opacity(0.08), lineWidth: 0.8))
    }
}

struct LowerPhraseSlotStep: View {
    let tone: DiaryTone
    let suggestion: LowerPhraseSuggestion
    @Binding var selectedFirstIndex: Int
    @Binding var selectedSecondIndex: Int

    private var secondOptions: [String] {
        suggestion.secondOptions(for: selectedFirstIndex)
    }

    var body: some View {
        DiaryFormSection {
            StepSectionTitle(number: "3", title: "下の句を詠む")

            PhraseChoiceList(
                title: "前半の七音",
                subtitle: "上の句に続く、気持ちの入口",
                options: suggestion.firstOptions,
                selectedIndex: $selectedFirstIndex,
                accent: tone.tint
            ) {
                selectedSecondIndex = 0
            }

            PhraseChoiceList(
                title: "後半の七音",
                subtitle: "余韻をそっと結ぶ",
                options: secondOptions,
                selectedIndex: $selectedSecondIndex,
                accent: tone.tint
            )
        }
    }
}

struct AITankaFlowStep: View {
    let tone: DiaryTone
    let upperLines: [String]
    let lowerOptions: [String]
    @Binding var selectedLowerIndex: Int
    @Binding var customLowerText: String

    private var customIndex: Int { lowerOptions.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            DiaryFormSection {
                StepSectionTitle(number: "3", title: "上の句（自動）")

                Text("写真・今日の事実・今のこころから、事実を短歌らしい情景へ書き換えます。")
                    .font(UtakataFontStyle.rounded(size: 12, weight: .medium))
                    .foregroundStyle(Color.secondaryText)

                UpperPhrasePreview(lines: upperLines, accent: tone.tint)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            DiaryFormSection {
                StepSectionTitle(number: "4", title: "下の句を選ぶ")

                VStack(spacing: 10) {
                    ForEach(Array(lowerOptions.enumerated()), id: \.offset) { index, phrase in
                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                selectedLowerIndex = index
                            }
                        } label: {
                            LowerPhraseSelectionRow(
                                phrase: phrase,
                                accent: tone.tint,
                                isSelected: selectedLowerIndex == index
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            selectedLowerIndex = customIndex
                        }
                    } label: {
                        HStack(spacing: 9) {
                            Image(systemName: selectedLowerIndex == customIndex ? "checkmark.circle.fill" : "circle")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(selectedLowerIndex == customIndex ? Color.meijiRed : Color.secondaryText.opacity(0.62))
                            Text("自由に記入する")
                                .font(UtakataFontStyle.rounded(size: 14, weight: .semibold))
                                .foregroundStyle(Color.primaryText)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)

                    TextField("例：夜風のなかで 少し休もう", text: $customLowerText)
                        .textFieldStyle(.plain)
                        .font(UtakataFontStyle.rounded(size: 15, weight: .medium))
                        .foregroundStyle(Color.primaryText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                        .background(Color(hex: 0xFFF9F2).opacity(0.92), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(selectedLowerIndex == customIndex ? Color.meijiRed.opacity(0.44) : Color.retroGold.opacity(0.24), lineWidth: 0.9))
                        .onTapGesture {
                            selectedLowerIndex = customIndex
                        }
                }
                .padding(.top, 2)
            }
        }
        .onChange(of: lowerOptions) { _, newValue in
            if selectedLowerIndex > newValue.count {
                selectedLowerIndex = 0
            }
        }
    }
}

struct LowerPhraseSelectionRow: View {
    let phrase: String
    let accent: Color
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            PlumBlossom()
                .fill(isSelected ? accent.opacity(0.88) : accent.opacity(0.16))
                .frame(width: 18, height: 18)

            Text(phrase)
                .font(UtakataFontStyle.rounded(size: 15, weight: .semibold))
                .foregroundStyle(Color.primaryText.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.meijiRed)
            }
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 14)
        .background {
            LinearGradient(
                colors: [
                    Color(hex: 0xFFF9F2).opacity(0.94),
                    Color(hex: 0xF7E7D5).opacity(0.88),
                    accent.opacity(isSelected ? 0.12 : 0.04)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isSelected ? accent.opacity(0.7) : Color.retroGold.opacity(0.24), lineWidth: isSelected ? 1.2 : 0.8)
        )
    }
}

struct TankaSuggestionStep: View {
    let tone: DiaryTone
    let suggestions: [TankaRewriteSuggestion]
    @Binding var selectedIndex: Int

    var body: some View {
        DiaryFormSection {
            StepSectionTitle(number: "3", title: "短歌を選ぶ")

            VStack(alignment: .leading, spacing: 7) {
                Text("日記の一節を、そのまま繋げずに詩へ書き換えた3案です。")
                    .font(UtakataFontStyle.rounded(size: 12, weight: .medium))
                    .foregroundStyle(Color.secondaryText)

                VStack(spacing: 10) {
                    ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                        Button {
                            withAnimation(.spring(response: 0.26, dampingFraction: 0.82)) {
                                selectedIndex = index
                            }
                        } label: {
                            TankaSuggestionRow(
                                suggestion: suggestion,
                                accent: tone.tint,
                                isSelected: selectedIndex == index
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .onChange(of: suggestions) { _, newValue in
            if selectedIndex >= newValue.count {
                selectedIndex = 0
            }
        }
    }
}

struct TankaSuggestionRow: View {
    let suggestion: TankaRewriteSuggestion
    let accent: Color
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                PlumBlossom()
                    .fill(isSelected ? accent.opacity(0.92) : accent.opacity(0.18))
                    .frame(width: 18, height: 18)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.meijiRed)
                }
            }
            .frame(width: 24)

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 8) {
                    Text(suggestion.title)
                        .font(UtakataFontStyle.rounded(size: 14, weight: .semibold))
                        .foregroundStyle(Color.primaryText)
                    Text(suggestion.moodNote)
                        .font(UtakataFontStyle.rounded(size: 11, weight: .regular))
                        .foregroundStyle(Color.secondaryText)
                    Spacer(minLength: 0)
                }

                Text(suggestion.lines.joined(separator: "　"))
                    .font(.system(size: 14, weight: .regular, design: .serif))
                    .foregroundStyle(Color.primaryText.opacity(0.86))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 13)
        .background {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: 0xFFF9F2).opacity(0.94),
                        Color(hex: 0xF7E7D5).opacity(0.88),
                        accent.opacity(isSelected ? 0.12 : 0.04)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                WashiPattern()
                    .opacity(0.14)
            }
            .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(isSelected ? accent.opacity(0.72) : Color.retroGold.opacity(0.26), lineWidth: isSelected ? 1.3 : 0.8)
        )
        .scaleEffect(isSelected ? 1.01 : 1)
    }
}

struct PhraseChoiceList: View {
    let title: String
    let subtitle: String
    let options: [String]
    @Binding var selectedIndex: Int
    let accent: Color
    var onSelect: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(UtakataFontStyle.rounded(size: 14, weight: .semibold))
                    .foregroundStyle(Color.primaryText)
                Text(subtitle)
                    .font(UtakataFontStyle.rounded(size: 11, weight: .regular))
                    .foregroundStyle(Color.secondaryText)
                Spacer(minLength: 0)
            }

            VStack(spacing: 0) {
                ForEach(Array(options.enumerated()), id: \.offset) { index, phrase in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            selectedIndex = index
                            onSelect()
                        }
                    } label: {
                        HStack(spacing: 12) {
                            PlumBlossom()
                                .fill(selectedIndex == index ? accent.opacity(0.82) : accent.opacity(0.16))
                                .frame(width: 17, height: 17)

                            Text(phrase)
                                .font(UtakataFontStyle.rounded(size: 15, weight: .semibold))
                                .foregroundStyle(Color.primaryText)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            if selectedIndex == index {
                                Image(systemName: "checkmark")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(Color.meijiRed)
                            }
                        }
                        .padding(.vertical, 13)
                        .padding(.horizontal, 14)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if index < options.count - 1 {
                        Divider()
                            .overlay(Color.retroGold.opacity(0.18))
                            .padding(.leading, 42)
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
    let photoData: Data?
    let weatherEffect: WeatherVisualEffect
    let isStoring: Bool
    @State private var didOpen = false

    var body: some View {
        DiaryFormSection {
            StepSectionTitle(number: "4", title: "短歌日記の完成")

            HStack {
                Spacer()
                TankaOmikujiPreviewCard(
                    upperPhrase: upperPhrase,
                    lowerPhrase: lowerPhrase,
                    accent: mood.accent,
                    photoData: photoData,
                    weatherEffect: weatherEffect
                )
                .frame(width: 252, height: 386)
                .scaleEffect(isStoring ? 0.42 : 1)
                .offset(x: isStoring ? 92 : 0, y: isStoring ? 142 : 0)
                .rotationEffect(.degrees(isStoring ? 8 : 0))
                .opacity(didOpen ? (isStoring ? 0.28 : 1) : 0)
                .scaleEffect(didOpen ? 1 : 0.94)
                .animation(.spring(response: 0.58, dampingFraction: 0.86), value: didOpen)
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
        .onAppear {
            didOpen = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                didOpen = true
            }
        }
    }
}

struct TankaOmikujiPreviewCard: View {
    let upperPhrase: [String]
    let lowerPhrase: String
    let accent: Color
    let photoData: Data?
    let weatherEffect: WeatherVisualEffect
    @AppStorage("utakataNickname") private var nickname = ""

    private var allLines: [String] {
        Array(upperPhrase.prefix(3)) + lowerPhrase.tankaLowerLines()
    }

    private var authorName: String {
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "名無しの詠み人" : trimmed
    }

    private var cardDateText: String {
        let calendar = Calendar(identifier: .gregorian)
        let month = calendar.component(.month, from: .now)
        let day = calendar.component(.day, from: .now)
        return "\(Self.japaneseNumber(month))月\(Self.japaneseNumber(day))日"
    }

    private var selectedImage: Image? {
        guard
            let photoData,
            let uiImage = UIImage(data: photoData)
        else { return nil }

        return Image(uiImage: uiImage)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: 0xFFF9F2),
                    Color(hex: 0xF4E4CB),
                    accent.opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            WashiPattern()
                .opacity(0.34)

            TaishoCheckPattern(color: Color.meijiRed.opacity(0.025), tile: 24)

            WeatherAtmosphereCanvas(effect: weatherEffect, accent: accent)
                .opacity(0.42)
                .allowsHitTesting(false)

            VStack(spacing: 11) {
                Text(cardDateText)
                    .font(UtakataFontStyle.handLetter(size: 13, weight: .regular))
                    .foregroundStyle(Color.primaryText.opacity(0.58))
                    .padding(.top, 20)

                TanzakuCard(
                    image: selectedImage,
                    lines: allLines,
                    authorName: authorName,
                    accent: accent
                )
                .padding(.horizontal, 16)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 4)

            MemoryCornerRibbons(color: accent)
                .padding(12)

            OrnateOmikujiBorder()
                .stroke(Color.retroGold.opacity(0.58), lineWidth: 1)
                .padding(10)

            OrnateOmikujiBorder()
                .stroke(Color.meijiRed.opacity(0.20), lineWidth: 0.8)
                .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.meijiRed.opacity(0.20), lineWidth: 1.0))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.retroGold.opacity(0.44), lineWidth: 0.8).padding(6))
        .shadow(color: .black.opacity(0.13), radius: 22, x: 0, y: 14)
        .shadow(color: accent.opacity(0.12), radius: 18, x: 0, y: 8)
    }

    private static func japaneseNumber(_ value: Int) -> String {
        let digits = ["", "一", "二", "三", "四", "五", "六", "七", "八", "九"]
        switch value {
        case 1...9:
            return digits[value]
        case 10:
            return "十"
        case 11...19:
            return "十\(digits[value - 10])"
        case 20:
            return "二十"
        case 21...29:
            return "二十\(digits[value - 20])"
        case 30:
            return "三十"
        case 31:
            return "三十一"
        default:
            return "\(value)"
        }
    }
}

struct TanzakuCard: View {
    let image: Image?
    let lines: [String]
    let authorName: String
    let accent: Color

    private var upperLines: [String] {
        Array(lines.prefix(3))
    }

    private var lowerLines: [String] {
        Array(lines.dropFirst(3).prefix(2))
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: 0xFFF4EF),
                            Color(hex: 0xFFF9F2),
                            Color(hex: 0xF4E4CB).opacity(0.86),
                            accent.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            WashiPattern()
                .opacity(0.24)
                .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))

            VStack(alignment: .leading, spacing: 13) {
                ZStack {
                    Rectangle()
                        .fill(Color(hex: 0xF7E9DD).opacity(0.78))

                    if let image {
                        image
                            .resizable()
                            .scaledToFill()
                            .saturation(0.82)
                            .contrast(1.04)
                            .colorMultiply(Color(hex: 0xF8E1C5))
                    } else {
                        VStack(spacing: 8) {
                            PlumBlossom()
                                .fill(accent.opacity(0.24))
                                .frame(width: 24, height: 24)
                            Text("今日の余白")
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundStyle(Color.secondaryText.opacity(0.72))
                        }
                    }
                }
                .frame(height: 132)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    LinearGradient(
                        colors: [.clear, Color(hex: 0xFFF9F2).opacity(0.16)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                )
                .clipped()

                TategakiTankaView(lines: upperLines + lowerLines, accent: accent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 112)
                    .padding(.horizontal, 5)

                HStack(spacing: 5) {
                    Spacer()
                    Text("詠み人：\(authorName)")
                        .font(.system(size: 9.4, weight: .light, design: .default))
                        .foregroundStyle(Color(hex: 0x555555).opacity(0.82))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
            }
            .padding(13)
        }
        .frame(width: 216, height: 314)
        .shadow(color: .black.opacity(0.20), radius: 22, x: 0, y: 14)
    }
}

struct DiaryPoemLineGroup: View {
    let lines: [String]
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                Text(line)
                    .font(.system(size: index == 0 ? 15 : 14, weight: index == 0 ? .regular : .light, design: .default))
                    .foregroundStyle(Color.primaryText.opacity(index == 0 ? 0.92 : 0.82))
                    .lineSpacing(10)
                    .tracking(0.6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct TategakiTankaView: View {
    let lines: [String]
    let accent: Color

    private var normalizedLines: [String] {
        var result = lines.prefix(5).map { $0.normalizedVerticalPoemText }
        while result.count < 5 {
            result.append("")
        }
        return result
    }

    var body: some View {
        GeometryReader { proxy in
            let maxCount = max(normalizedLines.map(\.count).max() ?? 1, 1)
            let characterSpacing = 2.2
            let availableHeight = max(44, proxy.size.height - 22)
            let fittedFontSize = min(
                15.0,
                max(9.0, (availableHeight - CGFloat(maxCount - 1) * characterSpacing) / CGFloat(maxCount))
            )

            HStack(alignment: .top, spacing: 8) {
                ForEach(Array(normalizedLines.enumerated()).reversed(), id: \.offset) { index, line in
                    VerticalTankaColumn(
                        text: line,
                        isLowerPhrase: index >= 3,
                        accent: accent,
                        fontSize: fittedFontSize
                    )

                    if index == 3 {
                        VerticalTankaDivider(accent: accent)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(Color(hex: 0xFFF9F2).opacity(0.46), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.retroGold.opacity(0.16), lineWidth: 0.8))
    }
}

struct VerticalTankaColumn: View {
    let text: String
    let isLowerPhrase: Bool
    let accent: Color
    let fontSize: CGFloat

    private var characters: [String] {
        text.normalizedVerticalPoemText.map(String.init)
    }

    var body: some View {
        VStack(spacing: 2.2) {
            ForEach(Array(characters.enumerated()), id: \.offset) { _, character in
                Text(character)
                    .font(.system(size: fontSize, weight: .regular, design: .serif))
                    .foregroundStyle(isLowerPhrase ? Color.primaryText.opacity(0.78) : Color.primaryText.opacity(0.90))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .allowsTightening(true)
                    .tracking(1.2)
                    .shadow(color: Color(hex: 0xFFF9F2).opacity(0.45), radius: 0.5, x: 0, y: 0.5)
            }
        }
        .frame(width: 19)
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, isLowerPhrase ? 4 : 0)
        .clipped()
    }
}

struct VerticalTankaDivider: View {
    let accent: Color

    var body: some View {
        VStack(spacing: 5) {
            ForEach(0..<5, id: \.self) { _ in
                Circle()
                    .fill(Color.retroGold.opacity(0.36))
                    .frame(width: 3.5, height: 3.5)
            }
        }
        .frame(width: 8)
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 12)
    }
}

private extension String {
    var normalizedVerticalPoemText: String {
        replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "　", with: "")
            .replacingOccurrences(of: "\n", with: "")
    }
}

struct WeatherAtmosphereCanvas: View {
    let effect: WeatherVisualEffect
    let accent: Color

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate

                switch effect {
                case .sunlight:
                    drawSunlight(in: &context, size: size, time: time)
                case .rain:
                    drawRain(in: &context, size: size, time: time)
                case .cloud:
                    drawCloud(in: &context, size: size, time: time)
                case .snow:
                    drawSnow(in: &context, size: size, time: time)
                case .night:
                    drawNight(in: &context, size: size, time: time)
                case .none:
                    drawSunlight(in: &context, size: size, time: time, opacity: 0.18)
                }
            }
        }
    }

    private func drawSunlight(in context: inout GraphicsContext, size: CGSize, time: TimeInterval, opacity: Double = 0.34) {
        for index in 0..<18 {
            let progress = (CGFloat(time * 0.05) + CGFloat(index) * 0.137).truncatingRemainder(dividingBy: 1)
            let x = size.width * CGFloat((index * 37) % 100) / 100
            let y = size.height * progress
            let radius = CGFloat(2 + (index % 4))
            let rect = CGRect(x: x, y: y, width: radius, height: radius)
            context.fill(Path(ellipseIn: rect), with: .color(Color.retroGold.opacity(opacity)))
        }
    }

    private func drawRain(in context: inout GraphicsContext, size: CGSize, time: TimeInterval) {
        for index in 0..<24 {
            let progress = (CGFloat(time * 0.22) + CGFloat(index) * 0.071).truncatingRemainder(dividingBy: 1)
            let x = size.width * CGFloat((index * 29) % 100) / 100
            let y = size.height * progress
            var path = Path()
            path.move(to: CGPoint(x: x, y: y))
            path.addLine(to: CGPoint(x: x - 5, y: y + 18))
            context.stroke(path, with: .color(Color.meijiBlue.opacity(0.22)), lineWidth: 1.0)
        }
    }

    private func drawCloud(in context: inout GraphicsContext, size: CGSize, time: TimeInterval) {
        for index in 0..<6 {
            let drift = sin(time * 0.25 + Double(index)) * 10
            let x = size.width * CGFloat(index + 1) / 7 + CGFloat(drift)
            let y = size.height * CGFloat(0.18 + Double(index % 3) * 0.22)
            let rect = CGRect(x: x - 34, y: y - 12, width: 68, height: 24)
            context.fill(Path(ellipseIn: rect), with: .color(Color(hex: 0xB8CAD0).opacity(0.16)))
        }
    }

    private func drawSnow(in context: inout GraphicsContext, size: CGSize, time: TimeInterval) {
        for index in 0..<22 {
            let progress = (CGFloat(time * 0.04) + CGFloat(index) * 0.083).truncatingRemainder(dividingBy: 1)
            let sway = sin(time * 0.8 + Double(index)) * 8
            let x = size.width * CGFloat((index * 41) % 100) / 100 + CGFloat(sway)
            let y = size.height * progress
            let rect = CGRect(x: x, y: y, width: 3.5, height: 3.5)
            context.fill(Path(ellipseIn: rect), with: .color(Color.white.opacity(0.38)))
        }
    }

    private func drawNight(in context: inout GraphicsContext, size: CGSize, time: TimeInterval) {
        for index in 0..<16 {
            let pulse = 0.18 + 0.12 * (sin(time * 0.9 + Double(index)) + 1) / 2
            let x = size.width * CGFloat((index * 31) % 100) / 100
            let y = size.height * CGFloat((index * 47) % 100) / 100
            let rect = CGRect(x: x, y: y, width: 2.6, height: 2.6)
            context.fill(Path(ellipseIn: rect), with: .color(accent.opacity(pulse)))
        }
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

                ForEach(0..<5, id: \.self) { index in
                    DoveSilhouette()
                        .fill(Color.white.opacity(0.72))
                        .frame(width: CGFloat(30 + index * 5), height: CGFloat(20 + index * 3))
                        .rotationEffect(.degrees(Double([-14, 9, -4, 18, -20][index])))
                        .position(
                            x: proxy.size.width * dovePositions[index].0,
                            y: proxy.size.height * dovePositions[index].1
                        )
                        .shadow(color: Color.retroGold.opacity(0.12), radius: 8, x: 0, y: 3)
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

    private var dovePositions: [(CGFloat, CGFloat)] {
        [(0.18, 0.28), (0.76, 0.24), (0.32, 0.48), (0.82, 0.58), (0.55, 0.34)]
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

struct DiaryPhotoMenuButton: View {
    let photoData: Data?
    let onCameraTap: () -> Void
    let onLibraryTap: () -> Void

    var body: some View {
        Menu {
            Button(action: onCameraTap) {
                Label(photoData == nil ? "写真を撮る" : "撮り直す", systemImage: "camera.fill")
            }

            Button(action: onLibraryTap) {
                Label(photoData == nil ? "写真を選択" : "写真を変更", systemImage: "photo.on.rectangle")
            }
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: photoData == nil ? "camera.fill" : "checkmark.circle.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(photoData == nil ? Color.meijiRed : Color.retroPaper)
                        .frame(width: 58, height: 58)
                        .background(
                            photoData == nil
                            ? LinearGradient(colors: [Color(hex: 0xFFF9F2), Color.retroPaper], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.meijiRed, Color.retroRose], startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: Circle()
                        )
                        .overlay(Circle().stroke(Color.meijiRed.opacity(0.28), lineWidth: 0.9))
                        .overlay(Circle().stroke(Color.retroGold.opacity(0.38), lineWidth: 0.7).padding(5))
                        .shadow(color: Color.meijiRed.opacity(0.14), radius: 10, x: 0, y: 5)

                    PlumBlossom()
                        .fill(Color.retroGold.opacity(photoData == nil ? 0.72 : 0.95))
                        .frame(width: 11, height: 11)
                        .offset(x: -4, y: 5)
                }

                Text(photoData == nil ? "写真" : "追加済")
                    .font(UtakataFontStyle.rounded(size: 10, weight: .semibold))
                    .foregroundStyle(photoData == nil ? Color.meijiRed : Color.retroPaper)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(photoData == nil ? Color(hex: 0xFFF9F2).opacity(0.82) : Color.meijiRed.opacity(0.9), in: Capsule())
            }
            .accessibilityLabel(photoData == nil ? "写真を追加" : "写真を変更")
        }
        .menuStyle(.button)
    }
}

struct LetterPaperDivider: View {
    var body: some View {
        HStack(spacing: 10) {
            Rectangle()
                .fill(LinearGradient(colors: [.clear, Color.meijiRed.opacity(0.24)], startPoint: .leading, endPoint: .trailing))
                .frame(height: 0.8)
            PlumBlossom()
                .fill(Color.retroGold.opacity(0.58))
                .frame(width: 11, height: 11)
            Rectangle()
                .fill(LinearGradient(colors: [Color.meijiRed.opacity(0.24), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(height: 0.8)
        }
        .padding(.horizontal, 6)
    }
}

struct RetroPhotoFrame: View {
    let image: Image

    var body: some View {
        image
            .resizable()
            .scaledToFill()
            .saturation(0.68)
            .contrast(1.08)
            .colorMultiply(Color(hex: 0xF1D7B6))
            .overlay(
                LinearGradient(
                    colors: [
                        Color(hex: 0x6E2F2D).opacity(0.10),
                        .clear,
                        Color(hex: 0x24394B).opacity(0.12)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(RetroFilmGrain().opacity(0.20))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.retroPaper.opacity(0.78), lineWidth: 3))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.retroGold.opacity(0.42), lineWidth: 0.8).padding(3))
            .clipped()
    }
}

struct RetroFilmGrain: View {
    var body: some View {
        Canvas { context, size in
            for index in 0..<130 {
                let x = CGFloat((index * 37) % 100) / 100 * size.width
                let y = CGFloat((index * 61) % 100) / 100 * size.height
                let alpha = Double((index % 7) + 2) / 100
                let rect = CGRect(x: x, y: y, width: CGFloat((index % 3) + 1), height: CGFloat((index % 3) + 1))
                context.fill(Path(ellipseIn: rect), with: .color(Color.primaryText.opacity(alpha)))
            }
        }
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

private extension UIImage {
    static func diaryStorageJPEGData(from data: Data, maxPixel: CGFloat = 1600, compressionQuality: CGFloat = 0.78) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        return image.diaryStorageJPEGData(maxPixel: maxPixel, compressionQuality: compressionQuality)
    }

    func diaryStorageJPEGData(maxPixel: CGFloat = 1600, compressionQuality: CGFloat = 0.78) -> Data? {
        let resized = diaryResized(maxPixel: maxPixel)
        return resized.jpegData(compressionQuality: compressionQuality)
    }

    func diaryResized(maxPixel: CGFloat) -> UIImage {
        let longestSide = max(size.width, size.height)
        guard longestSide > maxPixel, longestSide > 0 else {
            return normalizedForDiaryStorage()
        }

        let scale = maxPixel / longestSide
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    func normalizedForDiaryStorage() -> UIImage {
        guard imageOrientation != .up else { return self }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
