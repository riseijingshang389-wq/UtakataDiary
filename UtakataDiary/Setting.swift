import SwiftUI
import UserNotifications

enum UtakataFontStyle: String, CaseIterable, Identifiable {
    case mincho
    case gothic
    case handwritten
    case classic

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mincho: return "明朝体"
        case .gothic: return "ゴシック体"
        case .handwritten: return "手書き風"
        case .classic: return "レトロ活字"
        }
    }

    var subtitle: String {
        switch self {
        case .mincho: return "短歌がいちばん綺麗に見える"
        case .gothic: return "現代的で読みやすい"
        case .handwritten: return "日記っぽく柔らかい"
        case .classic: return "大正ロマンの紙面感"
        }
    }

    func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch self {
        case .mincho:
            return .system(size: size, weight: weight, design: .serif)
        case .gothic:
            return .system(size: size, weight: weight, design: .default)
        case .handwritten:
            return .custom("Klee-Medium", size: size)
        case .classic:
            return .custom("Hiragino Mincho ProN", size: size)
        }
    }
}

struct Setting: View {
    @AppStorage("utakataFontStyle") private var fontStyleRaw = UtakataFontStyle.mincho.rawValue
    @AppStorage("utakataDailyNotificationEnabled") private var notificationEnabled = false
    @AppStorage("utakataNickname") private var nickname = ""
    @AppStorage("utakataBirthdate") private var birthdateInterval = Date(timeIntervalSince1970: 946684800).timeIntervalSince1970
    @AppStorage("utakataLocationEnabled") private var locationEnabled = false
    @AppStorage("utakataMorningHour") private var morningHour = 7
    @AppStorage("utakataMorningMinute") private var morningMinute = 30
    @AppStorage("utakataNightHour") private var nightHour = 22
    @AppStorage("utakataNightMinute") private var nightMinute = 0
    @AppStorage("utakataTextSize") private var textSize = 1.0
    @State private var notificationMessage = "朝のみくじと夜の日記作成をお知らせします。"

    private var selectedFont: UtakataFontStyle {
        UtakataFontStyle(rawValue: fontStyleRaw) ?? .mincho
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                HeaderView(title: "設定", subtitle: "しつらえ")

                SettingSection(title: "1. ユーザー設定", tint: Color.meijiRed) {
                    SettingTextFieldRow(title: "ニックネーム", placeholder: "未設定", text: $nickname)

                    SettingDateRow(title: "生年月日", subtitle: "おみくじ星座用", date: birthdateBinding, displayedComponents: .date)

                    SettingToggleRow(
                        title: "位置情報の利用許可",
                        subtitle: "天気連動用",
                        isOn: $locationEnabled
                    )
                }

                SettingSection(title: "2. 通知設定", tint: Color.meijiBlue) {
                    SettingToggleRow(
                        title: "プッシュ通知を有効にする",
                        subtitle: notificationMessage,
                        isOn: Binding(
                            get: { notificationEnabled },
                            set: { setNotificationEnabled($0) }
                        )
                    )

                    SettingDateRow(title: "朝の「うたかたみくじ」通知", subtitle: nil, date: morningTimeBinding, displayedComponents: .hourAndMinute)

                    SettingDateRow(title: "夜の「日記作成」通知", subtitle: nil, date: nightTimeBinding, displayedComponents: .hourAndMinute)
                }

                SettingSection(title: "3. 表示とデザイン", tint: Color.meijiRed) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("書体（フォント）の選択")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color.primaryText)

                        HStack(spacing: 10) {
                            ForEach([UtakataFontStyle.mincho, .gothic]) { style in
                                FontRadioButton(style: style, isSelected: selectedFont == style) {
                                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                        fontStyleRaw = style.rawValue
                                    }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("文字サイズ")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(Color.primaryText)
                            Spacer()
                            Text(textSizeLabel)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color.secondaryText)
                        }

                        Slider(value: $textSize, in: 0...2, step: 1)
                            .tint(Color.meijiRed)

                        HStack {
                            Text("小")
                            Spacer()
                            Text("標準")
                            Spacer()
                            Text("大")
                        }
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.secondaryText)
                    }
                }

                SettingSection(title: "4. データ管理", tint: Color.meijiBlue) {
                    SettingNavigationRow(title: "iCloudと同期してバックアップ作成")
                }

                SettingSection(title: "5. その他", tint: Color.meijiRed) {
                    SettingNavigationRow(title: "利用規約")
                    SettingNavigationRow(title: "プライバシーポリシー")
                    SettingValueRow(title: "バージョン", value: "1.0.0")
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 20)
        }
    }

    private func setNotificationEnabled(_ isEnabled: Bool) {
        if isEnabled {
            NotificationManager.requestDailyReminders { granted in
                notificationEnabled = granted
                notificationMessage = granted
                    ? "朝のみくじと夜の日記作成をお知らせします。"
                    : "通知が許可されませんでした。iPhoneの設定から通知を許可してください。"
            }
        } else {
            notificationEnabled = false
            notificationMessage = "通知はオフです。必要になったらまたオンにできます。"
            NotificationManager.cancelDailyReminders()
        }
    }

    private var birthdateBinding: Binding<Date> {
        Binding(
            get: { Date(timeIntervalSince1970: birthdateInterval) },
            set: { birthdateInterval = $0.timeIntervalSince1970 }
        )
    }

    private var morningTimeBinding: Binding<Date> {
        timeBinding(hour: $morningHour, minute: $morningMinute)
    }

    private var nightTimeBinding: Binding<Date> {
        timeBinding(hour: $nightHour, minute: $nightMinute)
    }

    private func timeBinding(hour: Binding<Int>, minute: Binding<Int>) -> Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(from: DateComponents(hour: hour.wrappedValue, minute: minute.wrappedValue)) ?? .now
            },
            set: { date in
                hour.wrappedValue = Calendar.current.component(.hour, from: date)
                minute.wrappedValue = Calendar.current.component(.minute, from: date)
                if notificationEnabled {
                    NotificationManager.scheduleDailyReminders()
                }
            }
        )
    }

    private var textSizeLabel: String {
        switch Int(textSize) {
        case 0: return "小"
        case 2: return "大"
        default: return "標準"
        }
    }
}

enum NotificationManager {
    private static let morningIdentifier = "utakata.daily.omikuji.reminder"
    private static let nightIdentifier = "utakata.daily.diary.reminder"

    static func refreshDailyReminderIfNeeded() {
        guard UserDefaults.standard.bool(forKey: "utakataDailyNotificationEnabled") else { return }
        scheduleDailyReminders()
    }

    static func requestDailyReminders(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    scheduleDailyReminders()
                } else {
                    cancelDailyReminders()
                }
                completion(granted)
            }
        }
    }

    static func scheduleDailyReminders() {
        let defaults = UserDefaults.standard
        scheduleReminder(
            identifier: morningIdentifier,
            title: "うたかたみくじ",
            body: "今日の予兆を、そっと引いてみませんか。",
            hour: defaults.object(forKey: "utakataMorningHour") as? Int ?? 7,
            minute: defaults.object(forKey: "utakataMorningMinute") as? Int ?? 30
        )
        scheduleReminder(
            identifier: nightIdentifier,
            title: "うたかた日記",
            body: "今日の光を、一枚の札にしまいませんか。",
            hour: defaults.object(forKey: "utakataNightHour") as? Int ?? 22,
            minute: defaults.object(forKey: "utakataNightMinute") as? Int ?? 0
        )
    }

    private static func scheduleReminder(identifier: String, title: String, body: String, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        UNUserNotificationCenter.current().add(request)
    }

    static func cancelDailyReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [morningIdentifier, nightIdentifier])
    }
}

struct SettingSection<Content: View>: View {
    let title: String
    let tint: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RetroRibbonLabel(text: title, tint: tint)
            VStack(spacing: 0) {
                content
            }
            .background(Color.retroPaper.opacity(0.66), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.primaryText.opacity(0.18), lineWidth: 1)
            )
        }
        .padding(18)
        .taishoPanel(tint: tint)
    }
}

struct SettingTextFieldRow: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        SettingRowShell {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.primaryText)

            Spacer(minLength: 12)

            TextField(placeholder, text: $text)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.primaryText)
                .multilineTextAlignment(.trailing)
                .textInputAutocapitalization(.never)
        }
    }
}

struct SettingDateRow: View {
    let title: String
    let subtitle: String?
    @Binding var date: Date
    let displayedComponents: DatePickerComponents

    var body: some View {
        SettingRowShell {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.primaryText)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.secondaryText)
                }
            }

            Spacer(minLength: 12)

            DatePicker("", selection: $date, displayedComponents: displayedComponents)
                .labelsHidden()
                .tint(Color.meijiRed)
        }
    }
}

struct SettingToggleRow: View {
    let title: String
    let subtitle: String?
    @Binding var isOn: Bool

    var body: some View {
        SettingRowShell {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.primaryText)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 12)

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.meijiRed)
        }
    }
}

struct SettingNavigationRow: View {
    let title: String

    var body: some View {
        Button {} label: {
            SettingRowShell {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.primaryText)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Color.secondaryText.opacity(0.72))
            }
        }
        .buttonStyle(.plain)
    }
}

struct SettingValueRow: View {
    let title: String
    let value: String

    var body: some View {
        SettingRowShell {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(Color.primaryText)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.secondaryText.opacity(0.72))
        }
    }
}

struct SettingRowShell<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            content
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.primaryText.opacity(0.1))
                .frame(height: 1)
                .padding(.leading, 14)
        }
    }
}

struct FontRadioButton: View {
    let style: UtakataFontStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(isSelected ? Color.meijiRed : Color.secondaryText.opacity(0.64))

                Text(style.title)
                    .font(style.font(size: 15, weight: .semibold))
                    .foregroundStyle(Color.primaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(isSelected ? Color.meijiRed.opacity(0.12) : Color.white.opacity(0.32), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(isSelected ? Color.meijiRed.opacity(0.62) : Color.primaryText.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct FontStyleTile: View {
    let style: UtakataFontStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("あ")
                        .font(style.font(size: 30, weight: .semibold))
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.seal.fill" : "seal")
                        .font(.headline.weight(.bold))
                }
                .foregroundStyle(isSelected ? Color.meijiRed : Color.primaryText)

                Text(style.title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.primaryText)

                Text(style.subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
            .padding(14)
            .background(isSelected ? Color.retroPaper.opacity(0.86) : Color.retroPaper.opacity(0.58), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(isSelected ? Color.meijiRed.opacity(0.72) : Color.primaryText.opacity(0.18), lineWidth: isSelected ? 1.4 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct VerticalSettingPreview: View {
    let fontStyle: UtakataFontStyle

    var body: some View {
        HStack(spacing: 6) {
            ForEach(["夕暮れに", "泡の記憶が", "ひかりだす"].reversed(), id: \.self) { line in
                VStack(spacing: 1) {
                    ForEach(Array(line.enumerated()), id: \.offset) { _, char in
                        Text(String(char))
                            .font(fontStyle.font(size: 17, weight: .medium))
                    }
                }
            }
        }
        .foregroundStyle(Color.primaryText)
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(Color.retroPaper.opacity(0.76), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(Color.meijiBlue.opacity(0.42), lineWidth: 1)
        )
    }
}
