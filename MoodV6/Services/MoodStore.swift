import Foundation
import RealmSwift
import Combine

protocol MoodStoreProtocol {
    var entriesPublisher: AnyPublisher<[MoodEntry], Never> { get }
    
    func save(entry: MoodEntry) throws
    func delete(entry: MoodEntry) throws
    func fetchEntries(from startDate: Date, to endDate: Date) -> [MoodEntry]
    func fetchAllEntries() -> [MoodEntry]
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
    
    func save(entry: MoodEntry) throws {
        try realm.write {
            realm.add(entry)
        }
    }
    
    func fetchAllEntries() -> [MoodEntry] {
        Array(realm.objects(MoodEntry.self).sorted(byKeyPath: "date", ascending: false))
    }
    
    func fetchEntries(from startDate: Date, to endDate: Date) -> [MoodEntry] {
        let predicate = NSPredicate(format: "date >= %@ AND date <= %@", startDate as NSDate, endDate as NSDate)
        return Array(realm.objects(MoodEntry.self).filter(predicate).sorted(byKeyPath: "date", ascending: false))
    }
    
    func delete(entry: MoodEntry) throws {
        try realm.write {
            realm.delete(entry)
        }
    }
} 