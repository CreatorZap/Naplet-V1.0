//
//  NapletWidgetBundle.swift
//  NapletWidget
//
//  Created by Edy Souza Fotografia on 23/01/26.
//

import WidgetKit
import SwiftUI

@main
struct NapletWidgetBundle: WidgetBundle {
    var body: some Widget {
        NapletSleepWidget()
        NapletQuickActionWidget()
    }
}
