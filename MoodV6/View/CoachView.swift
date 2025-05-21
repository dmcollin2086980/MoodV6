import SwiftUI

struct CoachView: View {
    @StateObject private var viewModel: CoachViewModel
    @Environment(\.dismiss) private var dismiss
    
    init() {
        let store = try! MoodStore()
        _viewModel = StateObject(wrappedValue: CoachViewModel(moodStore: store))
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(viewModel.suggestions) { suggestion in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(suggestion.title)
                                .font(.headline)
                            Text(suggestion.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
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
            .task {
                await viewModel.loadSuggestions()
            }
        }
    }
}

#Preview {
    CoachView()
} 