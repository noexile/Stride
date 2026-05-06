// Item.swift — Stride data models (replaces Xcode placeholder)

import Foundation
import SwiftData

// MARK: - Enums

enum ShoeStatus: String, Codable {
    case active
    case retired
}

enum WearSurface: String, Codable {
    case road
    case trail
    case track
}

enum WarningState {
    case ok
    case approaching
    case exceeded
}

// MARK: - Models

@Model
final class Shoe {
    var id: UUID
    var name: String
    var purchaseDate: Date
    var mileageThreshold: Double
    var status: ShoeStatus
    var notes: String?

    @Relationship(deleteRule: .cascade, inverse: \ShoeRunAssignment.shoe)
    var assignments: [ShoeRunAssignment]

    init(
        name: String,
        purchaseDate: Date = .now,
        mileageThreshold: Double = 400.0,
        status: ShoeStatus = .active,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.purchaseDate = purchaseDate
        self.mileageThreshold = mileageThreshold
        self.status = status
        self.notes = notes
        self.assignments = []
    }

    var totalMileage: Double {
        assignments.reduce(0) { $0 + $1.run.distanceMiles }
    }

    var warningState: WarningState {
        let ratio = totalMileage / mileageThreshold
        if ratio >= 1.0 { return .exceeded }
        if ratio >= 0.9 { return .approaching }
        return .ok
    }
}

@Model
final class Run {
    var id: UUID
    var healthKitWorkoutId: UUID
    var startDate: Date
    var endDate: Date
    var distanceMiles: Double
    var sourceName: String?
    var wearSurface: WearSurface?

    @Relationship(inverse: \ShoeRunAssignment.run)
    var assignment: ShoeRunAssignment?

    init(
        healthKitWorkoutId: UUID,
        startDate: Date,
        endDate: Date,
        distanceMiles: Double,
        sourceName: String? = nil,
        wearSurface: WearSurface? = nil
    ) {
        self.id = UUID()
        self.healthKitWorkoutId = healthKitWorkoutId
        self.startDate = startDate
        self.endDate = endDate
        self.distanceMiles = distanceMiles
        self.sourceName = sourceName
        self.wearSurface = wearSurface
    }
}

@Model
final class ShoeRunAssignment {
    var id: UUID
    var shoe: Shoe
    var run: Run
    var assignedAt: Date

    init(shoe: Shoe, run: Run, assignedAt: Date = .now) {
        self.id = UUID()
        self.shoe = shoe
        self.run = run
        self.assignedAt = assignedAt
    }
}
