//
//  StrideTests.swift
//  StrideTests
//
//  Created by Alexander Zorov on 6.05.26.
//

import Testing
import Foundation
import SwiftData
@testable import Stride

// MARK: - Shoe model — init defaults

@Suite("Shoe init defaults")
struct ShoeInitTests {

    @Test("Default threshold is 400 miles")
    func defaultThreshold() {
        let shoe = Shoe(name: "Test Shoe")
        #expect(shoe.mileageThreshold == 400.0)
    }

    @Test("Default status is active")
    func defaultStatus() {
        let shoe = Shoe(name: "Test Shoe")
        #expect(shoe.status == .active)
    }

    @Test("Default notes is nil")
    func defaultNotes() {
        let shoe = Shoe(name: "Test Shoe")
        #expect(shoe.notes == nil)
    }

    @Test("Default assignments is empty")
    func defaultAssignments() {
        let shoe = Shoe(name: "Test Shoe")
        #expect(shoe.assignments.isEmpty)
    }

    @Test("id is a UUID (non-nil)")
    func idIsAssigned() {
        let shoe = Shoe(name: "Test Shoe")
        // UUID() always produces a valid value; verifying two shoes get distinct IDs
        let other = Shoe(name: "Other Shoe")
        #expect(shoe.id != other.id)
    }

    @Test("Custom values are stored correctly")
    func customValues() {
        let date = Date(timeIntervalSince1970: 0)
        let shoe = Shoe(name: "Custom", purchaseDate: date, mileageThreshold: 300.0, status: .retired, notes: "race-day only")
        #expect(shoe.name == "Custom")
        #expect(shoe.purchaseDate == date)
        #expect(shoe.mileageThreshold == 300.0)
        #expect(shoe.status == .retired)
        #expect(shoe.notes == "race-day only")
    }
}

// MARK: - Shoe model — totalMileage

@Suite("Shoe totalMileage")
struct ShoeTotalMileageTests {

    @Test("Zero assignments returns 0.0")
    func zeroAssignments() {
        let shoe = Shoe(name: "Brand New")
        #expect(shoe.totalMileage == 0.0)
    }

    @Test("Single assignment returns that run's distance")
    func singleAssignment() {
        let shoe = Shoe(name: "One Run Shoe")
        shoe.assignments = [ShoeRunAssignment(shoe: shoe, run: makeRun(miles: 6.2))]
        #expect(shoe.totalMileage == 6.2)
    }

    @Test("Two assignments sum correctly")
    func twoAssignments() {
        let shoe = Shoe(name: "Pegasus 41")
        shoe.assignments = [
            ShoeRunAssignment(shoe: shoe, run: makeRun(miles: 5.0)),
            ShoeRunAssignment(shoe: shoe, run: makeRun(miles: 8.3)),
        ]
        #expect(shoe.totalMileage == 13.3)
    }

    @Test("Many assignments accumulate correctly")
    func manyAssignments() {
        let shoe = Shoe(name: "Workhorse")
        shoe.assignments = (1...10).map { i in
            ShoeRunAssignment(shoe: shoe, run: makeRun(miles: Double(i)))
        }
        // 1+2+...+10 = 55
        #expect(shoe.totalMileage == 55.0)
    }

    @Test("Zero-mile run contributes 0 to total")
    func zeroMileRun() {
        let shoe = Shoe(name: "Shoe")
        shoe.assignments = [ShoeRunAssignment(shoe: shoe, run: makeRun(miles: 0.0))]
        #expect(shoe.totalMileage == 0.0)
    }
}

// MARK: - Shoe model — warningState boundaries

@Suite("Shoe warningState")
struct ShoeWarningStateTests {

    // Parameterized test across all meaningful boundary values
    // (ratio, expectedState)
    @Test("warningState is correct for each boundary ratio",
          arguments: [
            (miles: 0.0,    threshold: 400.0, expected: WarningState.ok),          // 0%
            (miles: 200.0,  threshold: 400.0, expected: WarningState.ok),          // 50%
            (miles: 359.9,  threshold: 400.0, expected: WarningState.ok),          // 89.975% — just below approaching
            (miles: 360.0,  threshold: 400.0, expected: WarningState.approaching), // exactly 90%
            (miles: 380.0,  threshold: 400.0, expected: WarningState.approaching), // 95%
            (miles: 399.9,  threshold: 400.0, expected: WarningState.approaching), // 99.975% — just below exceeded
            (miles: 400.0,  threshold: 400.0, expected: WarningState.exceeded),    // exactly 100%
            (miles: 450.0,  threshold: 400.0, expected: WarningState.exceeded),    // 112.5%
          ])
    func warningStateBoundaries(miles: Double, threshold: Double, expected: WarningState) {
        let shoe = Shoe(name: "Shoe", mileageThreshold: threshold)
        shoe.assignments = [ShoeRunAssignment(shoe: shoe, run: makeRun(miles: miles))]
        #expect(shoe.warningState == expected)
    }

    @Test("Zero miles on a fresh shoe is .ok")
    func zeroMilesIsOk() {
        let shoe = Shoe(name: "Untouched")
        #expect(shoe.warningState == .ok)
    }

    @Test("warningState respects minimum threshold (100 miles)")
    func minimumThreshold() {
        let shoe = Shoe(name: "Min Threshold", mileageThreshold: 100.0)
        // 89 miles = 89% → .ok
        shoe.assignments = [ShoeRunAssignment(shoe: shoe, run: makeRun(miles: 89.0))]
        #expect(shoe.warningState == .ok)
        // 90 miles = exactly 90% → .approaching
        shoe.assignments = [ShoeRunAssignment(shoe: shoe, run: makeRun(miles: 90.0))]
        #expect(shoe.warningState == .approaching)
        // 100 miles = exactly 100% → .exceeded
        shoe.assignments = [ShoeRunAssignment(shoe: shoe, run: makeRun(miles: 100.0))]
        #expect(shoe.warningState == .exceeded)
    }

    @Test("warningState respects maximum threshold (1000 miles)")
    func maximumThreshold() {
        let shoe = Shoe(name: "Max Threshold", mileageThreshold: 1000.0)
        shoe.assignments = [ShoeRunAssignment(shoe: shoe, run: makeRun(miles: 900.0))]
        #expect(shoe.warningState == .approaching) // exactly 90%
        shoe.assignments = [ShoeRunAssignment(shoe: shoe, run: makeRun(miles: 1000.0))]
        #expect(shoe.warningState == .exceeded)    // exactly 100%
    }

    @Test("warningState with multiple runs crossing threshold")
    func multipleRunsCrossThreshold() {
        let shoe = Shoe(name: "Accumulating", mileageThreshold: 400.0)
        // 3 runs of 100 mi each = 300 mi = 75% → .ok
        shoe.assignments = (0..<3).map { _ in ShoeRunAssignment(shoe: shoe, run: makeRun(miles: 100.0)) }
        #expect(shoe.warningState == .ok)
        // add a 4th → 400 mi = 100% → .exceeded
        shoe.assignments = (0..<4).map { _ in ShoeRunAssignment(shoe: shoe, run: makeRun(miles: 100.0)) }
        #expect(shoe.warningState == .exceeded)
    }
}

// MARK: - Run model — init

@Suite("Run init")
struct RunInitTests {

    @Test("All fields stored correctly")
    func allFields() {
        let workoutId = UUID()
        let start = Date(timeIntervalSince1970: 1000)
        let end   = Date(timeIntervalSince1970: 2000)
        let run = Run(
            healthKitWorkoutId: workoutId,
            startDate: start,
            endDate: end,
            distanceMiles: 5.5,
            sourceName: "Apple Watch",
            wearSurface: .road
        )
        #expect(run.healthKitWorkoutId == workoutId)
        #expect(run.startDate == start)
        #expect(run.endDate == end)
        #expect(run.distanceMiles == 5.5)
        #expect(run.sourceName == "Apple Watch")
        #expect(run.wearSurface == .road)
        #expect(run.assignment == nil)
    }

    @Test("Optional fields default to nil")
    func optionalDefaults() {
        let run = Run(healthKitWorkoutId: UUID(), startDate: .now, endDate: .now, distanceMiles: 3.0)
        #expect(run.sourceName == nil)
        #expect(run.wearSurface == nil)
        #expect(run.assignment == nil)
    }

    @Test("Each Run gets a distinct id")
    func distinctIds() {
        let run1 = makeRun(miles: 1.0)
        let run2 = makeRun(miles: 1.0)
        #expect(run1.id != run2.id)
    }
}

// MARK: - ShoeRunAssignment — init

@Suite("ShoeRunAssignment init")
struct AssignmentInitTests {

    @Test("Assignment stores shoe and run references")
    func shoeAndRunReferences() {
        let shoe = Shoe(name: "Shoe")
        let run  = makeRun(miles: 5.0)
        let assignment = ShoeRunAssignment(shoe: shoe, run: run)
        #expect(assignment.shoe === shoe)
        #expect(assignment.run === run)
    }

    @Test("Default assignedAt is approximately now")
    func assignedAtIsNow() {
        let before = Date.now
        let assignment = ShoeRunAssignment(shoe: Shoe(name: "S"), run: makeRun(miles: 1.0))
        let after = Date.now
        #expect(assignment.assignedAt >= before)
        #expect(assignment.assignedAt <= after)
    }

    @Test("Custom assignedAt is stored")
    func customAssignedAt() {
        let ts = Date(timeIntervalSince1970: 999_999)
        let assignment = ShoeRunAssignment(shoe: Shoe(name: "S"), run: makeRun(miles: 1.0), assignedAt: ts)
        #expect(assignment.assignedAt == ts)
    }

    @Test("Each assignment gets a distinct id")
    func distinctIds() {
        let shoe = Shoe(name: "S")
        let a1 = ShoeRunAssignment(shoe: shoe, run: makeRun(miles: 1.0))
        let a2 = ShoeRunAssignment(shoe: shoe, run: makeRun(miles: 2.0))
        #expect(a1.id != a2.id)
    }
}

// MARK: - AddShoeViewModel

@Suite("AddShoeViewModel — canSave logic")
struct CanSaveTests {

    @Test("Non-empty name allows save")
    func nonEmptyName() {
        let vm = AddShoeViewModel()
        vm.name = "Nike Pegasus 41"
        #expect(vm.canSave)
    }

    @Test("Empty string blocks save")
    func emptyString() {
        let vm = AddShoeViewModel()
        vm.name = ""
        #expect(!vm.canSave)
    }

    @Test("Whitespace-only string blocks save")
    func whitespaceOnly() {
        let vm = AddShoeViewModel()
        vm.name = "   "
        #expect(!vm.canSave)
    }

    @Test("Tabs-only string blocks save")
    func tabsOnly() {
        let vm = AddShoeViewModel()
        vm.name = "\t\t"
        #expect(!vm.canSave)
    }

    @Test("Mixed whitespace-only string blocks save")
    func mixedWhitespaceOnly() {
        let vm = AddShoeViewModel()
        vm.name = "  \t  "
        #expect(!vm.canSave)
    }

    @Test("Name with leading/trailing whitespace is allowed (trimmed name is non-empty)")
    func leadingTrailingWhitespace() {
        let vm = AddShoeViewModel()
        vm.name = "  Nike  "
        #expect(vm.canSave)
    }

    @Test("Single character name is allowed")
    func singleCharacter() {
        let vm = AddShoeViewModel()
        vm.name = "A"
        #expect(vm.canSave)
    }

    @Test("trimmedName strips leading/trailing whitespace")
    func trimmedNameValue() {
        let vm = AddShoeViewModel()
        vm.name = "  Nike Pegasus  "
        #expect(vm.trimmedName == "Nike Pegasus")
    }

    @Test("trimmedName preserves internal whitespace")
    func internalWhitespacePreserved() {
        let vm = AddShoeViewModel()
        vm.name = "  New Balance 1080  "
        #expect(vm.trimmedName == "New Balance 1080")
    }
}

// MARK: - SwiftData persistence (in-memory container)

@Suite("Shoe persistence")
struct ShoePersistenceTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Shoe.self, Run.self, ShoeRunAssignment.self, configurations: config)
    }

    @Test("Inserted shoe is fetchable")
    func insertAndFetch() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let shoe = Shoe(name: "Hoka Clifton 9", mileageThreshold: 500.0)
        context.insert(shoe)
        try context.save()

        let descriptor = FetchDescriptor<Shoe>()
        let results = try context.fetch(descriptor)
        #expect(results.count == 1)
        #expect(results[0].name == "Hoka Clifton 9")
        #expect(results[0].mileageThreshold == 500.0)
    }

    @Test("Inserting two shoes produces two records")
    func insertTwoShoes() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        context.insert(Shoe(name: "Shoe A"))
        context.insert(Shoe(name: "Shoe B"))
        try context.save()

        let results = try context.fetch(FetchDescriptor<Shoe>())
        #expect(results.count == 2)
    }

    @Test("Deleting a shoe with no assignments succeeds")
    func deleteShoeNoAssignments() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let shoe = Shoe(name: "Delete Me")
        context.insert(shoe)
        try context.save()

        context.delete(shoe)
        try context.save()

        let results = try context.fetch(FetchDescriptor<Shoe>())
        #expect(results.isEmpty)
    }

    @Test("Deleting a shoe with assignments cascades and removes assignments")
    func deleteShoeWithAssignmentsCascades() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let shoe = Shoe(name: "Has Runs")
        let run  = Run(healthKitWorkoutId: UUID(), startDate: .now, endDate: .now, distanceMiles: 5.0)
        context.insert(shoe)
        context.insert(run)
        let assignment = ShoeRunAssignment(shoe: shoe, run: run)
        context.insert(assignment)
        try context.save()

        context.delete(shoe)
        try context.save()

        // Shoe is gone
        let shoes = try context.fetch(FetchDescriptor<Shoe>())
        #expect(shoes.isEmpty)

        // Assignment is cascade-deleted
        let assignments = try context.fetch(FetchDescriptor<ShoeRunAssignment>())
        #expect(assignments.isEmpty)
    }

    @Test("totalMileage is correct after persisting a run and assignment")
    func totalMileagePersisted() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let shoe = Shoe(name: "Persisted Shoe", mileageThreshold: 400.0)
        let run  = Run(healthKitWorkoutId: UUID(), startDate: .now, endDate: .now, distanceMiles: 42.195)
        context.insert(shoe)
        context.insert(run)
        let assignment = ShoeRunAssignment(shoe: shoe, run: run)
        context.insert(assignment)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Shoe>())
        #expect(fetched.count == 1)
        // Floating-point: compare to 5 decimal places
        #expect(abs(fetched[0].totalMileage - 42.195) < 0.001)
    }

    @Test("Shoe status persists correctly")
    func statusPersists() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let shoe = Shoe(name: "Retired Runner", status: .retired)
        context.insert(shoe)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Shoe>())
        #expect(fetched[0].status == .retired)
    }
}

// MARK: - Enum coverage

@Suite("Enums")
struct EnumTests {

    @Test("ShoeStatus raw values")
    func shoeStatusRawValues() {
        #expect(ShoeStatus.active.rawValue == "active")
        #expect(ShoeStatus.retired.rawValue == "retired")
    }

    @Test("WearSurface raw values")
    func wearSurfaceRawValues() {
        #expect(WearSurface.road.rawValue == "road")
        #expect(WearSurface.trail.rawValue == "trail")
        #expect(WearSurface.track.rawValue == "track")
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
