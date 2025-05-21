import Foundation

@MainActor
class GoalViewModel: ObservableObject {
    @Published var goals: [Goal] = []
    @Published var showingAddGoalSheet = false
    @Published var error: Error?
    @Published var showingCompletionAlert = false
    @Published var completedGoal: Goal?
    
    private let goalStore: GoalStore
    
    init(goalStore: GoalStore) {
        self.goalStore = goalStore
    }
    
    var overdueGoals: [Goal] {
        let now = Date()
        return goals.filter { goal in
            !goal.isCompleted && goal.targetDate < now
        }
    }
    
    var activeGoals: [Goal] {
        let now = Date()
        return goals.filter { goal in
            !goal.isCompleted && goal.targetDate >= now
        }
    }
    
    var completedGoals: [Goal] {
        goals.filter { $0.isCompleted }
    }
    
    func fetchGoals() async {
        goals = await goalStore.fetchAllGoals()
    }
    
    func addGoal(title: String, description: String, targetDate: Date) async throws {
        let goal = Goal()
        goal.id = ObjectId.generate()
        goal.title = title
        goal.goalDescription = description
        goal.startDate = Date()
        goal.targetDate = targetDate
        
        try await Task { @MainActor in
            try goalStore.save(goal)
        }.value
        
        await fetchGoals()
    }
    
    func updateGoal(_ goal: Goal) async throws {
        try await Task { @MainActor in
            try goalStore.update(goal)
        }.value
        
        await fetchGoals()
    }
    
    func deleteGoal(_ goal: Goal) async throws {
        try await Task { @MainActor in
            try goalStore.delete(goal: goal)
        }.value
        
        await fetchGoals()
    }
} 