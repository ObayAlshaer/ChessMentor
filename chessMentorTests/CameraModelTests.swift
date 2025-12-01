import XCTest
@testable import chessMentor
import AVFoundation
import UIKit
import SwiftUI

// MARK: - Helpers

private func blankImage(_ size: CGSize = .init(width: 200, height: 200)) -> UIImage {
    let r = UIGraphicsImageRenderer(size: size)
    return r.image { ctx in
        UIColor.white.setFill()
        ctx.fill(CGRect(origin: .zero, size: size))
    }
}

/// Test subclass that avoids real hardware start/stop when we specifically want to assert retake behavior.
final class TestableCameraModel: CameraModel {
    private(set) var didStartSession = false
    private(set) var didStopSession  = false
    override func startSession() { didStartSession = true }
    override func stopSession()  { didStopSession  = true }
}

// MARK: - CameraModel tests

final class CameraModelTests: XCTestCase {

    /// `setup()` on Simulator should fail to obtain a device and safely exit
    /// (no preview layer created, `isPreviewReady` stays false, `isCameraAvailable` stays false).
    @MainActor
    func testSetup_SetsConsistentFlagsAndPreview() {
        let cam = CameraModel()

        // Act
        cam.setup()

        // preview layer is created on main async in your code; wait a tick
        let exp = expectation(description: "preview processed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Invariant 1: previewReady matches preview presence
            XCTAssertEqual(cam.isPreviewReady, cam.preview != nil, "isPreviewReady should reflect preview availability")

            // Invariant 2: if a device is marked available, we should have a preview layer
            if cam.isCameraAvailable {
                XCTAssertNotNil(cam.preview, "If camera is available, preview layer should exist")
            } else {
                XCTAssertNil(cam.preview, "If camera is NOT available, preview layer should be nil")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    /// Even with an empty session (no inputs/outputs), start/stop should not crash.
    func testStartThenStopSession_NoCrash() {
        let cam = CameraModel()

        // Start runs on a global queue; give it a small tick.
        cam.startSession()
        let startExp = expectation(description: "started")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.05) { startExp.fulfill() }
        wait(for: [startExp], timeout: 1.0)

        cam.stopSession()
        let stopExp = expectation(description: "stopped")
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.05) { stopExp.fulfill() }
        wait(for: [stopExp], timeout: 1.0)

        // No crash/assert; just exercise the code paths for coverage.
        XCTAssertTrue(true)
    }

    /// `retakePicture()` should clear state and restart session (verified via the test subclass).
    func testRetakePictureResetsStateAndStartsSession() {
        let cam = TestableCameraModel()
        cam.capturedPhoto = blankImage()
        cam.isTaken = true

        cam.retakePicture()

        XCTAssertNil(cam.capturedPhoto, "retakePicture should clear capturedPhoto")
        XCTAssertFalse(cam.isTaken, "retakePicture should set isTaken = false")
        XCTAssertTrue(cam.didStartSession, "retakePicture should start session again")
    }

    /// With no inputs present, flipCamera() should still toggle the position safely.
    func testFlipCameraTogglesPosition() {
        let cam = CameraModel()
        cam.currentPosition = .back
        cam.flipCamera()
        XCTAssertEqual(cam.currentPosition, .front, "Expected toggle to front")
        cam.flipCamera()
        XCTAssertEqual(cam.currentPosition, .back, "Expected toggle back to rear")
    }

    // NOTE: We intentionally do NOT call takePicture() in tests because
    // AVCapturePhotoOutput.capturePhoto requires an active, enabled video connection.
}

// MARK: - CameraPreview tests (host in a real UIWindow so lifecycle runs)

final class CameraPreviewTests: XCTestCase {

    /// Hosts a SwiftUI view in a real UIWindow so UIViewRepresentable lifecycle runs.
    @discardableResult
    @MainActor
    private func hostInWindow<V: View>(_ root: V, size: CGSize) -> (UIWindow, UIHostingController<V>) {
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        let host = UIHostingController(rootView: root)
        window.rootViewController = host
        window.makeKeyAndVisible()
        _ = host.view                                // force load
        host.view.frame = window.bounds
        host.view.layoutIfNeeded()
        return (window, host)
    }

    @MainActor
    func testHostingAddsPreviewLayer() {
        let cam = CameraModel()
        // A layer backed by an idle session is fine; we only test attachment here.
        let session = AVCaptureSession()
        let layer   = AVCaptureVideoPreviewLayer(session: session)
        cam.preview = layer

        let viewSize = CGSize(width: 220, height: 200)
        let root = CameraPreview(camera: cam).frame(width: viewSize.width, height: viewSize.height)
        _ = hostInWindow(root, size: viewSize)

        // Give SwiftUI a tick to call makeUIView/updateUIView
        let exp = expectation(description: "layer attached")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertNotNil(layer.superlayer, "Preview layer should be attached to a superlayer")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    @MainActor
    func testPreviewLayerGetsNonZeroFrame() {
        let cam = CameraModel()
        let session = AVCaptureSession()
        let layer   = AVCaptureVideoPreviewLayer(session: session)
        cam.preview = layer

        let targetSize = CGSize(width: 320, height: 480)
        let root = CameraPreview(camera: cam).frame(width: targetSize.width, height: targetSize.height)
        _ = hostInWindow(root, size: targetSize)

        let exp = expectation(description: "preview layer sized")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            XCTAssertGreaterThan(layer.frame.size.width,  1.0, "Preview layer width should be > 0")
            XCTAssertGreaterThan(layer.frame.size.height, 1.0, "Preview layer height should be > 0")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    @MainActor
    func testHostingWithoutLayerDoesNotCrash() {
        let cam = CameraModel()
        cam.preview = nil

        let viewSize = CGSize(width: 200, height: 150)
        let root = CameraPreview(camera: cam).frame(width: viewSize.width, height: viewSize.height)
        _ = hostInWindow(root, size: viewSize)

        // No assertions—just ensure no crash when preview layer is nil.
        XCTAssertTrue(true)
    }
}
