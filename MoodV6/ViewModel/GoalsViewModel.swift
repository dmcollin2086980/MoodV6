import Foundation
import Combine

class GoalsViewModel: ObservableObject {
    @Published var goals: [Goal] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showingCompletionAlert = false
    @Published var completedGoal: Goal?
    
    private let goalStore: GoalStore
    private var cancellables = Set<AnyCancellable>()
    
    init(goalStore: GoalStore) {
        self.goalStore = goalStore
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        goalStore.goalsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] goals in
                self?.goals = goals
            }
            .store(in: &cancellables)
    }
    
    func createGoal(title: String, goalDescription: String, frequency: GoalFrequency, targetCount: Int, targetDate: Date = Date().addingTimeInterval(30 * 24 * 3600)) async throws {
        let goal = Goal(title: title, goalDescription: goalDescription, frequency: frequency, targetCount: targetCount, targetDate: targetDate)
        
        try await Task { @MainActor in
            try goalStore.save(goal)
        }.value
    }
    
    func deleteGoal(_ goal: Goal) async throws {
        try await Task { @MainActor in
            try goalStore.delete(goal: goal)
        }.value
    }
    
    func incrementProgress(for goal: Goal) async throws {
        goal.incrementProgress()
        
        try await Task { @MainActor in
            try goalStore.update(goal)
        }.value
        
        if goal.isCompleted {
            await MainActor.run {
                completedGoal = goal
                showingCompletionAlert = true
            }
        }
    }
    
    func resetProgress(for goal: Goal) async throws {
        goal.resetProgress()
        
        try await Task { @MainActor in
            try goalStore.update(goal)
        }.value
    }
    
    var activeGoals: [Goal] {
        goals.filter { !$0.isCompleted }
    }
    
    var completedGoals: [Goal] {
        goals.filter { $0.isCompleted }
    }
    
    var overdueGoals: [Goal] {
        goals.filter { $0.isOverdue && !$0.isCompleted }
    }
} 