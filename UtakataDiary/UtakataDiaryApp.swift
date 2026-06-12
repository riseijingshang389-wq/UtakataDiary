//
//  UtakataDiaryApp.swift
//  UtakataDiary
//
//  Created by 井上凜清 on 2026/05/24.
//

import SwiftUI

@main
struct UtakataDiaryApp: App {
    @StateObject private var fontManager = FontManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(fontManager)
                .environment(\.font, fontManager.font(role: .body))
        }
    }
}
