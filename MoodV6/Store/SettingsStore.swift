import Foundation

protocol SettingsStore {
    func getSettings() async throws -> Settings
    func updateSettings(_ settings: Settings) async throws
}

class RealmSettingsStore: SettingsStore {
    private let realm: Realm
    
    init() throws {
        realm = try Realm()
    }
    
    func getSettings() async throws -> Settings {
        if let settings = realm.objects(Settings.self).first {
            return settings
        }
        let settings = Settings()
        try realm.write {
            realm.add(settings)
        }
        return settings
    }
    
    func updateSettings(_ settings: Settings) async throws {
        try realm.write {
            realm.add(settings, update: .modified)
        }
    }
} 