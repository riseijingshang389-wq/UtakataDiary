import SwiftUI
import UserNotifications

private extension Color {
    static let settingInk = Color(hex: 0x2B1E1E)
    static let settingPaper = Color(hex: 0xFFF9F2).opacity(0.9)
    static let settingLine = Color(hex: 0x9A463F).opacity(0.34)
    static let settingGold = Color(hex: 0xBBA36B)
}

enum UtakataFontStyle: String, CaseIterable, Identifiable {
    case mincho
    case gothic
    case handwritten
    case classic

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mincho: return "レトロ明朝"
        case .gothic: return "丸ゴシック"
        case .handwritten: return "手書き風"
        case .classic: return "活字明朝"
        }
    }

    var subtitle: String {
        switch self {
        case .mincho: return "格式ある見出し向き"
        case .gothic: return "丸く親しみやすい"
        case .handwritten: return "日記の温度が出る"
        case .classic: return "大正ロマンの紙面感"
        }
    }

    func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch self {
        case .mincho:
            return .custom("SawarabiMincho-Regular", size: size)
        case .gothic:
            return .custom("ZenMaruGothic-Regular", size: size)
        case .handwritten:
            return .custom("Yomogi-Regular", size: size)
        case .classic:
            return .custom("Hiragino Mincho ProN", size: size)
        }
    }

    static func retroMincho(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        FontManager.persistedStyle.font(size: size, weight: weight)
    }

    static func rounded(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        FontManager.persistedStyle.font(size: size, weight: weight)
    }

    static func handLetter(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        FontManager.persistedStyle.font(size: size, weight: weight)
    }
}

struct Setting: View {
    @EnvironmentObject private var fontManager: FontManager
    @AppStorage("utakataFontStyle") private var fontStyleRaw = UtakataFontStyle.mincho.rawValue
    @AppStorage("utakataDailyNotificationEnabled") private var notificationEnabled = false
    @AppStorage("utakataMorningNotificationEnabled") private var morningNotificationEnabled = false
    @AppStorage("utakataNightNotificationEnabled") private var nightNotificationEnabled = false
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
        fontManager.selectedStyle
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                OmikujiPreDrawFantasyLayer()
                    .opacity(0.78)
                    .ignoresSafeArea()

                List {
                    Section {
                        NavigationLink {
                            UserSettingsScreen(
                                nickname: $nickname,
                                birthdate: birthdateBinding,
                                locationEnabled: $locationEnabled
                            )
                        } label: {
                            Text("ユーザー設定")
                                .foregroundStyle(Color.settingInk)
                        }
                    } header: {
                        SettingListHeader("ユーザー")
                    }
                    .utakataGroupedRows()

                    Section {
                        NavigationLink {
                            NotificationSettingsScreen(
                                morningEnabled: Binding(
                                    get: { morningNotificationEnabled },
                                    set: { setMorningReminderEnabled($0) }
                                ),
                                nightEnabled: Binding(
                                    get: { nightNotificationEnabled },
                                    set: { setNightReminderEnabled($0) }
                                ),
                                morningTime: morningTimeBinding,
                                nightTime: nightTimeBinding
                            )
                        } label: {
                            Text("通知設定")
                                .foregroundStyle(Color.settingInk)
                        }

                        NavigationLink {
                            DisplayDesignSettingsScreen(
                                selectedFont: selectedFont,
                                fontStyleRaw: $fontStyleRaw,
                                textSize: $textSize,
                                onSelectFont: selectFont
                            )
                        } label: {
                            Text("表示とデザイン")
                                .foregroundStyle(Color.settingInk)
                        }
                    } header: {
                        SettingListHeader("通知と表示")
                    }
                    .utakataGroupedRows()

                    Section {
                        NavigationLink {
                            DataManagementSettingsScreen()
                        } label: {
                            Text("データ管理")
                                .foregroundStyle(Color.settingInk)
                        }
                    } header: {
                        SettingListHeader("データ")
                    }
                    .utakataGroupedRows()

                    Section {
                        NavigationLink {
                            UtakataGuideScreen()
                        } label: {
                            Text("使い方 / 情報")
                                .foregroundStyle(Color.settingInk)
                        }
                        NavigationLink {
                            PolicyTextScreen(title: "利用規約", text: termsText)
                        } label: {
                            Text("利用規約")
                                .foregroundStyle(Color.settingInk)
                        }
                        NavigationLink {
                            PolicyTextScreen(title: "プライバシーポリシー", text: privacyText)
                        } label: {
                            Text("プライバシーポリシー")
                                .foregroundStyle(Color.settingInk)
                        }
                    } header: {
                        SettingListHeader("その他")
                    }
                    .utakataGroupedRows()
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .tint(Color.meijiRed)
                .padding(.bottom, 80)
            }
            .utakataNavigationTitle("設定", systemImage: "gearshape")
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    private func selectFont(_ style: UtakataFontStyle) {
        fontStyleRaw = style.rawValue
        fontManager.setStyle(style)
    }

    private func setMorningReminderEnabled(_ isEnabled: Bool) {
        morningNotificationEnabled = isEnabled
        updateNotificationAuthorizationIfNeeded(isEnabled)
    }

    private func setNightReminderEnabled(_ isEnabled: Bool) {
        nightNotificationEnabled = isEnabled
        updateNotificationAuthorizationIfNeeded(isEnabled)
    }

    private func updateNotificationAuthorizationIfNeeded(_ isEnabled: Bool) {
        notificationEnabled = morningNotificationEnabled || nightNotificationEnabled
        if isEnabled {
            NotificationManager.requestDailyReminders { granted in
                notificationEnabled = granted
                if !granted {
                    morningNotificationEnabled = false
                    nightNotificationEnabled = false
                }
            }
        } else {
            NotificationManager.scheduleDailyReminders()
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
                NotificationManager.scheduleDailyReminders()
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

    private var termsText: String {
        "うたかた日記は、日々の出来事を短歌風の札として楽しむためのアプリです。記録された内容は、ユーザー自身の思い出として大切に扱われます。アプリの利用にあたっては、他者の権利やプライバシーを尊重し、安心して使える範囲でお楽しみください。"
    }

    private var privacyText: String {
        "ニックネーム、生年月日、通知時刻などの設定情報は、アプリ体験を整えるために使用されます。写真や位置情報などの権限は、ユーザーが許可した場合にのみ利用されます。不要になった権限は、iPhoneの設定からいつでも変更できます。"
    }
}

enum NotificationManager {
    private static let morningIdentifier = "utakata.daily.omikuji.reminder"
    private static let nightIdentifier = "utakata.daily.diary.reminder"

    static func refreshDailyReminderIfNeeded() {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: "utakataMorningNotificationEnabled") || defaults.bool(forKey: "utakataNightNotificationEnabled") else { return }
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
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [morningIdentifier, nightIdentifier])

        if defaults.bool(forKey: "utakataMorningNotificationEnabled") {
            scheduleReminder(
                identifier: morningIdentifier,
                title: "うたかたみくじ",
                body: "今日の予兆を、そっと引いてみませんか。",
                hour: defaults.object(forKey: "utakataMorningHour") as? Int ?? 7,
                minute: defaults.object(forKey: "utakataMorningMinute") as? Int ?? 30
            )
        }

        if defaults.bool(forKey: "utakataNightNotificationEnabled") {
            scheduleReminder(
                identifier: nightIdentifier,
                title: "うたかた日記",
                body: "今日の光を、一枚の札にしまいませんか。",
                hour: defaults.object(forKey: "utakataNightHour") as? Int ?? 22,
                minute: defaults.object(forKey: "utakataNightMinute") as? Int ?? 0
            )
        }
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

struct UserSettingsScreen: View {
    @Binding var nickname: String
    @Binding var birthdate: Date
    @Binding var locationEnabled: Bool

    var body: some View {
        StandardSettingsBackground {
            List {
                Section {
                    TextField("ニックネーム", text: $nickname)
                        .foregroundStyle(Color.settingInk)
                    DatePicker(selection: $birthdate, displayedComponents: .date) {
                        Text("生年月日")
                            .foregroundStyle(Color.settingInk)
                    }
                    .environment(\.locale, Locale(identifier: "ja_JP"))
                    Toggle(isOn: $locationEnabled) {
                        Text("位置情報の利用許可")
                            .foregroundStyle(Color.settingInk)
                    }
                    .tint(Color.meijiRed)
                }
                .utakataGroupedRows()
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .tint(Color.meijiRed)
        }
        .utakataNavigationTitle("ユーザー設定")
    }
}

struct NotificationSettingsScreen: View {
    @Binding var morningEnabled: Bool
    @Binding var nightEnabled: Bool
    @Binding var morningTime: Date
    @Binding var nightTime: Date

    var body: some View {
        StandardSettingsBackground {
            List {
                Section {
                    Toggle(isOn: $morningEnabled) {
                        Text("朝のうたかたみくじ通知")
                            .foregroundStyle(Color.settingInk)
                    }
                    .tint(Color.meijiRed)

                    if morningEnabled {
                        DatePicker(selection: $morningTime, displayedComponents: .hourAndMinute) {
                            Text("通知時刻")
                                .foregroundStyle(Color.settingInk)
                        }
                            .datePickerStyle(.wheel)
                            .tint(Color.meijiRed)
                    }
                }
                .utakataGroupedRows()

                Section {
                    Toggle(isOn: $nightEnabled) {
                        Text("夜の日記通知")
                            .foregroundStyle(Color.settingInk)
                    }
                    .tint(Color.meijiRed)

                    if nightEnabled {
                        DatePicker(selection: $nightTime, displayedComponents: .hourAndMinute) {
                            Text("通知時刻")
                                .foregroundStyle(Color.settingInk)
                        }
                            .datePickerStyle(.wheel)
                            .tint(Color.meijiRed)
                    }
                }
                .utakataGroupedRows()
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .tint(Color.meijiRed)
        }
        .utakataNavigationTitle("通知設定")
    }
}

struct DisplayDesignSettingsScreen: View {
    let selectedFont: UtakataFontStyle
    @Binding var fontStyleRaw: String
    @Binding var textSize: Double
    let onSelectFont: (UtakataFontStyle) -> Void
    @State private var draftFont: UtakataFontStyle
    @State private var draftTextSize: Double
    @State private var isDirty = false
    @State private var didSave = false

    init(
        selectedFont: UtakataFontStyle,
        fontStyleRaw: Binding<String>,
        textSize: Binding<Double>,
        onSelectFont: @escaping (UtakataFontStyle) -> Void
    ) {
        self.selectedFont = selectedFont
        self._fontStyleRaw = fontStyleRaw
        self._textSize = textSize
        self.onSelectFont = onSelectFont
        self._draftFont = State(initialValue: selectedFont)
        self._draftTextSize = State(initialValue: textSize.wrappedValue)
    }

    private var previewSize: CGFloat {
        switch Int(draftTextSize) {
        case 0: return 15
        case 2: return 23
        default: return 19
        }
    }

    var body: some View {
        StandardSettingsBackground {
            ZStack(alignment: .bottom) {
                List {
                    Section {
                        LetterPreviewCard(selectedFont: draftFont, previewSize: previewSize)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 10, trailing: 20))

                    Section {
                        ForEach([UtakataFontStyle.mincho, .gothic, .handwritten]) { style in
                            Button {
                                updateDraftFont(style)
                            } label: {
                                HStack {
                                    Text(style.title)
                                        .foregroundStyle(Color.settingInk)
                                    Spacer()
                                    if draftFont == style {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.meijiRed)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        SettingListHeader("書体")
                    }
                    .utakataGroupedRows()

                    Section {
                        HStack(alignment: .center, spacing: 14) {
                            Text("A")
                                .font(.footnote)
                                .foregroundStyle(Color.settingInk.opacity(0.78))
                            Slider(
                                value: Binding(
                                    get: { draftTextSize },
                                    set: { updateDraftTextSize($0) }
                                ),
                                in: 0...2,
                                step: 1
                            )
                            .tint(Color.settingGold)
                            Text("A")
                                .font(.title2)
                                .foregroundStyle(Color.settingInk)
                        }
                        .padding(.vertical, 8)
                    } header: {
                        SettingListHeader("文字サイズ")
                    }
                    .utakataGroupedRows()
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .tint(Color.meijiRed)
                .safeAreaPadding(.bottom, isDirty || didSave ? 92 : 12)

                VStack(spacing: 10) {
                    if didSave {
                        Text("保存しました")
                            .utakataFont(style: .caption, size: 12, weight: .semibold)
                            .foregroundStyle(Color.settingInk)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color(hex: 0xFFF9F2).opacity(0.94), in: Capsule())
                            .overlay(Capsule().stroke(Color.settingGold.opacity(0.38), lineWidth: 0.8))
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    }

                    if isDirty {
                        Button {
                            saveChanges()
                        } label: {
                            Text("保存")
                                .utakataFont(style: .button, size: 16, weight: .semibold)
                                .foregroundStyle(Color.retroPaper)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(Color.meijiRed, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.retroGold.opacity(0.50), lineWidth: 1))
                                .shadow(color: Color.meijiRed.opacity(0.22), radius: 14, x: 0, y: 8)
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .bottom)))
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 16)
                .animation(.spring(response: 0.34, dampingFraction: 0.86), value: isDirty)
                .animation(.easeInOut(duration: 0.22), value: didSave)
            }
        }
        .utakataNavigationTitle("表示とデザイン")
        .onAppear {
            resetDraftToCurrentValues()
        }
    }

    private func updateDraftFont(_ style: UtakataFontStyle) {
        withAnimation(.easeInOut(duration: 0.18)) {
            draftFont = style
            updateDirtyState()
            didSave = false
        }
    }

    private func updateDraftTextSize(_ value: Double) {
        draftTextSize = value
        updateDirtyState()
        didSave = false
    }

    private func updateDirtyState() {
        isDirty = draftFont.rawValue != fontStyleRaw || Int(draftTextSize) != Int(textSize)
    }

    private func resetDraftToCurrentValues() {
        draftFont = selectedFont
        draftTextSize = textSize
        updateDirtyState()
    }

    private func saveChanges() {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
            textSize = draftTextSize
            fontStyleRaw = draftFont.rawValue
            onSelectFont(draftFont)
            isDirty = false
            didSave = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
            withAnimation(.easeInOut(duration: 0.22)) {
                didSave = false
            }
        }
    }
}

struct DataManagementSettingsScreen: View {
    @AppStorage("utakataICloudSyncEnabled") private var iCloudSyncEnabled = false

    var body: some View {
        StandardSettingsBackground {
            List {
                Section {
                    Toggle(isOn: $iCloudSyncEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("iCloud同期")
                                .foregroundStyle(Color.settingInk)
                            Text("ONにすると、この端末の日記をあなたのiCloudに保存して同期します。")
                                .font(.caption)
                                .foregroundStyle(Color.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .tint(Color.meijiRed)
                }
                header: {
                    SettingListHeader("バックアップ")
                } footer: {
                    Text("開発者はiCloud上の日記や写真にアクセスできません。同期をOFFにすると、この端末内での利用に戻ります。")
                        .font(.caption)
                        .foregroundStyle(Color.secondaryText)
                }
                .utakataGroupedRows()
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .tint(Color.meijiRed)
        }
        .utakataNavigationTitle("データ管理")
    }
}

struct UtakataGuideScreen: View {
    private let sections: [GuideSection] = [
        GuideSection(
            number: "一",
            title: "日記を書く",
            message: "日記画面の＋から、写真や一言をそっと入れます。長く書かなくても、その日の空気が短歌の札になります。",
            preview: .diary
        ),
        GuideSection(
            number: "二",
            title: "翌朝のみくじ",
            message: "前日に日記を書いていると、翌朝5時以降に小さなみくじの印が灯ります。押した時だけ、朝の儀式がはじまります。",
            preview: .mikuji
        ),
        GuideSection(
            number: "三",
            title: "思い出をめくる",
            message: "思い出画面では、札棚に残った日々をかるたのように眺められます。気になる札をタップして、裏側の気持ちをめくってください。",
            preview: .memory
        )
    ]

    var body: some View {
        StandardSettingsBackground {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    VStack(spacing: 10) {
                        Text("使い方 / 情報")
                            .utakataFont(style: .header, size: 28, weight: .semibold)
                            .foregroundStyle(Color.settingInk)

                        Text("これは説明書というより、うたかた日記との待ち合わせの手紙です。迷った時だけ、そっと開いてください。")
                            .utakataFont(style: .body, size: 14)
                            .foregroundStyle(Color.secondaryText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(5)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 22)

                    ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                        if index.isMultiple(of: 2) {
                            GuideStepCard(section: section)
                            GuidePreviewCard(kind: section.preview)
                        } else {
                            GuidePreviewCard(kind: section.preview)
                            GuideStepCard(section: section)
                        }
                    }

                    GuideClosingLetter()
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, 20)
            }
        }
        .utakataNavigationTitle("使い方 / 情報")
    }
}

struct GuideSection: Identifiable {
    let id = UUID()
    let number: String
    let title: String
    let message: String
    let preview: GuidePreviewKind
}

enum GuidePreviewKind {
    case diary
    case mikuji
    case memory
}

struct GuideStepCard: View {
    let section: GuideSection

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(section.number)
                .utakataFont(style: .date, size: 15, weight: .bold)
                .foregroundStyle(Color.retroPaper)
                .frame(width: 34, height: 34)
                .background(Color.meijiRed.opacity(0.88), in: Circle())
                .overlay(Circle().stroke(Color.retroGold.opacity(0.58), lineWidth: 1))

            VStack(alignment: .leading, spacing: 7) {
                Text(section.title)
                    .utakataFont(style: .headline)
                    .foregroundStyle(Color.settingInk)

                Text(section.message)
                    .utakataFont(style: .body, size: 13)
                    .foregroundStyle(Color.secondaryText)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color.settingPaper, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.settingLine, lineWidth: 0.9))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.settingGold.opacity(0.24), lineWidth: 0.7).padding(5))
        .shadow(color: Color.meijiRed.opacity(0.06), radius: 10, x: 0, y: 5)
    }
}

struct GuidePreviewCard: View {
    let kind: GuidePreviewKind

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(title)
                    .utakataFont(style: .caption, size: 12, weight: .semibold)
                    .foregroundStyle(Color.meijiRed.opacity(0.76))
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.retroGold)
            }

            preview
        }
        .padding(15)
        .background {
            ZStack {
                Color.settingPaper
                TaishoCheckPattern(color: Color.meijiRed.opacity(0.018), tile: 22)
                WashiPattern()
                    .opacity(0.10)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.settingLine, lineWidth: 0.85))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.settingGold.opacity(0.26), lineWidth: 0.7).padding(5))
        .shadow(color: Color.meijiRed.opacity(0.06), radius: 10, x: 0, y: 5)
    }

    private var title: String {
        switch kind {
        case .diary: return "日記画面の見本"
        case .mikuji: return "朝のみくじの見本"
        case .memory: return "思い出画面の見本"
        }
    }

    private var icon: String {
        switch kind {
        case .diary: return "calendar"
        case .mikuji: return "scroll.fill"
        case .memory: return "square.grid.3x3.fill"
        }
    }

    @ViewBuilder
    private var preview: some View {
        switch kind {
        case .diary:
            GuideDiaryMock()
        case .mikuji:
            GuideMikujiMock()
        case .memory:
            GuideMemoryMock()
        }
    }
}

struct GuideDiaryMock: View {
    var body: some View {
        VStack(spacing: 9) {
            HStack {
                Text("2026年6月")
                    .utakataFont(style: .title, size: 18)
                Spacer()
                Circle()
                    .fill(Color.meijiRed.opacity(0.86))
                    .frame(width: 28, height: 28)
                    .overlay(Image(systemName: "plus").font(.system(size: 13, weight: .bold)).foregroundStyle(.white))
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 7) {
                ForEach(1...21, id: \.self) { day in
                    Text("\(day)")
                        .utakataFont(style: .date, size: 11)
                        .foregroundStyle(day == 13 ? Color.retroPaper : Color.settingInk.opacity(0.78))
                        .frame(width: 24, height: 24)
                        .background(day == 13 ? Color.meijiRed.opacity(0.58) : Color.clear, in: Circle())
                }
            }
        }
        .padding(14)
        .background(Color(hex: 0xFFF9F2).opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct GuideMikujiMock: View {
    var body: some View {
        HStack(spacing: 14) {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(Color(hex: 0xFFF9F2))
                    .frame(width: 58, height: 58)
                    .overlay(Circle().stroke(Color.settingGold.opacity(0.5), lineWidth: 1))
                Image(systemName: "scroll.fill")
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(Color.meijiRed)
                Circle()
                    .fill(Color.meijiRed)
                    .frame(width: 11, height: 11)
                    .offset(x: -4, y: 4)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("翌朝だけ灯る印")
                    .utakataFont(style: .headline, size: 15)
                    .foregroundStyle(Color.settingInk)
                Text("昨日の札がある朝、静かに待っています。")
                    .utakataFont(style: .caption, size: 12)
                    .foregroundStyle(Color.secondaryText)
            }
            Spacer()
        }
        .padding(14)
        .background(Color(hex: 0xFFF9F2).opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct GuideMemoryMock: View {
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 9), count: 3), spacing: 9) {
            ForEach(0..<6, id: \.self) { index in
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0xFFF8EA), Color(hex: 0xE9D3D4).opacity(0.78), Color(hex: 0xD8E4EA).opacity(0.62)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 76)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.settingGold.opacity(0.45), lineWidth: 0.8))
                    .overlay {
                        Text(index.isMultiple(of: 2) ? "雨あがる" : "夜の窓")
                            .utakataFont(style: .tanka, size: 10)
                            .foregroundStyle(Color.settingInk.opacity(0.78))
                            .rotationEffect(.degrees(90))
                    }
            }
        }
        .padding(12)
        .background(Color(hex: 0xFFF9F2).opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct GuideClosingLetter: View {
    var body: some View {
        VStack(spacing: 9) {
            PlumBlossom()
                .fill(Color.meijiRed.opacity(0.52))
                .frame(width: 18, height: 18)

            Text("うたかた日記との向き合い方")
                .utakataFont(style: .headline, size: 16)
                .foregroundStyle(Color.settingInk)

            Text("毎日を完璧に残そうとしなくて大丈夫です。ふと目に留まった光や、言葉になりきらない気持ちが一枚の札になれば、それだけで今日の記憶はちゃんとここにあります。")
                .utakataFont(style: .body, size: 13)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            Text("通知やiCloud同期は、設定からいつでも変更できます。")
                .utakataFont(style: .caption, size: 11)
                .foregroundStyle(Color.secondaryText.opacity(0.72))
                .padding(.top, 2)
        }
        .padding(18)
        .background(Color.settingPaper, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.settingLine, lineWidth: 0.85))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.settingGold.opacity(0.24), lineWidth: 0.7).padding(5))
    }
}

struct PolicyTextScreen: View {
    let title: String
    let text: String

    var body: some View {
        StandardSettingsBackground {
            List {
                Section {
                    Text(text)
                        .font(.body)
                        .lineSpacing(5)
                        .padding(.vertical, 6)
                        .foregroundStyle(Color.settingInk)
                }
                .utakataGroupedRows()
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .tint(Color.meijiRed)
        }
        .utakataNavigationTitle(title)
    }
}

struct UtakataNavigationTitle: View {
    let title: String
    let systemImage: String?

    var body: some View {
        HStack(spacing: 7) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.meijiRed.opacity(0.88))
            }

            Text(title)
                .utakataFont(style: .title, size: 21, weight: .semibold)
                .foregroundStyle(Color.settingInk)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
}

private extension View {
    func utakataNavigationTitle(_ title: String, systemImage: String? = nil) -> some View {
        self
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    UtakataNavigationTitle(title: title, systemImage: systemImage)
                }
            }
    }
}

struct StandardSettingsBackground<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            AppBackground()
            OmikujiPreDrawFantasyLayer()
                .opacity(0.72)
                .ignoresSafeArea()
            content
        }
    }
}

struct SettingListHeader: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(UtakataFontStyle.rounded(size: 12, weight: .semibold))
            .foregroundStyle(Color.meijiRed.opacity(0.78))
            .textCase(nil)
            .padding(.leading, 2)
            .padding(.bottom, 3)
    }
}

struct SettingGroupedRowBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: 0xFFF9F2).opacity(0.94),
                    Color(hex: 0xF8E7D6).opacity(0.88),
                    Color(hex: 0xF3E5CB).opacity(0.84)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            WashiPattern()
                .opacity(0.10)

            TaishoCheckPattern(color: Color.meijiRed.opacity(0.018), tile: 24)

            RetroCornerOrnaments(color: Color.meijiRed.opacity(0.16))
                .padding(9)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.settingLine, lineWidth: 0.85)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.settingGold.opacity(0.28), lineWidth: 0.7)
                .padding(4)
        )
        .shadow(color: Color.meijiRed.opacity(0.08), radius: 10, x: 0, y: 5)
    }
}

struct LetterPreviewCard: View {
    let selectedFont: UtakataFontStyle
    let previewSize: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 8) {
                PlumBlossom()
                    .fill(Color.meijiRed.opacity(0.84))
                    .frame(width: 16, height: 16)
                Rectangle()
                    .fill(Color.meijiRed.opacity(0.55))
                    .frame(height: 1)
            }

            Text("あはれなる今日の余韻")
                .font(selectedFont.font(size: previewSize, weight: .semibold))
                .foregroundStyle(Color.settingInk)

            Text("選んだ書体と文字サイズがここに反映されます。")
                .font(selectedFont.font(size: max(previewSize - 4, 13), weight: .regular))
                .foregroundStyle(Color.settingInk.opacity(0.68))
                .fixedSize(horizontal: false, vertical: true)

            Rectangle()
                .fill(Color.settingGold.opacity(0.46))
                .frame(height: 1)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color(hex: 0xFFF8EA), Color(hex: 0xF8E8D4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.settingLine, lineWidth: 0.9))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.settingGold.opacity(0.24), lineWidth: 0.7).padding(5))
        .shadow(color: Color.meijiRed.opacity(0.08), radius: 12, x: 0, y: 6)
    }
}

private extension View {
    func utakataGroupedRows() -> some View {
        self
            .listRowBackground(SettingGroupedRowBackground())
            .listRowSeparatorTint(Color.settingGold.opacity(0.26))
    }
}

struct SettingMenuGroup<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: 0xFFF8F0).opacity(0.88), Color(hex: 0xF7DEC9).opacity(0.78)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                WashiPattern()
                    .opacity(0.13)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.meijiRed.opacity(0.24), lineWidth: 1.1))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.retroGold.opacity(0.36), lineWidth: 0.8).padding(5))
        .shadow(color: Color.meijiRed.opacity(0.09), radius: 16, x: 0, y: 8)
    }
}

struct SettingMenuRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 13) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.retroPaper)
                .frame(width: 38, height: 38)
                .background(tint.opacity(0.9), in: Circle())
                .overlay(Circle().stroke(Color.retroGold.opacity(0.42), lineWidth: 1))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(UtakataFontStyle.rounded(size: 16, weight: .semibold))
                    .foregroundStyle(Color.primaryText)
                Text(subtitle)
                    .font(UtakataFontStyle.rounded(size: 12, weight: .medium))
                    .foregroundStyle(Color.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(Color.secondaryText.opacity(0.55))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.primaryText.opacity(0.08))
                .frame(height: 0.8)
                .padding(.leading, 67)
        }
    }
}

struct SettingDetailScreen<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppBackground()
            OmikujiPreDrawFantasyLayer()
                .opacity(0.56)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "chevron.left")
                                Text("戻る")
                            }
                            .font(UtakataFontStyle.rounded(size: 15, weight: .semibold))
                            .foregroundStyle(Color.meijiRed)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                            .background(Color.retroPaper.opacity(0.56), in: Capsule())
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Text(title)
                            .font(UtakataFontStyle.retroMincho(size: 24, weight: .semibold))
                            .foregroundStyle(Color.primaryText)

                        Spacer()

                        Color.clear
                            .frame(width: 68, height: 32)
                    }
                    .padding(.top, 8)

                    content
                }
                .padding(.horizontal, 22)
                .padding(.top, 12)
                .padding(.bottom, 140)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct FontMoodPreview: View {
    let selectedFont: UtakataFontStyle

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("文字の雰囲気")
                .font(UtakataFontStyle.rounded(size: 14, weight: .semibold))
                .foregroundStyle(Color.secondaryText)

            HStack(spacing: 12) {
                Text("あはれ吉")
                    .font(UtakataFontStyle.retroMincho(size: 24, weight: .semibold))
                Text("琥珀イヤホン")
                    .font(UtakataFontStyle.handLetter(size: 19, weight: .medium))
                Text("今日の記録")
                    .font(selectedFont.font(size: 18, weight: .semibold))
            }
            .foregroundStyle(Color.primaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(Color.retroPaper.opacity(0.68), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.retroGold.opacity(0.24), lineWidth: 1))
        }
    }
}

struct StationeryTextPanel: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(UtakataFontStyle.retroMincho(size: 20, weight: .semibold))
                .foregroundStyle(Color.primaryText)

            Text(text)
                .font(UtakataFontStyle.rounded(size: 15, weight: .medium))
                .lineSpacing(7)
                .foregroundStyle(Color.primaryText.opacity(0.86))
                .fixedSize(horizontal: false, vertical: true)
                .padding(18)
                .background {
                    ZStack {
                        Color(hex: 0xFFF8EA).opacity(0.78)
                        VStack(spacing: 13) {
                            ForEach(0..<8, id: \.self) { _ in
                                Rectangle()
                                    .fill(Color.meijiBlue.opacity(0.08))
                                    .frame(height: 0.8)
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.retroGold.opacity(0.24), lineWidth: 1))
        }
    }
}

struct SettingSection<Content: View>: View {
    let title: String
    let tint: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(UtakataFontStyle.rounded(size: 12, weight: .bold))
                .foregroundStyle(tint.opacity(0.92))
                .padding(.horizontal, 6)

            VStack(spacing: 0) {
                content
            }
            .background {
                ZStack {
                    LinearGradient(
                        colors: [Color(hex: 0xFFF8EA).opacity(0.94), Color.retroPaper.opacity(0.86)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    WashiPattern()
                        .opacity(0.12)
                }
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(tint.opacity(0.3), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(Color.retroGold.opacity(0.32), lineWidth: 0.8)
                    .padding(5)
            )
            .shadow(color: Color.primaryText.opacity(0.055), radius: 12, x: 0, y: 6)
        }
        .padding(.horizontal, 2)
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
                .frame(maxWidth: 150, alignment: .trailing)
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
                .frame(maxWidth: 150, alignment: .trailing)
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
                .frame(width: 54, alignment: .trailing)
        }
    }
}

struct SettingFontPickerRow: View {
    let selectedFont: UtakataFontStyle
    @Binding var fontStyleRaw: String

    var body: some View {
        SettingRowShell {
            Text("書体（フォント）の選択")
                .font(UtakataFontStyle.rounded(size: 15, weight: .bold))
                .foregroundStyle(Color.primaryText)

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 8) {
                ForEach([UtakataFontStyle.mincho, .gothic, .handwritten]) { style in
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            fontStyleRaw = style.rawValue
                        }
                    } label: {
                        HStack(spacing: 9) {
                            Image(systemName: selectedFont == style ? "largecircle.fill.circle" : "circle")
                                .font(.system(size: 13, weight: .bold))
                            Text(style.title)
                                .font(style.font(size: 14, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.9)
                        }
                        .foregroundStyle(selectedFont == style ? Color.meijiRed : Color.secondaryText)
                        .frame(width: 124, alignment: .leading)
                        .padding(.vertical, 9)
                        .padding(.horizontal, 12)
                        .background(
                            selectedFont == style ? Color.meijiRed.opacity(0.12) : Color(hex: 0xFFF8EA).opacity(0.76),
                            in: Capsule()
                        )
                        .overlay(Capsule().stroke(selectedFont == style ? Color.meijiRed.opacity(0.52) : Color.retroGold.opacity(0.24), lineWidth: 0.9))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 150, alignment: .trailing)
        }
    }
}

struct SettingTextSizeRow: View {
    @Binding var textSize: Double
    let valueLabel: String

    var body: some View {
        SettingRowShell {
            Text("文字サイズ")
                .font(UtakataFontStyle.rounded(size: 15, weight: .bold))
                .foregroundStyle(Color.primaryText)

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 7) {
                Text(valueLabel)
                    .font(UtakataFontStyle.rounded(size: 12, weight: .bold))
                    .foregroundStyle(Color.secondaryText)

                Slider(value: $textSize, in: 0...2, step: 1)
                    .tint(Color.meijiRed)
                    .frame(width: 126)

                HStack {
                    Text("小")
                    Spacer()
                    Text("標準")
                    Spacer()
                    Text("大")
                }
                .font(UtakataFontStyle.rounded(size: 10, weight: .bold))
                .foregroundStyle(Color.secondaryText.opacity(0.78))
                .frame(width: 126)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(Color(hex: 0xFFF8EA).opacity(0.94), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.retroGold.opacity(0.28), lineWidth: 0.8))
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.primaryText.opacity(0.09))
                .frame(height: 0.8)
                .padding(.leading, 16)
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
