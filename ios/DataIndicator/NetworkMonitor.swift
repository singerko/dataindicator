// NetworkMonitor.swift
// Monitorovanie siete a zobrazenie overlay na iOS.

import Foundation
import Network
import SwiftUI

/// Typ pripojenia siete (Wi‑Fi, mobilné dáta, alebo bez siete).
enum NetworkType {
    case wifi
    case cellular
    case none
}

/// ObservableObject, ktorý sleduje stav siete a spravuje overlay.
class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var networkType: NetworkType = .none
    @Published var isConnected = false
    @Published var isMonitoring = false
    
    private var overlayWindow: UIWindow?
    
    /// Spustí monitorovanie siete po vytvorení objektu.
    init() {
        startNetworkMonitoring()
    }
    
    /// Začne počúvať zmeny siete pomocou `NWPathMonitor`.
    func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                
                if path.usesInterfaceType(.wifi) {
                    self?.networkType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.networkType = .cellular
                } else {
                    self?.networkType = .none
                }
            }
        }
        
        monitor.start(queue: queue)
    }
    
    /// Zastaví monitorovanie siete.
    func stopNetworkMonitoring() {
        monitor.cancel()
    }
    
    /// Zapne overlay indikátor.
    func startMonitoring() {
        isMonitoring = true
        showOverlay()
    }
    
    /// Vypne overlay indikátor.
    func stopMonitoring() {
        isMonitoring = false
        hideOverlay()
    }
    
    /// iOS nevyžaduje špeciálne povolenia pre overlay.
    func checkPermissions() {
        // iOS nepoužíva špeciálne permissions pre overlay ako Android
        // Ale môžeme skontrolovať dostupnosť network monitoring
    }
    
    /// Vytvorí a zobrazí overlay okno.
    private func showOverlay() {
        guard overlayWindow == nil else { return }
        
        let overlayWindow = UIWindow(frame: UIScreen.main.bounds)
        overlayWindow.windowLevel = UIWindow.Level.statusBar + 1
        overlayWindow.backgroundColor = UIColor.clear
        overlayWindow.isHidden = false
        
        let overlayView = OverlayIndicatorHostingController(networkMonitor: self)
        overlayWindow.rootViewController = overlayView
        
        self.overlayWindow = overlayWindow
    }
    
    /// Skryje a uvoľní overlay okno.
    private func hideOverlay() {
        overlayWindow?.isHidden = true
        overlayWindow = nil
    }
}

/// UIHostingController pre zobrazenie SwiftUI OverlayView v samostatnom okne.
class OverlayIndicatorHostingController: UIHostingController<OverlayView> {
    /// Inicializuje hosting controller s OverlayView.
    init(networkMonitor: NetworkMonitor) {
        super.init(rootView: OverlayView().environmentObject(networkMonitor))
        view.backgroundColor = UIColor.clear
    }
    
    /// Inicializácia z Interface Buildera nie je podporovaná.
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Nastaví priehľadné pozadie.
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.clear
    }
}
