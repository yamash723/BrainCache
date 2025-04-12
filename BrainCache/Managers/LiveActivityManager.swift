import Foundation
import ActivityKit

class LiveActivityManager: ObservableObject {
    @Published var isLiveActivityRunning = false
    private var activity: Activity<MemoAttributes>?

    // アプリ起動時に既存のLiveActivityを確認
    init() {
        if #available(iOS 16.1, *) {
            checkForRunningActivities()
        }
    }
    
    @available(iOS 16.1, *)
    private func checkForRunningActivities() {
        // 既存のLiveActivityを確認
        for activity in Activity<MemoAttributes>.activities {
            self.activity = activity
            isLiveActivityRunning = true
            break
        }
    }

    // 自動管理のための新しいメソッド
    @MainActor
    @available(iOS 16.1, *)
    func autoManageLiveActivity(for content: String, title: String = "クイックメモ") {
        if content.isEmpty {
            // 内容が空の場合はLiveActivityを終了
            if isLiveActivityRunning {
                endLiveActivity()
            }
        } else {
            // 内容がある場合は開始または更新
            if isLiveActivityRunning {
                updateLiveActivity(content: content)
            } else {
                startLiveActivity(title: title, content: content)
            }
        }
    }
    
    @MainActor
    func startLiveActivity(title: String, content: String) {
        // iOS 16.1以降でのみ利用可能
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }
        
        let attributes = MemoAttributes(title: title)
        let contentState = MemoAttributes.ContentState(memoContent: content)
        
        do {
            // iOS 16.2以降の新しい構文を使用
            if #available(iOS 16.2, *) {
                activity = try Activity.request(
                    attributes: attributes,
                    content: .init(state: contentState, staleDate: nil),
                    pushType: nil
                )
            } else {
                // iOS 16.1用の古い構文
                activity = try Activity.request(
                    attributes: attributes,
                    contentState: contentState,
                    pushType: nil
                )
            }
            
            isLiveActivityRunning = true
            print("Live Activity started with ID: \(activity?.id ?? "unknown")")
        } catch {
            print("Error starting Live Activity: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func updateLiveActivity(content: String) {
        guard let activity = activity else { return }
        
        Task {
            let updatedContentState = MemoAttributes.ContentState(memoContent: content)
            
            // iOS 16.2以降の新しい構文を使用
            if #available(iOS 16.2, *) {
                await activity.update(
                    ActivityContent(state: updatedContentState, staleDate: nil)
                )
            } else {
                // iOS 16.1用の古い構文
                await activity.update(using: updatedContentState)
            }
        }
    }
    
    @MainActor
    func endLiveActivity() {
        guard let activity = activity else { return }
        
        Task {
            // iOS 16.2以降の新しい構文を使用
            if #available(iOS 16.2, *) {
                await activity.end(
                    ActivityContent(state: activity.content.state, staleDate: nil),
                    dismissalPolicy: .immediate
                )
            } else {
                // iOS 16.1用の古い構文
                await activity.end(dismissalPolicy: .immediate)
            }
            
            self.activity = nil
            self.isLiveActivityRunning = false
        }
    }
}
