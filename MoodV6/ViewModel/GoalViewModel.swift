import Foundation

@MainActor
class GoalViewModel: ObservableObject {
    @Published var goals: [Goal] = []
    @Published var showingAddGoalSheet = false
    
    private let goalStore: GoalStore
    
    init(goalStore: GoalStore) {
        self.goalStore = goalStore
    }
    
    func fetchGoals() async {
        do {
            goals = try await goalStore.fetchGoals()
        } catch {
            print("Error fetching goals: \(error)")
        }
    }
    
    func addGoal(title: String, description: String, targetDate: Date) async {
        do {
            try await goalStore.addGoal(title: title, description: description, targetDate: targetDate)
            await fetchGoals()
        } catch {
            print("Error adding goal: \(error)")
        }
    }
    
    func updateGoal(_ goal: Goal) async {
        do {
            try await goalStore.updateGoal(goal)
            await fetchGoals()
        } catch {
            print("Error updating goal: \(error)")
        }
    }
    
    func deleteGoal(_ goal: Goal) async {
        do {
            try await goalStore.deleteGoal(goal)
            await fetchGoals()
        } catch {
            print("Error deleting goal: \(error)")
        }
    }
} 