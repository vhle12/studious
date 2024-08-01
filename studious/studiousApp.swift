import SwiftUI

@main
struct StudiousApp: App {
    var body: some Scene {
        MenuBarExtra("Studious", systemImage: "list.bullet.circle.fill") {
            MainView()
        }
        .menuBarExtraStyle(.window)
    }
}
