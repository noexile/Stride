//
//  StrideTests.swift
//  StrideTests
//
//  Created by Alexander Zorov on 6.05.26.
//

import Testing
import Foundation
@testable import Stride

@Suite("Shoe model")
struct ShoeTests {

    @Test("Default mileage threshold is 400 miles")
    func defaultThreshold() {
        let shoe = Shoe(name: "Test Shoe", purchaseDate: .now)
        #expect(shoe.mileageThreshold == 400.0)
    }

    @Test("totalMileage sums distanceMiles across all assigned runs")
    func totalMileage() throws {
        let shoe = Shoe(name: "Pegasus 41", purchaseDate: .now)

        let run1 = makeRun(miles: 5.0)
        let run2 = makeRun(miles: 8.3)
        let assignment1 = ShoeRunAssignment(shoe: shoe, run: run1)
        let assignment2 = ShoeRunAssignment(shoe: shoe, run: run2)
        shoe.assignments = [assignment1, assignment2]

        #expect(shoe.totalMileage == 13.3)
    }

    @Test("warningState is .ok when mileage is below 90% of threshold")
    func warningStateOk() {
        let shoe = Shoe(name: "Fresh Shoe", purchaseDate: .now, mileageThreshold: 400.0)
        shoe.assignments = [ShoeRunAssignment(shoe: shoe, run: makeRun(miles: 300.0))]

        #expect(shoe.warningState == .ok)
    }

    @Test("warningState is .approaching when mileage is between 90% and 99% of threshold")
    func warningStateApproaching() {
        let shoe = Shoe(name: "Tired Shoe", purchaseDate: .now, mileageThreshold: 400.0)
        shoe.assignments = [ShoeRunAssignment(shoe: shoe, run: makeRun(miles: 360.0))]

        #expect(shoe.warningState == .approaching)
    }

    @Test("warningState is .exceeded when mileage meets or exceeds threshold")
    func warningStateExceeded() {
        let shoe = Shoe(name: "Dead Shoe", purchaseDate: .now, mileageThreshold: 400.0)
        shoe.assignments = [ShoeRunAssignment(shoe: shoe, run: makeRun(miles: 400.0))]

        #expect(shoe.warningState == .exceeded)
    }

    @Test("warningState is .exceeded when mileage is over threshold")
    func warningStateExceededOver() {
        let shoe = Shoe(name: "Way Over", purchaseDate: .now, mileageThreshold: 400.0)
        shoe.assignments = [ShoeRunAssignment(shoe: shoe, run: makeRun(miles: 450.0))]

        #expect(shoe.warningState == .exceeded)
    }
}

// MARK: - Helpers

private func makeRun(miles: Double) -> Run {
    Run(
        healthKitWorkoutId: UUID(),
        startDate: .now,
        endDate: .now,
        distanceMiles: miles
    )
}
