import SwiftUI
import UniformTypeIdentifiers

struct DataExportView: View {
    @StateObject private var viewModel: DataExportViewModel
    @Environment(\.dismiss) private var dismiss
    
    init() {
        let store = try! MoodStore()
        let exportService = DataExportService(moodStore: store)
        _viewModel = StateObject(wrappedValue: DataExportViewModel(exportService: exportService))
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
                }
                
                if let exportURL = viewModel.exportURL {
                    Section {
                        ShareLink(item: exportURL) {
                            Label("Share Export", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
            .navigationTitle("Export Data")
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

@MainActor
class DataExportViewModel: ObservableObject {
    @Published var exportURL: URL?
    @Published var showingError = false
    @Published var error: Error?
    
    private let exportService: DataExportService
    
    init(exportService: DataExportService) {
        self.exportService = exportService
    }
    
    func exportData() async {
        do {
            exportURL = try await exportService.exportData()
        } catch {
            self.error = error
            showingError = true
        }
    }
}

#Preview {
    DataExportView()
} 