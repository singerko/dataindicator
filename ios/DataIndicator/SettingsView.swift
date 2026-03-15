// SettingsView.swift
// Obrazovka pre nastavenia iOS verzie aplikácie.

import SwiftUI

/// UI pre nastavenia indikátora (farby, rozmery, auto‑štart).
struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var networkMonitor: NetworkMonitor
    
    @AppStorage("indicatorHeight") private var indicatorHeight: Double = 4.0
    @AppStorage("indicatorWidthPercent") private var indicatorWidthPercent: Double = 100.0
    @AppStorage("alignment") private var alignment: String = "center"
    @AppStorage("wifiColor") private var wifiColorHex: String = "#4CAF50"
    @AppStorage("mobileColor") private var mobileColorHex: String = "#F44336"
    @AppStorage("noInternetColor") private var noInternetColorHex: String = "#9E9E9E"
    @AppStorage("autoStartEnabled") private var autoStartEnabled: Bool = false
    
    /// UI celej obrazovky.
    var body: some View {
        NavigationView {
            Form {
                // Základné nastavenia
                Section("Základné nastavenia") {
                    Toggle("Auto-štart aplikácie", isOn: $autoStartEnabled)
                        .help("Automaticky spustiť monitoring po štarte telefónu")
                }
                
                // Rozmery indikátora
                Section("Rozmery indikátora") {
                    VStack(alignment: .leading) {
                        Text("Výška: \(Int(indicatorHeight)) px")
                        Slider(value: $indicatorHeight, in: 1...20, step: 1)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Šírka: \(Int(indicatorWidthPercent))%")
                        Slider(value: $indicatorWidthPercent, in: 10...100, step: 5)
                    }
                    
                    Picker("Zarovnanie", selection: $alignment) {
                        Text("Vľavo").tag("left")
                        Text("Stred").tag("center")
                        Text("Vpravo").tag("right")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .disabled(indicatorWidthPercent >= 100)
                }
                
                // Farby
                Section("Farby indikátora") {
                    ColorPickerRow(
                        title: "WiFi pripojenie",
                        colorHex: $wifiColorHex,
                        defaultColor: "#4CAF50"
                    )
                    
                    ColorPickerRow(
                        title: "Mobilné dáta",
                        colorHex: $mobileColorHex,
                        defaultColor: "#F44336"
                    )
                    
                    ColorPickerRow(
                        title: "Bez internetu",
                        colorHex: $noInternetColorHex,
                        defaultColor: "#9E9E9E"
                    )
                }
                
                // Preview
                Section("Náhľad") {
                    VStack {
                        Text("Náhľad indikátora")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        GeometryReader { geometry in
                            HStack {
                                if alignment == "center" {
                                    Spacer()
                                }
                                
                                Rectangle()
                                    .fill(Color(hex: wifiColorHex) ?? .green)
                                    .frame(
                                        width: geometry.size.width * (indicatorWidthPercent / 100.0),
                                        height: indicatorHeight
                                    )
                                
                                if alignment == "center" {
                                    Spacer()
                                } else if alignment == "left" {
                                    Spacer()
                                }
                            }
                        }
                        .frame(height: max(indicatorHeight, 20))
                        .background(Color(.systemGray6))
                        .cornerRadius(4)
                    }
                }
                
                // Akcie
                Section {
                    Button("Resetovať na predvolené") {
                        resetToDefaults()
                    }
                    .foregroundColor(.red)
                    
                    Button("Test indikátora (5s)") {
                        testIndicator()
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Nastavenia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Hotovo") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    /// Obnoví predvolené hodnoty nastavení.
    private func resetToDefaults() {
        indicatorHeight = 4.0
        indicatorWidthPercent = 100.0
        alignment = "center"
        wifiColorHex = "#4CAF50"
        mobileColorHex = "#F44336"
        noInternetColorHex = "#9E9E9E"
        autoStartEnabled = false
    }
    
    /// Spustí krátky test indikátora (5 sekúnd).
    private func testIndicator() {
        if !networkMonitor.isMonitoring {
            networkMonitor.startMonitoring()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                networkMonitor.stopMonitoring()
            }
        }
    }
}

/// Riadok s výberom farby a prevodom na HEX.
struct ColorPickerRow: View {
    let title: String
    @Binding var colorHex: String
    let defaultColor: String
    
    @State private var selectedColor: Color
    
    /// Inicializácia riadku s výberom farby.
    init(title: String, colorHex: Binding<String>, defaultColor: String) {
        self.title = title
        self._colorHex = colorHex
        self.defaultColor = defaultColor
        self._selectedColor = State(initialValue: Color(hex: colorHex.wrappedValue) ?? Color(hex: defaultColor)!)
    }
    
    /// UI riadku s ColorPickerom.
    var body: some View {
        HStack {
            Text(title)
            
            Spacer()
            
            ColorPicker("", selection: $selectedColor)
                .frame(width: 44, height: 44)
                .onChange(of: selectedColor) { newColor in
                    colorHex = newColor.toHex()
                }
        }
    }
}

/// Utility pre konverziu farby na HEX.
extension Color {
    /// Vráti farbu ako HEX reťazec (napr. `#FF0000`).
    func toHex() -> String {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return "#000000"
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        
        return String(format: "#%02lX%02lX%02lX",
                     lroundf(r * 255),
                     lroundf(g * 255),
                     lroundf(b * 255))
    }
}

#Preview {
    SettingsView()
        .environmentObject(NetworkMonitor())
}
