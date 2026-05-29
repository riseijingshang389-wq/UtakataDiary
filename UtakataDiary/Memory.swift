import SwiftUI

struct MemoryView: View {
    let cards: [DiaryCard]
    @State private var selectedCardID: UUID?

    var selectedCard: DiaryCard {
        cards.first(where: { $0.id == selectedCardID }) ?? cards.first ?? DiaryCard.samples[0]
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                HeaderView(title: "メモリー", subtitle: "札棚")

                KarutaShelfView(cards: cards, selectedCardID: $selectedCardID)
            }
            .padding(.horizontal, 22)
            .padding(.top, 20)
        }
    }
}

struct KarutaShelfView: View {
    let cards: [DiaryCard]
    @Binding var selectedCardID: UUID?

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    RetroRibbonLabel(text: "札棚", tint: Color.meijiBlue)
                    Text("上の句だけを並べて、めくると日記がひらく")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.secondaryText)
                }

                Spacer()

                Text("和")
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.retroPaper)
                    .frame(width: 36, height: 36)
                    .background(Color.meijiRed, in: TaishoBadgeShape())
                    .overlay(TaishoBadgeShape().stroke(Color.retroGold.opacity(0.72), lineWidth: 1))
            }

            ZStack(alignment: .top) {
                VStack(spacing: 92) {
                    ForEach(0..<max(2, (cards.count + 2) / 3), id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(
                                LinearGradient(colors: [Color(hex: 0xB89A78).opacity(0.46), Color(hex: 0x6F5848).opacity(0.28)], startPoint: .top, endPoint: .bottom)
                            )
                            .frame(height: 14)
                            .shadow(color: Color(hex: 0x4B362B).opacity(0.16), radius: 8, x: 0, y: 5)
                    }
                }
                .padding(.top, 92)

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                        Button {
                            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                                selectedCardID = selectedCardID == card.id ? nil : card.id
                            }
                        } label: {
                            KarutaMemoryTile(
                                card: card,
                                isFlipped: selectedCardID == card.id,
                                angle: index.isMultiple(of: 2) ? -1.0 : 0.8
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(12)
        .background {
            ZStack {
                LinearGradient(colors: [Color(hex: 0xF0DFC3), Color(hex: 0xE7D3B4), Color(hex: 0xD8C3A3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                TaishoCheckPattern(color: Color.meijiBlue.opacity(0.08), tile: 26)
                WashiPattern()
                    .opacity(0.34)
                RetroCornerOrnaments(color: Color.meijiRed.opacity(0.34))
                    .padding(12)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primaryText.opacity(0.38), lineWidth: 1.1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.meijiRed.opacity(0.32), lineWidth: 0.9)
                .padding(6)
        )
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
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))

            KarutaDiaryBack(card: card)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
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
                Rectangle()
                    .fill(card.mood.accent.opacity(0.86))
                    .frame(height: 18)
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
        PoemCardView(
            upperPhrase: card.upperPhrase,
            lowerPhrase: card.lowerPhrase,
            mood: card.mood,
            compact: true,
            photoData: card.photoData
        )
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
