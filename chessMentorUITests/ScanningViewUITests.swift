import XCTest

final class ScanningViewUITests: XCTestCase {

    // Keep the normal (non-UI-test-mode) chrome check if you want
    func testScannerChromeAppears() {
        let app = XCUIApplication()
        app.launch()

        // Navigate to scanner (your LoginView shows a NavigationLink)
        let getStarted = app.buttons["Get Started"].firstMatch
        if getStarted.waitForExistence(timeout: 5) {
            getStarted.tap()
        }

        XCTAssertTrue(app.staticTexts["Find a board to scan"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.images["Crosshairs"].exists || app.otherElements["crosshair"].exists)
    }
    func testLaunchShowsGetStartedButton() {
        let app = XCUIApplication()
        app.launch()

        // Support both an accessibility ID ("GetStartedButton") and the visible label ("Get Started")
        let byId     = app.buttons["GetStartedButton"].firstMatch
        let byLabel  = app.buttons["Get Started"].firstMatch

        // Wait generously; either one counts as success
        let found = byId.waitForExistence(timeout: 12) || byLabel.waitForExistence(timeout: 12)
        XCTAssertTrue(found, "Expected a 'Get Started' button to be visible on launch")
    }
}
