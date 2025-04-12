import Foundation

class NoteStorage: ObservableObject {
    @Published var noteContent: String = ""
    private let fileManager = FileManager.default
    private var documentURL: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("note.md")
    }
    
    init() {
        loadNote()
    }
    
    func saveNote() {
        do {
            try noteContent.write(to: documentURL, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to save note: \(error.localizedDescription)")
        }
    }
    
    func loadNote() {
        if fileManager.fileExists(atPath: documentURL.path) {
            do {
                noteContent = try String(contentsOf: documentURL, encoding: .utf8)
            } catch {
                print("Failed to load note: \(error.localizedDescription)")
            }
        }
    }
}
