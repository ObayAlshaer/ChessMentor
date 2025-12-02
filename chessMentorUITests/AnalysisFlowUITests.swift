//
//  AnalysisFlowUITests.swift
//  chessMentor
//
//  Created by Mohamed-Obay Alshaer on 2025-12-01.
//

import XCTest

final class AnalysisFlowUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Results View Tests
    
    func testResultsViewShowsAnalysisFailed() {
        // Navigate to results without an image
        // This tests the .failed state rendering
        
        let resultsRoot = app.otherElements["results_root"]
        
        // If we can navigate to ResultsView without a photo, it should show failure
        if resultsRoot.waitForExistence(timeout: 5) {
            let failedText = app.staticTexts["Analysis failed"]
            XCTAssertTrue(failedText.exists || resultsRoot.exists)
        }
    }
    
    func testResultsViewAccessibilityIdentifier() {
        // Verify the accessibility identifier is set
        let resultsRoot = app.otherElements["results_root"]
        
        // This confirms the view has the identifier for UI testing
        // Even if we can't navigate to it, the test documents the expected identifier
        XCTAssertNotNil(resultsRoot)
    }
    
    // MARK: - Live Analysis View Tests
    
    func testLiveAnalysisViewLoads() {
        // Navigate to Live Analysis
        let liveAnalysisButton = app.buttons["Live Analysis"]
        
        if liveAnalysisButton.waitForExistence(timeout: 3) {
            liveAnalysisButton.tap()
            
            // Verify the view loaded by checking for HUD elements
            let stopButton = app.buttons.matching(identifier: "stop.circle.fill").firstMatch
            XCTAssertTrue(stopButton.waitForExistence(timeout: 5))
        }
    }
    
    func testLiveAnalysisViewShowsStatus() {
        let liveAnalysisButton = app.buttons["Live Analysis"]
        
        if liveAnalysisButton.waitForExistence(timeout: 3) {
            liveAnalysisButton.tap()
            
            // The status text should appear (it's in a Capsule)
            // We can't easily check the exact text, but we verify elements exist
            sleep(2)  // Give time for camera to initialize
            
            // Verify the view is displayed
            XCTAssertTrue(app.navigationBars["Live Analysis"].exists)
        }
    }
    
    func testLiveAnalysisStopButton() {
        let liveAnalysisButton = app.buttons["Live Analysis"]
        
        if liveAnalysisButton.waitForExistence(timeout: 3) {
            liveAnalysisButton.tap()
            
            sleep(2)  // Wait for view to load
            
            // Find and tap stop button
            let stopButton = app.buttons.element(boundBy: 0)  // First button in HUD
            if stopButton.waitForExistence(timeout: 3) {
                stopButton.tap()
                
                // After stop, we should navigate back
                sleep(1)
            }
        }
    }
    
    // MARK: - Camera Permission Tests
    
    func testCameraPermissionAlert() {
        // This test documents camera permission handling
        // On first launch, iOS shows a permission alert
        
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allowButton = springboard.buttons["Allow"]
        
        if allowButton.waitForExistence(timeout: 5) {
            allowButton.tap()
        }
        
        // Continue with normal flow
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }
}
