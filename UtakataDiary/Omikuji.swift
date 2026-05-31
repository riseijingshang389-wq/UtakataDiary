import SwiftUI

struct FortuneView: View {
    @State private var showingQuiz = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                HeaderView(title: "うたかたみくじ", subtitle: "未来ログの伏線")

                ProphecyOmikujiCard()

                ProphecyQuestCard()

                DaytimeQuizCard {
                    showingQuiz = true
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 20)
        }
        .sheet(isPresented: $showingQuiz) {
            QuizView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

struct MorningOmikujiDrawView: View {
    let onClose: () -> Void
    @State private var isShaking = false
    @State private var didDraw = false
    @State private var stickOffset: CGFloat = 0

    var body: some View {
        ZStack {
            OmikujiPaperBackground()

            if didDraw {
                OmikujiResultScreen(onClose: onClose)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                OmikujiDrawStage(
                    isShaking: isShaking,
                    stickOffset: stickOffset,
                    onSkip: onClose
                ) {
                    isShaking.toggle()
                    stickOffset = -18
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                        withAnimation(.spring(response: 0.7, dampingFraction: 0.78)) {
                            didDraw = true
                        }
                    }
                }
            }
        }
        .overlay(alignment: .topLeading) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.primaryText)
                    .frame(width: 42, height: 42)
                    .background(Color.retroPaper.opacity(0.82), in: Circle())
                    .overlay(Circle().stroke(Color.primaryText.opacity(0.28), lineWidth: 1))
                    .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
            }
            .padding(.top, 16)
            .padding(.leading, 18)
        }
    }
}

struct OmikujiDrawStage: View {
    let isShaking: Bool
    let stickOffset: CGFloat
    let onSkip: () -> Void
    let onDraw: () -> Void
    @State private var isBreathing = false

    var body: some View {
        GeometryReader { proxy in
            let cardWidth = min(proxy.size.width * 0.78, 306)
            let cardHeight = min(max(proxy.size.height * 0.43, 292), 360)

            ZStack {
                OmikujiPreDrawFantasyLayer()

                VStack(spacing: 0) {
                    OmikujiHeader()
                        .padding(.top, 54)
                        .padding(.bottom, 10)

                    Text("今日の予兆を、ひとひら")
                        .font(UtakataFontStyle.retroMincho(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: 0x7D3B36))
                        .padding(.vertical, 7)
                        .padding(.horizontal, 18)
                        .background(Color(hex: 0xFFF7E5).opacity(0.72), in: Capsule())
                        .overlay(Capsule().stroke(Color.retroGold.opacity(0.42), lineWidth: 0.9))
                        .padding(.bottom, 18)

                    Spacer(minLength: 4)

                    OmikujiInvitationCard(stickOffset: stickOffset)
                        .frame(width: cardWidth, height: cardHeight)
                        .rotationEffect(.degrees(isShaking ? -3.0 : 3.0))
                        .offset(y: isBreathing ? -4 : 3)
                        .shadow(color: Color(hex: 0x8B2F3B).opacity(0.28), radius: 26, x: 0, y: 18)
                        .animation(.easeInOut(duration: 0.12).repeatCount(8, autoreverses: true), value: isShaking)
                        .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: isBreathing)

                    Spacer(minLength: 18)

                    Button(action: onDraw) {
                        OmikujiTicketDrawButton(isBreathing: isBreathing)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 12)

                    Button(action: onSkip) {
                        Text("みくじを引かない")
                            .font(UtakataFontStyle.rounded(size: 13, weight: .semibold))
                            .foregroundStyle(Color(hex: 0x7B6660).opacity(0.88))
                            .padding(.vertical, 9)
                            .padding(.horizontal, 18)
                            .background(Color(hex: 0xFFF7E5).opacity(0.42), in: Capsule())
                            .overlay(Capsule().stroke(Color.retroGold.opacity(0.24), lineWidth: 0.8))
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 28)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
            .clipped()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.9).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
        }
    }
}

struct OmikujiPreDrawFantasyLayer: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: 0xFFF3E6).opacity(0.72),
                        Color(hex: 0xF7D3D9).opacity(0.38),
                        Color(hex: 0xF9E8C4).opacity(0.54)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                RadialGradient(
                    colors: [Color(hex: 0xC93D4C).opacity(0.24), .clear],
                    center: .topTrailing,
                    startRadius: 12,
                    endRadius: proxy.size.width * 0.86
                )
                .ignoresSafeArea()

                RadialGradient(
                    colors: [Color(hex: 0xE9A3B2).opacity(0.24), .clear],
                    center: .bottomLeading,
                    startRadius: 18,
                    endRadius: proxy.size.width * 0.8
                )
                .ignoresSafeArea()

                WavePattern()
                    .stroke(Color.retroGold.opacity(0.12), lineWidth: 0.8)
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .opacity(0.55)

                TaishoCheckPattern(color: Color.primaryText.opacity(0.028), tile: 30)
                    .ignoresSafeArea()

                WagasaArc()
                    .stroke(Color(hex: 0xB9343D).opacity(0.58), lineWidth: 1.3)
                    .frame(width: 260, height: 150)
                    .rotationEffect(.degrees(-18))
                    .offset(x: proxy.size.width * 0.32, y: -48)

                WagasaArc()
                    .stroke(Color(hex: 0xF0B5BE).opacity(0.48), lineWidth: 1.0)
                    .frame(width: 230, height: 135)
                    .rotationEffect(.degrees(160))
                    .offset(x: -proxy.size.width * 0.32, y: proxy.size.height * 0.52)

                OmikujiRibbonLine()
                    .stroke(Color(hex: 0xB9343D).opacity(0.34), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                    .frame(width: proxy.size.width * 1.16, height: 210)
                    .rotationEffect(.degrees(-8))
                    .offset(x: 14, y: proxy.size.height * 0.22)

                OmikujiRibbonLine()
                    .stroke(Color.retroGold.opacity(0.38), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
                    .frame(width: proxy.size.width * 1.08, height: 160)
                    .rotationEffect(.degrees(12))
                    .offset(x: -8, y: proxy.size.height * 0.58)

                ForEach(0..<12, id: \.self) { index in
                    OmikujiFloatingSparkle(index: index)
                        .position(
                            x: sparklePosition(index: index, size: proxy.size).x,
                            y: sparklePosition(index: index, size: proxy.size).y
                        )
                }

                ForEach(0..<8, id: \.self) { index in
                    SakuraPetalShape()
                        .fill(index.isMultiple(of: 2) ? Color(hex: 0xE96E8A).opacity(0.36) : Color(hex: 0xF4B7C2).opacity(0.42))
                        .frame(width: CGFloat(15 + (index % 3) * 4), height: CGFloat(20 + (index % 2) * 4))
                        .rotationEffect(.degrees(Double(index * 31)))
                        .position(
                            x: petalPosition(index: index, size: proxy.size).x,
                            y: petalPosition(index: index, size: proxy.size).y
                        )
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func sparklePosition(index: Int, size: CGSize) -> CGPoint {
        let values: [(CGFloat, CGFloat)] = [
            (0.14, 0.20), (0.82, 0.16), (0.72, 0.30), (0.22, 0.36),
            (0.88, 0.48), (0.12, 0.55), (0.77, 0.67), (0.28, 0.73),
            (0.52, 0.13), (0.46, 0.83), (0.09, 0.82), (0.92, 0.78)
        ]
        let pair = values[index % values.count]
        return CGPoint(x: size.width * pair.0, y: size.height * pair.1)
    }

    private func petalPosition(index: Int, size: CGSize) -> CGPoint {
        let values: [(CGFloat, CGFloat)] = [
            (0.18, 0.13), (0.67, 0.20), (0.91, 0.28), (0.08, 0.42),
            (0.83, 0.57), (0.17, 0.69), (0.67, 0.82), (0.34, 0.88)
        ]
        let pair = values[index % values.count]
        return CGPoint(x: size.width * pair.0, y: size.height * pair.1)
    }
}

struct OmikujiInvitationCard: View {
    let stickOffset: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0xB9343D), Color(hex: 0x8C303A), Color(hex: 0x2D4E55)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                WavePattern()
                    .stroke(Color(hex: 0xF3D6A3).opacity(0.24), lineWidth: 0.9)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))

                WagasaArc()
                    .stroke(Color(hex: 0xF7D4A3).opacity(0.34), lineWidth: 1.1)
                    .frame(width: width * 0.92, height: height * 0.34)
                    .rotationEffect(.degrees(-12))
                    .offset(x: width * 0.16, y: -height * 0.34)

                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color(hex: 0xF5D9A8), lineWidth: 2.1)
                    .padding(13)

                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(hex: 0xFFF2D0).opacity(0.82), lineWidth: 0.9)
                    .padding(23)

                OmikujiCardCornerOrnaments()
                    .stroke(Color(hex: 0xF5D9A8).opacity(0.78), style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
                    .padding(24)

                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0xFFF8EA).opacity(0.96), Color(hex: 0xF2DDBB).opacity(0.92)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: width * 0.42, height: height * 0.64)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: 0x8B4D44).opacity(0.46), lineWidth: 1.1))
                    .overlay(
                        VStack(spacing: 12) {
                            PlumBlossom()
                                .fill(Color(hex: 0xC64650).opacity(0.86))
                                .frame(width: 28, height: 28)

                            VerticalText("うたかたみくじ", spacing: 5)
                                .font(UtakataFontStyle.retroMincho(size: 19, weight: .semibold))
                                .foregroundStyle(Color(hex: 0x211B17))

                            Image(systemName: "sparkles")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(Color.retroGold)
                        }
                        .padding(.vertical, 18)
                    )

                Text("予兆の短札")
                    .font(UtakataFontStyle.retroMincho(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: 0xFFF8EA))
                    .padding(.vertical, 6)
                    .padding(.horizontal, 14)
                    .background(Color(hex: 0x2D4E55).opacity(0.66), in: TicketButtonShape())
                    .overlay(TicketButtonShape().stroke(Color.retroGold.opacity(0.72), lineWidth: 0.8))
                    .offset(y: -height * 0.39 + stickOffset * 0.18)

                PlumBlossom()
                    .fill(Color(hex: 0xF2B0BE).opacity(0.88))
                    .frame(width: 36, height: 36)
                    .offset(x: -width * 0.34, y: -height * 0.31)

                PlumBlossom()
                    .fill(Color(hex: 0xD4464F).opacity(0.8))
                    .frame(width: 30, height: 30)
                    .offset(x: width * 0.35, y: height * 0.29)

                ForEach(0..<7, id: \.self) { index in
                    Image(systemName: index.isMultiple(of: 2) ? "sparkle" : "sparkles")
                        .font(.system(size: index.isMultiple(of: 2) ? 11 : 14, weight: .semibold))
                        .foregroundStyle(index.isMultiple(of: 2) ? Color(hex: 0xFFF2C2) : Color(hex: 0xF4B7C2))
                        .offset(x: sparkleOffsets[index].0 * width, y: sparkleOffsets[index].1 * height)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color(hex: 0x4D3734).opacity(0.78), lineWidth: 1.4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.retroGold.opacity(0.7), lineWidth: 0.9)
                    .padding(8)
            )
        }
    }

    private var sparkleOffsets: [(CGFloat, CGFloat)] {
        [(-0.31, -0.15), (-0.18, 0.29), (0.29, -0.21), (0.22, 0.09), (-0.05, -0.33), (0.36, 0.35), (-0.35, 0.36)]
    }
}

struct OmikujiTicketDrawButton: View {
    let isBreathing: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .semibold))
            Text("うたかたみくじを引く")
                .font(UtakataFontStyle.retroMincho(size: 17, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.78)
            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .semibold))
        }
        .foregroundStyle(Color(hex: 0xFFF8EA))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 17)
        .background(
            LinearGradient(
                colors: [Color(hex: 0xB9343D), Color(hex: 0x7F3340)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: TicketButtonShape()
        )
        .overlay(TicketButtonShape().stroke(Color(hex: 0xF6DA9D), lineWidth: 2.0))
        .overlay(TicketButtonShape().stroke(Color(hex: 0xFFF8D7).opacity(0.78), lineWidth: 0.8).padding(5))
        .shadow(color: Color(hex: 0xB9343D).opacity(isBreathing ? 0.34 : 0.18), radius: isBreathing ? 22 : 12, x: 0, y: 10)
        .scaleEffect(isBreathing ? 1.018 : 0.988)
        .offset(y: isBreathing ? -2 : 2)
    }
}

struct OmikujiFloatingSparkle: View {
    let index: Int

    var body: some View {
        Image(systemName: index.isMultiple(of: 3) ? "sparkles" : "sparkle")
            .font(.system(size: CGFloat(10 + (index % 4) * 3), weight: .semibold))
            .foregroundStyle(index.isMultiple(of: 2) ? Color.retroGold.opacity(0.62) : Color(hex: 0xE56A82).opacity(0.52))
            .blur(radius: index.isMultiple(of: 5) ? 0.8 : 0)
    }
}

struct OmikujiRibbonLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX - 20, y: rect.midY + 28))
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.midY - 34),
            control1: CGPoint(x: rect.minX + rect.width * 0.22, y: rect.minY + 28),
            control2: CGPoint(x: rect.minX + rect.width * 0.34, y: rect.maxY + 18)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX + 20, y: rect.midY + 10),
            control1: CGPoint(x: rect.minX + rect.width * 0.68, y: rect.minY - 8),
            control2: CGPoint(x: rect.minX + rect.width * 0.82, y: rect.maxY - 28)
        )
        return path
    }
}

struct OmikujiCardCornerOrnaments: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let length = min(rect.width, rect.height) * 0.18

        func corner(_ origin: CGPoint, sx: CGFloat, sy: CGFloat) {
            path.move(to: CGPoint(x: origin.x + sx * length, y: origin.y))
            path.addQuadCurve(
                to: CGPoint(x: origin.x, y: origin.y + sy * length),
                control: CGPoint(x: origin.x + sx * length * 0.42, y: origin.y + sy * length * 0.42)
            )
            path.move(to: CGPoint(x: origin.x + sx * length * 0.55, y: origin.y + sy * 7))
            path.addLine(to: CGPoint(x: origin.x + sx * length * 0.92, y: origin.y + sy * 7))
            path.move(to: CGPoint(x: origin.x + sx * 7, y: origin.y + sy * length * 0.55))
            path.addLine(to: CGPoint(x: origin.x + sx * 7, y: origin.y + sy * length * 0.92))
        }

        corner(CGPoint(x: rect.minX, y: rect.minY), sx: 1, sy: 1)
        corner(CGPoint(x: rect.maxX, y: rect.minY), sx: -1, sy: 1)
        corner(CGPoint(x: rect.minX, y: rect.maxY), sx: 1, sy: -1)
        corner(CGPoint(x: rect.maxX, y: rect.maxY), sx: -1, sy: -1)

        return path
    }
}

struct OmikujiResultScreen: View {
    let onClose: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let cardWidth = min(proxy.size.width * 0.88, 342)
            let cardHeight: CGFloat = 948

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    OmikujiHeader()
                        .padding(.top, 14)

                    ZStack {
                        OmikujiBackdropCards()
                            .scaleEffect(cardWidth / 258)
                            .offset(y: 28)

                        PassiveLogOmikujiCard()
                            .frame(width: cardWidth, height: cardHeight)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: cardHeight + 36)

                    Button(action: onClose) {
                        Text("今日をはじめる")
                            .font(UtakataFontStyle.retroMincho(size: 23, weight: .semibold))
                            .foregroundStyle(Color(hex: 0xFFF8EA))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: 0x9EB29A), Color(hex: 0x6F8A77)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                in: RetroStampButtonShape()
                            )
                            .overlay(RetroStampButtonShape().stroke(Color(hex: 0xF4E8C8), lineWidth: 2.2))
                            .overlay(RetroStampButtonShape().stroke(Color(hex: 0x4D5F55).opacity(0.56), lineWidth: 0.8).padding(5))
                            .shadow(color: Color(hex: 0x4D5F55).opacity(0.18), radius: 12, x: 0, y: 6)
                    }
                    .padding(.horizontal, 32)
                    .overlay(alignment: .trailing) {
                        Text("短\n札")
                            .font(UtakataFontStyle.retroMincho(size: 21, weight: .semibold))
                            .foregroundStyle(Color.primaryText)
                            .multilineTextAlignment(.center)
                            .frame(width: 48, height: 64)
                            .background(Color(hex: 0xE8E1C9), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(hex: 0x544843), lineWidth: 1.6))
                            .rotationEffect(.degrees(11))
                            .offset(x: -18, y: -8)
                    }

                    HStack(spacing: 58) {
                        Image(systemName: "house.fill")
                        Image(systemName: "calendar")
                        Image(systemName: "seal.fill")
                    }
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x4E5557))
                    .padding(.bottom, 18)
                }
                .padding(.horizontal, 16)
                .frame(width: proxy.size.width, alignment: .top)
            }
        }
    }
}

struct OmikujiHeader: View {
    @AppStorage("utakataFontStyle") private var fontStyleRaw = UtakataFontStyle.mincho.rawValue

    var body: some View {
        HStack(alignment: .center) {
            MizuhikiMark()
                .frame(width: 82, height: 52)

            Spacer(minLength: 10)

            Text("Utakata Nikki")
                .font(currentFont.font(size: 36, weight: .regular))
                .foregroundStyle(Color(hex: 0x1F1A17))
                .minimumScaleFactor(0.62)
                .lineLimit(1)

            Spacer(minLength: 10)

            HStack(spacing: 6) {
                DecorativeTicket()
                    .frame(width: 44, height: 58)
                    .rotationEffect(.degrees(-12))
                Text("×1")
                    .font(UtakataFontStyle.retroMincho(size: 30, weight: .medium))
                    .foregroundStyle(Color(hex: 0x1F1A17))
            }
        }
        .padding(.horizontal, 18)
    }

    private var currentFont: UtakataFontStyle {
        UtakataFontStyle(rawValue: fontStyleRaw) ?? .mincho
    }
}

struct PassiveLogOmikujiCard: View {
    @AppStorage("utakataFontStyle") private var fontStyleRaw = UtakataFontStyle.mincho.rawValue

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x2F4E55), Color(hex: 0x20353E), Color(hex: 0x8B3E3B).opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            WavePattern()
                .stroke(Color(hex: 0xD7C799).opacity(0.18), lineWidth: 0.8)

            OrnateOmikujiBorder()
                .stroke(Color(hex: 0xE4D1A6).opacity(0.82), lineWidth: 1.1)
                .padding(10)

            VStack(spacing: 14) {
                OmikujiTitlePlaque(fontStyle: currentFont)
                    .padding(.top, 16)

                ZStack {
                    Color(hex: 0xFCF6E5)
                    WashiPattern()
                        .opacity(0.1)
                    TaishoCheckPattern(color: Color.meijiRed.opacity(0.018), tile: 28)

                    OrnateOmikujiBorder()
                        .stroke(Color(hex: 0xB54F3F).opacity(0.32), lineWidth: 0.8)
                        .padding(7)

                    VStack(spacing: 0) {
                        OmikujiTopStage(fontStyle: currentFont)

                        DividerLine()
                            .padding(.vertical, 18)

                        OmikujiMiddleStage(fontStyle: currentFont)

                        DividerLine()
                            .padding(.vertical, 18)

                        OmikujiBottomStage(fontStyle: currentFont)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 30)
                    .padding(.bottom, 78)

                    DoveSilhouette()
                        .fill(Color.white.opacity(0.55))
                        .frame(width: 42, height: 27)
                        .rotationEffect(.degrees(-12))
                        .offset(x: -92, y: -282)
                    DoveSilhouette()
                        .fill(Color.white.opacity(0.42))
                        .frame(width: 34, height: 22)
                        .rotationEffect(.degrees(16))
                        .offset(x: 92, y: 300)
                }
                .frame(minHeight: 792)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: 0x544843).opacity(0.78), lineWidth: 1.0))
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(Color.retroGold.opacity(0.44), lineWidth: 0.8)
                        .padding(8)
                )
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
            }

            PlumBlossom()
                .fill(Color(hex: 0xB54F3F))
                .frame(width: 42, height: 42)
                .offset(x: 115, y: -260)
            PlumBlossom()
                .fill(Color(hex: 0xB54F3F))
                .frame(width: 32, height: 32)
                .offset(x: -116, y: 268)
        }
        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color(hex: 0x544843), lineWidth: 1.6))
        .overlay(
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .stroke(Color.retroGold.opacity(0.58), lineWidth: 0.9)
                .padding(6)
        )
        .shadow(color: .black.opacity(0.24), radius: 18, x: 0, y: 12)
    }

    private var currentFont: UtakataFontStyle {
        UtakataFontStyle(rawValue: fontStyleRaw) ?? .mincho
    }
}

struct OmikujiTopStage: View {
    let fontStyle: UtakataFontStyle

    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            Spacer(minLength: 0)

            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0xFFF8EA), Color(hex: 0xF4DFBE)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        OrnateOmikujiBorder()
                            .stroke(Color.retroGold.opacity(0.58), lineWidth: 0.8)
                            .padding(5)
                    )
                    .shadow(color: Color.retroGold.opacity(0.18), radius: 10, x: 0, y: 5)

                VerticalText("あはれ吉", spacing: 5)
                    .font(UtakataFontStyle.retroMincho(size: 36, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x11100E))
                    .frame(width: 52)

                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.retroGold)
                    .offset(x: -31, y: -50)
                Image(systemName: "sparkle")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.retroRose.opacity(0.82))
                    .offset(x: 34, y: 48)
            }
            .frame(width: 86, height: 150)

            OmikujiFortuneLabel(text: "今日の運勢", fontStyle: fontStyle)

            Spacer(minLength: 0)
        }
        .frame(height: 178)
        .padding(.top, 2)
    }
}

struct OmikujiMiddleStage: View {
    let fontStyle: UtakataFontStyle

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            OmikujiLuckyColumn(
                title: "ラッキーアイテム",
                value: "琥珀イヤホン",
                fontStyle: fontStyle
            )

            HStack(alignment: .top, spacing: 5) {
                ForEach(["泡沫の日にも", "琥珀色の光が", "そっと残ります"].reversed(), id: \.self) { line in
                    VerticalText(line, spacing: 4.2)
                        .font(UtakataFontStyle.handLetter(size: 11.4, weight: .medium))
                        .foregroundStyle(Color.primaryText)
                        .frame(width: 16, alignment: .top)
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .padding(.vertical, 20)
            .padding(.horizontal, 12)
            .background(Color(hex: 0xF9ECD2).opacity(0.64), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.retroGold.opacity(0.22), lineWidth: 0.8))

            OmikujiStageTitle("今日の解説", fontStyle: fontStyle)
        }
        .frame(height: 220)
        .padding(.horizontal, 2)
    }
}

struct OmikujiBottomStage: View {
    let fontStyle: UtakataFontStyle

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            OmikujiLuckyColumn(
                title: "ラッキープレイス",
                value: "古書店",
                fontStyle: fontStyle
            )

            OmikujiLuckyColumn(
                title: "ラッキーアクション",
                value: "夜の日記",
                fontStyle: fontStyle
            )

            OmikujiStageTitle("今日の幸運", fontStyle: fontStyle)
        }
        .frame(height: 220)
        .padding(.horizontal, 2)
        .padding(.bottom, 6)
    }
}

struct OmikujiLuckyColumn: View {
    let title: String
    let value: String
    let fontStyle: UtakataFontStyle

    var body: some View {
        VStack(spacing: 10) {
            VerticalText(title, spacing: 2.2)
                .font(UtakataFontStyle.retroMincho(size: 7.2, weight: .bold))
                .foregroundStyle(Color(hex: 0x8B4D44))
            VerticalText(value, spacing: 3)
                .font(UtakataFontStyle.handLetter(size: 10.2, weight: .semibold))
                .foregroundStyle(Color.primaryText)
        }
        .frame(width: 48)
        .frame(minHeight: 178, alignment: .center)
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .background(Color(hex: 0xF9ECD2).opacity(0.64), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.retroGold.opacity(0.22), lineWidth: 0.8))
    }
}

struct OmikujiStageTitle: View {
    let text: String
    let fontStyle: UtakataFontStyle

    init(_ text: String, fontStyle: UtakataFontStyle) {
        self.text = text
        self.fontStyle = fontStyle
    }

    var body: some View {
        ZStack {
            RetroVerticalLabelShape()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0xB54F3F), Color(hex: 0x7E3838)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(RetroVerticalLabelShape().stroke(Color.retroGold.opacity(0.72), lineWidth: 0.9))

            PlumBlossom()
                .fill(Color(hex: 0xF3D7C5).opacity(0.88))
                .frame(width: 13, height: 13)
                .offset(y: -48)

            VerticalText(text, spacing: 3.5)
                .font(UtakataFontStyle.retroMincho(size: 10.4, weight: .bold))
                .foregroundStyle(Color.retroPaper)
                .padding(.vertical, 16)
                .frame(width: 26)
        }
        .frame(width: 30, height: 122)
    }
}

struct OmikujiFortuneLabel: View {
    let text: String
    let fontStyle: UtakataFontStyle

    var body: some View {
        ZStack {
            RetroVerticalLabelShape()
                .fill(Color(hex: 0xF7E8CA).opacity(0.92))
                .overlay(RetroVerticalLabelShape().stroke(Color(hex: 0x8B4D44).opacity(0.55), lineWidth: 0.8))

            VerticalText(text, spacing: 3)
                .font(UtakataFontStyle.retroMincho(size: 13, weight: .semibold))
                .foregroundStyle(Color(hex: 0x8B4D44))
        }
        .frame(width: 32, height: 118)
    }
}

struct OmikujiTitlePlaque: View {
    let fontStyle: UtakataFontStyle

    var body: some View {
        HStack(spacing: 7) {
            PlumBlossom()
                .fill(Color(hex: 0xB54F3F))
                .frame(width: 15, height: 15)
            Text("うたかたみくじ")
                .font(UtakataFontStyle.retroMincho(size: 16, weight: .semibold))
                .foregroundStyle(Color.primaryText)
            PlumBlossom()
                .fill(Color(hex: 0xB54F3F))
                .frame(width: 15, height: 15)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .background(Color(hex: 0xF7F0DE), in: TicketButtonShape())
        .overlay(TicketButtonShape().stroke(Color(hex: 0x544843).opacity(0.82), lineWidth: 1.1))
        .overlay(TicketButtonShape().stroke(Color.retroGold.opacity(0.56), lineWidth: 0.8).padding(4))
    }
}

struct OmikujiFortuneColumn: View {
    let fontStyle: UtakataFontStyle

    var body: some View {
        VStack(spacing: 10) {
            Text("運勢")
                .font(fontStyle.font(size: 12, weight: .bold))
                .foregroundStyle(Color(hex: 0x8B4D44))
                .padding(.vertical, 5)
                .frame(width: 36)
                .background(Color(hex: 0xF7F0DE), in: RoundedRectangle(cornerRadius: 3, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color(hex: 0x544843).opacity(0.3), lineWidth: 0.8))

            VerticalText("あはれ吉")
                .font(fontStyle.font(size: 29, weight: .semibold))
                .foregroundStyle(Color(hex: 0x11100E))
                .frame(width: 42)

            Spacer(minLength: 0)

            Image(systemName: "seal.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Color(hex: 0x8B4D44).opacity(0.76))
                .padding(.bottom, 4)
        }
        .frame(width: 44)
        .frame(maxHeight: .infinity)
    }
}

struct OmikujiVerticalColumn: View {
    let title: String
    let text: String
    let fontStyle: UtakataFontStyle
    let width: CGFloat
    var small = false

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(fontStyle.font(size: 11, weight: .bold))
                .foregroundStyle(Color(hex: 0x8B4D44))
                .padding(.vertical, 5)
                .frame(width: width)
                .background(Color(hex: 0xF7F0DE), in: RoundedRectangle(cornerRadius: 3, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color(hex: 0x544843).opacity(0.3), lineWidth: 0.8))

            HStack(alignment: .top, spacing: 4) {
                ForEach(Array(text.components(separatedBy: "\n").enumerated()).reversed(), id: \.offset) { _, line in
                    VerticalText(line)
                        .font(fontStyle.font(size: small ? 12 : 14, weight: .medium))
                        .foregroundStyle(Color.primaryText)
                        .lineLimit(nil)
                }
            }
            .frame(width: width, alignment: .top)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(width: width)
        .frame(maxHeight: .infinity)
    }
}

struct OmikujiFortuneTopSection: View {
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VerticalText("運勢")
                .font(.system(size: 13, weight: .bold, design: .serif))
                .foregroundStyle(Color(hex: 0x8B4D44))
                .frame(width: 20, height: 76)

            VStack(spacing: 3) {
                ForEach(Array(Array("あはれ吉").enumerated()), id: \.offset) { _, char in
                    Text(String(char))
                        .font(.system(size: 32, weight: .semibold, design: .serif))
                        .foregroundStyle(Color(hex: 0x11100E))
                        .lineLimit(1)
                }
            }
            .frame(width: 52, height: 126)

            VStack(spacing: 8) {
                Image(systemName: "headphones")
                    .font(.system(size: 28, weight: .semibold))
                Image(systemName: "book.closed")
                    .font(.system(size: 27, weight: .semibold))
            }
            .foregroundStyle(Color(hex: 0x544843))
            .frame(width: 42)

            VStack(alignment: .leading, spacing: 8) {
                OmikujiSmallLabel(title: "今日の予兆", value: "夕暮れの街灯")
                OmikujiSmallLabel(title: "情景", value: "琥珀色の帰り道")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 142)
        .padding(.horizontal, 13)
        .padding(.vertical, 8)
    }
}

struct OmikujiSmallLabel: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .black, design: .serif))
                .foregroundStyle(Color(hex: 0x8B4D44))
                .lineLimit(1)
            Text(value)
                .font(.system(size: 15, weight: .semibold, design: .serif))
                .foregroundStyle(Color.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(Color(hex: 0xF7F0DE).opacity(0.82), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(Color(hex: 0x544843).opacity(0.24), lineWidth: 0.8)
        )
    }
}

struct OmikujiExplanationSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("【今日の解説】")
                .font(.system(size: 12, weight: .bold, design: .serif))
            Text("泡沫のような一日の中にも、琥珀色に輝く詩があります。帰り道は少し遠回りを。夜は静かに日記を開き、今日の気配を札にしまいましょう。")
                .font(.system(size: 11, weight: .medium, design: .serif))
                .lineSpacing(2)
                .lineLimit(4)
                .minimumScaleFactor(0.82)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(Color.primaryText)
        .frame(height: 92, alignment: .topLeading)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }
}

struct OmikujiPredictionSection: View {
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    private let items: [(title: String, value: String, icon: String)] = [
        ("ラッキープレイス", "夕暮れの古書店", "mappin.and.ellipse"),
        ("ラッキーアイテム", "琥珀色のイヤホン", "headphones"),
        ("ラッキーアクション", "夜の日記を聴く", "moon.stars.fill"),
        ("今日の予兆", "泡沫の静寂", "sparkles")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("【予兆】")
                .font(.system(size: 12, weight: .bold, design: .serif))
                .foregroundStyle(Color.primaryText)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(items, id: \.title) { item in
                    OmikujiInfoTile(title: item.title, value: item.value, icon: item.icon)
                }
            }
        }
        .frame(height: 124, alignment: .topLeading)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }
}

struct OmikujiInfoTile: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption2.weight(.bold))
                Text(title)
                    .font(.system(size: 9, weight: .black, design: .serif))
                    .lineLimit(1)
                    .minimumScaleFactor(0.68)
            }
            .foregroundStyle(Color(hex: 0x8B4D44))

            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .serif))
                .foregroundStyle(Color.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity, minHeight: 42, alignment: .topLeading)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(hex: 0xF7F0DE).opacity(0.82), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(Color(hex: 0x544843).opacity(0.28), lineWidth: 0.8)
        )
    }
}

struct DividerLine: View {
    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Color(hex: 0x544843).opacity(0.38))
                .frame(height: 0.8)
            PlumBlossom()
                .fill(Color.retroGold.opacity(0.58))
                .frame(width: 9, height: 9)
            Rectangle()
                .fill(Color(hex: 0x544843).opacity(0.38))
                .frame(height: 0.8)
        }
        .padding(.horizontal, 18)
    }
}

struct DecorativeVerticalDivider: View {
    var body: some View {
        VStack(spacing: 9) {
            Rectangle()
                .fill(Color(hex: 0x544843).opacity(0.28))
                .frame(width: 0.8)
            PlumBlossom()
                .fill(Color.retroGold.opacity(0.58))
                .frame(width: 10, height: 10)
            Rectangle()
                .fill(Color(hex: 0x544843).opacity(0.28))
                .frame(width: 0.8)
        }
    }
}

struct OmikujiPaperBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0xF8F2E3), Color(hex: 0xEEE6D0), Color(hex: 0xFDF9EA)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            WavePattern()
                .stroke(Color(hex: 0xB7A883).opacity(0.32), lineWidth: 1.1)
                .frame(height: 170)
                .offset(y: -220)

            WavePattern()
                .stroke(Color(hex: 0x2F4E55).opacity(0.22), lineWidth: 1.0)
                .frame(height: 180)
                .offset(y: 210)

            ForEach(0..<7, id: \.self) { index in
                PlumBlossom()
                    .fill(index.isMultiple(of: 2) ? Color(hex: 0xB54F3F).opacity(0.72) : Color(hex: 0xAFA06F).opacity(0.62))
                    .frame(width: CGFloat([18, 24, 16, 28, 20, 14, 22][index]), height: CGFloat([18, 24, 16, 28, 20, 14, 22][index]))
                    .offset(x: CGFloat([-148, 132, -92, 168, 80, -170, 118][index]), y: CGFloat([-270, -230, 250, 126, -300, -150, 318][index]))
            }
        }
    }
}

struct OmikujiBackdropCards: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: 0x27404A))
                .overlay(WavePattern().stroke(Color(hex: 0xD7C799).opacity(0.38), lineWidth: 1))
                .frame(width: 250, height: 420)
                .rotationEffect(.degrees(-1.5))
                .offset(x: -92, y: -10)

            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: 0xFDF9EA))
                .overlay(WavePattern().stroke(Color(hex: 0xD7C799).opacity(0.28), lineWidth: 1))
                .frame(width: 248, height: 360)
                .rotationEffect(.degrees(1.5))
                .offset(x: 90, y: 46)

            PlumBlossom()
                .fill(Color(hex: 0xB54F3F))
                .frame(width: 62, height: 62)
                .offset(x: -150, y: -190)

            PlumBlossom()
                .fill(Color(hex: 0xB54F3F))
                .frame(width: 54, height: 54)
                .offset(x: 160, y: 170)
        }
    }
}

struct VerticalText: View {
    let text: String
    var spacing: CGFloat = 1

    init(_ text: String, spacing: CGFloat = 1) {
        self.text = text
        self.spacing = spacing
    }

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(Array(text.enumerated()), id: \.offset) { _, character in
                Text(String(character))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
        }
    }
}

struct OrnateOmikujiBorder: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let inset: CGFloat = min(rect.width, rect.height) * 0.055
        let inner = rect.insetBy(dx: inset, dy: inset)

        path.addRoundedRect(in: inner, cornerSize: CGSize(width: 8, height: 8))
        path.addRoundedRect(in: inner.insetBy(dx: 7, dy: 7), cornerSize: CGSize(width: 5, height: 5))

        let corner = min(inner.width, inner.height) * 0.14
        let corners = [
            CGPoint(x: inner.minX, y: inner.minY),
            CGPoint(x: inner.maxX, y: inner.minY),
            CGPoint(x: inner.minX, y: inner.maxY),
            CGPoint(x: inner.maxX, y: inner.maxY)
        ]

        for point in corners {
            let sx: CGFloat = point.x < inner.midX ? 1 : -1
            let sy: CGFloat = point.y < inner.midY ? 1 : -1

            path.move(to: CGPoint(x: point.x + sx * 9, y: point.y + sy * corner))
            path.addCurve(
                to: CGPoint(x: point.x + sx * corner, y: point.y + sy * 9),
                control1: CGPoint(x: point.x + sx * 12, y: point.y + sy * (corner * 0.55)),
                control2: CGPoint(x: point.x + sx * (corner * 0.55), y: point.y + sy * 12)
            )

            path.move(to: CGPoint(x: point.x + sx * 16, y: point.y + sy * 16))
            path.addLine(to: CGPoint(x: point.x + sx * (corner * 0.82), y: point.y + sy * 16))
            path.move(to: CGPoint(x: point.x + sx * 16, y: point.y + sy * 16))
            path.addLine(to: CGPoint(x: point.x + sx * 16, y: point.y + sy * (corner * 0.82)))
        }

        return path
    }
}

struct RetroVerticalLabelShape: Shape {
    func path(in rect: CGRect) -> Path {
        let notch = min(rect.width, rect.height) * 0.16
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - notch, y: rect.minY + notch))
        path.addLine(to: CGPoint(x: rect.maxX - notch * 0.45, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX - notch, y: rect.maxY - notch))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + notch, y: rect.maxY - notch))
        path.addLine(to: CGPoint(x: rect.minX + notch * 0.45, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + notch, y: rect.minY + notch))
        path.closeSubpath()
        return path
    }
}

struct RetroStampButtonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let cut = min(rect.width, rect.height) * 0.28
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + cut, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX - cut, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + cut, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

struct DoveSilhouette: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: w * 0.1, y: h * 0.58))
        path.addCurve(to: CGPoint(x: w * 0.42, y: h * 0.34), control1: CGPoint(x: w * 0.2, y: h * 0.22), control2: CGPoint(x: w * 0.34, y: h * 0.18))
        path.addCurve(to: CGPoint(x: w * 0.54, y: h * 0.5), control1: CGPoint(x: w * 0.47, y: h * 0.38), control2: CGPoint(x: w * 0.5, y: h * 0.44))
        path.addCurve(to: CGPoint(x: w * 0.92, y: h * 0.36), control1: CGPoint(x: w * 0.66, y: h * 0.18), control2: CGPoint(x: w * 0.8, y: h * 0.18))
        path.addCurve(to: CGPoint(x: w * 0.64, y: h * 0.72), control1: CGPoint(x: w * 0.82, y: h * 0.64), control2: CGPoint(x: w * 0.72, y: h * 0.78))
        path.addCurve(to: CGPoint(x: w * 0.46, y: h * 0.66), control1: CGPoint(x: w * 0.58, y: h * 0.68), control2: CGPoint(x: w * 0.52, y: h * 0.64))
        path.addCurve(to: CGPoint(x: w * 0.12, y: h * 0.88), control1: CGPoint(x: w * 0.34, y: h * 0.92), control2: CGPoint(x: w * 0.2, y: h * 0.98))
        path.addCurve(to: CGPoint(x: w * 0.1, y: h * 0.58), control1: CGPoint(x: w * 0.14, y: h * 0.76), control2: CGPoint(x: w * 0.12, y: h * 0.66))
        path.closeSubpath()

        return path
    }
}

struct WavePattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let rowSpacing: CGFloat = 18
        let arcWidth: CGFloat = 28

        var y = rect.minY + 8
        while y < rect.maxY {
            var x = rect.minX - arcWidth
            while x < rect.maxX + arcWidth {
                path.addArc(
                    center: CGPoint(x: x + arcWidth / 2, y: y),
                    radius: arcWidth / 2,
                    startAngle: .degrees(180),
                    endAngle: .degrees(0),
                    clockwise: false
                )
                x += arcWidth
            }
            y += rowSpacing
        }

        return path
    }
}

struct PlumBlossom: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.22

        for index in 0..<5 {
            let angle = Double(index) * 72 * .pi / 180 - .pi / 2
            let petalCenter = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            path.addEllipse(in: CGRect(x: petalCenter.x - radius, y: petalCenter.y - radius, width: radius * 2, height: radius * 2))
        }

        path.addEllipse(in: CGRect(x: center.x - radius * 0.52, y: center.y - radius * 0.52, width: radius * 1.04, height: radius * 1.04))
        return path
    }
}

struct MizuhikiMark: View {
    var body: some View {
        ZStack {
            ForEach([-12.0, -6.0, 0.0, 6.0, 12.0], id: \.self) { offset in
                Path { path in
                    path.move(to: CGPoint(x: 4, y: 10 + offset / 4))
                    path.addCurve(to: CGPoint(x: 78, y: 42 - offset / 4), control1: CGPoint(x: 28, y: -4 + offset), control2: CGPoint(x: 52, y: 56 - offset))
                }
                .stroke(offset == 0 ? Color(hex: 0x9C4D43) : Color(hex: 0xB6A476), lineWidth: 1.4)
            }
        }
    }
}

struct DecorativeTicket: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(hex: 0x2F4E55))
                .overlay(WavePattern().stroke(Color(hex: 0xD7C799).opacity(0.45), lineWidth: 0.8))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(hex: 0x544843), lineWidth: 1.2))
            PlumBlossom()
                .fill(Color(hex: 0xB54F3F))
                .frame(width: 20, height: 20)
        }
    }
}

struct TicketButtonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let notch: CGFloat = 16
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + notch, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - notch, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - notch / 2, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX - notch, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + notch, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + notch / 2, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

struct OmikujiBox: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(colors: [Color(hex: 0xA84E45), Color(hex: 0x7D3B36)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 170, height: 220)
                .shadow(color: Color(hex: 0x8B4D44).opacity(0.28), radius: 24, x: 0, y: 16)

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(hex: 0xF5D9B7).opacity(0.85), lineWidth: 2)
                .frame(width: 132, height: 178)

            VStack(spacing: 14) {
                Text("うたかた")
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundStyle(Color(hex: 0xFDF7EC))
                Text("みくじ")
                    .font(.system(size: 34, weight: .semibold, design: .serif))
                    .foregroundStyle(Color(hex: 0xFDF7EC))
            }

            Capsule()
                .fill(Color(hex: 0x2F2724).opacity(0.7))
                .frame(width: 54, height: 12)
                .offset(y: -96)
        }
    }
}

struct QuizView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAnswer: String?
    private let answers = ["2025年5月", "2025年9月", "2026年1月"]

    var body: some View {
        ZStack {
            AppBackground()

            VStack(alignment: .leading, spacing: 22) {
                Text("これはいつの気持ち？")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.primaryText)

                VStack(alignment: .leading, spacing: 12) {
                    Text("上の句")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.secondaryText)
                    Text("夜のコンビニ\n雨粒ひかり\n靴ぬらす")
                        .font(.system(size: 30, weight: .medium, design: .serif))
                        .lineSpacing(7)
                        .foregroundStyle(Color.primaryText)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.cardFill, in: RoundedRectangle(cornerRadius: 28, style: .continuous))

                VStack(spacing: 10) {
                    ForEach(answers, id: \.self) { answer in
                        PhraseChoiceButton(title: answer, isSelected: selectedAnswer == answer) {
                            selectedAnswer = answer
                        }
                    }
                }

                HStack {
                    Text("残り 02:48")
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        .foregroundStyle(Color.secondaryText)
                    Spacer()
                    Button("閉じる") {
                        dismiss()
                    }
                    .font(.subheadline.weight(.semibold))
                }
            }
            .padding(24)
        }
    }
}

struct ProphecyOmikujiCard: View {
    var body: some View {
        VStack(spacing: 18) {
            Text("今日の伏線")
                .font(.headline)
                .foregroundStyle(Color.secondaryText)

            VStack(spacing: 12) {
                Text("薄光")
                    .font(.system(size: 46, weight: .semibold, design: .serif))
                Text("15時ごろの空が\n夜の上の句を連れてきます")
                    .font(.title3.weight(.medium))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
            .foregroundStyle(Color.primaryText)

            HStack(spacing: 8) {
                Label("未来のログ", systemImage: "sparkles")
                Text("予言")
            }
            .font(.caption.weight(.bold))
            .foregroundStyle(Color(hex: 0x8B6B55))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.white.opacity(0.48), in: Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .background(
            LinearGradient(colors: [Color(hex: 0xFFF0CF), Color(hex: 0xE8F2EA), Color(hex: 0xE9D9EA)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.78), lineWidth: 1)
        )
        .shadow(color: Color(hex: 0xC5766B).opacity(0.18), radius: 22, x: 0, y: 14)
    }
}

struct ProphecyQuestCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("予言クエスト")
                    .font(.title3.weight(.semibold))
                Spacer()
                Text("日中")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.utakataAccent, in: Capsule())
            }

            Label("15時頃に空の写真を撮る", systemImage: "camera.aperture")
                .font(.headline)
                .foregroundStyle(Color.primaryText)

            Text("夜に日記を開くと、その写真の光から上の句が浮かびます。頑張って記録するのではなく、予言を少し覚えて過ごすだけ。")
                .font(.subheadline)
                .foregroundStyle(Color.secondaryText)
                .lineSpacing(4)
        }
        .padding(18)
        .background(Color.cardFill, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.72), lineWidth: 1)
        )
    }
}

struct DaytimeQuizCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(hex: 0x65779A).opacity(0.16))
                    Image(systemName: "timer")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color(hex: 0x65779A))
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 5) {
                    Text("日中だけ、過去が遊びにくる")
                        .font(.headline)
                        .foregroundStyle(Color.primaryText)
                    Text("3分限定クイズで、見返さない日記をエンタメに変えます。")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Color.secondaryText.opacity(0.55))
            }
            .padding(16)
            .background(Color.white.opacity(0.42), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color(hex: 0x65779A).opacity(0.22), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
