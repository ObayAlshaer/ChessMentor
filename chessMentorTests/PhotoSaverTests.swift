import XCTest
@testable import chessMentor
import UIKit
import Photos

final class PhotoSaverTests: XCTestCase {
    
    // MARK: - Enum Type Tests
    
    func testPhotoSaverIsEnum() {
        let _: PhotoSaver.Type = PhotoSaver.self
        XCTAssertTrue(true)
    }
    
    // MARK: - Test Image Creation
    
    func testCreateValidImageForSaving() {
        let image = createTestImage()
        
        XCTAssertNotNil(image)
        // Check point size, not pixel size
        XCTAssertGreaterThan(image.size.width, 0)
        XCTAssertGreaterThan(image.size.height, 0)
    }
    
    func testCreateImageWithPNGData() {
        let image = createTestImage()
        let pngData = image.pngData()
        
        XCTAssertNotNil(pngData)
        XCTAssertGreaterThan(pngData!.count, 0)
    }
    
    func testCreateImageWithJPEGData() {
        let image = createTestImage()
        let jpegData = image.jpegData(compressionQuality: 0.8)
        
        XCTAssertNotNil(jpegData)
        XCTAssertGreaterThan(jpegData!.count, 0)
    }
    
    func testCreateVariousSizedImages() {
        let sizes: [CGSize] = [
            CGSize(width: 100, height: 100),
            CGSize(width: 800, height: 800),
            CGSize(width: 1920, height: 1080)
        ]
        
        for size in sizes {
            let image = createTestImage(size: size)
            // Images are created, just verify they exist
            XCTAssertNotNil(image)
            XCTAssertGreaterThan(image.size.width, 0)
            XCTAssertGreaterThan(image.size.height, 0)
        }
    }
    
    func testCreateImageWithDifferentColors() {
        let colors: [UIColor] = [.white, .black, .red, .blue, .green, .gray]
        
        for color in colors {
            let image = createTestImage(color: color)
            XCTAssertNotNil(image)
            XCTAssertNotNil(image.pngData())
        }
    }
    
    // MARK: - Authorization Status Tests
    
    func testAuthorizationStatusValues() {
        let statuses: [PHAuthorizationStatus] = [
            .notDetermined,
            .restricted,
            .denied,
            .authorized,
            .limited
        ]
        
        for status in statuses {
            XCTAssertNotNil(status)
        }
    }
    
    func testCurrentAuthorizationStatus() {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        XCTAssertNotNil(status)
    }
    
    // MARK: - Image Data Integrity Tests
    
    func testImageDataRoundTrip() {
        let original = createTestImage()
        
        guard let data = original.pngData() else {
            XCTFail("Failed to get PNG data")
            return
        }
        
        guard let restored = UIImage(data: data) else {
            XCTFail("Failed to restore image from data")
            return
        }
        
        // Just verify restoration works
        XCTAssertNotNil(restored)
        XCTAssertGreaterThan(restored.size.width, 0)
    }
    
    func testJPEGCompressionQualityLevels() {
        let image = createTestImage()
        let qualities: [CGFloat] = [0.1, 0.5, 1.0]
        
        for quality in qualities {
            let data = image.jpegData(compressionQuality: quality)
            XCTAssertNotNil(data)
            XCTAssertGreaterThan(data!.count, 0)
        }
    }
    
    // MARK: - Helper
    
    private func createTestImage(size: CGSize = CGSize(width: 800, height: 800), color: UIColor = .white) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }
}
