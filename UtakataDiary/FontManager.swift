import SwiftUI

enum UtakataFontRole {
    case header
    case hero
    case title
    case headline
    case body
    case date
    case caption
    case tanka
    case button
    case menu

    var defaultSize: CGFloat {
        switch self {
        case .header: return 32
        case .hero: return 34
        case .title: return 24
        case .headline: return 17
        case .body: return 15
        case .date: return 13
        case .caption: return 12
        case .tanka: return 18
        case .button: return 16
        case .menu: return 15
        }
    }

    var defaultWeight: Font.Weight {
        switch self {
        case .header:
            return .semibold
        case .hero, .title: return .semibold
        case .headline, .button: return .semibold
        case .body, .tanka: return .regular
        case .date, .menu: return .semibold
        case .caption: return .medium
        }
    }
}

@MainActor
final class FontManager: ObservableObject {
    static let storageKey = "utakataFontStyle"
    static let shared = FontManager()

    @Published var selectedStyle: UtakataFontStyle {
        didSet {
            UserDefaults.standard.set(selectedStyle.rawValue, forKey: Self.storageKey)
        }
    }

    init() {
        let rawValue = UserDefaults.standard.string(forKey: Self.storageKey)
        selectedStyle = UtakataFontStyle(rawValue: rawValue ?? "") ?? .mincho
    }

    func setStyle(_ style: UtakataFontStyle) {
        selectedStyle = style
    }

    func font(
        role: UtakataFontRole,
        size: CGFloat? = nil,
        weight: Font.Weight? = nil
    ) -> Font {
        selectedStyle.font(
            size: size ?? role.defaultSize,
            weight: weight ?? role.defaultWeight
        )
    }

    nonisolated static var persistedStyle: UtakataFontStyle {
        let rawValue = UserDefaults.standard.string(forKey: "utakataFontStyle")
        return UtakataFontStyle(rawValue: rawValue ?? "") ?? .mincho
    }
}

struct UtakataFontModifier: ViewModifier {
    @EnvironmentObject private var fontManager: FontManager

    let role: UtakataFontRole
    let size: CGFloat?
    let weight: Font.Weight?

    func body(content: Content) -> some View {
        content.font(fontManager.font(role: role, size: size, weight: weight))
    }
}

extension View {
    func utakataFont(
        style role: UtakataFontRole,
        size: CGFloat? = nil,
        weight: Font.Weight? = nil
    ) -> some View {
        modifier(UtakataFontModifier(role: role, size: size, weight: weight))
    }

    func utakataFont(
        _ role: UtakataFontRole = .body,
        size: CGFloat? = nil,
        weight: Font.Weight? = nil
    ) -> some View {
        modifier(UtakataFontModifier(role: role, size: size, weight: weight))
    }
}
