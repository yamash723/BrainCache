import WidgetKit
import SwiftUI
import ActivityKit

struct MemoWidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MemoAttributes.self) { context in
            // ロック画面表示用のビュー
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            // Dynamic Island用のビュー
            DynamicIsland {
                // 展開されていない状態
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.title)
                        .font(.headline)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Image(systemName: "note.text")
                }
                
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.memoContent)
                        .lineLimit(2)
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    Text("タップしてメモを開く")
                        .font(.caption)
                }
            } compactLeading: {
                Image(systemName: "note.text")
            } compactTrailing: {
                Text(context.attributes.title.prefix(1))
            } minimal: {
                Image(systemName: "note.text")
            }
        }
    }
}

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<MemoAttributes>
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "note.text")
                    .foregroundColor(.accentColor)
                
                Text(context.attributes.title)
                    .font(.headline)
                
                Spacer()
            }
            .padding(.bottom, 4)
            
            Text(context.state.memoContent)
                .font(.body)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            Text("タップしてメモを開く")
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .activityBackgroundTint(Color.secondarySystemBackground)
        .activitySystemActionForegroundColor(Color.black)
    }
}

// iOS 16以前との互換性のため
extension Color {
    static var secondarySystemBackground: Color {
        Color(UIColor.secondarySystemBackground)
    }
}
