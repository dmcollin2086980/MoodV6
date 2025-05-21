import Foundation

enum CoachingInsightType {
    case positive
    case improvement
    case neutral
}

class CoachingInsight: Identifiable {
    let id = UUID()
    let message: String
    let type: CoachingInsightType
    
    init(message: String, type: CoachingInsightType) {
        self.message = message
        self.type = type
    }
}

protocol CoachService {
    func generateDailyInsight() -> CoachingInsight
}
