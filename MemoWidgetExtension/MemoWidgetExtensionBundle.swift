//
//  MemoWidgetExtensionBundle.swift
//  MemoWidgetExtension
//
//  Created by 山下秀平 on R 7/04/12.
//

import WidgetKit
import SwiftUI

@main
struct MemoWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        MemoWidgetExtension()
        MemoWidgetExtensionLiveActivity()
    }
}
