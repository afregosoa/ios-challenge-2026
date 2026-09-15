import SwiftUI
import SwiftData

@main
struct ApplaudoChallengeApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: SavedCat.self)
    }
}
