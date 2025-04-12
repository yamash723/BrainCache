//
//  Item.swift
//  quick-memo
//
//  Created by 山下秀平 on R 7/04/12.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
