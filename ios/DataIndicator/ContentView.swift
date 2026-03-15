// ContentView.swift
// Hlavná SwiftUI obrazovka pre iOS verziu aplikácie.

import SwiftUI

/// Hlavná obrazovka s ovládaním a legendou stavu siete.
struct ContentView: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @State private var isMonitoringEnabled = false
    
    /// UI celej obrazovky.
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Hlavná sekcia
                VStack(spacing: 12) {
                    Text("DataIndicator")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("Monitor pripojenia k internetu")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Status indikátor
                    NetworkStatusView()
                        .environmentObject(networkMonitor)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Ovládanie
                VStack(spacing: 16) {
                    Toggle("Overlay indikátor", isOn: $isMonitoringEnabled)
                        .font(.headline)
                        .onChange(of: isMonitoringEnabled) { value in
                            if value {
                                networkMonitor.startMonitoring()
                            } else {
                                networkMonitor.stopMonitoring()
                            }
                        }
                    
                    if isMonitoringEnabled {
                        Text("Overlay je aktívny")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Legenda
                VStack(alignment: .leading, spacing: 8) {
                    Text("Farebné indikátory:")
                        .font(.headline)
                    
                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 12, height: 12)
                        Text("WiFi pripojenie")
                    }
                    
                    HStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                        Text("Mobilné dáta")
                    }
                    
                    HStack {
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 12, height: 12)
                        Text("Bez internetu")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
                
                // Nastavenia tlačidlo
                NavigationLink(destination: SettingsView()) {
                    Text("Nastavenia")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .padding()
            .navigationBarHidden(true)
        }
        .onAppear {
            networkMonitor.checkPermissions()
        }
    }
}

/// Malý indikátor stavu siete (farba + text).
struct NetworkStatusView: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor
    
    /// UI komponentu status indikátora.
    var body: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 16, height: 16)
            
            Text(statusText)
                .font(.body)
                .fontWeight(.medium)
        }
    }
    
    /// Farba podľa typu pripojenia.
    private var statusColor: Color {
        switch networkMonitor.networkType {
        case .wifi:
            return .green
        case .cellular:
            return .red
        case .none:
            return .gray
        }
    }
    
    /// Text podľa typu pripojenia.
    private var statusText: String {
        switch networkMonitor.networkType {
        case .wifi:
            return "WiFi pripojenie"
        case .cellular:
            return "Mobilné dáta"
        case .none:
            return "Bez pripojenia"
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(NetworkMonitor())
}
