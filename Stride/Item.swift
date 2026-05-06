//
//  Item.swift
//  Stride
//
//  Created by Alexander Zorov on 6.05.26.
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
