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

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 34)

            OmikujiHeader()

            ZStack {
                OmikujiBox()
                    .rotationEffect(.degrees(isShaking ? -4 : 4))
                    .animation(.easeInOut(duration: 0.12).repeatCount(8, autoreverses: true), value: isShaking)

                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(hex: 0xFDF7EC))
                    .frame(width: 34, height: 168)
                    .overlay(
                        Text("短札")
                            .font(.system(size: 18, weight: .semibold, design: .serif))
                            .foregroundStyle(Color(hex: 0x8B4D44))
                            .rotationEffect(.degrees(90))
                    )
                    .offset(y: 8 + stickOffset)
            }
            .frame(height: 280)

            Button(action: onDraw) {
                Label("うたかたみくじを引く", systemImage: "sparkles")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.utakataPrimary)
            .padding(.horizontal, 28)

            Button(action: onSkip) {
                Text("みくじを引かない")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.secondaryText)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 18)
                    .background(Color.retroPaper.opacity(0.58), in: Capsule())
                    .overlay(Capsule().stroke(Color.primaryText.opacity(0.16), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer(minLength: 28)
        }
    }
}

struct OmikujiResultScreen: View {
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            OmikujiHeader()
                .padding(.top, 16)

            ZStack {
                OmikujiBackdropCards()
                    .offset(y: 24)

                PassiveLogOmikujiCard()
                    .frame(width: 258, height: 528)
            }
            .frame(maxHeight: .infinity)

            Button(action: onClose) {
                Text("「今日をはじめる」")
                    .font(.system(size: 28, weight: .medium, design: .serif))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(Color(hex: 0x8EA18C), in: TicketButtonShape())
                    .overlay(
                        TicketButtonShape()
                            .stroke(Color(hex: 0xE8E1C9), lineWidth: 2)
                    )
            }
            .padding(.horizontal, 30)
            .overlay(alignment: .trailing) {
                Text("短\n札")
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.primaryText)
                    .multilineTextAlignment(.center)
                    .frame(width: 54, height: 72)
                    .background(Color(hex: 0xE8E1C9), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(hex: 0x544843), lineWidth: 2))
                    .rotationEffect(.degrees(12))
                    .offset(x: -18, y: -8)
            }

            HStack(spacing: 68) {
                Image(systemName: "house.fill")
                Image(systemName: "calendar")
                Image(systemName: "seal.fill")
            }
            .font(.system(size: 30, weight: .semibold))
            .foregroundStyle(Color(hex: 0x4E5557))
            .padding(.bottom, 14)
        }
        .padding(.horizontal, 16)
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
                .minimumScaleFactor(0.8)
                .lineLimit(1)

            Spacer(minLength: 10)

            HStack(spacing: 6) {
                DecorativeTicket()
                    .frame(width: 44, height: 58)
                    .rotationEffect(.degrees(-12))
                Text("×1")
                    .font(.system(size: 30, weight: .medium, design: .serif))
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
            Color(hex: 0x27404A)
            WavePattern()
                .stroke(Color(hex: 0xD7C799).opacity(0.28), lineWidth: 1)

            VStack(spacing: 8) {
                Text("うたかたみくじ")
                    .font(currentFont.font(size: 16, weight: .semibold))
                    .foregroundStyle(Color.primaryText)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(hex: 0xF7F0DE), in: TicketButtonShape())
                    .overlay(TicketButtonShape().stroke(Color(hex: 0x544843), lineWidth: 1.3))
                    .padding(.top, 13)

                ZStack {
                    Color(hex: 0xFCF6E5)
                    WashiPattern()
                        .opacity(0.18)

                    VStack(spacing: 0) {
                        OmikujiTopStage(fontStyle: currentFont)

                        DividerLine()
                            .padding(.vertical, 2)

                        OmikujiMiddleStage(fontStyle: currentFont)

                        DividerLine()
                            .padding(.vertical, 2)

                        OmikujiBottomStage(fontStyle: currentFont)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
                }
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(hex: 0x544843), lineWidth: 1.4))
                .padding(.horizontal, 12)
                .padding(.bottom, 13)
            }

            PlumBlossom()
                .fill(Color(hex: 0xB54F3F))
                .frame(width: 44, height: 44)
                .offset(x: 102, y: -218)
            PlumBlossom()
                .fill(Color(hex: 0xB54F3F))
                .frame(width: 34, height: 34)
                .offset(x: -104, y: 220)
        }
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(hex: 0x544843), lineWidth: 2.5))
        .shadow(color: .black.opacity(0.22), radius: 12, x: 0, y: 8)
    }

    private var currentFont: UtakataFontStyle {
        UtakataFontStyle(rawValue: fontStyleRaw) ?? .mincho
    }
}

struct OmikujiTopStage: View {
    let fontStyle: UtakataFontStyle

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            Spacer(minLength: 0)

            VerticalText("今日の運勢")
                .font(fontStyle.font(size: 15, weight: .medium))
                .foregroundStyle(Color(hex: 0x8B4D44))
                .frame(width: 24)

            VerticalText("あはれ吉")
                .font(fontStyle.font(size: 34, weight: .semibold))
                .foregroundStyle(Color(hex: 0x11100E))
                .frame(width: 46)

            Spacer(minLength: 0)
        }
        .frame(height: 154)
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "sparkles")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.retroGold.opacity(0.82))
                .padding(.trailing, 8)
        }
    }
}

struct OmikujiMiddleStage: View {
    let fontStyle: UtakataFontStyle

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            OmikujiStageTitle("今日の解説", fontStyle: fontStyle)

            HStack(alignment: .top, spacing: 5) {
                ForEach(["泡沫の日にも", "琥珀色の光が", "そっと残ります"].reversed(), id: \.self) { line in
                    VerticalText(line)
                        .font(fontStyle.font(size: 13, weight: .medium))
                        .foregroundStyle(Color.primaryText)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(height: 112)
        .padding(.leading, 4)
    }
}

struct OmikujiBottomStage: View {
    let fontStyle: UtakataFontStyle

    private let items = [
        ("ラッキープレイス", "古書店"),
        ("ラッキーアクション", "夜の日記"),
        ("ラッキーアイテム", "琥珀イヤホン")
    ]

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            OmikujiStageTitle("今日の幸運", fontStyle: fontStyle)

            ForEach(items, id: \.0) { item in
                VStack(spacing: 8) {
                    VerticalText(item.0)
                        .font(fontStyle.font(size: 10, weight: .bold))
                        .foregroundStyle(Color(hex: 0x8B4D44))
                VerticalText(item.1)
                        .font(fontStyle.font(size: 13, weight: .semibold))
                        .foregroundStyle(Color.primaryText)
                }
                .frame(width: 38, alignment: .top)
                .frame(maxHeight: .infinity, alignment: .top)
            }

            Spacer(minLength: 0)
        }
        .frame(height: 142)
        .padding(.leading, 4)
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
        VerticalText(text)
            .font(fontStyle.font(size: 11, weight: .bold))
            .foregroundStyle(Color.retroPaper)
            .padding(.vertical, 8)
            .frame(width: 26)
            .background(Color(hex: 0x8B4D44), in: RoundedRectangle(cornerRadius: 3, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .stroke(Color.retroGold.opacity(0.58), lineWidth: 0.8)
            )
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
        Rectangle()
            .fill(Color(hex: 0x544843))
            .frame(height: 1)
            .padding(.horizontal, 10)
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

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        VStack(spacing: 1) {
            ForEach(Array(text.enumerated()), id: \.offset) { _, character in
                Text(String(character))
                    .lineLimit(1)
            }
        }
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
