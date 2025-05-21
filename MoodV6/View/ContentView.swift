import SwiftUI

struct ContentView: View {
    @StateObject private var moodStore = MoodStore()
    @StateObject private var settingsStore = SettingsStore()
    
    var body: some View {
        TabView {
            MoodEntryView()
                .tabItem {
                    Label("Mood", systemImage: "face.smiling")
                }
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock")
                }
            
            GoalsView()
                .tabItem {
                    Label("Goals", systemImage: "target")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .environmentObject(moodStore)
        .environmentObject(settingsStore)
    }
}

#Preview {
    ContentView()
} 