import Foundation

@MainActor
class MoodViewModel: ObservableObject {
    @Published var entries: [MoodEntry] = []
    @Published var showingEntrySheet = false
    @Published var showingHistorySheet = false
    
    private let moodStore: MoodStore
    
    init(moodStore: MoodStore) {
        self.moodStore = moodStore
    }
    
    func fetchEntries() async {
        do {
            entries = try await moodStore.fetchEntries()
        } catch {
            print("Error fetching entries: \(error)")
        }
    }
    
    func addEntry(moodType: MoodType, note: String?, tags: Set<String>) async {
        do {
            try await moodStore.addEntry(moodType: moodType, note: note, tags: tags)
            await fetchEntries()
        } catch {
            print("Error adding entry: \(error)")
        }
    }
    
    func deleteEntry(_ entry: MoodEntry) async {
        do {
            try await moodStore.deleteEntry(entry)
            await fetchEntries()
        } catch {
            print("Error deleting entry: \(error)")
        }
    }
} 