import Foundation
import Combine
import SwiftUI
import RealmSwift

class MoodEntryViewModel: ObservableObject {
    @Published var selectedMood: MoodType?
    @Published var note: String = ""
    @Published var selectedTags: Set<String> = []
    @Published var isSaving = false
    @Published var error: Error?
    
    private let moodStore: MoodStoreProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(moodStore: MoodStoreProtocol) {
        self.moodStore = moodStore
    }
    
    var isSaveEnabled: Bool {
        selectedMood != nil
    }
    
    @MainActor func saveMood() async {
        guard let mood = selectedMood else { return }
        
        isSaving = true
        let entry = MoodEntry(
            moodType: mood,
            note: note.isEmpty ? nil : note,
            tags: Array(selectedTags)
        )
        
        do {
            try await moodStore.save(entry: entry)
            resetForm()
        } catch {
            self.error = error
        }
        
        isSaving = false
    }
    
    private func resetForm() {
        selectedMood = nil
        note = ""
        selectedTags.removeAll()
    }
} 
