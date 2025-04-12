//
//  MemoWidgetExtensionLiveActivity.swift
//  MemoWidgetExtension
//
//  Created by 山下秀平 on R 7/04/12.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct MemoWidgetExtensionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct MemoWidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MemoWidgetExtensionAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension MemoWidgetExtensionAttributes {
    fileprivate static var preview: MemoWidgetExtensionAttributes {
        MemoWidgetExtensionAttributes(name: "World")
    }
}

extension MemoWidgetExtensionAttributes.ContentState {
    fileprivate static var smiley: MemoWidgetExtensionAttributes.ContentState {
        MemoWidgetExtensionAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: MemoWidgetExtensionAttributes.ContentState {
         MemoWidgetExtensionAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: MemoWidgetExtensionAttributes.preview) {
   MemoWidgetExtensionLiveActivity()
} contentStates: {
    MemoWidgetExtensionAttributes.ContentState.smiley
    MemoWidgetExtensionAttributes.ContentState.starEyes
}
