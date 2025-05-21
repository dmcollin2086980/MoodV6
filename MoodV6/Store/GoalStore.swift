import Foundation
import RealmSwift

protocol GoalStore {
    func fetchGoals() async throws -> [Goal]
    func addGoal(title: String, description: String, targetDate: Date) async throws
    func updateGoal(_ goal: Goal) async throws
    func deleteGoal(_ goal: Goal) async throws
}

class RealmGoalStore: GoalStore {
    private let realm: Realm
    
    init() throws {
        realm = try Realm()
    }
    
    func fetchGoals() async throws -> [Goal] {
        Array(realm.objects(Goal.self))
    }
    
    func addGoal(title: String, description: String, targetDate: Date) async throws {
        let goal = Goal()
        goal.title = title
        goal.goalDescription = description
        goal.targetDate = targetDate
        
        try realm.write {
            realm.add(goal)
        }
    }
    
    func updateGoal(_ goal: Goal) async throws {
        try realm.write {
            realm.add(goal, update: .modified)
        }
    }
    
    func deleteGoal(_ goal: Goal) async throws {
        try realm.write {
            realm.delete(goal)
        }
    }
} 