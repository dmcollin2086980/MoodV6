import SwiftUI
import RealmSwift

struct HistoryView: View {
    @StateObject private var viewModel: HistoryViewModel
    @Environment(\.dismiss) private var dismiss
    
    init() {
        let store = try! MoodStore()
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
                            do {
                                try await viewModel.deleteEntry(entry)
                            } catch {
                                print("Error deleting entry: \(error)")
                            }
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
    
    private var moodType: MoodType? {
        MoodType(rawValue: entry.moodType)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let mood = moodType {
                    Text("\(mood.emoji) \(mood.rawValue)")
                        .font(.headline)
                } else {
                    Text(entry.moodType)
                        .font(.headline)
                }
                Spacer()
                Text(entry.date, style: .time)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let note = entry.note, !note.isEmpty {
                Text(note)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if !entry.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(Array(entry.tags), id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
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