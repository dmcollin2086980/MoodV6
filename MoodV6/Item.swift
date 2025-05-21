//
//  Item.swift
//  MoodV6
//
//  Created by Daniel Collinsworth on 5/21/25.
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
