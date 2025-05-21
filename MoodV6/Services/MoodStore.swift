import Foundation
import RealmSwift
import Combine

protocol MoodStoreProtocol {
    var entriesPublisher: AnyPublisher<[MoodEntry], Never> { get }
    
    func save(entry: MoodEntry) async throws
    func delete(entry: MoodEntry) async throws
    func fetchEntries(from startDate: Date, to endDate: Date) async -> [MoodEntry]
    func fetchAllEntries() async -> [MoodEntry]
}

@MainActor
class MoodStore: ObservableObject, MoodStoreProtocol {
    private let realm: Realm
    private let entriesSubject = CurrentValueSubject<[MoodEntry], Never>([])
    
    var entriesPublisher: AnyPublisher<[MoodEntry], Never> {
        entriesSubject.eraseToAnyPublisher()
    }
    
    init() throws {
        realm = try Realm()
        setupNotificationToken()
    }
    
    private func setupNotificationToken() {
        let entries = realm.objects(MoodEntry.self)
        entriesSubject.send(Array(entries))
        
        _ = entries.observe { [weak self] changes in
            switch changes {
            case .initial(let entries):
                self?.entriesSubject.send(Array(entries))
            case .update(let entries, _, _, _):
                self?.entriesSubject.send(Array(entries))
            case .error(let error):
                print("Error observing entries: \(error)")
            }
        }
    }
    
    func save(entry: MoodEntry) async throws {
        try await Task { @MainActor in
            try realm.write {
                realm.add(entry)
            }
        }.value
    }
    
    func delete(entry: MoodEntry) async throws {
        try await Task { @MainActor in
            try realm.write {
                realm.delete(entry)
            }
        }.value
    }
    
    func fetchEntries(from startDate: Date, to endDate: Date) async -> [MoodEntry] {
        await Task { @MainActor in
            Array(realm.objects(MoodEntry.self)
                .filter("date >= %@ AND date < %@", startDate, endDate)
                .sorted(byKeyPath: "date", ascending: false))
        }.value
    }
    
    func fetchAllEntries() async -> [MoodEntry] {
        await Task { @MainActor in
            Array(realm.objects(MoodEntry.self).sorted(byKeyPath: "date", ascending: false))
        }.value
    }
} 