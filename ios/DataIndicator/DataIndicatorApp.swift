// DataIndicatorApp.swift
// Vstupný bod iOS aplikácie.

import SwiftUI

@main
/// Hlavná aplikácia pre iOS.
struct DataIndicatorApp: App {
    @StateObject private var networkMonitor = NetworkMonitor()
    
    /// Koreňová scéna aplikácie.
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(networkMonitor)
        }
    }
}
