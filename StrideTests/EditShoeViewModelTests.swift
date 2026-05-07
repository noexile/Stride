import Testing
import Foundation
import SwiftData
@testable import Stride

// MARK: - EditShoeViewModel — init

@Suite("EditShoeViewModel — init from shoe")
struct EditShoeViewModelInitTests {

    @Test("Seeds name from shoe")
    func seedsName() {
        let shoe = Shoe(name: "Clifton 9", mileageThreshold: 400)
        let vm = EditShoeViewModel(shoe: shoe)
        #expect(vm.name == "Clifton 9")
    }

    @Test("Seeds purchaseDate from shoe")
    func seedsPurchaseDate() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let shoe = Shoe(name: "Shoe", purchaseDate: date, mileageThreshold: 400)
        let vm = EditShoeViewModel(shoe: shoe)
        #expect(vm.purchaseDate == date)
    }

    @Test("Seeds mileageThreshold from shoe")
    func seedsThreshold() {
        let shoe = Shoe(name: "Shoe", mileageThreshold: 650)
        let vm = EditShoeViewModel(shoe: shoe)
        #expect(vm.mileageThreshold == 650)
    }

    @Test("Seeds status from shoe")
    func seedsStatus() {
        let shoe = Shoe(name: "Shoe", mileageThreshold: 400, status: .retired)
        let vm = EditShoeViewModel(shoe: shoe)
        #expect(vm.status == .retired)
    }

    @Test("Seeds notes as empty string when shoe.notes is nil")
    func seedsNotesNilToEmpty() {
        let shoe = Shoe(name: "Shoe", mileageThreshold: 400)
        let vm = EditShoeViewModel(shoe: shoe)
        #expect(vm.notes == "")
    }

    @Test("Seeds notes from shoe when non-nil")
    func seedsNotesValue() {
        let shoe = Shoe(name: "Shoe", mileageThreshold: 400, notes: "race-day only")
        let vm = EditShoeViewModel(shoe: shoe)
        #expect(vm.notes == "race-day only")
    }
}

// MARK: - EditShoeViewModel — canSave

@Suite("EditShoeViewModel — canSave")
struct EditShoeViewModelCanSaveTests {

    @Test("canSave is true with a valid name")
    func canSaveValidName() {
        let vm = EditShoeViewModel(shoe: Shoe(name: "Pegasus 41", mileageThreshold: 400))
        #expect(vm.canSave)
    }

    @Test("canSave is false when name is cleared to empty")
    func canSaveFalseEmpty() {
        let vm = EditShoeViewModel(shoe: Shoe(name: "Pegasus 41", mileageThreshold: 400))
        vm.name = ""
        #expect(!vm.canSave)
    }

    @Test("canSave is false when name is whitespace only")
    func canSaveFalseWhitespace() {
        let vm = EditShoeViewModel(shoe: Shoe(name: "Pegasus 41", mileageThreshold: 400))
        vm.name = "   "
        #expect(!vm.canSave)
    }

    @Test("trimmedName strips leading and trailing whitespace")
    func trimmedNameValue() {
        let vm = EditShoeViewModel(shoe: Shoe(name: "Old Name", mileageThreshold: 400))
        vm.name = "  Hoka Clifton  "
        #expect(vm.trimmedName == "Hoka Clifton")
    }
}

// MARK: - EditShoeViewModel — applyChanges

@Suite("EditShoeViewModel — applyChanges")
struct EditShoeViewModelApplyChangesTests {

    @Test("applyChanges writes trimmed name to shoe")
    func writesName() {
        let shoe = Shoe(name: "Old Name", mileageThreshold: 400)
        let vm = EditShoeViewModel(shoe: shoe)
        vm.name = "  New Name  "
        vm.applyChanges(to: shoe)
        #expect(shoe.name == "New Name")
    }

    @Test("applyChanges writes purchaseDate to shoe")
    func writesPurchaseDate() {
        let shoe = Shoe(name: "Shoe", mileageThreshold: 400)
        let vm = EditShoeViewModel(shoe: shoe)
        let newDate = Date(timeIntervalSince1970: 500_000)
        vm.purchaseDate = newDate
        vm.applyChanges(to: shoe)
        #expect(shoe.purchaseDate == newDate)
    }

    @Test("applyChanges writes mileageThreshold to shoe")
    func writesThreshold() {
        let shoe = Shoe(name: "Shoe", mileageThreshold: 400)
        let vm = EditShoeViewModel(shoe: shoe)
        vm.mileageThreshold = 750
        vm.applyChanges(to: shoe)
        #expect(shoe.mileageThreshold == 750)
    }

    @Test("applyChanges writes status retired to shoe")
    func writesStatusRetired() {
        let shoe = Shoe(name: "Shoe", mileageThreshold: 400, status: .active)
        let vm = EditShoeViewModel(shoe: shoe)
        vm.status = .retired
        vm.applyChanges(to: shoe)
        #expect(shoe.status == .retired)
    }

    @Test("applyChanges writes status active to shoe")
    func writesStatusActive() {
        let shoe = Shoe(name: "Shoe", mileageThreshold: 400, status: .retired)
        let vm = EditShoeViewModel(shoe: shoe)
        vm.status = .active
        vm.applyChanges(to: shoe)
        #expect(shoe.status == .active)
    }

    @Test("applyChanges stores non-empty notes on shoe")
    func writesNonEmptyNotes() {
        let shoe = Shoe(name: "Shoe", mileageThreshold: 400)
        let vm = EditShoeViewModel(shoe: shoe)
        vm.notes = "race-day only"
        vm.applyChanges(to: shoe)
        #expect(shoe.notes == "race-day only")
    }

    @Test("applyChanges sets shoe.notes to nil when notes is empty")
    func writesEmptyNotesAsNil() {
        let shoe = Shoe(name: "Shoe", mileageThreshold: 400, notes: "old note")
        let vm = EditShoeViewModel(shoe: shoe)
        vm.notes = ""
        vm.applyChanges(to: shoe)
        #expect(shoe.notes == nil)
    }

    @Test("applyChanges sets shoe.notes to nil when notes is whitespace only")
    func writesWhitespaceNotesAsNil() {
        let shoe = Shoe(name: "Shoe", mileageThreshold: 400, notes: "old note")
        let vm = EditShoeViewModel(shoe: shoe)
        vm.notes = "   "
        vm.applyChanges(to: shoe)
        #expect(shoe.notes == nil)
    }

    @Test("applyChanges trims leading and trailing whitespace from notes")
    func trimsNotes() {
        let shoe = Shoe(name: "Shoe", mileageThreshold: 400)
        let vm = EditShoeViewModel(shoe: shoe)
        vm.notes = "  keep this  "
        vm.applyChanges(to: shoe)
        #expect(shoe.notes == "keep this")
    }
}

// MARK: - EditShoeViewModel — persistence

@Suite("EditShoeViewModel — persistence")
struct EditShoeViewModelPersistenceTests {

    private func makeContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Shoe.self, Run.self, ShoeRunAssignment.self, configurations: config)
    }

    @Test("Edited name is fetchable after context.save()")
    func editedNamePersists() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let shoe = Shoe(name: "Original Name", mileageThreshold: 400)
        context.insert(shoe)
        try context.save()

        let vm = EditShoeViewModel(shoe: shoe)
        vm.name = "Updated Name"
        vm.applyChanges(to: shoe)
        try context.save()

        let results = try context.fetch(FetchDescriptor<Shoe>())
        #expect(results.count == 1)
        #expect(results[0].name == "Updated Name")
    }

    @Test("Edited threshold is fetchable after context.save()")
    func editedThresholdPersists() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let shoe = Shoe(name: "Shoe", mileageThreshold: 400)
        context.insert(shoe)
        try context.save()

        let vm = EditShoeViewModel(shoe: shoe)
        vm.mileageThreshold = 600
        vm.applyChanges(to: shoe)
        try context.save()

        let results = try context.fetch(FetchDescriptor<Shoe>())
        #expect(results[0].mileageThreshold == 600)
    }

    @Test("Status change to retired persists after context.save()")
    func editedStatusPersists() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let shoe = Shoe(name: "Shoe", mileageThreshold: 400, status: .active)
        context.insert(shoe)
        try context.save()

        let vm = EditShoeViewModel(shoe: shoe)
        vm.status = .retired
        vm.applyChanges(to: shoe)
        try context.save()

        let results = try context.fetch(FetchDescriptor<Shoe>())
        #expect(results[0].status == .retired)
    }

    @Test("Notes cleared to nil persists after context.save()")
    func editedNotesNilPersists() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let shoe = Shoe(name: "Shoe", mileageThreshold: 400, notes: "some note")
        context.insert(shoe)
        try context.save()

        let vm = EditShoeViewModel(shoe: shoe)
        vm.notes = ""
        vm.applyChanges(to: shoe)
        try context.save()

        let results = try context.fetch(FetchDescriptor<Shoe>())
        #expect(results[0].notes == nil)
    }

    @Test("All fields updated simultaneously persist correctly")
    func allFieldsPersistTogether() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let shoe = Shoe(name: "Old", mileageThreshold: 400, status: .active)
        context.insert(shoe)
        try context.save()

        let newDate = Date(timeIntervalSince1970: 1_000_000)
        let vm = EditShoeViewModel(shoe: shoe)
        vm.name = "New"
        vm.purchaseDate = newDate
        vm.mileageThreshold = 500
        vm.status = .retired
        vm.notes = "updated"
        vm.applyChanges(to: shoe)
        try context.save()

        let results = try context.fetch(FetchDescriptor<Shoe>())
        let updated = results[0]
        #expect(updated.name == "New")
        #expect(updated.purchaseDate == newDate)
        #expect(updated.mileageThreshold == 500)
        #expect(updated.status == .retired)
        #expect(updated.notes == "updated")
    }
}
