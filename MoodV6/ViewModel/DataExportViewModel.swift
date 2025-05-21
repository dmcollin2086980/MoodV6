import Foundation
import SwiftUI
import UniformTypeIdentifiers
import RealmSwift

@MainActor
class DataExportViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showingExportSheet = false
    @Published var showingImportSheet = false
    @Published var exportURL: URL?
    @Published var exportFormat: ExportFormat = .json
    @Published var showingError = false
    
    private let dataExportService: DataExportService
    
    var alertBinding: Binding<Bool> {
        Binding(
            get: { self.showingError },
            set: { self.showingError = $0 }
        )
    }
    
    init(dataExportService: DataExportService) {
        self.dataExportService = dataExportService
    }
    
    func exportData() async {
        isLoading = true
        
        do {
            let url = try await dataExportService.exportData(format: exportFormat)
            exportURL = url
            showingExportSheet = true
        } catch {
            self.error = error
            self.showingError = true
        }
        
        isLoading = false
    }
    
    func importData(_ data: Data) {
        isLoading = true
        
        do {
            try await dataExportService.importData(data, format: exportFormat)
        } catch {
            self.error = error
            self.showingError = true
        }
        
        isLoading = false
    }
    
    var exportUTType: UTType {
        switch exportFormat {
        case .json:
            return .json
        case .csv:
            return .commaSeparatedText
        }
    }
    
    var exportFileName: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        return "moodv5-backup-\(dateString).\(exportFormat.fileExtension)"
    }
} 
