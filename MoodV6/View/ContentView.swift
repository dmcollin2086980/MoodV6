import SwiftUI
import RealmSwift
import Combine

struct ContentView: View {
    @StateObject private var moodViewModel: MoodViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    @StateObject private var goalViewModel: GoalViewModel
    
    init() {
        do {
            let moodStore = try MoodStore()
            let settingsStore = try RealmSettingsStore()
            let goalStore = try RealmGoalStore()
            
            _moodViewModel = StateObject(wrappedValue: MoodViewModel(moodStore: moodStore))
            _settingsViewModel = StateObject(wrappedValue: SettingsViewModel(settingsStore: settingsStore))
            _goalViewModel = StateObject(wrappedValue: GoalViewModel(goalStore: goalStore))
        } catch {
            fatalError("Failed to initialize stores: \(error)")
        }
    }
    
    var body: some View {
        TabView {
            MoodView(viewModel: moodViewModel)
                .tabItem {
                    Label("Mood", systemImage: "face.smiling")
                }
            
            GoalsView(viewModel: goalViewModel)
                .tabItem {
                    Label("Goals", systemImage: "target")
                }
            
            SettingsView(viewModel: settingsViewModel)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
} 
