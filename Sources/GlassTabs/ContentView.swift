import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TimerView()
                .tabItem { Label("Timer", systemImage: "timer") }
            StopwatchView()
                .tabItem { Label("Stopwatch", systemImage: "stopwatch") }
            NotesView()
                .tabItem { Label("Notes", systemImage: "note.text") }
        }
        .tint(.white)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}
