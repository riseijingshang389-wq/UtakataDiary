import SwiftUI

struct MemoryView: View {
    let cards: [DiaryCard]
    let onOpenSettings: () -> Void
    let onCreateDiary: (DiaryCard) -> Void
    @State private var selectedCard: DiaryCard?
    @State private var isCardFlipped = false
    @State private var showingComposer = false
    @State private var visibleMonth = Date.now
    @Namespace private var cardNamespace

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ja_JP")
        return calendar
    }

    private var monthCards: [DiaryCard] {
        let filtered = cards.filter { calendar.isDate($0.date, equalTo: visibleMonth, toGranularity: .month) }
        return filtered.isEmpty ? cards : filtered
    }

    var body: some View {
        ZStack {
            AppBackground()
            OmikujiPreDrawFantasyLayer()
                .opacity(0.52)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    ScreenHeaderWithSettings(
                        title: "メモリー",
                        subtitle: "記憶のかるた",
                        onOpenSettings: onOpenSettings
                    )
                        .padding(.top, 4)

                    MemoryMonthSwitcher(month: visibleMonth) {
                        visibleMonth = calendar.date(byAdding: .month, value: -1, to: visibleMonth) ?? visibleMonth
                    } onNext: {
                        visibleMonth = calendar.date(byAdding: .month, value: 1, to: visibleMonth) ?? visibleMonth
                    }

                    KarutaShelfView(cards: monthCards) { card in
                        open(card)
                    }
                    .environment(\.cardNamespace, cardNamespace)
                    .environment(\.selectedMemoryCardID, selectedCard?.id)
                }
                .padding(.horizontal, 22)
                .padding(.top, 20)
                .padding(.bottom, 196)
            }

            FloatingDiaryActionButton {
                showingComposer = true
            }
            .padding(.trailing, 24)
            .padding(.bottom, 148)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)

            if let selectedCard {
                MemoryCardOverlay(
                    card: selectedCard,
                    namespace: cardNamespace,
                    isFlipped: isCardFlipped,
                    onClose: close
                )
                .zIndex(20)
            }
        }
        .sheet(isPresented: $showingComposer) {
            DiaryComposerView { card in
                onCreateDiary(card)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private func open(_ card: DiaryCard) {
        withAnimation(.spring(response: 0.46, dampingFraction: 0.82)) {
            selectedCard = card
            isCardFlipped = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            withAnimation(.spring(response: 0.62, dampingFraction: 0.82)) {
                isCardFlipped = true
            }
        }
    }

    private func close() {
        withAnimation(.spring(response: 0.46, dampingFraction: 0.86)) {
            isCardFlipped = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                selectedCard = nil
            }
        }
    }
}

private struct CardNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

private struct SelectedMemoryCardIDKey: EnvironmentKey {
    static let defaultValue: UUID? = nil
}

private extension EnvironmentValues {
    var cardNamespace: Namespace.ID? {
        get { self[CardNamespaceKey.self] }
        set { self[CardNamespaceKey.self] = newValue }
    }

    var selectedMemoryCardID: UUID? {
        get { self[SelectedMemoryCardIDKey.self] }
        set { self[SelectedMemoryCardIDKey.self] = newValue }
    }
}

struct MemoryMonthSwitcher: View {
    let month: Date
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.headline.weight(.bold))
                    .frame(width: 38, height: 38)
                    .background(Color.retroPaper.opacity(0.72), in: Circle())
                    .overlay(Circle().stroke(Color.retroGold.opacity(0.44), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            VStack(spacing: 3) {
                Text(month.classicalMonthName)
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.primaryText)
                Text(month.memoryMonthYear)
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(Color.secondaryText)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 28)
            .background(Color(hex: 0xFFF5E1).opacity(0.74), in: TicketButtonShape())
            .overlay(TicketButtonShape().stroke(Color.meijiRed.opacity(0.38), lineWidth: 1))
            .overlay(TicketButtonShape().stroke(Color.retroGold.opacity(0.38), lineWidth: 0.8).padding(5))

            Spacer(minLength: 0)

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.headline.weight(.bold))
                    .frame(width: 38, height: 38)
                    .background(Color.retroPaper.opacity(0.72), in: Circle())
                    .overlay(Circle().stroke(Color.retroGold.opacity(0.44), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(Color.meijiRed)
    }
}

struct KarutaShelfView: View {
    let cards: [DiaryCard]
    let onSelect: (DiaryCard) -> Void
    @Environment(\.cardNamespace) private var namespace
    @Environment(\.selectedMemoryCardID) private var selectedCardID

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(cards) { card in
                    Button(action: { onSelect(card) }) {
                        MiniOmikujiMemoryCard(card: card)
                            .modifier(MemoryMatchedCardModifier(cardID: card.id, namespace: namespace))
                            .opacity(selectedCardID == card.id ? 0.08 : 1)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background {
            ZStack {
                Color(hex: 0xFFF9F2).opacity(0.9)
                WashiPattern()
                    .opacity(0.13)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.meijiRed.opacity(0.24), lineWidth: 0.8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.retroGold.opacity(0.24), lineWidth: 0.7)
                .padding(4)
        )
    }
}

private struct MemoryMatchedCardModifier: ViewModifier {
    let cardID: UUID
    let namespace: Namespace.ID?

    func body(content: Content) -> some View {
        if let namespace {
            content.matchedGeometryEffect(id: cardID, in: namespace)
        } else {
            content
        }
    }
}

struct MiniOmikujiMemoryCard: View {
    let card: DiaryCard

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: 0xFFF5EC),
                    Color(hex: 0xF5DCE5),
                    Color(hex: 0xD8ECF2),
                    card.mood.accent.opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            WashiPattern()
                .opacity(0.24)

            OrnateOmikujiBorder()
                .stroke(Color.retroGold.opacity(0.6), lineWidth: 0.85)
                .padding(7)

            MemoryCornerRibbons(color: card.mood.accent)
                .padding(7)

            DoveSilhouette()
                .fill(Color.white.opacity(0.58))
                .frame(width: 22, height: 14)
                .rotationEffect(.degrees(-12))
                .offset(x: 23, y: -38)

            VStack(spacing: 10) {
                HStack {
                    Text(card.date.karutaDay)
                        .font(.caption2.monospacedDigit().weight(.bold))
                        .foregroundStyle(card.mood.accent)
                    Spacer()
                    Circle()
                        .fill(Color.retroGold.opacity(0.72))
                        .frame(width: 8, height: 8)
                }

                Spacer(minLength: 2)

                HStack(alignment: .center, spacing: 6) {
                    ForEach(Array(card.upperPhrase.prefix(3).enumerated()).reversed(), id: \.offset) { _, line in
                        VerticalText(line, spacing: 2.8)
                            .font(UtakataFontStyle.handLetter(size: 10.5, weight: .semibold))
                            .foregroundStyle(Color.primaryText)
                            .frame(width: 13)
                    }
                }
                .frame(maxWidth: .infinity)

                Spacer(minLength: 2)

                Text("取り札")
                    .font(UtakataFontStyle.retroMincho(size: 10, weight: .semibold))
                    .foregroundStyle(Color.primaryText.opacity(0.62))
                    .lineLimit(1)
            }
            .padding(12)
        }
        .aspectRatio(0.68, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.meijiRed.opacity(0.26), lineWidth: 0.9))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.retroGold.opacity(0.38), lineWidth: 0.7).padding(5))
        .shadow(color: card.mood.accent.opacity(0.12), radius: 10, x: 0, y: 5)
    }
}

struct MemoryCornerRibbons: View {
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ribbon
                    .position(x: 12, y: 12)
                ribbon
                    .rotationEffect(.degrees(90))
                    .position(x: proxy.size.width - 12, y: 12)
                ribbon
                    .rotationEffect(.degrees(-90))
                    .position(x: 12, y: proxy.size.height - 12)
                ribbon
                    .rotationEffect(.degrees(180))
                    .position(x: proxy.size.width - 12, y: proxy.size.height - 12)
            }
        }
        .allowsHitTesting(false)
    }

    private var ribbon: some View {
        ZStack {
            Capsule()
                .fill(color.opacity(0.72))
                .frame(width: 22, height: 6)
                .rotationEffect(.degrees(38))
            Capsule()
                .fill(Color.retroGold.opacity(0.62))
                .frame(width: 20, height: 4)
                .rotationEffect(.degrees(-38))
        }
    }
}

struct VintageUmbrellaGirl: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Parasol canopy.
        path.move(to: CGPoint(x: w * 0.12, y: h * 0.24))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.88, y: h * 0.24),
            control: CGPoint(x: w * 0.50, y: h * -0.03)
        )
        path.addLine(to: CGPoint(x: w * 0.54, y: h * 0.40))
        path.closeSubpath()

        // Parasol handle.
        path.move(to: CGPoint(x: w * 0.51, y: h * 0.28))
        path.addLine(to: CGPoint(x: w * 0.55, y: h * 0.28))
        path.addLine(to: CGPoint(x: w * 0.52, y: h * 0.82))
        path.addLine(to: CGPoint(x: w * 0.48, y: h * 0.82))
        path.closeSubpath()

        // Hair.
        path.move(to: CGPoint(x: w * 0.36, y: h * 0.40))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.66, y: h * 0.41),
            control: CGPoint(x: w * 0.50, y: h * 0.26)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.60, y: h * 0.61),
            control: CGPoint(x: w * 0.74, y: h * 0.52)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.34, y: h * 0.62),
            control: CGPoint(x: w * 0.43, y: h * 0.68)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.36, y: h * 0.40),
            control: CGPoint(x: w * 0.26, y: h * 0.50)
        )
        path.closeSubpath()

        // Face.
        path.addEllipse(in: CGRect(x: w * 0.39, y: h * 0.40, width: w * 0.20, height: h * 0.15))

        // Ribbon brooch.
        path.move(to: CGPoint(x: w * 0.35, y: h * 0.57))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.49, y: h * 0.59),
            control: CGPoint(x: w * 0.43, y: h * 0.50)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.35, y: h * 0.57),
            control: CGPoint(x: w * 0.42, y: h * 0.66)
        )
        path.closeSubpath()

        path.move(to: CGPoint(x: w * 0.65, y: h * 0.57))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.51, y: h * 0.59),
            control: CGPoint(x: w * 0.57, y: h * 0.50)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.65, y: h * 0.57),
            control: CGPoint(x: w * 0.58, y: h * 0.66)
        )
        path.closeSubpath()

        // Kimono.
        path.move(to: CGPoint(x: w * 0.28, y: h * 0.95))
        path.addLine(to: CGPoint(x: w * 0.40, y: h * 0.58))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.61, y: h * 0.58),
            control: CGPoint(x: w * 0.50, y: h * 0.64)
        )
        path.addLine(to: CGPoint(x: w * 0.76, y: h * 0.95))
        path.closeSubpath()

        // Sleeve.
        path.move(to: CGPoint(x: w * 0.29, y: h * 0.66))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.16, y: h * 0.84),
            control: CGPoint(x: w * 0.12, y: h * 0.70)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.34, y: h * 0.78),
            control: CGPoint(x: w * 0.23, y: h * 0.90)
        )
        path.closeSubpath()

        path.move(to: CGPoint(x: w * 0.70, y: h * 0.66))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.88, y: h * 0.84),
            control: CGPoint(x: w * 0.90, y: h * 0.70)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.66, y: h * 0.78),
            control: CGPoint(x: w * 0.80, y: h * 0.91)
        )
        path.closeSubpath()

        return path
    }
}

struct MemoryCardOverlay: View {
    let card: DiaryCard
    let namespace: Namespace.ID
    let isFlipped: Bool
    let onClose: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.opacity(0.36)
                    .ignoresSafeArea()
                    .onTapGesture(perform: onClose)

                MemoryExpandedFlipCard(card: card, isFlipped: isFlipped)
                    .matchedGeometryEffect(id: card.id, in: namespace)
                    .frame(
                        width: min(proxy.size.width * 0.74, 304),
                        height: min(proxy.size.height * 0.64, 520)
                    )
                    .onTapGesture(perform: onClose)
                    .shadow(color: Color.black.opacity(0.28), radius: 30, x: 0, y: 20)
            }
        }
        .transition(.opacity)
    }
}

struct MemoryExpandedFlipCard: View {
    let card: DiaryCard
    let isFlipped: Bool

    var body: some View {
        ZStack {
            MiniOmikujiMemoryCard(card: card)
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.78)

            MemoryKarutaBackCard(card: card)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0), perspective: 0.78)
        }
        .scaleEffect(isFlipped ? 1.02 : 1)
    }
}

struct MemoryKarutaBackCard: View {
    let card: DiaryCard

    private var poemLines: [String] {
        Array(card.upperPhrase.prefix(3)) + card.lowerPhrase.tankaLowerLines()
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: 0xFFF5EC),
                    Color(hex: 0xF5DCE5),
                    Color(hex: 0xD8ECF2),
                    card.mood.accent.opacity(0.14)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            WashiPattern()
                .opacity(0.24)

            ForEach(0..<14, id: \.self) { index in
                Image(systemName: index.isMultiple(of: 3) ? "sparkles" : "sparkle")
                    .font(.system(size: CGFloat(8 + (index % 4) * 3), weight: .semibold))
                    .foregroundStyle(index.isMultiple(of: 2) ? Color.retroGold.opacity(0.74) : Color(hex: 0xF6B5C1).opacity(0.66))
                    .offset(x: sparkleOffsets[index].0, y: sparkleOffsets[index].1)
            }

            ForEach(0..<7, id: \.self) { index in
                SakuraPetalShape()
                    .fill(index.isMultiple(of: 2) ? Color(hex: 0xF4B7C2).opacity(0.54) : Color(hex: 0xFFF2D8).opacity(0.42))
                    .frame(width: CGFloat(12 + (index % 3) * 3), height: CGFloat(18 + (index % 2) * 4))
                    .rotationEffect(.degrees(Double(index * 29)))
                    .offset(x: petalOffsets[index].0, y: petalOffsets[index].1)
            }

            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.retroGold.opacity(0.62), lineWidth: 1.2)
                .padding(12)

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.meijiRed.opacity(0.2), lineWidth: 0.8)
                .padding(22)

            MemoryCornerRibbons(color: card.mood.accent)
                .padding(14)

            VintageUmbrellaGirl()
                .fill(Color.primaryText.opacity(0.12))
                .frame(width: 92, height: 150)
                .offset(x: -78, y: 120)

            DoveSilhouette()
                .fill(Color.white.opacity(0.66))
                .frame(width: 42, height: 27)
                .rotationEffect(.degrees(-10))
                .offset(x: 88, y: -162)

            VStack(spacing: 15) {
                HStack {
                    Text(card.date.memoryTitle)
                        .font(UtakataFontStyle.handLetter(size: 14, weight: .semibold))
                        .foregroundStyle(Color.primaryText)
                    Spacer()
                    HStack(spacing: 5) {
                        PlumBlossom()
                            .fill(card.mood.accent.opacity(0.94))
                            .frame(width: 20, height: 20)
                        Text(emotionLabel)
                            .font(UtakataFontStyle.handLetter(size: 11, weight: .bold))
                            .foregroundStyle(Color.primaryText)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(hex: 0xFFF9F2).opacity(0.62), in: Capsule())
                    .overlay(Capsule().stroke(Color.retroGold.opacity(0.58), lineWidth: 0.8))
                }

                Spacer(minLength: 4)

                HStack(alignment: .top, spacing: 12) {
                    ForEach(Array(poemLines.enumerated()).reversed(), id: \.offset) { index, line in
                        VerticalText(line, spacing: index >= 3 ? 4.1 : 4.6)
                            .font(UtakataFontStyle.handLetter(size: index >= 3 ? 18 : 20, weight: .semibold))
                            .foregroundStyle(Color.primaryText)
                            .frame(width: index >= 3 ? 24 : 27)
                    }
                }
                .padding(.vertical, 22)
                .padding(.horizontal, 18)
                .background(Color(hex: 0xFFF9F2).opacity(0.42), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.retroGold.opacity(0.36), lineWidth: 0.8))

                Spacer(minLength: 4)

                Text(card.placeHint)
                    .font(UtakataFontStyle.handLetter(size: 14, weight: .medium))
                    .foregroundStyle(Color.primaryText.opacity(0.72))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .padding(30)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.meijiRed.opacity(0.24), lineWidth: 1.1))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.retroGold.opacity(0.58), lineWidth: 0.8).padding(7))
    }

    private var emotionLabel: String {
        switch card.mood {
        case .dawn: return "喜"
        case .rain: return "穏"
        case .evening: return "怒"
        case .night: return "憂"
        }
    }

    private var sparkleOffsets: [(CGFloat, CGFloat)] {
        [(-92, -168), (-36, -196), (82, -176), (104, -88), (-108, -64), (-54, 18), (92, 28), (-102, 112), (-28, 156), (88, 142), (0, -116), (44, 98), (-80, 198), (112, 202)]
    }

    private var petalOffsets: [(CGFloat, CGFloat)] {
        [(-96, -126), (88, -116), (-118, -4), (108, 58), (-76, 128), (54, 178), (0, -206)]
    }
}

struct MemoryDetailSheet: View {
    let card: DiaryCard

    var body: some View {
        ZStack {
            AppBackground()
            OmikujiPreDrawFantasyLayer()
                .opacity(0.46)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    Text(card.date.memoryTitle)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color.primaryText)
                        .padding(.top, 20)

                    PoemCardView(
                        upperPhrase: card.upperPhrase,
                        lowerPhrase: card.lowerPhrase,
                        mood: card.mood,
                        compact: true,
                        photoData: card.photoData
                    )
                    .frame(width: 236, height: 360)

                    Text(card.placeHint)
                        .font(.body)
                        .foregroundStyle(Color.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color(hex: 0xFFF9F2).opacity(0.9), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

struct WoodenDrawerShelfPattern: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<8, id: \.self) { index in
                    let y = CGFloat(index) * proxy.size.height / 7
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: 0x6D452F).opacity(0.18),
                                    Color(hex: 0xFFF0D2).opacity(0.22),
                                    Color(hex: 0x4D3024).opacity(0.16)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: index.isMultiple(of: 2) ? 2.2 : 1.1)
                        .offset(y: y - proxy.size.height / 2)
                }

                ForEach(0..<4, id: \.self) { index in
                    Rectangle()
                        .fill(Color(hex: 0x5A392A).opacity(0.08))
                        .frame(width: 1)
                        .offset(x: CGFloat(index - 1) * proxy.size.width / 3)
                }
            }
        }
    }
}

struct WashiPattern: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            let spacing: CGFloat = 18

            stride(from: -size.height, through: size.width, by: spacing).forEach { start in
                path.move(to: CGPoint(x: start, y: 0))
                path.addLine(to: CGPoint(x: start + size.height, y: size.height))
            }

            context.stroke(path, with: .color(Color.white.opacity(0.32)), lineWidth: 0.8)
        }
    }
}

struct KarutaMemoryTile: View {
    let card: DiaryCard
    let isFlipped: Bool
    let angle: Double

    var body: some View {
        ZStack {
            ModernKarutaFront(card: card)
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.72)

            KarutaDiaryBack(card: card)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0), perspective: 0.72)
        }
        .aspectRatio(0.62, contentMode: .fit)
        .rotationEffect(.degrees(isFlipped ? 0 : angle))
        .scaleEffect(isFlipped ? 1.0 : 0.98)
        .shadow(color: card.mood.accent.opacity(isFlipped ? 0.32 : 0.16), radius: isFlipped ? 20 : 10, x: 0, y: isFlipped ? 12 : 5)
    }
}

struct ModernKarutaFront: View {
    let card: DiaryCard

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.retroPaper, Color(hex: 0xEFE1C8), card.mood.accent.opacity(0.18)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            WashiPattern()
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .opacity(0.42)

            VStack {
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(card.mood.accent.opacity(0.86))
                        .frame(width: 42, height: 18)
                        .clipShape(TicketButtonShape())
                    Spacer()
                    Circle()
                        .fill(
                            RadialGradient(colors: [Color(hex: 0xFFF5C8), Color.retroGold], center: .topLeading, startRadius: 1, endRadius: 12)
                        )
                        .frame(width: 15, height: 15)
                        .shadow(color: Color.retroGold.opacity(0.25), radius: 5, x: 0, y: 2)
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                Spacer()
                Rectangle()
                    .fill(Color.meijiBlue.opacity(0.18))
                    .frame(height: 12)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .stroke(Color.primaryText.opacity(0.6), lineWidth: 1.2)
                .padding(9)

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .stroke(card.mood.accent.opacity(0.42), lineWidth: 0.9)
                .padding(15)

            RetroCornerOrnaments(color: card.mood.accent.opacity(0.42))
                .padding(13)

            VStack(spacing: 14) {
                HStack {
                    Spacer()
                    Text("上")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.retroPaper)
                        .frame(width: 28, height: 28)
                        .background(card.mood.accent.opacity(0.92), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(Color.retroGold.opacity(0.72), lineWidth: 1)
                        )
                }

                Spacer(minLength: 2)

                HStack(alignment: .center, spacing: 13) {
                    ForEach(Array(card.upperPhrase.prefix(3).enumerated()).reversed(), id: \.offset) { _, line in
                        VerticalPoemLine(
                            text: line,
                            isLowerPhrase: false,
                            accent: card.mood.accent,
                            compact: true
                        )
                    }
                }

                Spacer(minLength: 2)

                HStack {
                    Text(card.date.karutaDay)
                        .font(.caption2.monospacedDigit().weight(.bold))
                        .foregroundStyle(card.mood.accent)
                    Spacer()
                    HStack(spacing: 5) {
                        Circle()
                            .fill(card.mood.accent.opacity(0.55))
                            .frame(width: 6, height: 6)
                        Circle()
                            .fill(Color(hex: 0x8B4D44).opacity(0.38))
                            .frame(width: 6, height: 6)
                    }
                }
            }
            .padding(18)
        }
    }
}

struct KarutaDiaryBack: View {
    let card: DiaryCard

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0xFFF8EA), Color(hex: 0xF2E1C7), card.mood.accent.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            WashiPattern()
                .opacity(0.36)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(spacing: 10) {
                Text(card.date.karutaDay)
                    .font(.caption2.monospacedDigit().weight(.black))
                    .foregroundStyle(card.mood.accent)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Color.retroPaper.opacity(0.68), in: Capsule())

                HStack(alignment: .top, spacing: 9) {
                    ForEach(Array(card.lowerPhrase.tankaLowerLines().enumerated()).reversed(), id: \.offset) { _, line in
                        VerticalPoemLine(text: line, isLowerPhrase: true, accent: card.mood.accent, compact: true)
                    }
                }
                .padding(.vertical, 6)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(["今日の気配", card.placeHint, card.upperPhrase.joined(separator: " / ")], id: \.self) { line in
                        Text(line)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.primaryText.opacity(0.78))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(9)
                .background {
                    ZStack {
                        Color(hex: 0xFFFDF5).opacity(0.62)
                        VStack(spacing: 7) {
                            ForEach(0..<5, id: \.self) { _ in
                                Rectangle()
                                    .fill(Color.meijiBlue.opacity(0.09))
                                    .frame(height: 0.8)
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.retroGold.opacity(0.24), lineWidth: 0.8))
            }
            .padding(14)

            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .stroke(Color.primaryText.opacity(0.48), lineWidth: 1.1)
                .padding(9)

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .stroke(card.mood.accent.opacity(0.32), lineWidth: 0.9)
                .padding(15)
        }
    }
}

struct MemoryPreviewCard: View {
    let card: DiaryCard

    var body: some View {
        HStack(spacing: 18) {
            PoemCardView(
                upperPhrase: card.upperPhrase,
                lowerPhrase: card.lowerPhrase,
                mood: card.mood,
                compact: true,
                photoData: card.photoData
            )
            .frame(width: 118, height: 180)

            VStack(alignment: .leading, spacing: 10) {
                Text(card.date.memoryTitle)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.primaryText)
                Text(card.upperPhrase.joined(separator: " / "))
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.secondaryText)
                    .lineLimit(2)
                Text(card.lowerPhrase)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondaryText.opacity(0.82))
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .background(Color.cardFill, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(.white.opacity(0.7), lineWidth: 1)
        )
    }
}

extension Date {
    var memoryMonthYear: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年 M月"
        return formatter.string(from: self)
    }

    var classicalMonthName: String {
        let month = Calendar.current.component(.month, from: self)
        let names = ["睦月", "如月", "弥生", "卯月", "皐月", "水無月", "文月", "葉月", "長月", "神無月", "霜月", "師走"]
        return names[max(0, min(month - 1, names.count - 1))]
    }
}
