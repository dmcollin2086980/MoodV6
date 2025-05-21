import SwiftUI

struct GoalCard: View {
    let goal: Goal
    @ObservedObject var viewModel: GoalViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(goal.title)
                    .font(.headline)
                
                Spacer()
                
                if !goal.isCompleted {
                    Button {
                        incrementGoal()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Text(goal.goalDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                ProgressView(value: Double(goal.currentCount), total: Double(goal.targetCount))
                    .progressViewStyle(LinearProgressViewStyle())
                
                Text("\(goal.currentCount)/\(goal.targetCount)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Started: \(goal.startDate, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !goal.isCompleted {
                    Text("Target: \(goal.targetDate, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(goal.targetDate < Date() ? .red : .secondary)
                } else if let completedDate = goal.completedDate {
                    Text("Completed: \(completedDate, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .contextMenu {
            if !goal.isCompleted {
                Button {
                    incrementGoal()
                } label: {
                    Label("Increment Progress", systemImage: "plus.circle")
                }
            }
            
            Button(role: .destructive) {
                deleteGoal()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    private func incrementGoal() {
        var updatedGoal = goal
        updatedGoal.currentCount += 1
        
        // Check if goal is now completed
        if updatedGoal.currentCount >= updatedGoal.targetCount {
            updatedGoal.isCompleted = true
            updatedGoal.completedDate = Date()
            viewModel.completedGoal = updatedGoal
            viewModel.showingCompletionAlert = true
        }
        
        Task {
            do {
                try await viewModel.updateGoal(updatedGoal)
            } catch {
                viewModel.error = error
            }
        }
    }
    
    private func deleteGoal() {
        Task {
            do {
                try await viewModel.deleteGoal(goal)
            } catch {
                viewModel.error = error
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}

#Preview {
    let goal = Goal()
    goal.title = "Exercise Daily"
    goal.goalDescription = "30 minutes of exercise each day"
    goal.currentCount = 3
    goal.targetCount = 7
    goal.startDate = Date().addingTimeInterval(-7 * 24 * 3600)
    goal.targetDate = Date().addingTimeInterval(7 * 24 * 3600)
    
    return GoalCard(goal: goal, viewModel: GoalViewModel(goalStore: try! RealmGoalStore()))
        .padding()
        .previewLayout(.sizeThatFits)
}
