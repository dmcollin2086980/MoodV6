import Foundation
import RealmSwift

enum MoodType: String, CaseIterable {
    case happy = "Happy"
    case sad = "Sad"
    case angry = "Angry"
    case calm = "Calm"
}

class MoodEntry: Object, Codable {
    @Persisted(primaryKey: true) var id: ObjectId
    @Persisted var moodType: MoodType
    @Persisted var note: String?
    @Persisted var tags: List<String>
    @Persisted var timestamp: Date
    
    convenience init(moodType: MoodType, note: String?, tags: [String]) {
        self.init()
        self.moodType = moodType
        self.note = note
        self.tags.append(objectsIn: tags)
        self.timestamp = Date()
    }
    
    // Required for Codable
    required init() {
        super.init()
    }
}
