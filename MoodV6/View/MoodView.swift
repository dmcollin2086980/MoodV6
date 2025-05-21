import SwiftUI

struct MoodView: View {
    @ObservedObject var viewModel: MoodViewModel
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.entries) { entry in
                    MoodEntryRow(entry: entry)
                }
            }
            .navigationTitle("Mood")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showingEntrySheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.showingHistorySheet = true
                    } label: {
                        Image(systemName: "clock")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingEntrySheet) {
                MoodEntryView()
            }
            .sheet(isPresented: $viewModel.showingHistorySheet) {
                HistoryView()
            }
            .task {
                await viewModel.fetchEntries()
            }
        }
    }
}

#Preview {
    MoodView(viewModel: MoodViewModel(moodStore: try! MoodStore()))
} 