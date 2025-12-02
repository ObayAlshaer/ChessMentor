//
//  LiveCaptureServiceTests.swift
//  chessMentor
//
//  Created by Mohamed-Obay Alshaer on 2025-12-01.
//

import XCTest
@testable import chessMentor
import AVFoundation

final class LiveCaptureServiceTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    @MainActor
    func testServiceInitialization() {
        let service = LiveCaptureService()
        XCTAssertNotNil(service)
    }
    
    @MainActor
    func testServiceHasSession() {
        let service = LiveCaptureService()
        XCTAssertNotNil(service.session)
    }
    
    @MainActor
    func testSessionIsAVCaptureSession() {
        let service = LiveCaptureService()
        XCTAssertTrue(service.session is AVCaptureSession)
    }
    
    @MainActor
    func testOnFrameCallbackIsNilInitially() {
        let service = LiveCaptureService()
        XCTAssertNil(service.onFrame)
    }
    
    @MainActor
    func testCanSetOnFrameCallback() {
        let service = LiveCaptureService()
        
        service.onFrame = { _ in }
        
        XCTAssertNotNil(service.onFrame)
    }
    
    @MainActor
    func testStopCanBeCalledSafely() {
        let service = LiveCaptureService()
        
        // Should not crash
        service.stop()
        
        XCTAssertNotNil(service)
    }
    
    @MainActor
    func testStopCanBeCalledMultipleTimes() {
        let service = LiveCaptureService()
        
        service.stop()
        service.stop()
        service.stop()
        
        XCTAssertNotNil(service)
    }
    
    @MainActor
    func testMultipleServiceInstances() {
        let service1 = LiveCaptureService()
        let service2 = LiveCaptureService()
        
        XCTAssertNotNil(service1)
        XCTAssertNotNil(service2)
        XCTAssertNotNil(service1.session)
        XCTAssertNotNil(service2.session)
    }
}
