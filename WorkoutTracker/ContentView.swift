import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            RoutineListView()
                .tabItem {
                    Label("Routines", systemImage: "list.bullet.clipboard.fill")
                }

            // Placeholder — replaced in Step 5
            Text("History coming in Step 5")
                .foregroundStyle(.secondary)
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
        }
        .preferredColorScheme(.dark)
    }
}
