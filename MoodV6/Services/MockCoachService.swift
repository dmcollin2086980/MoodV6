import Foundation

class MockCoachService: CoachService {
    func generateDailyInsight() -> CoachingInsight {
        let insights = [
            CoachingInsight(message: "You've been consistently positive this week! Keep it up!", type: .positive),
            CoachingInsight(message: "Try to maintain a more consistent mood pattern throughout the day", type: .improvement),
            CoachingInsight(message: "Your mood has been relatively stable today", type: .neutral)
        ]
        return insights.randomElement() ?? CoachingInsight(message: "No insights available", type: .neutral)
    }
}
