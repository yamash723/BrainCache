import SwiftUI
import ActivityKit

struct ContentView: View {
    @StateObject private var noteStorage = NoteStorage()
    @StateObject private var liveActivityManager = LiveActivityManager()
    
    @State private var memoTitle = "QuickMemo"
    @State private var showingShareSheet = false

    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        NavigationStack {
            VStack {
                MarkdownEditorView(text: $noteStorage.noteContent)
            }
            .navigationTitle("BrainCache")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        shareContent()
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .onChange(of: noteStorage.noteContent) { oldValue, newValue in
                // 内容が変更されたら保存
                noteStorage.saveNote()
                
                // LiveActivityを自動管理
                if #available(iOS 16.1, *) {
                    liveActivityManager.autoManageLiveActivity(for: newValue)
                }
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if #available(iOS 16.1, *) {
                    if newPhase == .background && !noteStorage.noteContent.isEmpty {
                        // バックグラウンドに移行したときにLiveActivityを開始
                        liveActivityManager.autoManageLiveActivity(for: noteStorage.noteContent)
                    }
                }
            }
        }
    }
    
    private func shareContent() {
        guard !noteStorage.noteContent.isEmpty else { return }
        
        let activityVC = UIActivityViewController(
            activityItems: [noteStorage.noteContent],
            applicationActivities: nil
        )
        
        // 現在のウィンドウシーンを取得して表示
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            // iPadの場合はポップオーバーを設定
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootViewController.view
                popover.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootViewController.present(activityVC, animated: true)
        }
    }
}
