import Foundation
import ActivityKit

struct MemoAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var memoContent: String
    }
    
    var title: String
}
