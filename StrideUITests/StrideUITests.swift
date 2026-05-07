//
//  StrideUITests.swift
//  StrideUITests
//
//  Created by Alexander Zorov on 6.05.26.
//

import XCTest

final class StrideUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Helpers

    /// Launch a clean instance of the app.
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        return app
    }

    /// Navigate to the Shoes tab (it is the first tab and selected by default, but
    /// calling this makes intent explicit and guards against future tab-order changes).
    private func selectShoesTab(in app: XCUIApplication) {
        app.tabBars.buttons["Shoes"].tap()
    }

    /// Add a shoe through the full UI flow and return once the sheet is dismissed.
    /// Precondition: the Shoes tab must already be visible.
    @discardableResult
    private func addShoe(named name: String, in app: XCUIApplication) -> Bool {
        // Tap the "Add Shoe" toolbar button (Label("Add Shoe", systemImage: "plus"))
        let addButton = app.navigationBars["My Shoes"].buttons["Add Shoe"]
        guard addButton.waitForExistence(timeout: 5) else { return false }
        addButton.tap()

        // The AddShoeView sheet has its own NavigationStack with title "Add Shoe"
        let sheet = app.navigationBars["Add Shoe"]
        guard sheet.waitForExistence(timeout: 5) else { return false }

        // Type in the shoe name text field (placeholder: "Name (e.g. Nike Pegasus 41)")
        let nameField = app.textFields["Name (e.g. Nike Pegasus 41)"]
        guard nameField.waitForExistence(timeout: 5) else { return false }
        nameField.tap()
        nameField.typeText(name)

        // Tap Save
        let saveButton = sheet.buttons["Save"]
        guard saveButton.waitForExistence(timeout: 5) else { return false }
        saveButton.tap()

        return true
    }

    // MARK: - Flow 1: Add a shoe and see it in the list

    @MainActor
    func testAddShoeAppearsInList() throws {
        let app = launchApp()
        selectShoesTab(in: app)

        let shoeName = "Test Shoe XCUITest"
        let added = addShoe(named: shoeName, in: app)
        XCTAssertTrue(added, "Failed during the add-shoe UI flow")

        // The sheet dismisses and we are back on the list.
        // Assert the new shoe name appears in the list.
        let shoeCell = app.staticTexts[shoeName]
        XCTAssertTrue(
            shoeCell.waitForExistence(timeout: 5),
            "Expected '\(shoeName)' to appear in the Shoes list after saving"
        )
    }

    // MARK: - Flow 2: Tap a shoe and reach the detail view

    @MainActor
    func testTapShoeOpensDetailView() throws {
        let app = launchApp()
        selectShoesTab(in: app)

        let shoeName = "Test Shoe XCUITest"

        // Add the shoe first (app starts fresh with an empty SwiftData store)
        let added = addShoe(named: shoeName, in: app)
        XCTAssertTrue(added, "Failed during the add-shoe UI flow")

        // Wait for the shoe to appear in the list
        let shoeCell = app.staticTexts[shoeName]
        XCTAssertTrue(
            shoeCell.waitForExistence(timeout: 5),
            "Shoe did not appear in the list before attempting to tap it"
        )

        // Tap the cell to trigger the NavigationLink → ShoeDetailView
        shoeCell.tap()

        // ShoeDetailView sets .navigationTitle(shoe.name) with .large display mode.
        // The large title renders as a static text element with the shoe name.
        let detailTitle = app.navigationBars[shoeName]
        XCTAssertTrue(
            detailTitle.waitForExistence(timeout: 5),
            "Expected navigation bar titled '\(shoeName)' in ShoeDetailView"
        )

        // Corroborate with a known section header from ShoeDetailView ("Mileage")
        let mileageHeader = app.staticTexts["Mileage"]
        XCTAssertTrue(
            mileageHeader.waitForExistence(timeout: 5),
            "Expected the 'Mileage' section header to be visible in ShoeDetailView"
        )
    }

    // MARK: - Launch performance

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
