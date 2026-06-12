import SwiftUI
import WidgetKit

struct UtakataTankaEntry: TimelineEntry {
    let date: Date
    let memories: [LatestTankaWidgetData]
    let isSample: Bool
}

struct UtakataTankaProvider: TimelineProvider {
    func placeholder(in context: Context) -> UtakataTankaEntry {
        makeEntry(context: context)
    }

    func getSnapshot(in context: Context, completion: @escaping (UtakataTankaEntry) -> Void) {
        completion(makeEntry(context: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UtakataTankaEntry>) -> Void) {
        let entry = makeEntry(context: context)
        let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
    }

    private func makeEntry(context: Context) -> UtakataTankaEntry {
        let now = Date()
        let memories = LatestTankaWidgetStore.memoryMoment(count: cardCount(for: context.family), now: now)
        return UtakataTankaEntry(
            date: now,
            memories: memories,
            isSample: memories.allSatisfy { $0 == .sample }
        )
    }

    private func cardCount(for family: WidgetFamily) -> Int {
        switch family {
        case .systemSmall:
            return 1
        case .systemMedium:
            return 2
        case .systemLarge, .systemExtraLarge:
            return 4
        default:
            return 1
        }
    }
}

struct UtakataTankaWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: UtakataTankaEntry

    var body: some View {
        ZStack {
            Color(hex: 0xFAF7F2)

            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: 0xB89E66).opacity(0.72), lineWidth: 1)
                .padding(8)

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.72), lineWidth: 0.7)
                .padding(12)

            VStack(alignment: .leading, spacing: headerSpacing) {
                header

                if family == .systemSmall {
                    MemoryMomentCard(memory: firstMemory, entryDate: entry.date, prominent: true)
                } else {
                    LazyVGrid(columns: gridColumns, spacing: 8) {
                        ForEach(displayMemories) { memory in
                            MemoryMomentCard(memory: memory, entryDate: entry.date, prominent: false)
                        }
                    }
                }

                if family != .systemSmall {
                    footer
                }
            }
            .padding(contentPadding)
        }
        .containerBackground(for: .widget) {
            Color(hex: 0xFAF7F2)
        }
    }

    private var firstMemory: LatestTankaWidgetData {
        entry.memories.first ?? .sample
    }

    private var displayMemories: [LatestTankaWidgetData] {
        entry.memories.isEmpty ? [.sample] : entry.memories
    }

    private var gridColumns: [GridItem] {
        let count = family == .systemMedium ? 2 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: count)
    }

    private var headerSpacing: CGFloat {
        family == .systemSmall ? 8 : 10
    }

    private var contentPadding: CGFloat {
        family == .systemSmall ? 16 : 18
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 8) {
            UtakataWidgetLogo()

            VStack(alignment: .leading, spacing: 2) {
                Text("思い出の瞬き")
                    .font(.system(size: family == .systemSmall ? 13 : 15, weight: .semibold, design: .serif))
                    .foregroundStyle(Color(hex: 0x1E3A5F))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(entry.isSample ? "Sample" : "ふいに届いた一首")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: 0x1E3A5F).opacity(0.48))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Text("✨")
                .font(.system(size: family == .systemSmall ? 14 : 16))
        }
    }

    private var footer: some View {
        Text("次に開くころ、また別の記憶かもしれません。")
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .foregroundStyle(Color(hex: 0x1E3A5F).opacity(0.48))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MemoryMomentCard: View {
    let memory: LatestTankaWidgetData
    let entryDate: Date
    let prominent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: prominent ? 8 : 5) {
            Text(LatestTankaWidgetStore.yearsAgoText(for: memory.date, now: entryDate))
                .font(.system(size: prominent ? 12 : 10, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: 0x8F3F3E).opacity(0.82))
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Text(memory.tanka)
                .font(.system(size: prominent ? 14 : 11, weight: .regular, design: .serif))
                .foregroundStyle(Color(hex: 0x1E3A5F))
                .lineSpacing(prominent ? 5 : 3)
                .minimumScaleFactor(prominent ? 0.62 : 0.55)
                .lineLimit(5)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)
        }
        .padding(prominent ? 13 : 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.58),
                    Color(hex: 0xF6EADF).opacity(0.78)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: prominent ? 14 : 12, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: prominent ? 14 : 12, style: .continuous)
                .stroke(Color(hex: 0xB89E66).opacity(0.38), lineWidth: 0.8)
        }
    }
}

struct UtakataWidgetLogo: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: 0xFAF7F2))
                .overlay(Circle().stroke(Color(hex: 0x1E3A5F).opacity(0.16), lineWidth: 1))

            Text("う")
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundStyle(Color(hex: 0x1E3A5F))
        }
        .frame(width: 30, height: 30)
    }
}

struct UtakataTankaWidget: Widget {
    let kind = LatestTankaWidgetStore.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UtakataTankaProvider()) { entry in
            UtakataTankaWidgetView(entry: entry)
        }
        .configurationDisplayName("思い出の瞬き")
        .description("過去の日記から、ふいに一首を届けます。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct UtakataDiaryWidgetBundle: WidgetBundle {
    var body: some Widget {
        UtakataTankaWidget()
    }
}

private extension Color {
    init(hex: Int) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }
}
