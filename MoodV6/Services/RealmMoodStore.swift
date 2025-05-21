import Foundation
import RealmSwift
import Combine

class RealmMoodStore: MoodStoreProtocol {
    private var realm: Realm?
    private let entriesSubject = CurrentValueSubject<[MoodEntry], Never>([])
    
    var entriesPublisher: AnyPublisher<[MoodEntry], Never> {
        entriesSubject.eraseToAnyPublisher()
    }
    
    init() {
        setupRealm()
    }
    
    private func setupRealm() {
        do {
            realm = try Realm()
            observeEntries()
        } catch {
            print("Error setting up Realm: \(error)")
        }
    }
    
    private func observeEntries() {
        guard let realm = realm else { return }
        
        let entries = realm.objects(MoodEntry.self)
            .sorted(byKeyPath: "timestamp", ascending: false)
        
        let token = entries.observe { [weak self] changes in
            switch changes {
            case .initial(let entries):
                self?.entriesSubject.send(Array(entries))
            case .update(let entries, _, _, _):
                self?.entriesSubject.send(Array(entries))
            case .error(let error):
                print("Error observing entries: \(error)")
            }
        }
        
        // Store token to prevent deallocation
        objc_setAssociatedObject(self, "realmToken", token, .OBJC_ASSOCIATION_RETAIN)
    }
    
    func save(entry: MoodEntry) throws {
        guard let realm = realm else { throw NSError(domain: "RealmMoodStore", code: -1, userInfo: [NSLocalizedDescriptionKey: "Realm not initialized"]) }
        
        try realm.write {
            realm.add(entry)
        }
    }
    
    func delete(entry: MoodEntry) throws {
        guard let realm = realm else { throw NSError(domain: "RealmMoodStore", code: -1, userInfo: [NSLocalizedDescriptionKey: "Realm not initialized"]) }
        
        try realm.write {
            realm.delete(entry)
        }
    }
    
    func fetchEntries(from startDate: Date, to endDate: Date) -> [MoodEntry] {
        guard let realm = realm else { return [] }
        
        return Array(realm.objects(MoodEntry.self)
            .filter("timestamp >= %@ AND timestamp < %@", startDate, endDate)
            .sorted(byKeyPath: "timestamp", ascending: false))
    }
    
    func fetchAllEntries() -> [MoodEntry] {
        guard let realm = realm else { return [] }
        
        return Array(realm.objects(MoodEntry.self)
            .sorted(byKeyPath: "timestamp", ascending: false))
    }
} 