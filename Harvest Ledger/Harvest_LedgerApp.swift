import SwiftUI

@main
struct Harvest_LedgerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(RecordStore())
        }
    }
}
