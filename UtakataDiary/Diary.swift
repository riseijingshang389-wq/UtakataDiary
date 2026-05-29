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
                            Text("最新の日記")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(Color.primaryText)

                            MemoryPreviewCard(card: latestCard)
                        }
                    } else {
                        EmptyDiaryHint()
                    }

                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 22)
                .padding(.top, 20)
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
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    TaishoBadgeShape()
                        .fill(
                            LinearGradient(colors: [Color.meijiRed, Color.retroRose], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 66, height: 66)
                        .overlay(
                            TaishoBadgeShape()
                                .stroke(Color.retroGold.opacity(0.82), lineWidth: 1.2)
                                .padding(6)
                        )
                        .shadow(color: Color.meijiRed.opacity(0.24), radius: 16, x: 0, y: 8)

                    Image(systemName: "plus")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 7) {
                    RetroRibbonLabel(text: "日記を作成", tint: Color.meijiRed)
                    Text("写真を選ぶ / 撮る → 上の句 → 下の句 → 一枚の札へ")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                FlowChip(number: "1", title: "写真")
                FlowLine()
                FlowChip(number: "2", title: "上の句")
                FlowLine()
                FlowChip(number: "3", title: "下の句")
                FlowLine()
                FlowChip(number: "4", title: "札")
            }
        }
        .padding(22)
        .background {
            ZStack {
                Color.retroPaper.opacity(0.88)
                TaishoCheckPattern(color: Color.meijiBlue.opacity(0.08), tile: 22)
                WashiPattern()
                    .opacity(0.26)
                RetroCornerOrnaments(color: Color.meijiRed.opacity(0.42))
                    .padding(10)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.meijiRed.opacity(0.62), lineWidth: 1.4)
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

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 8) {
                ForEach(["日", "月", "火", "水", "木", "金", "土"], id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.secondaryText.opacity(0.72))
                }

                ForEach(days, id: \.self) { day in
                    let hasCard = cards.contains { calendar.isDate($0.date, inSameDayAs: day) }
                    Text("\(calendar.component(.day, from: day))")
                        .font(.caption.monospacedDigit().weight(hasCard ? .bold : .medium))
                        .foregroundStyle(hasCard ? Color.retroPaper : Color.secondaryText)
                        .frame(height: 32)
                        .frame(maxWidth: .infinity)
                        .background(hasCard ? Color.meijiRed : Color.retroPaper.opacity(0.55), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(hasCard ? Color.retroGold.opacity(0.68) : Color.primaryText.opacity(0.16), lineWidth: 0.8)
                        )
                }
            }
        }
        .padding(20)
        .taishoPanel(tint: Color.meijiBlue)
    }
}

struct FlowChip: View {
    let number: String
    let title: String

    var body: some View {
        VStack(spacing: 4) {
            Text(number)
                .font(.caption2.monospacedDigit().weight(.bold))
                .foregroundStyle(Color.retroPaper)
                .frame(width: 22, height: 22)
                .background(Color.meijiBlue, in: TaishoBadgeShape())
                .overlay(TaishoBadgeShape().stroke(Color.retroGold.opacity(0.58), lineWidth: 0.8))
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FlowLine: View {
    var body: some View {
        Rectangle()
            .fill(Color.secondaryText.opacity(0.18))
            .frame(width: 10, height: 1)
            .padding(.top, -14)
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
    @State private var selectedEmotion = DiaryEmotion.joy
    @State private var customLowerPhrase = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var generatedUpperPhrase = ["写真を選ぶと", "今日の上の句", "浮かびます"]
    @State private var showingFinishedCard = false
    @State private var showingCamera = false

    private var currentLowerPhrase: String {
        let trimmedPhrase = customLowerPhrase.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedPhrase.isEmpty ? selectedEmotion.lowerPhrase : trimmedPhrase
    }

    private var canCreate: Bool {
        selectedPhotoData != nil
    }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    HeaderView(title: "日記を作成", subtitle: "写真から一首へ")

                    DiarySourcePicker(
                        photoData: selectedPhotoData,
                        selectedItem: $selectedPhotoItem,
                        onCameraTap: { showingCamera = true }
                    )
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        Task {
                            guard let data = try? await newItem?.loadTransferable(type: Data.self) else {
                                return
                            }
                            applyPhotoData(data)
                        }
                    }

                    if let selectedPhotoData {
                        StepSectionTitle(number: "2", title: "上の句を確認")

                        HStack {
                            Spacer()
                            PoemCardView(
                                upperPhrase: generatedUpperPhrase,
                                lowerPhrase: currentLowerPhrase,
                                mood: .rain,
                                compact: true,
                                photoData: selectedPhotoData
                            )
                            .frame(width: 238, height: 360)
                            Spacer()
                        }

                        VStack(alignment: .leading, spacing: 14) {
                            StepSectionTitle(number: "3", title: "感情を選ぶ / 下の句を書く")

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
                                ForEach(DiaryEmotion.allCases, id: \.self) { emotion in
                                    EmotionChoiceChip(
                                        emotion: emotion,
                                        isSelected: customLowerPhrase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && selectedEmotion == emotion
                                    ) {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            customLowerPhrase = ""
                                            selectedEmotion = emotion
                                        }
                                    }
                                }
                            }

                            Text(currentLowerPhrase)
                                .font(.system(size: 20, weight: .semibold, design: .serif))
                                .foregroundStyle(Color.primaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .background(Color.retroPaper.opacity(0.62), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(selectedEmotion.tint.opacity(0.42), lineWidth: 1)
                                )

                            CustomLowerPhraseField(text: $customLowerPhrase)
                        }
                    }

                    Button {
                        showingFinishedCard = true
                    } label: {
                        Label("日記を作成", systemImage: "seal")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.utakataPrimary)
                    .opacity(canCreate ? 1 : 0.45)
                    .disabled(!canCreate)
                    .padding(.bottom, 36)
                }
                .padding(.horizontal, 22)
                .padding(.top, 22)
            }
        }
        .sheet(isPresented: $showingFinishedCard) {
            FinishedCardView(card: makeCard()) { card in
                onCreate(card)
                dismiss()
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker { image in
                if let data = image.jpegData(compressionQuality: 0.88) {
                    applyPhotoData(data)
                }
                showingCamera = false
            } onCancel: {
                showingCamera = false
            }
        }
    }

    private func applyPhotoData(_ data: Data) {
        selectedPhotoData = data
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            generatedUpperPhrase = PhotoPhraseGenerator.upperPhrase(from: data)
        }
    }

    private func makeCard() -> DiaryCard {
        DiaryCard(
            date: .now,
            upperPhrase: generatedUpperPhrase,
            lowerPhrase: currentLowerPhrase,
            mood: .rain,
            placeHint: selectedPhotoData == nil ? "写真なし" : "選んだ写真",
            photoData: selectedPhotoData
        )
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
            .frame(height: 180)
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
