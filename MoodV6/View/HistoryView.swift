import SwiftUI
import RealmSwift

struct HistoryView: View {
    @StateObject private var viewModel: HistoryViewModel
    @Environment(\.dismiss) private var dismiss
    
    init() {
        let store = RealmMoodStore()
        _viewModel = StateObject(wrappedValue: HistoryViewModel(moodStore: store))
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.entries) { entry in
                    MoodEntryRow(entry: entry)
                        .swipeActions {
                            Button(role: .destructive) {
                                viewModel.entryToDelete = entry
                                viewModel.showingDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showingDatePicker = true
                    } label: {
                        Image(systemName: "calendar")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingDatePicker) {
                DatePickerView(selectedDate: $viewModel.selectedDate)
            }
            .alert("Delete Entry", isPresented: $viewModel.showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let entry = viewModel.entryToDelete {
                        Task {
                            await viewModel.deleteEntry(entry)
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to delete this entry?")
            }
            .task {
                await viewModel.fetchEntries()
            }
        }
    }
}

struct MoodEntryRow: View {
    let entry: MoodEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.mood.rawValue)
                    .font(.headline)
                Spacer()
                Text(entry.timestamp, style: .time)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if !entry.note.isEmpty {
                Text(entry.note)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct DatePickerView: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    HistoryView()
} 