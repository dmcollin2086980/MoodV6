import Foundation
import RealmSwift

enum ExportFormat {
    case json
    case csv
    
    var fileExtension: String {
        switch self {
        case .json: return "json"
        case .csv: return "csv"
        }
    }
    
    var mimeType: String {
        switch self {
        case .json: return "application/json"
        case .csv: return "text/csv"
        }
    }
}

struct ExportData: Codable {
    let version: String
    let exportDate: Date
    let moodEntries: [MoodEntryExport]
    let goals: [GoalExport]
    let settings: UserSettingsExport
    
    struct MoodEntryExport: Codable {
        let id: String
        let date: Date
        let moodType: String
        let note: String?
        
        init(from entry: MoodEntry) {
            self.id = entry.id.stringValue
            self.date = entry.date
            self.moodType = entry.moodType
            self.note = entry.note
        }
        
        init(id: String, date: Date, moodType: String, note: String?) {
            self.id = id
            self.date = date
            self.moodType = moodType
            self.note = note
        }
    }
    
    struct GoalExport: Codable {
        let id: String
        let title: String
        let goalDescription: String
        let frequency: String
        let targetCount: Int
        let currentCount: Int
        let startDate: Date
        let lastCompletedDate: Date?
        let isCompleted: Bool
        
        init(from goal: Goal) {
            self.id = goal.id.stringValue
            self.title = goal.title
            self.goalDescription = goal.goalDescription
            self.frequency = goal.frequency
            self.targetCount = goal.targetCount
            self.currentCount = goal.currentCount
            self.startDate = goal.startDate
            self.lastCompletedDate = goal.lastCompletedDate
            self.isCompleted = goal.isCompleted
        }
        
        init(id: String, title: String, goalDescription: String, frequency: String, targetCount: Int, currentCount: Int, startDate: Date, lastCompletedDate: Date?, isCompleted: Bool) {
            self.id = id
            self.title = title
            self.goalDescription = goalDescription
            self.frequency = frequency
            self.targetCount = targetCount
            self.currentCount = currentCount
            self.startDate = startDate
            self.lastCompletedDate = lastCompletedDate
            self.isCompleted = isCompleted
        }
    }
    
    struct UserSettingsExport: Codable {
        let reminderEnabled: Bool
        let reminderTime: Date?
        let darkModeEnabled: Bool
        let notificationsEnabled: Bool
        let weeklyReportEnabled: Bool
        let defaultMoodNote: String
        let lastBackupDate: Date?
        let autoBackupEnabled: Bool
        
        init(from settings: UserSettings) {
            self.reminderEnabled = settings.reminderEnabled
            self.reminderTime = settings.reminderTime
            self.darkModeEnabled = settings.darkModeEnabled
            self.notificationsEnabled = settings.notificationsEnabled
            self.weeklyReportEnabled = settings.weeklyReportEnabled
            self.defaultMoodNote = settings.defaultMoodNote
            self.lastBackupDate = settings.lastBackupDate
            self.autoBackupEnabled = settings.autoBackupEnabled
        }
        
        init(reminderEnabled: Bool, reminderTime: Date?, darkModeEnabled: Bool, notificationsEnabled: Bool, weeklyReportEnabled: Bool, defaultMoodNote: String, lastBackupDate: Date?, autoBackupEnabled: Bool) {
            self.reminderEnabled = reminderEnabled
            self.reminderTime = reminderTime
            self.darkModeEnabled = darkModeEnabled
            self.notificationsEnabled = notificationsEnabled
            self.weeklyReportEnabled = weeklyReportEnabled
            self.defaultMoodNote = defaultMoodNote
            self.lastBackupDate = lastBackupDate
            self.autoBackupEnabled = autoBackupEnabled
        }
    }
}

class DataExportService {
    private let moodStore: MoodStoreProtocol
    private let goalStore: GoalStore
    private let settingsStore: SettingsStore
    
    init(moodStore: MoodStoreProtocol, goalStore: GoalStore, settingsStore: SettingsStore) {
        self.moodStore = moodStore
        self.goalStore = goalStore
        self.settingsStore = settingsStore
    }
    
    func exportData(format: ExportFormat) async throws -> URL {
        let entries = await moodStore.fetchAllEntries()
        let goals = await goalStore.fetchAllGoals()
        let settings = await settingsStore.fetchSettings()
        
        let exportData = ExportData(
            version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
            exportDate: Date(),
            moodEntries: entries.map { ExportData.MoodEntryExport(from: $0) },
            goals: goals.map { ExportData.GoalExport(from: $0) },
            settings: ExportData.UserSettingsExport(from: settings)
        )
        
        switch format {
        case .json:
            let data = try JSONEncoder().encode(exportData)
            return try saveJSONToFile(data)
        case .csv:
            let csvString = generateCSV(from: exportData)
            return try saveCSVToFile(csvString)
        }
    }
    
    func importData(_ data: Data, format: ExportFormat) async throws {
        let exportData: ExportData
        
        switch format {
        case .json:
            exportData = try JSONDecoder().decode(ExportData.self, from: data)
        case .csv:
            exportData = try parseCSV(data)
        }
        
        // Validate data
        try validateImportData(exportData)
        
        // Import data
        try await importMoodEntries(exportData.moodEntries)
        try await importGoals(exportData.goals)
        try await importSettings(exportData.settings)
    }
    
    private func generateCSV(from data: ExportData) -> String {
        var csvString = "version,exportDate\n"
        csvString += "\(data.version),\(data.exportDate.formatted())\n\n"
        
        // Mood entries
        csvString += "moodEntries\n"
        csvString += "id,date,moodType,note\n"
        for entry in data.moodEntries {
            let noteStr = entry.note ?? ""
            csvString += "\(entry.id),\(entry.date.formatted()),\(entry.moodType),\(noteStr)\n"
        }
        
        // Goals
        csvString += "\ngoals\n"
        csvString += "id,title,goalDescription,frequency,targetCount,currentCount,startDate,lastCompletedDate,isCompleted\n"
        for goal in data.goals {
            let lastCompletedStr = goal.lastCompletedDate?.formatted() ?? ""
            csvString += "\(goal.id),\(goal.title),\(goal.goalDescription),\(goal.frequency),\(goal.targetCount),\(goal.currentCount),\(goal.startDate.formatted()),\(lastCompletedStr),\(goal.isCompleted)\n"
        }
        
        // Settings
        csvString += "\nsettings\n"
        csvString += "reminderEnabled,reminderTime,darkModeEnabled,notificationsEnabled,weeklyReportEnabled,defaultMoodNote,lastBackupDate,autoBackupEnabled\n"
        let settings = data.settings
        let reminderTimeStr = settings.reminderTime?.formatted() ?? ""
        let lastBackupStr = settings.lastBackupDate?.formatted() ?? ""
        csvString += "\(settings.reminderEnabled),\(reminderTimeStr),\(settings.darkModeEnabled),\(settings.notificationsEnabled),\(settings.weeklyReportEnabled),\(settings.defaultMoodNote),\(lastBackupStr),\(settings.autoBackupEnabled)\n"
        
        return csvString
    }
    
    private func parseCSV(_ data: Data) throws -> ExportData {
        guard let csvString = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "DataExportService", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Invalid CSV data",
                NSLocalizedFailureReasonErrorKey: "Failed to convert data to string"
            ])
        }
        
        // Split the CSV into sections
        let sections = csvString.components(separatedBy: "\n\n")
        guard sections.count >= 4 else {
            throw NSError(domain: "DataExportService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid CSV format"])
        }
        
        // Parse version and export date
        let headerLines = sections[0].components(separatedBy: "\n")
        guard headerLines.count >= 2 else {
            throw NSError(domain: "DataExportService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid header format"])
        }
        
        let version = headerLines[1].components(separatedBy: ",")[0]
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        
        guard let exportDate = dateFormatter.date(from: headerLines[1].components(separatedBy: ",")[1]) else {
            throw NSError(domain: "DataExportService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid export date"])
        }
        
        // Parse mood entries
        let moodEntryLines = sections[1].components(separatedBy: "\n")
        var moodEntries: [ExportData.MoodEntryExport] = []
        
        for line in moodEntryLines.dropFirst() { // Skip header
            let components = line.components(separatedBy: ",")
            guard components.count >= 4,
                  let date = dateFormatter.date(from: components[1]) else { continue }
            
            let entry = ExportData.MoodEntryExport(
                id: components[0],
                date: date,
                moodType: components[2],
                note: components[3].isEmpty ? nil : components[3]
            )
            moodEntries.append(entry)
        }
        
        // Parse goals
        let goalLines = sections[2].components(separatedBy: "\n")
        var goals: [ExportData.GoalExport] = []
        
        for line in goalLines.dropFirst() { // Skip header
            let components = line.components(separatedBy: ",")
            guard components.count >= 9,
                  let targetCount = Int(components[4]),
                  let currentCount = Int(components[5]),
                  let startDate = dateFormatter.date(from: components[6]),
                  let isCompleted = Bool(components[8]) else { continue }
            
            let lastCompletedDate = components[7].isEmpty ? nil : dateFormatter.date(from: components[7])
            
            let goal = ExportData.GoalExport(
                id: components[0],
                title: components[1],
                goalDescription: components[2],
                frequency: components[3],
                targetCount: targetCount,
                currentCount: currentCount,
                startDate: startDate,
                lastCompletedDate: lastCompletedDate,
                isCompleted: isCompleted
            )
            goals.append(goal)
        }
        
        // Parse settings
        let settingsLines = sections[3].components(separatedBy: "\n")
        guard settingsLines.count >= 2 else {
            throw NSError(domain: "DataExportService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Invalid settings format"])
        }
        
        let settingsComponents = settingsLines[1].components(separatedBy: ",")
        guard settingsComponents.count >= 8,
              let reminderEnabled = Bool(settingsComponents[0]),
              let darkModeEnabled = Bool(settingsComponents[2]),
              let notificationsEnabled = Bool(settingsComponents[3]),
              let weeklyReportEnabled = Bool(settingsComponents[4]),
              let autoBackupEnabled = Bool(settingsComponents[7]) else {
            throw NSError(domain: "DataExportService", code: 6, userInfo: [
                NSLocalizedDescriptionKey: "Invalid settings data",
                NSLocalizedFailureReasonErrorKey: "Failed to parse settings components"
            ])
        }
        
        let reminderTime = settingsComponents[1].isEmpty ? nil : dateFormatter.date(from: settingsComponents[1])
        let lastBackupDate = settingsComponents[6].isEmpty ? nil : dateFormatter.date(from: settingsComponents[6])
        
        let settings = ExportData.UserSettingsExport(
            reminderEnabled: reminderEnabled,
            reminderTime: reminderTime,
            darkModeEnabled: darkModeEnabled,
            notificationsEnabled: notificationsEnabled,
            weeklyReportEnabled: weeklyReportEnabled,
            defaultMoodNote: settingsComponents[5],
            lastBackupDate: lastBackupDate,
            autoBackupEnabled: autoBackupEnabled
        )
        
        return ExportData(
            version: version,
            exportDate: exportDate,
            moodEntries: moodEntries,
            goals: goals,
            settings: settings
        )
    }
    
    private func validateImportData(_ data: ExportData) throws {
        // Validate version compatibility
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        if data.version != currentVersion {
            throw NSError(domain: "DataExportService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Incompatible data version"])
        }
        
        // Validate data integrity
        for entry in data.moodEntries {
            guard MoodType(rawValue: entry.moodType) != nil else {
                throw NSError(domain: "DataExportService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid mood type in import data"])
            }
        }
        
        for goal in data.goals {
            guard GoalFrequency(rawValue: goal.frequency) != nil else {
                throw NSError(domain: "DataExportService", code: 5, userInfo: [NSLocalizedDescriptionKey: "Invalid goal frequency in import data"])
            }
            if goal.goalDescription.isEmpty {
                throw NSError(domain: "DataExportService", code: 7, userInfo: [NSLocalizedDescriptionKey: "Goal description cannot be empty"])
            }
        }
    }
    
    private func importMoodEntries(_ entries: [ExportData.MoodEntryExport]) async throws {
        for entry in entries {
            let moodEntry = MoodEntry()
            do {
                moodEntry.id = try ObjectId(string: entry.id)
            } catch {
                moodEntry.id = ObjectId.generate()
            }
            moodEntry.date = entry.date
            moodEntry.moodType = entry.moodType
            moodEntry.note = entry.note
            try await moodStore.save(entry: moodEntry)
        }
    }
    
    private func importGoals(_ goals: [ExportData.GoalExport]) async throws {
        for goal in goals {
            let newGoal = Goal()
            do {
                newGoal.id = try ObjectId(string: goal.id)
            } catch {
                newGoal.id = ObjectId.generate()
            }
            newGoal.title = goal.title
            newGoal.goalDescription = goal.goalDescription
            newGoal.frequency = goal.frequency
            newGoal.targetCount = goal.targetCount
            newGoal.currentCount = goal.currentCount
            newGoal.startDate = goal.startDate
            newGoal.lastCompletedDate = goal.lastCompletedDate
            newGoal.isCompleted = goal.isCompleted
            try await goalStore.save(newGoal)
        }
    }
    
    private func importSettings(_ settings: ExportData.UserSettingsExport) async throws {
        let newSettings = UserSettings()
        newSettings.reminderEnabled = settings.reminderEnabled
        newSettings.reminderTime = settings.reminderTime
        newSettings.darkModeEnabled = settings.darkModeEnabled
        newSettings.notificationsEnabled = settings.notificationsEnabled
        newSettings.weeklyReportEnabled = settings.weeklyReportEnabled
        newSettings.defaultMoodNote = settings.defaultMoodNote
        newSettings.lastBackupDate = settings.lastBackupDate
        newSettings.autoBackupEnabled = settings.autoBackupEnabled
        try await settingsStore.save(newSettings)
    }
    
    private func saveCSVToFile(_ csvString: String) throws -> URL {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "mood_export_\(Date().timeIntervalSince1970).csv"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }
    
    private func saveJSONToFile(_ data: Data) throws -> URL {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "mood_export_\(Date().timeIntervalSince1970).json"
        let fileURL = documentsPath.appendingPathComponent(fileName)
        
        try data.write(to: fileURL)
        return fileURL
    }
} 
