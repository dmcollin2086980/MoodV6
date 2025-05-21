import SwiftUI

struct DataExportView: View {
    @StateObject private var viewModel: DataExportViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(moodStore: MoodStore, goalStore: GoalStore, settingsStore: SettingsStore) {
        let exportService = DataExportService(moodStore: moodStore, goalStore: goalStore, settingsStore: settingsStore)
        _viewModel = StateObject(wrappedValue: DataExportViewModel(dataExportService: exportService))
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button {
                        Task {
                            await viewModel.exportData()
                        }
                    } label: {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                } header: {
                    Text("Export Options")
                }
                
                if let exportURL = viewModel.exportURL {
                    Section {
                        ShareLink(item: exportURL) {
                            Label("Share Export", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
            .navigationTitle("Data Export")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Export Error", isPresented: viewModel.alertBinding) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "An unknown error occurred")
            }
        }
    }
}

#Preview {
    let moodStore = try! MoodStore()
    let goalStore = try! RealmGoalStore()
    let settingsStore = try! RealmSettingsStore()
    DataExportView(moodStore: moodStore, goalStore: goalStore, settingsStore: settingsStore)
} 
