import SwiftUI
import PhotosUI
import UIKit

struct TodayView: View {
    @Binding var savedCards: [DiaryCard]
    let onOpenSettings: () -> Void
    let onDiaryCreated: (Date) -> Void
    @State private var showingComposer = false
    @State private var selectedDate = Date.now
    @State private var visibleMonth = Date.now

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ja_JP")
        return calendar
    }

    private var selectedCard: DiaryCard? {
        savedCards.first { calendar.isDate($0.date, inSameDayAs: selectedDate) }
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
                            onOpenSettings: onOpenSettings
                        )
                            .padding(.top, 4)

                        DiaryCalendarBoard(
                            cards: savedCards,
                            visibleMonth: $visibleMonth,
                            selectedDate: $selectedDate
                        )

                        DiarySelectedDayLog(
                            date: selectedDate,
                            card: selectedCard
                        ) {
                            showingComposer = true
                        }

                        Spacer(minLength: 170)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 126)
                }

                FloatingDiaryActionButton {
                    showingComposer = true
                }
                .padding(.trailing, 24)
                .padding(.bottom, 148)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingComposer) {
                DiaryComposerView { card in
                    if !savedCards.contains(where: { Calendar.current.isDate($0.date, inSameDayAs: card.date) }) {
                        savedCards.insert(card, at: 0)
                    }
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
        VStack(spacing: 18) {
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
                    .font(UtakataFontStyle.rounded(size: 26, weight: .semibold))
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

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 15) {
                ForEach(["月", "火", "水", "木", "金", "土", "日"], id: \.self) { weekday in
                    Text(weekday)
                        .font(UtakataFontStyle.rounded(size: 16, weight: .semibold))
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
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 22)
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
                    .font(UtakataFontStyle.rounded(size: 20, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(textColor)
                    .monospacedDigit()

                if hasCard {
                    Image(systemName: symbol)
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundStyle(isSelected ? Color.retroPaper : Color.meijiRed.opacity(0.82))
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 8, height: 8)
                }
            }
            .frame(height: 48)
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
                        .frame(width: 48, height: 48)
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
                        .frame(width: 38, height: 38)
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
    let card: DiaryCard?
    let onCreate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(date.japaneseMonthDay)
                        .font(UtakataFontStyle.retroMincho(size: 23, weight: .semibold))
                        .foregroundStyle(Color.primaryText)
                    Text(card == nil ? "投稿がありません" : "この日のうたかた")
                        .font(UtakataFontStyle.rounded(size: 13, weight: .medium))
                        .foregroundStyle(Color.secondaryText)
                }

                Spacer()

                if card == nil {
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

            if let card {
                MemoryPreviewCard(card: card)
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
        .taishoPanel(tint: card?.mood.accent ?? Color.meijiRed)
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
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var showingCamera = false
    @State private var mode = DiaryComposerMode.ai
    @State private var factText = ""
    @State private var manualUpperText = ""
    @State private var manualLowerText = ""
    @State private var manualHint: String?
    @State private var selectedTone = DiaryTone.joy
    @State private var selectedLowerIndex = 0
    @State private var isStoring = false
    @State private var sparkleBurst = false

    private var currentLowerPhrase: String {
        selectedTone.lowerOptions[safe: selectedLowerIndex] ?? selectedTone.lowerOptions[0]
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
        DiaryFactPhraseGenerator.upperPhrase(from: factText, tone: selectedTone)
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
                VStack(alignment: .leading, spacing: 16) {
                    HeaderView(title: "日記を作成", subtitle: "5秒で一首")

                    DiaryComposerModeSwitcher(mode: $mode)

                    DiarySourcePicker(
                        photoData: photoData,
                        selectedItem: $selectedPhotoItem,
                        onCameraTap: { showingCamera = true }
                    )

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

                    TonePickerStep(selectedTone: $selectedTone, selectedLowerIndex: $selectedLowerIndex)

                    if mode == .ai {
                        LowerPhraseSlotStep(
                            tone: selectedTone,
                            selectedIndex: $selectedLowerIndex
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
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                guard let data = try? await newItem?.loadTransferable(type: Data.self) else { return }
                await MainActor.run {
                    photoData = data
                }
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker { image in
                photoData = image.jpegData(compressionQuality: 0.84)
                showingCamera = false
            } onCancel: {
                showingCamera = false
            }
            .ignoresSafeArea()
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
    let photoData: Data?
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
                    photoData: photoData
                )
                .frame(width: 232, height: 358)
                .rotation3DEffect(.degrees(didOpen ? 0 : -78), axis: (x: 0, y: 1, z: 0), anchor: .leading, perspective: 0.72)
                .scaleEffect(isStoring ? 0.42 : 1)
                .offset(x: isStoring ? 92 : 0, y: isStoring ? 142 : 0)
                .rotationEffect(.degrees(isStoring ? 8 : 0))
                .opacity(didOpen ? (isStoring ? 0.28 : 1) : 0.2)
                .animation(.spring(response: 0.62, dampingFraction: 0.82), value: didOpen)
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

    private var allLines: [String] {
        Array(upperPhrase.prefix(3)) + lowerPhrase.tankaLowerLines()
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
                    Color(hex: 0xFFF5EC),
                    Color(hex: 0xF5DCE5),
                    Color(hex: 0xD8ECF2),
                    accent.opacity(0.14)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            WashiPattern()
                .opacity(0.24)

            TaishoCheckPattern(color: Color.meijiRed.opacity(0.025), tile: 24)

            OrnateOmikujiBorder()
                .stroke(Color.retroGold.opacity(0.58), lineWidth: 1)
                .padding(10)

            OrnateOmikujiBorder()
                .stroke(Color.meijiRed.opacity(0.22), lineWidth: 0.8)
                .padding(18)

            VStack(spacing: 12) {
                if let selectedImage {
                    RetroPhotoFrame(image: selectedImage)
                        .frame(height: 118)
                        .padding(.horizontal, 27)
                        .padding(.top, 46)
                } else {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(hex: 0xFFF9F2).opacity(0.44))
                        .frame(height: 56)
                        .padding(.horizontal, 42)
                        .padding(.top, 58)
                }

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
                .frame(maxHeight: .infinity, alignment: .center)
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }

            VStack {
                Text("うたかた日記")
                    .font(UtakataFontStyle.retroMincho(size: 13, weight: .semibold))
                    .foregroundStyle(Color.primaryText.opacity(0.8))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color(hex: 0xFFF9F2).opacity(0.82), in: Capsule())
                    .overlay(Capsule().stroke(Color.retroGold.opacity(0.36), lineWidth: 0.8))
                Spacer()
            }
            .padding(.top, 18)

            MemoryCornerRibbons(color: accent)
                .padding(10)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.meijiRed.opacity(0.25), lineWidth: 1.1))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.retroGold.opacity(0.48), lineWidth: 0.8).padding(6))
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
        DiaryFormSection {
            StepSectionTitle(number: "0", title: "写真")

            VStack(spacing: 13) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(hex: 0xFFF9F2).opacity(0.78))
                    TaishoCheckPattern(color: Color.meijiBlue.opacity(0.05), tile: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    if let selectedImage {
                        RetroPhotoFrame(image: selectedImage)
                            .padding(10)
                    } else {
                        VStack(spacing: 11) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 34, weight: .semibold))
                                .foregroundStyle(Color.meijiRed)
                            Text("今日の一枚を入れる")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(Color.primaryText)
                            Text("撮るか、ライブラリから選べます")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.secondaryText)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(height: 226)
                .clipped()
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.retroGold.opacity(0.34), lineWidth: 0.8))

                HStack(spacing: 12) {
                    Button(action: onCameraTap) {
                        SourceActionTile(title: photoData == nil ? "写真を撮る" : "撮り直す", systemImage: "camera.fill")
                    }
                    .buttonStyle(.plain)

                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        SourceActionTile(title: photoData == nil ? "ライブラリから選択" : "写真を変更", systemImage: "photo.on.rectangle")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
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
