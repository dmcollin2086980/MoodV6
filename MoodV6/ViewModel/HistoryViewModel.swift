import Foundation
import Combine
import SwiftUI
import RealmSwift

@MainActor
class HistoryViewModel: ObservableObject {
    @Published var entries: [MoodEntry] = []
    @Published var selectedTimeFrame: TimeFrame = .week
    @Published var isLoading = false
    @Published var error: Error?
    @Published var selectedDate: Date = Date()
    @Published var showingDatePicker = false
    @Published var showingDeleteConfirmation = false
    @Published var entryToDelete: MoodEntry?
    
    private let moodStore: MoodStore
    private var cancellables = Set<AnyCancellable>()
    private var entriesPublisher: AsyncStream<[MoodEntry]>?
    private var task: Task<Void, Never>?
    
    enum TimeFrame: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case all = "All Time"
        
        var dateRange: (start: Date, end: Date)? {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .week:
                let start = calendar.date(byAdding: .day, value: -7, to: now)!
                return (start, now)
            case .month:
                let start = calendar.date(byAdding: .month, value: -1, to: now)!
                return (start, now)
            case .year:
                let start = calendar.date(byAdding: .year, value: -1, to: now)!
                return (start, now)
            case .all:
                return nil
            }
        }
    }
    
    init(moodStore: MoodStore) {
        self.moodStore = moodStore
        setupSubscriptions()
        setupEntriesPublisher()
    }
    
    deinit {
        task?.cancel()
    }
    
    private func setupSubscriptions() {
        moodStore.entriesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] entries in
                self?.updateEntries(entries)
            }
            .store(in: &cancellables)
    }
    
    private func setupEntriesPublisher() {
        let (stream, continuation) = AsyncStream<[MoodEntry]>.makeStream()
        entriesPublisher = stream
        
        task = Task {
            for await entries in stream {
                await MainActor.run {
                    self.entries = entries
                }
            }
        }
        
        // Initial fetch
        Task {
            await fetchEntries()
        }
    }
    
    private func updateEntries(_ allEntries: [MoodEntry]) {
        guard let dateRange = selectedTimeFrame.dateRange else {
            entries = allEntries
            return
        }
        
        entries = allEntries.filter { entry in
            entry.date >= dateRange.start && entry.date <= dateRange.end
        }
    }
    
    func deleteEntry(_ entry: MoodEntry) {
        do {
            try moodStore.delete(entry: entry)
        } catch {
            self.error = error
        }
    }
    
    func refreshEntries() {
        isLoading = true
        if let dateRange = selectedTimeFrame.dateRange {
            entries = moodStore.fetchEntries(from: dateRange.start, to: dateRange.end)
        } else {
            entries = moodStore.fetchAllEntries()
        }
        isLoading = false
    }
    
    func fetchEntries() async {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        do {
            let realm = try await Realm()
            let entries = realm.objects(MoodEntry.self)
                .filter("timestamp >= %@ AND timestamp < %@", startOfDay, endOfDay)
                .sorted(byKeyPath: "timestamp", ascending: false)
            
            await MainActor.run {
                self.entries = Array(entries)
            }
        } catch {
            print("Error fetching entries: \(error)")
        }
    }
    
    func deleteEntry(_ entry: MoodEntry) async {
        do {
            let realm = try await Realm()
            try await realm.write {
                realm.delete(entry)
            }
            await fetchEntries()
        } catch {
            print("Error deleting entry: \(error)")
        }
    }
    
    func fetchEntries(from startDate: Date, to endDate: Date) async {
        do {
            let realm = try await Realm()
            let entries = realm.objects(MoodEntry.self)
                .filter("timestamp >= %@ AND timestamp < %@", startDate, endDate)
                .sorted(byKeyPath: "timestamp", ascending: false)
            
            await MainActor.run {
                self.entries = Array(entries)
            }
        } catch {
            print("Error fetching entries: \(error)")
        }
    }
    
    func fetchAllEntries() async {
        do {
            let realm = try await Realm()
            let entries = realm.objects(MoodEntry.self)
                .sorted(byKeyPath: "timestamp", ascending: false)
            
            await MainActor.run {
                self.entries = Array(entries)
            }
        } catch {
            print("Error fetching entries: \(error)")
        }
    }
} 