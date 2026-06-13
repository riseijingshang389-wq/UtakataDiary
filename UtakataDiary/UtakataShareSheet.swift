import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct UtakataShareImagePayload: Identifiable, Transferable {
    let id = UUID()
    let pngData: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { payload in
            payload.pngData
        }
    }
}

struct UtakataActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

@MainActor
enum UtakataLetterShareRenderer {
    static func render(
        upperPhrase: [String],
        lowerPhrase: String,
        mood: CardMood,
        photoData: Data?,
        weatherEffect: WeatherVisualEffect
    ) -> UIImage? {
        let card = UtakataLetterShareCard(
            upperPhrase: upperPhrase,
            lowerPhrase: lowerPhrase,
            mood: mood,
            photoData: photoData,
            weatherEffect: weatherEffect
        )
        .frame(width: 1080, height: 1920)

        let renderer = ImageRenderer(content: card)
        renderer.scale = 1
        renderer.proposedSize = ProposedViewSize(width: 1080, height: 1920)
        return renderer.uiImage
    }
}

struct UtakataLetterShareCard: View {
    let upperPhrase: [String]
    let lowerPhrase: String
    let mood: CardMood
    let photoData: Data?
    let weatherEffect: WeatherVisualEffect

    var body: some View {
        ZStack {
            AppBackground()
            OmikujiPreDrawFantasyLayer()
                .opacity(0.56)

            VStack(spacing: 42) {
                Text("うたかたの一筆箋")
                    .utakataFont(style: .header, size: 74, weight: .semibold)
                    .foregroundStyle(Color.primaryText)
                    .padding(.top, 92)

                TankaOmikujiPreviewCard(
                    upperPhrase: upperPhrase,
                    lowerPhrase: lowerPhrase,
                    accent: mood.accent,
                    photoData: photoData,
                    weatherEffect: weatherEffect
                )
                .frame(width: 760, height: 1164)
                .shadow(color: Color.primaryText.opacity(0.18), radius: 34, x: 0, y: 26)

                Text("Utakata Nikki")
                    .utakataFont(style: .caption, size: 30, weight: .medium)
                    .foregroundStyle(Color.secondaryText.opacity(0.78))

                Spacer(minLength: 60)
            }
            .padding(.horizontal, 80)
        }
        .frame(width: 1080, height: 1920)
        .clipped()
    }
}
