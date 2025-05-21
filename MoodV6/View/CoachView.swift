import SwiftUI

struct CoachView: View {
    @State private var isLoading = false
    @State private var message = "Welcome to Mood Coach! Here you'll find personalized insights based on your mood patterns."
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading insight...")
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(message)
                            .font(.headline)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        
                        Button("Get New Insight") {
                            generateNewInsight()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                }
            }
            .navigationTitle("Mood Coach")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                generateNewInsight()
            }
        }
    }
    
    private func generateNewInsight() {
        isLoading = true
        
        // Simulate network delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let insights = [
                "You've been consistently positive this week! Keep it up!",
                "Try to maintain a more consistent mood pattern throughout the day.",
                "Your mood has been relatively stable today.",
                "Consider tracking your mood at different times of day to identify patterns.",
                "Great job on maintaining your mood tracking streak!"
            ]
            
            message = insights.randomElement() ?? "No insights available"
            isLoading = false
        }
    }
}

#Preview {
    CoachView()
} 