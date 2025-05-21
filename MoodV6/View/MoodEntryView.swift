import SwiftUI


struct MoodEntryView: View {
    @StateObject private var viewModel: MoodEntryViewModel
    @Environment(\.dismiss) private var dismiss
    
    init() {
        let store = try! MoodStore()
        _viewModel = StateObject(wrappedValue: MoodEntryViewModel(moodStore: store))
    }
    
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Mood", selection: $viewModel.selectedMood) {
                        ForEach(MoodType.allCases, id: \.self) { mood in
                            Text(mood.rawValue).tag(mood)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    TextEditor(text: $viewModel.note)
                        .frame(minHeight: 100)
                } header: {
                    Text("Note")
                }
            }
            .navigationTitle("New Entry")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await viewModel.saveEntry()
                            dismiss()
                        }
                    }
                    .disabled(viewModel.selectedMood == nil)
                }
            }
        }
    }
}

#Preview {
    MoodEntryView()
} 
