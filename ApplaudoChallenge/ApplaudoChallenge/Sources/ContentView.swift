import SwiftUI

public struct ContentView: View {
    public init() {}

    public var body: some View {
        TabView {
            // MARK: - Tab 1: Cat List
            NavigationStack {
                CatListView()
            }
            .tabItem {
                Label("Cats", systemImage: "cat")
            }

            // MARK: - Tab 2: My Collection
            NavigationStack {
                MyCatsTabView()
            }
            .tabItem {
                Label("My Cats", systemImage: "heart")
            }
        }
        .tint(AppTheme.Colors.primary)
    }
}

#Preview {
    ContentView()
}

