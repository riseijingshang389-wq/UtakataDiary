import SwiftUI
import AVFoundation

final class OmikujiSoundPlayer {
    static let shared = OmikujiSoundPlayer()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!

    private init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        engine.prepare()
    }

    func playDrawSound() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            if !engine.isRunning {
                try engine.start()
            }
        } catch {
            return
        }

        if player.isPlaying {
            player.stop()
        }

        guard let buffer = makeDrawSoundBuffer() else { return }
        player.scheduleBuffer(buffer, at: nil, options: [])
        player.play()
    }

    private func makeDrawSoundBuffer() -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate
        let duration = 0.92
        let frameCount = Int(sampleRate * duration)
        guard
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount)),
            let channel = buffer.floatChannelData?[0]
        else {
            return nil
        }

        buffer.frameLength = AVAudioFrameCount(frameCount)

        for frame in 0..<frameCount {
            let time = Double(frame) / sampleRate
            var sample: Float = 0

            for burstStart in [0.00, 0.075, 0.15, 0.245, 0.34, 0.46] {
                if time >= burstStart {
                    let age = time - burstStart
                    let envelope = Float(exp(-42 * age))
                    let noise = Float.random(in: -1...1)
                    sample += noise * envelope * 0.045
                }
            }

            for chime in [
                (0.00, 1320.0, 0.13),
                (0.055, 1760.0, 0.10),
                (0.13, 1480.0, 0.12),
                (0.225, 1980.0, 0.09),
                (0.33, 1580.0, 0.11),
                (0.455, 2240.0, 0.075)
            ] {
                if time >= chime.0 {
                    let age = time - chime.0
                    let envelope = Float(exp(-7.8 * age))
                    let fundamental = Float(sin(2 * Double.pi * chime.1 * age))
                    let overtone = Float(sin(2 * Double.pi * chime.1 * 2.03 * age)) * 0.38
                    sample += (fundamental + overtone) * envelope * Float(chime.2)
                }
            }

            let fadeIn = min(Float(time / 0.018), 1)
            let fadeOut = min(Float((duration - time) / 0.18), 1)
            channel[frame] = max(-0.42, min(0.42, sample * fadeIn * fadeOut))
        }

        return buffer
    }
}

struct FortuneView: View {
    @State private var showingQuiz = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                HeaderView(title: "うたかたみくじ", subtitle: "未来の思い出の伏線")

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
    let fortune: OmikujiFortune
    @State private var isShaking = false
    @State private var didDraw: Bool
    @State private var stickOffset: CGFloat = 0

    init(
        fortune: OmikujiFortune = OmikujiFortune.random(),
        startsWithResult: Bool = false,
        onClose: @escaping () -> Void
    ) {
        self.fortune = fortune
        self.onClose = onClose
        _didDraw = State(initialValue: startsWithResult)
    }

    var body: some View {
        ZStack {
            OmikujiPaperBackground()

            if didDraw {
                OmikujiResultScreen(fortune: fortune, onClose: onClose)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                OmikujiDrawStage(
                    isShaking: isShaking,
                    stickOffset: stickOffset,
                    onSkip: onClose
                ) {
                    OmikujiSoundPlayer.shared.playDrawSound()
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
    let fortune: OmikujiFortune
    let onClose: () -> Void
    @GestureState private var isPressingStart = false

    var body: some View {
        GeometryReader { proxy in
            let cardWidth = min(proxy.size.width * 0.58, 226)
            let adaptiveCardHeightLimit = max(CGFloat(636), proxy.size.width * 1.2)
            let cardHeight = min(max(proxy.size.height - 174, 500), adaptiveCardHeightLimit)

            ZStack {
                OmikujiPreDrawFantasyLayer()
                    .opacity(0.28)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        OmikujiHeader()
                            .scaleEffect(0.82)
                            .frame(height: 74)
                            .padding(.top, 8)

                        ZStack {
                            PassiveLogOmikujiCard(fortune: fortune)
                                .frame(width: cardWidth, height: cardHeight)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: cardHeight + 10)

                        Spacer(minLength: 8)

                        Button(action: onClose) {
                            OmikujiStartDayButton()
                        }
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .updating($isPressingStart) { _, state, _ in
                                    state = true
                                }
                        )
                        .padding(.horizontal, 32)
                        .padding(.bottom, 22)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: proxy.size.height)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

struct HaikaraBlackCat: View {
    let isPlayful: Bool

    var body: some View {
        Image("HaikaraBlackCat")
            .resizable()
            .scaledToFit()
            .frame(width: 220, height: 158)
            .offset(x: 46, y: -2)
            .frame(width: 92, height: 116)
            .clipped()
            .blendMode(.multiply)
            .scaleEffect(isPlayful ? 1.035 : 1)
            .rotationEffect(.degrees(isPlayful ? -2 : 0), anchor: .bottom)
            .offset(y: isPlayful ? -3 : 0)
        .animation(.spring(response: 0.2, dampingFraction: 0.52), value: isPlayful)
        .shadow(color: Color(hex: 0x1D1515).opacity(0.22), radius: 9, x: 0, y: 5)
    }
}

struct CatEye: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: 0xFFF4B4), Color(hex: 0xC57A2E), Color(hex: 0x4A2413)],
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: 14
                    )
                )
                .frame(width: 16, height: 16)
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 4, height: 4)
                .offset(x: 4, y: -5)
            Image(systemName: "sparkle")
                .font(.system(size: 4, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.86))
                .offset(x: -3, y: 4)
        }
    }
}

struct CatEar: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.maxX * 0.96, y: rect.minY + rect.height * 0.24))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY), control: CGPoint(x: rect.midX, y: rect.maxY * 0.82))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.minY), control: CGPoint(x: rect.minX + rect.width * 0.06, y: rect.minY + rect.height * 0.24))
        return path
    }
}

struct CatTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 8, y: rect.maxY - 4))
        path.addCurve(
            to: CGPoint(x: rect.maxX - 9, y: rect.minY + 15),
            control1: CGPoint(x: rect.maxX * 0.90, y: rect.maxY * 0.86),
            control2: CGPoint(x: rect.maxX * 0.86, y: rect.midY * 0.56)
        )
        return path
    }
}

struct CatBody: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addCurve(to: CGPoint(x: rect.maxX, y: rect.maxY * 0.88), control1: CGPoint(x: rect.maxX * 0.92, y: rect.minY + rect.height * 0.18), control2: CGPoint(x: rect.maxX, y: rect.midY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY * 0.88), control: CGPoint(x: rect.midX, y: rect.maxY))
        path.addCurve(to: CGPoint(x: rect.midX, y: rect.minY), control1: CGPoint(x: rect.minX, y: rect.midY), control2: CGPoint(x: rect.minX + rect.width * 0.08, y: rect.minY + rect.height * 0.18))
        return path
    }
}

struct CatRibbon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.midY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.12), control: CGPoint(x: rect.minX + rect.width * 0.20, y: rect.minY - 2))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.05, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.midY), control: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.maxY * 0.86))
        path.move(to: CGPoint(x: rect.midX, y: rect.midY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.12), control: CGPoint(x: rect.maxX - rect.width * 0.20, y: rect.minY - 2))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.05, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.midY), control: CGPoint(x: rect.maxX - rect.width * 0.25, y: rect.maxY * 0.86))
        return path
    }
}

struct CatPaw: Shape {
    func path(in rect: CGRect) -> Path {
        Path(roundedRect: CGRect(x: 0, y: 0, width: 12, height: 16), cornerRadius: 6)
    }
}

struct CatWhiskers: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for offset in [-7.0, 0.0, 7.0] {
            path.move(to: CGPoint(x: rect.midX - 11, y: rect.midY + offset))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY + offset - 4))
            path.move(to: CGPoint(x: rect.midX + 11, y: rect.midY + offset))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY + offset - 4))
        }
        return path
    }
}

struct CatMouth: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.midY), control: CGPoint(x: rect.midX - rect.width * 0.18, y: rect.midY))
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY), control: CGPoint(x: rect.midX + rect.width * 0.18, y: rect.midY))
        return path
    }
}

struct OmikujiStartDayButton: View {
    var body: some View {
        HStack(spacing: 12) {
            OmikujiButtonFlourish()
                .stroke(Color.retroGold.opacity(0.82), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                .frame(width: 34, height: 14)

            Text("今日をはじめる")
                .font(UtakataFontStyle.retroMincho(size: 22, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            OmikujiButtonFlourish()
                .stroke(Color.retroGold.opacity(0.82), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                .frame(width: 34, height: 14)
                .scaleEffect(x: -1, y: 1)
        }
        .foregroundStyle(Color(hex: 0xFFF8EA))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(
            LinearGradient(
                colors: [Color(hex: 0x2E6567), Color(hex: 0x557E74), Color(hex: 0x243F47)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RetroStampButtonShape()
        )
        .overlay(RetroStampButtonShape().stroke(Color(hex: 0xF4E8C8), lineWidth: 2.0))
        .overlay(RetroStampButtonShape().stroke(Color.retroGold.opacity(0.72), lineWidth: 0.8).padding(5))
        .shadow(color: Color(hex: 0x1B4244).opacity(0.24), radius: 14, x: 0, y: 7)
    }
}

struct OmikujiButtonFlourish: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addCurve(
            to: CGPoint(x: rect.maxX * 0.72, y: rect.midY),
            control1: CGPoint(x: rect.width * 0.18, y: rect.minY),
            control2: CGPoint(x: rect.width * 0.42, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.move(to: CGPoint(x: rect.width * 0.72, y: rect.midY))
        path.addQuadCurve(
            to: CGPoint(x: rect.width * 0.54, y: rect.minY + 2),
            control: CGPoint(x: rect.width * 0.60, y: rect.midY - 1)
        )
        path.move(to: CGPoint(x: rect.width * 0.72, y: rect.midY))
        path.addQuadCurve(
            to: CGPoint(x: rect.width * 0.54, y: rect.maxY - 2),
            control: CGPoint(x: rect.width * 0.60, y: rect.midY + 1)
        )
        return path
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

struct OmikujiFortune: Codable {
    let fortune: String
    let explanationLines: [String]
    let item: String
    let action: String
    let place: String

    private enum Mood: CaseIterable {
        case bright
        case calm
        case romantic
        case quiet
    }

    private struct Core {
        let fortune: String
        let explanationLines: [String]
        let mood: Mood
    }

    private struct Element {
        let text: String
        let mood: Mood
    }

    static func random() -> OmikujiFortune {
        let core = cores.randomElement() ?? cores[0]
        return OmikujiFortune(
            fortune: core.fortune,
            explanationLines: core.explanationLines,
            item: pick(from: items, mood: core.mood),
            action: pick(from: actions, mood: core.mood),
            place: pick(from: places, mood: core.mood)
        )
    }

    private static func pick(from elements: [Element], mood: Mood) -> String {
        let matched = elements.filter { $0.mood == mood }
        return (matched.randomElement() ?? elements.randomElement())?.text ?? ""
    }

    private static let cores: [Core] = [
        Core(fortune: "あはれ吉", explanationLines: ["窓辺に射す陽光は", "微睡む時の栞となり", "ささやかな慈しみが", "心に小さな灯をともす"], mood: .calm),
        Core(fortune: "小春吉", explanationLines: ["古い歌の調べが", "遠い日の記憶を呼び", "焦らずとも春は", "すぐそこにあります"], mood: .bright),
        Core(fortune: "宵待吉", explanationLines: ["夕暮れの洋灯に", "願いの輪郭が灯り", "静かな帰り道で", "心はほどけます"], mood: .romantic),
        Core(fortune: "薄雲吉", explanationLines: ["薄雲の向こうには", "やわらかな返事があり", "急がぬ歩みほど", "美しく届きます"], mood: .calm),
        Core(fortune: "乙女吉", explanationLines: ["古い歌の調べが", "遠い日の記憶を呼び", "柔らかな春は", "すぐそこにあります"], mood: .romantic),
        Core(fortune: "夕映吉", explanationLines: ["夕映えの頬には", "今日の頑張りが宿り", "小さな誇らしさが", "胸に赤く灯ります"], mood: .bright),
        Core(fortune: "雨音吉", explanationLines: ["雨粒の音色には", "忘れた言葉がひそみ", "濡れた硝子越しに", "記憶がきらめきます"], mood: .quiet),
        Core(fortune: "星屑吉", explanationLines: ["眠る前の星屑が", "小さなご褒美となり", "明日のあなたへ", "静かに降り注ぎます"], mood: .quiet),
        Core(fortune: "花霞吉", explanationLines: ["霞む花の色にも", "今日だけの意味があり", "曖昧な気持ちほど", "やさしく残ります"], mood: .romantic),
        Core(fortune: "凪吉", explanationLines: ["凪いだ心の奥に", "きれいな余白が戻り", "何もしない時間が", "あなたを整えます"], mood: .calm),
        Core(fortune: "硝子吉", explanationLines: ["透ける気持ちは", "隠さぬほど澄み渡り", "素直なひと言が", "美しく響きます"], mood: .bright),
        Core(fortune: "鈴音吉", explanationLines: ["小さな鈴の音が", "見落とした合図となり", "ふとした返事から", "道は開けます"], mood: .bright),
        Core(fortune: "月影吉", explanationLines: ["月影に沈む憂いも", "夜の飾りへ変わり", "言えない寂しさを", "静かに包みます"], mood: .quiet),
        Core(fortune: "初音吉", explanationLines: ["はじめの一言が", "思うより遠くへ届き", "まだ知らぬ縁を", "そっと結びます"], mood: .bright),
        Core(fortune: "浪漫吉", explanationLines: ["昨日のため息さえ", "今日の物語に縫われ", "古い切符のように", "胸で光ります"], mood: .romantic)
    ]

    private static let items: [Element] = [
        Element(text: "硝子のインク瓶", mood: .calm),
        Element(text: "白い便箋", mood: .calm),
        Element(text: "薄荷の飴", mood: .calm),
        Element(text: "真珠の髪留め", mood: .romantic),
        Element(text: "リボンの栞", mood: .romantic),
        Element(text: "花柄の小鏡", mood: .romantic),
        Element(text: "金色の切符", mood: .bright),
        Element(text: "小さな鈴", mood: .bright),
        Element(text: "朝焼けの封筒", mood: .bright),
        Element(text: "月色のハンカチ", mood: .quiet),
        Element(text: "古い文庫本", mood: .quiet),
        Element(text: "夜更けの紅茶", mood: .quiet)
    ]

    private static let actions: [Element] = [
        Element(text: "手紙を綴る", mood: .calm),
        Element(text: "深く息をする", mood: .calm),
        Element(text: "窓辺で休む", mood: .calm),
        Element(text: "好きと書く", mood: .romantic),
        Element(text: "花を飾る", mood: .romantic),
        Element(text: "遠回りする", mood: .romantic),
        Element(text: "靴音を鳴らす", mood: .bright),
        Element(text: "朝日を浴びる", mood: .bright),
        Element(text: "笑顔で返す", mood: .bright),
        Element(text: "夜の日記", mood: .quiet),
        Element(text: "月を眺める", mood: .quiet),
        Element(text: "灯を落とす", mood: .quiet)
    ]

    private static let places: [Element] = [
        Element(text: "洋館の図書室", mood: .calm),
        Element(text: "窓際の喫茶店", mood: .calm),
        Element(text: "静かな文具店", mood: .calm),
        Element(text: "薔薇の小径", mood: .romantic),
        Element(text: "夕暮れの駅", mood: .romantic),
        Element(text: "古い写真館", mood: .romantic),
        Element(text: "朝の並木道", mood: .bright),
        Element(text: "日差しのベランダ", mood: .bright),
        Element(text: "花咲く広場", mood: .bright),
        Element(text: "月明かりの部屋", mood: .quiet),
        Element(text: "夜の書店", mood: .quiet),
        Element(text: "雨音の路地", mood: .quiet)
    ]
}

enum OmikujiFortuneStore {
    private static let fortuneKey = "utakataTodayOmikujiFortune"
    private static let dateKey = "utakataTodayOmikujiFortuneDate"

    static func todayFortune(createIfNeeded: Bool = true, now: Date = Date()) -> OmikujiFortune? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        let storedDay = Date(timeIntervalSince1970: UserDefaults.standard.double(forKey: dateKey))

        if
            calendar.isDate(storedDay, inSameDayAs: today),
            let data = UserDefaults.standard.data(forKey: fortuneKey),
            let fortune = try? JSONDecoder().decode(OmikujiFortune.self, from: data)
        {
            return fortune
        }

        guard createIfNeeded else { return nil }

        let fortune = OmikujiFortune.random()
        save(fortune, for: today)
        return fortune
    }

    static func save(_ fortune: OmikujiFortune, for day: Date = Date()) {
        guard let data = try? JSONEncoder().encode(fortune) else { return }
        let today = Calendar.current.startOfDay(for: day)
        UserDefaults.standard.set(today.timeIntervalSince1970, forKey: dateKey)
        UserDefaults.standard.set(data, forKey: fortuneKey)
    }
}

struct PassiveLogOmikujiCard: View {
    let fortune: OmikujiFortune
    @AppStorage("utakataFontStyle") private var fontStyleRaw = UtakataFontStyle.mincho.rawValue

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [Color(hex: 0xFFF9EA), Color(hex: 0xF7EACD), Color(hex: 0xEFE0BC)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                WashiPattern()
                    .opacity(0.17)

                TaishoCheckPattern(color: Color.meijiRed.opacity(0.012), tile: 26)

                VStack(spacing: 0) {
                    OmikujiPaperHeader()
                        .frame(height: proxy.size.height * 0.09)

                    OmikujiPaperFortune(text: fortune.fortune)
                        .frame(height: proxy.size.height * 0.20)

                    OmikujiPaperSeparator(symbol: "◆ ◆ ◆")
                        .padding(.vertical, proxy.size.height * 0.014)

                    OmikujiPaperExplanation(lines: fortune.explanationLines)
                        .frame(height: proxy.size.height * 0.30)

                    OmikujiPaperSeparator(symbol: "◇ ◇ ◇ ◇")
                        .padding(.vertical, proxy.size.height * 0.014)

                    OmikujiPaperLuckList(item: fortune.item, action: fortune.action, place: fortune.place)
                        .frame(maxHeight: .infinity)
                }
                .padding(.top, 20)
                .padding(.bottom, 24)
                .padding(.horizontal, 16)

                OmikujiPaperCornerMarks()
                    .stroke(Color.meijiRed.opacity(0.52), style: StrokeStyle(lineWidth: 0.9, lineCap: .round, lineJoin: .round))
                    .padding(13)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(hex: 0x2C211C).opacity(0.82), lineWidth: 1.2))
        .overlay(RoundedRectangle(cornerRadius: 1).stroke(Color.meijiRed.opacity(0.48), lineWidth: 0.8).padding(7))
        .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 12)
    }

    private var currentFont: UtakataFontStyle {
        UtakataFontStyle(rawValue: fontStyleRaw) ?? .mincho
    }
}

struct OmikujiPaperHeader: View {
    var body: some View {
        HStack(spacing: 6) {
            PlumBlossom()
                .fill(Color.meijiRed.opacity(0.58))
                .frame(width: 10, height: 10)

            Text("うたかたみくじ")
                .font(UtakataFontStyle.retroMincho(size: 12.5, weight: .semibold))
                .foregroundStyle(Color.primaryText.opacity(0.86))
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            PlumBlossom()
                .fill(Color.meijiRed.opacity(0.58))
                .frame(width: 10, height: 10)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 5)
        .background(Color(hex: 0xFFF9EA).opacity(0.72), in: TicketButtonShape())
        .overlay(TicketButtonShape().stroke(Color(hex: 0x2C211C).opacity(0.42), lineWidth: 0.8))
        .overlay(TicketButtonShape().stroke(Color.meijiRed.opacity(0.32), lineWidth: 0.7).padding(3))
        .padding(.top, 2)
        .frame(maxWidth: .infinity)
    }
}

struct OmikujiPaperFortune: View {
    let text: String

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Rectangle()
                .fill(Color(hex: 0x2C211C).opacity(0.66))
                .frame(width: 1, height: 88)

            VerticalText(text, spacing: 4.2)
                .font(UtakataFontStyle.retroMincho(size: 28, weight: .semibold))
                .foregroundStyle(Color(hex: 0x11100E))
                .frame(width: 48)

            Rectangle()
                .fill(Color(hex: 0x2C211C).opacity(0.66))
                .frame(width: 1, height: 88)
        }
        .padding(.top, 8)
        .overlay(alignment: .topTrailing) {
            Image(systemName: "sparkle")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.retroGold)
                .offset(x: 15, y: 8)
        }
        .overlay(alignment: .bottomLeading) {
            SakuraPetalShape()
                .fill(Color.retroRose.opacity(0.5))
                .frame(width: 9, height: 13)
                .rotationEffect(.degrees(-18))
                .offset(x: -15, y: -7)
        }
    }
}

struct OmikujiPaperSeparator: View {
    let symbol: String

    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Color.meijiRed.opacity(0.38))
                .frame(height: 0.8)
            Text(symbol)
                .font(UtakataFontStyle.retroMincho(size: 9, weight: .semibold))
                .foregroundStyle(Color.meijiRed.opacity(0.72))
                .lineLimit(1)
            Rectangle()
                .fill(Color.meijiRed.opacity(0.38))
                .frame(height: 0.8)
        }
    }
}

struct OmikujiPaperExplanation: View {
    let lines: [String]

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            HStack(alignment: .top, spacing: 8) {
                ForEach(lines.reversed(), id: \.self) { line in
                    VerticalText(line, spacing: 2.8)
                        .font(UtakataFontStyle.retroMincho(size: 10.7, weight: .medium))
                        .foregroundStyle(Color.primaryText)
                        .frame(width: 17, alignment: .top)
                        .frame(maxHeight: .infinity, alignment: .top)
                }
            }
            .frame(height: 154, alignment: .top)

            VerticalText("今日の解説", spacing: 2.8)
                .font(UtakataFontStyle.retroMincho(size: 9.9, weight: .bold))
                .foregroundStyle(Color.meijiRed)
                .frame(width: 18)
                .frame(height: 118, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 3)
    }
}

struct OmikujiPaperLuckList: View {
    let item: String
    let action: String
    let place: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            OmikujiPaperLuckItem(title: "場所", value: place)
            OmikujiPaperLuckItem(title: "行動", value: action)
            OmikujiPaperLuckItem(title: "アイテム", value: item)

            VerticalText("今日の幸運", spacing: 3.0)
                .font(UtakataFontStyle.retroMincho(size: 10.1, weight: .bold))
                .foregroundStyle(Color.meijiRed)
                .frame(width: 18)
                .frame(height: 118, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 7)
    }
}

struct OmikujiPaperLuckItem: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 5) {
            VerticalText(value, spacing: 2.35)
                .font(UtakataFontStyle.retroMincho(size: 10.8, weight: .semibold))
                .foregroundStyle(Color.primaryText)
                .frame(width: 17)
                .frame(height: 118, alignment: .top)

            VerticalText(title, spacing: 2.0)
                .font(UtakataFontStyle.retroMincho(size: 7.7, weight: .bold))
                .foregroundStyle(Color(hex: 0x7C423B))
                .frame(width: 11)
                .frame(height: 118, alignment: .top)
        }
        .frame(width: 36, height: 118, alignment: .top)
    }
}

struct OmikujiPaperCornerMarks: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let length = min(rect.width, rect.height) * 0.12

        func mark(_ origin: CGPoint, sx: CGFloat, sy: CGFloat) {
            path.move(to: CGPoint(x: origin.x + sx * length, y: origin.y))
            path.addLine(to: CGPoint(x: origin.x + sx * length * 0.42, y: origin.y))
            path.addQuadCurve(
                to: CGPoint(x: origin.x, y: origin.y + sy * length * 0.42),
                control: CGPoint(x: origin.x + sx * length * 0.18, y: origin.y + sy * length * 0.18)
            )
            path.addLine(to: CGPoint(x: origin.x, y: origin.y + sy * length))
        }

        mark(CGPoint(x: rect.minX, y: rect.minY), sx: 1, sy: 1)
        mark(CGPoint(x: rect.maxX, y: rect.minY), sx: -1, sy: 1)
        mark(CGPoint(x: rect.minX, y: rect.maxY), sx: 1, sy: -1)
        mark(CGPoint(x: rect.maxX, y: rect.maxY), sx: -1, sy: -1)
        return path
    }
}

struct OmikujiTopStage: View {
    let fontStyle: UtakataFontStyle

    var body: some View {
        HStack(alignment: .center, spacing: 13) {
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

                VerticalText("あはれ吉", spacing: 4)
                    .font(UtakataFontStyle.retroMincho(size: 31, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x11100E))
                    .frame(width: 46)

                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.retroGold)
                    .offset(x: -27, y: -40)
                Image(systemName: "sparkle")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.retroRose.opacity(0.82))
                    .offset(x: 29, y: 39)
            }
            .frame(width: 76, height: 116)

            OmikujiFortuneLabel(text: "今日の運勢", fontStyle: fontStyle)

            Spacer(minLength: 0)
        }
        .frame(height: 126)
    }
}

struct OmikujiMiddleStage: View {
    let fontStyle: UtakataFontStyle

    var body: some View {
        HStack(alignment: .center, spacing: 9) {
            OmikujiLuckyColumn(
                title: "ラッキーアイテム",
                value: "琥珀イヤホン",
                fontStyle: fontStyle
            )

            HStack(alignment: .top, spacing: 5) {
                ForEach(["泡沫の日にも", "琥珀色の光が", "そっと残ります"].reversed(), id: \.self) { line in
                    VerticalText(line, spacing: 3.4)
                        .font(UtakataFontStyle.retroMincho(size: 10.7, weight: .medium))
                        .foregroundStyle(Color.primaryText)
                        .frame(width: 15, alignment: .top)
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .padding(.vertical, 13)
            .padding(.horizontal, 10)
            .omikujiParchmentBlock(tint: Color.meijiRed)

            OmikujiStageTitle("今日の解説", fontStyle: fontStyle)
        }
        .frame(height: 154)
        .padding(.horizontal, 2)
    }
}

struct OmikujiBottomStage: View {
    let fontStyle: UtakataFontStyle

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
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
        .frame(height: 126)
        .padding(.horizontal, 2)
    }
}

struct OmikujiLuckyColumn: View {
    let title: String
    let value: String
    let fontStyle: UtakataFontStyle

    var body: some View {
        VStack(spacing: 10) {
            VerticalText(title, spacing: 2.2)
                .font(UtakataFontStyle.retroMincho(size: 6.7, weight: .bold))
                .foregroundStyle(Color(hex: 0x8B4D44))
            VerticalText(value, spacing: 3)
                .font(UtakataFontStyle.retroMincho(size: 9.6, weight: .semibold))
                .foregroundStyle(Color.primaryText)
        }
        .frame(width: 44)
        .frame(maxHeight: .infinity, alignment: .center)
        .padding(.vertical, 9)
        .padding(.horizontal, 5)
        .omikujiParchmentBlock(tint: Color.meijiRed)
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

            Image(systemName: "sparkles")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(Color.retroGold)
                .offset(x: -13, y: -30)

            SakuraPetalShape()
                .fill(Color(hex: 0xF4B7C2).opacity(0.82))
                .frame(width: 7, height: 10)
                .rotationEffect(.degrees(28))
                .offset(x: 13, y: 34)

            VerticalText(text, spacing: 3.5)
                .font(UtakataFontStyle.retroMincho(size: 10.4, weight: .bold))
                .foregroundStyle(Color.retroPaper)
                .padding(.vertical, 16)
                .frame(width: 26)
        }
        .frame(width: 30, height: 122)
    }
}

private extension View {
    func omikujiParchmentBlock(tint: Color) -> some View {
        background {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: 0xFFF8EA).opacity(0.94),
                        Color(hex: 0xF3E2C3).opacity(0.86),
                        Color(hex: 0xEAD0A8).opacity(0.52)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                WashiPattern()
                    .opacity(0.16)
                MemoryCornerRibbons(color: tint.opacity(0.72))
                    .padding(2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.meijiRed.opacity(0.26), lineWidth: 0.75))
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.retroGold.opacity(0.48), lineWidth: 0.7).padding(4))
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
                Label("未来の思い出", systemImage: "sparkles")
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
