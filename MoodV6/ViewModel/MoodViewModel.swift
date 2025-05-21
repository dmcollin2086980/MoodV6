import Foundation
import Combine

@MainActor
class MoodViewModel: ObservableObject {
    @Published var entries: [MoodEntry] = []
    @Published var showingEntrySheet = false
    @Published var showingHistorySheet = false
    
    private let moodStore: MoodStoreProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(moodStore: MoodStoreProtocol) {
        self.moodStore = moodStore
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        moodStore.entriesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] entries in
                self?.entries = entries
            }
            .store(in: &cancellables)
    }
    
    func fetchEntries() async {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        entries = await moodStore.fetchEntries(from: startOfDay, to: endOfDay)
    }
    
    func addEntry(moodType: MoodType, note: String?, tags: Set<String>) async {
        let entry = MoodEntry(moodType: moodType, note: note, tags: Array(tags))
        do {
            try await moodStore.save(entry: entry)
            await fetchEntries()
        } catch {
            print("Error adding entry: \(error)")
        }
    }
    
    func deleteEntry(_ entry: MoodEntry) async {
        do {
            try await moodStore.delete(entry: entry)
            await fetchEntries()
        } catch {
            print("Error deleting entry: \(error)")
        }
    }
} 
