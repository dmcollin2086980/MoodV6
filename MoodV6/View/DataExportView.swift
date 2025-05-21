import SwiftUI
@_exported import class MoodV6.DataExportViewModel

struct DataExportView: View {
    @StateObject private var viewModel: DataExportViewModel
    @Environment(\.dismiss) private var dismiss
    
    init() {
        do {
            let store = try MoodStore()
            let exportService = DataExportService(moodStore: store)
            _viewModel = StateObject(wrappedValue: DataExportViewModel(exportService: exportService))
        } catch {
            fatalError("Failed to initialize store: \(error)")
        }
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
            .alert("Export Error", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.error?.localizedDescription ?? "An unknown error occurred")
            }
        }
    }
}

#Preview {
    DataExportView()
} 